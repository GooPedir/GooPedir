from fastapi import FastAPI, File, HTTPException, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pytesseract

from app.config import settings
from app.extractor import ExtractionError, UnsupportedFileError, extract_from_upload


class PageResponse(BaseModel):
    page: int
    mode: str
    text: str


class ExtractResponse(BaseModel):
    filename: str
    content_type: str | None
    source_type: str
    mode: str
    pages: int
    text: str
    page_results: list[PageResponse]


app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/extract", response_model=ExtractResponse)
async def extract(file: UploadFile = File(...)) -> ExtractResponse:
    data = await file.read()

    if not data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Arquivo vazio.",
        )

    try:
        result = extract_from_upload(
            filename=file.filename or "",
            content_type=file.content_type,
            data=data,
        )
    except UnsupportedFileError as exc:
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail=str(exc)) from exc
    except ExtractionError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    except pytesseract.TesseractNotFoundError as exc:  # type: ignore[name-defined]
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Tesseract nao encontrado. Instale o Tesseract ou configure TESSERACT_CMD.",
        ) from exc

    return ExtractResponse(
        filename=file.filename or "",
        content_type=file.content_type,
        source_type=result.source_type,
        mode=result.mode,
        pages=result.pages,
        text=result.text,
        page_results=[PageResponse(page=item.page, mode=item.mode, text=item.text) for item in result.page_results],
    )
