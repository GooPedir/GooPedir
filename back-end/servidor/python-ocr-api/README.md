# OCR API

API em Python para extrair texto de PDFs e imagens.

Ela tenta extrair texto direto de PDFs pesquisaveis. Quando a pagina nao tem texto selecionavel, renderiza a pagina como imagem e usa OCR com Tesseract. Para imagens, usa OCR diretamente.

## Recursos

- `GET /health`: verifica se a API esta online.
- `POST /extract`: recebe um arquivo via `multipart/form-data` no campo `file`.
- Suporte a PDF, PNG, JPG, JPEG, TIFF, BMP e WEBP.
- OCR em portugues e ingles por padrao (`por+eng`).
- Dockerfile com Tesseract e idiomas instalados.

## Rodando local no Windows

1. Instale o Python 3.12+.
2. Instale o Tesseract OCR:
   - https://github.com/UB-Mannheim/tesseract/wiki
3. Crie o ambiente virtual:

```powershell
cd python-ocr-api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

4. Se o Tesseract nao estiver no `PATH`, configure:

```powershell
$env:TESSERACT_CMD="C:\Program Files\Tesseract-OCR\tesseract.exe"
```

5. Suba a API:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

A documentacao interativa fica em:

```text
http://localhost:8000/docs
```

## Rodando com Docker

```powershell
cd python-ocr-api
docker build -t ocr-api .
docker run --rm -p 8000:8000 ocr-api
```

Ou com Docker Compose:

```powershell
cd python-ocr-api
docker compose up --build
```

## Exemplo de chamada

```powershell
curl.exe -X POST "http://localhost:8000/extract" `
  -F "file=@C:\caminho\arquivo.pdf"
```

Resposta:

```json
{
  "filename": "arquivo.pdf",
  "content_type": "application/pdf",
  "source_type": "pdf",
  "mode": "mixed",
  "pages": 2,
  "text": "Texto extraido...",
  "page_results": [
    {
      "page": 1,
      "mode": "text",
      "text": "Texto da pagina 1..."
    }
  ]
}
```

## Variaveis de ambiente

| Variavel | Padrao | Descricao |
| --- | --- | --- |
| `APP_NAME` | `OCR API` | Nome exibido no OpenAPI. |
| `OCR_LANGUAGE` | `por+eng` | Idiomas usados pelo Tesseract. |
| `PDF_RENDER_DPI` | `220` | Qualidade da renderizacao de PDFs escaneados. |
| `TESSERACT_CMD` | vazio | Caminho do executavel do Tesseract no Windows. |
