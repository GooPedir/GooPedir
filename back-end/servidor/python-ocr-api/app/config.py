import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "OCR API")
    ocr_language: str = os.getenv("OCR_LANGUAGE", "por+eng")
    pdf_render_dpi: int = int(os.getenv("PDF_RENDER_DPI", "220"))
    tesseract_cmd: str | None = os.getenv("TESSERACT_CMD")


settings = Settings()
