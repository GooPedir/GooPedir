from __future__ import annotations

import io
from dataclasses import dataclass
from typing import Literal

import fitz
import pytesseract
from PIL import Image, UnidentifiedImageError

from app.config import settings


SourceType = Literal["pdf", "image"]
ExtractionMode = Literal["text", "ocr", "mixed"]


@dataclass
class PageResult:
    page: int
    mode: ExtractionMode
    text: str


@dataclass
class ExtractionResult:
    source_type: SourceType
    mode: ExtractionMode
    pages: int
    text: str
    page_results: list[PageResult]


class UnsupportedFileError(ValueError):
    pass


class ExtractionError(RuntimeError):
    pass


def configure_tesseract() -> None:
    if settings.tesseract_cmd:
        pytesseract.pytesseract.tesseract_cmd = settings.tesseract_cmd


def extract_from_upload(filename: str, content_type: str | None, data: bytes) -> ExtractionResult:
    configure_tesseract()

    if _looks_like_pdf(filename, content_type, data):
        return extract_pdf(data)

    if _looks_like_image(filename, content_type):
        return extract_image(data)

    raise UnsupportedFileError("Arquivo nao suportado. Envie PDF, PNG, JPG, JPEG, TIFF ou BMP.")


def extract_pdf(data: bytes) -> ExtractionResult:
    try:
        doc = fitz.open(stream=data, filetype="pdf")
    except Exception as exc:
        raise ExtractionError("Nao foi possivel abrir o PDF.") from exc

    page_results: list[PageResult] = []

    for page_index, page in enumerate(doc, start=1):
        direct_text = page.get_text("text").strip()

        if direct_text:
            page_results.append(PageResult(page=page_index, mode="text", text=direct_text))
            continue

        text = _ocr_pdf_page(page).strip()
        page_results.append(PageResult(page=page_index, mode="ocr", text=text))

    mode = _resolve_mode([page.mode for page in page_results])
    text = "\n\n".join(page.text for page in page_results if page.text)

    return ExtractionResult(
        source_type="pdf",
        mode=mode,
        pages=len(page_results),
        text=text,
        page_results=page_results,
    )


def extract_image(data: bytes) -> ExtractionResult:
    try:
        image = Image.open(io.BytesIO(data))
        image.load()
    except UnidentifiedImageError as exc:
        raise ExtractionError("Nao foi possivel abrir a imagem.") from exc

    text = _ocr_image(image).strip()
    page = PageResult(page=1, mode="ocr", text=text)

    return ExtractionResult(
        source_type="image",
        mode="ocr",
        pages=1,
        text=text,
        page_results=[page],
    )


def _ocr_pdf_page(page: fitz.Page) -> str:
    pixmap = page.get_pixmap(dpi=settings.pdf_render_dpi, alpha=False)
    image = Image.open(io.BytesIO(pixmap.tobytes("png")))
    return _ocr_image(image)


def _ocr_image(image: Image.Image) -> str:
    if image.mode not in ("RGB", "L"):
        image = image.convert("RGB")
    return pytesseract.image_to_string(image, lang=settings.ocr_language)


def _resolve_mode(modes: list[ExtractionMode]) -> ExtractionMode:
    unique_modes = set(modes)
    if unique_modes == {"text"}:
        return "text"
    if unique_modes == {"ocr"}:
        return "ocr"
    return "mixed"


def _looks_like_pdf(filename: str, content_type: str | None, data: bytes) -> bool:
    return (
        filename.lower().endswith(".pdf")
        or content_type == "application/pdf"
        or data.startswith(b"%PDF")
    )


def _looks_like_image(filename: str, content_type: str | None) -> bool:
    image_extensions = (".png", ".jpg", ".jpeg", ".tif", ".tiff", ".bmp", ".webp")
    return filename.lower().endswith(image_extensions) or bool(content_type and content_type.startswith("image/"))
