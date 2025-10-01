
import os
import sys
import time
import threading
import configparser
import urllib.request
import socket
from urllib.parse import urlparse
from pathlib import Path

import webview

try:
    from screeninfo import get_monitors
except Exception:
    get_monitors = None  # uso opcional

APP_NAME = "GooPedir Kiosk"

def is_frozen():
    return getattr(sys, 'frozen', False)

def exec_dir() -> Path:
    return Path(sys.executable).parent if is_frozen() else Path(__file__).parent

def bundle_dir() -> Path:
    return Path(getattr(sys, '_MEIPASS', exec_dir()))

EXEC_DIR = exec_dir()
BUNDLE_DIR = bundle_dir()
CONFIG_PATH = EXEC_DIR / 'config.ini'
FALLBACK_EXTERNAL = EXEC_DIR / 'fallback.html'
FALLBACK_BUNDLED = BUNDLE_DIR / 'fallback.html'

state = {
    'cfg': None,
    'cfg_mtime': None,
    'window': None,
    'current_url': None,
}

DEFAULT_CONFIG = """[app]
title = Painel de Chamadas
url = https://seu-dominio.com/tv/painel
# Tela cheia controlada pelo app
fullscreen = true
# Índice do monitor (0 = principal). Use 1 para monitor secundário. -1 para padrão do SO.
monitor_index = -1
# Recarrega periodicamente a página (em segundos)
refresh_interval_seconds = 5
user_agent = GooPedir-Kiosk/1.0

[advanced]
# Verificação do arquivo ini (segundos)
ini_watch_seconds = 3
# Timeout do healthcheck (segundos)
health_timeout = 8
# Pular healthcheck inicial (útil para localhost e dev)
skip_healthcheck = false
"""

DEFAULT_FALLBACK = """<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="utf-8" />
    <title>Sem conexão</title>
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <style>
      html,body{height:100%;margin:0;background:#0b0c0f;color:#f5f6fa;
        font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Cantarell,'Helvetica Neue',Arial,'Noto Sans',sans-serif}
      .wrap{display:flex;align-items:center;justify-content:center;height:100%;text-align:center;padding:24px}
      h1{font-size:42px;margin:0 0 8px;border-left:6px solid rgb(168,0,28);padding-left:12px}
      p{opacity:.8;max-width:720px;margin:8px auto 0}
      small{opacity:.5;display:block;margin-top:16px}
    </style>
  </head>
  <body>
    <div class="wrap">
      <div>
        <h1>Painel indisponível</h1>
        <p>Tentando reconectar ao painel… Verifique a internet ou o endereço configurado.</p>
        <small>powered by goopedir.com</small>
      </div>
    </div>
  </body>
</html>
"""

def ensure_files_exist():
    if not CONFIG_PATH.exists():
        CONFIG_PATH.write_text(DEFAULT_CONFIG, encoding='utf-8')
    if not FALLBACK_EXTERNAL.exists():
        try:
            FALLBACK_EXTERNAL.write_text(DEFAULT_FALLBACK, encoding='utf-8')
        except Exception:
            pass

def load_config():
    cfgp = configparser.ConfigParser()
    cfgp.read(CONFIG_PATH, encoding='utf-8')
    title = cfgp.get('app', 'title', fallback='Painel')
    url = cfgp.get('app', 'url', fallback='about:blank')
    fullscreen = cfgp.getboolean('app', 'fullscreen', fallback=True)
    monitor_index = cfgp.getint('app', 'monitor_index', fallback=-1)
    refresh_interval = cfgp.getint('app', 'refresh_interval_seconds', fallback=5)
    user_agent = cfgp.get('app', 'user_agent', fallback='GooPedir-Kiosk/1.0')

    ini_watch_seconds = cfgp.getint('advanced', 'ini_watch_seconds', fallback=3)
    health_timeout = cfgp.getint('advanced', 'health_timeout', fallback=8)
    skip_healthcheck = cfgp.getboolean('advanced', 'skip_healthcheck', fallback=False)

    return {
        'title': title,
        'url': url,
        'fullscreen': fullscreen,
        'monitor_index': monitor_index,
        'refresh_interval': refresh_interval,
        'user_agent': user_agent,
        'ini_watch_seconds': ini_watch_seconds,
        'health_timeout': health_timeout,
        'skip_healthcheck': skip_healthcheck,
    }

def is_localhost(url: str) -> bool:
    try:
        host = urlparse(url).hostname or ""
        return host in ("localhost", "127.0.0.1", "::1")
    except Exception:
        return False

