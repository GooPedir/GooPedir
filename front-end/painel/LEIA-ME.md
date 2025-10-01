
# GooPedir Kiosk v3 (Python + pywebview + monitor secundário)

Projeto pronto para:
- **Tela cheia**/kiosk
- **Ler `config.ini`** ao lado do `.exe` (cria se não existir)
- **Fallback offline** (`fallback.html` externo ou embutido)
- **Healthcheck robusto** (localhost, sem proxy, timeout configurável, skip opcional)
- **Escolher monitor** (`monitor_index`), abrindo no **monitor secundário** sem ser o principal

## Estrutura
```
painel-kiosk-v3/
├─ main.py
├─ config.ini
├─ fallback.html
└─ requirements.txt
```

## Requisitos
- Python 3.9+
- Windows / Linux / macOS
- `pywebview==4.4`
- **(opcional)** `screeninfo` (para selecionar monitor)

```bash
python -m venv .venv
# Windows
.\.venv\Scriptsctivate
# Linux/Mac
source .venv/bin/activate

pip install -r requirements.txt
```

### Linux (WebKitGTK)
```bash
sudo apt-get update
sudo apt-get install -y libwebkit2gtk-4.0-37 libwebkit2gtk-4.0-dev
```

## Configuração (`config.ini`)
```ini
[app]
title = Painel de Chamadas
url = http://127.0.0.1:3000/painel/1
fullscreen = true
monitor_index = 1          ; 0 = principal, 1 = secundário, -1 = padrão do SO
refresh_interval_seconds = 5
user_agent = GooPedir-Kiosk/1.0

[advanced]
ini_watch_seconds = 3
health_timeout = 8
skip_healthcheck = true    ; para dev/local, abre direto a URL
```

## Rodar em desenvolvimento
```bash
python main.py
```

## Build (Windows .exe)

### Opção A — com fallback externo (recomendado para fácil edição)
```powershell
pip install pyinstaller
pyinstaller --name GooPedirKiosk --onefile --noconsole main.py
# copie config.ini e fallback.html para a mesma pasta do GooPedirKiosk.exe
```

### Opção B — embutindo o fallback.html no executável
```powershell
pyinstaller --name GooPedirKiosk --onefile --noconsole --add-data "fallback.html:."
# no CMD, use ; em vez de :
# pyinstaller --name GooPedirKiosk --onefile --noconsole --add-data "fallback.html;."
```

## Dicas
- **“Arquivo não encontrado”**: resolvido nessa versão. O app cria `config.ini` e aceita `fallback.html` ao lado do exe ou embutido.
- **URL `localhost`**: prefira `http://127.0.0.1:3000/...` e considere `skip_healthcheck = true` no `[advanced]`.
- **Sair do kiosk**: `Ctrl + Shift + Q`.
- **Monitor secundário**: defina `monitor_index = 1`. Se a detecção falhar, o app cai para fullscreen no monitor padrão.