def check_url_alive(url: str, timeout: int) -> bool:
    try:
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        req = urllib.request.Request(url, method='GET')
        req.add_header('User-Agent', state['cfg']['user_agent'])
        with opener.open(req, timeout=timeout) as resp:
            status = getattr(resp, 'status', 200)
            return 100 <= status < 600
    except Exception:
        if is_localhost(url):
            try:
                parsed = urlparse(url)
                port = parsed.port or (443 if parsed.scheme == 'https' else 80)
                with socket.create_connection((parsed.hostname, port), timeout=timeout):
                    return True
            except Exception:
                return False
        return False

def pick_fallback_file() -> Path:
    if FALLBACK_EXTERNAL.exists():
        return FALLBACK_EXTERNAL
    if FALLBACK_BUNDLED.exists():
        return FALLBACK_BUNDLED
    tmp = EXEC_DIR / 'fallback_tmp.html'
    tmp.write_text(DEFAULT_FALLBACK, encoding='utf-8')
    return tmp

def pick_start_url():
    url = state['cfg']['url']
    if state['cfg']['skip_healthcheck'] or is_localhost(url):
        return url
    if check_url_alive(url, state['cfg']['health_timeout']):
        return url
    return pick_fallback_file().as_uri()

def set_window_url(target: str):
    if state['current_url'] == target:
        try:
            state['window'].reload()
        except Exception:
            pass
        return
    state['current_url'] = target
    state['window'].load_url(target)

def position_on_monitor(window, monitor_index: int, fullscreen: bool):
    if monitor_index < 0 or get_monitors is None:
        if fullscreen:
            try:
                window.toggle_fullscreen()
            except Exception:
                pass
        return

    try:
        monitors = get_monitors()
        if not monitors:
            if fullscreen:
                try: window.toggle_fullscreen()
                except Exception: pass
            return
        if monitor_index >= len(monitors):
            monitor_index = 0

        m = monitors[monitor_index]
        try:
            window.move(m.x, m.y)
            window.resize(m.width, m.height)
        except Exception:
            pass

        if fullscreen:
            def _fs():
                time.sleep(0.2)
                try:
                    window.toggle_fullscreen()
                except Exception:
                    pass
            threading.Thread(target=_fs, daemon=True).start()

    except Exception:
        if fullscreen:
            try:
                window.toggle_fullscreen()
            except Exception:
                pass

def kiosk_loop():
    while True:
        time.sleep(state['cfg']['ini_watch_seconds'])
        try:
            mtime = CONFIG_PATH.stat().st_mtime
            if state['cfg_mtime'] is None or mtime != state['cfg_mtime']:
                state['cfg'] = load_config()
                state['cfg_mtime'] = mtime
                url = state['cfg']['url']
                if state['cfg']['skip_healthcheck'] or is_localhost(url) or check_url_alive(url, state['cfg']['health_timeout']):
                    set_window_url(url)
                else:
                    set_window_url(pick_fallback_file().as_uri())
        except Exception:
            pass

def on_loaded():
    def refresher():
        while True:
            time.sleep(state['cfg']['refresh_interval'])
            try:
                if state['current_url'].startswith('file://'):
                    url = state['cfg']['url']
                    if state['cfg']['skip_healthcheck'] or is_localhost(url) or check_url_alive(url, state['cfg']['health_timeout']):
                        set_window_url(url)
                    continue
                state['window'].reload()
            except Exception:
                pass
    threading.Thread(target=refresher, daemon=True).start()

def on_shown():
    position_on_monitor(state['window'], state['cfg']['monitor_index'], state['cfg']['fullscreen'])

def on_key_down(e):
    try:
        if e and getattr(e, 'key', '').lower() == 'q' and e.ctrl and e.shift:
            state['window'].destroy()
    except Exception:
        pass

def main():
    ensure_files_exist()
    state['cfg'] = load_config()
    try:
        state['cfg_mtime'] = CONFIG_PATH.stat().st_mtime
    except FileNotFoundError:
        state['cfg_mtime'] = None

    start_url = pick_start_url()
    window = webview.create_window(
        state['cfg']['title'],
        url=start_url,
        fullscreen=False,
        confirm_close=False,
        text_select=False,
        easy_drag=False
    )
    state['window'] = window
    state['current_url'] = start_url

    window.events.loaded += on_loaded
    try:
        window.events.shown += on_shown
    except Exception:
        def _late_pos():
            time.sleep(0.6)
            on_shown()
        threading.Thread(target=_late_pos, daemon=True).start()

    try:
        window.events.key_down += on_key_down
    except Exception:
        pass

    threading.Thread(target=kiosk_loop, daemon=True).start()

    webview.start(gui=None, private_mode=True, storage_path=None)

if __name__ == '__main__':
    main()
