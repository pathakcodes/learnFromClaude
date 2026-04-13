#!/usr/bin/env python3
"""learnFromClaude dashboard server.

Serves the static dashboard and a small JSON API:
  GET  /                    -> dashboard.html
  GET  /flashcards.json     -> card DB (no-cache)
  GET  /api/config          -> {"content": "<CONFIG.md contents>"}
  POST /api/config          -> {"content": "..."} overwrites CONFIG.md atomically
  POST /api/config/reset    -> restores CONFIG.md from CONFIG.default.md
  POST /api/toggle-like     -> {"id": "<card-id>"}  flips liked flag, persists
  POST /api/delete          -> {"id": "<card-id>"}  removes a card

Binds to 127.0.0.1 only. Single-threaded so we never race on disk,
and every write is atomic (tmp + os.replace).
"""
import http.server
import socketserver
import os
import sys
import json
import shutil
import webbrowser
import datetime
import threading

PORT = int(os.environ.get("LEARN_FROM_CLAUDE_PORT",
           os.environ.get("LEARNING_COACH_PORT", "8765")))
# ROOT = plugin install dir (static assets: dashboard.html, default CONFIG.md).
# realpath dereferences any ~/.local/bin launcher symlink.
ROOT = os.path.dirname(os.path.realpath(__file__))

# DATA_DIR = user home (per-user state: cards, sessions, user-edited CONFIG.md).
# Plugin installs under ~/.claude/plugins/cache/... get wiped on update — so
# anything we want to keep lives here instead.
DATA_DIR = os.path.expanduser(
    os.environ.get("LFC_DATA_DIR", "~/.claude/learnFromClaude")
)
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(os.path.join(DATA_DIR, "sessions"), exist_ok=True)

FLASHCARDS = os.path.join(DATA_DIR, "flashcards.json")
CONFIG_FILE = os.path.join(DATA_DIR, "CONFIG.md")
# The plugin ships CONFIG.md as its default; the user's copy is editable.
CONFIG_DEFAULT = os.path.join(ROOT, "CONFIG.md")

# First-run bootstrap: copy shipped default into DATA_DIR so the user has
# something to edit, and initialize an empty card store.
if not os.path.exists(CONFIG_FILE) and os.path.exists(CONFIG_DEFAULT):
    shutil.copyfile(CONFIG_DEFAULT, CONFIG_FILE)
if not os.path.exists(FLASHCARDS):
    with open(FLASHCARDS, "w") as _f:
        _f.write("[]")

# Guards concurrent reads/writes from the (single-threaded) HTTP handler.
# Belt-and-braces: the server is ST, but this makes the intent explicit and
# future-proofs against a swap to ThreadingTCPServer.
FILE_LOCK = threading.Lock()


def _read_cards():
    try:
        with open(FLASHCARDS, "r") as f:
            data = json.load(f)
        return data if isinstance(data, list) else []
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def _write_cards(cards):
    tmp = FLASHCARDS + ".tmp"
    with open(tmp, "w") as f:
        json.dump(cards, f, indent=2)
    os.replace(tmp, FLASHCARDS)  # atomic on POSIX


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def log_message(self, fmt, *args):
        # Silence the default access log.
        pass

    def do_GET(self):
        if self.path in ("/", ""):
            self.path = "/dashboard.html"
        if self.path == "/api/config":
            return self._handle_get_config()
        # /flashcards.json lives in DATA_DIR (user home), not ROOT (plugin dir).
        # Read and reply directly so plugin updates don't orphan the card DB.
        if self.path.split("?", 1)[0] == "/flashcards.json":
            return self._handle_get_flashcards()
        return super().do_GET()

    def _handle_get_flashcards(self):
        try:
            with open(FLASHCARDS, "rb") as f:
                body = f.read()
        except FileNotFoundError:
            body = b"[]"
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.end_headers()
        self.wfile.write(body)

    def _handle_get_config(self):
        try:
            content = open(CONFIG_FILE).read() if os.path.exists(CONFIG_FILE) else ""
        except OSError as e:
            return self._json_reply(500, {"error": str(e)})
        return self._json_reply(200, {"content": content, "path": CONFIG_FILE})

    def end_headers(self):
        if self.path.startswith("/flashcards.json"):
            self.send_header("Cache-Control", "no-store, max-age=0")
        super().end_headers()

    # ---------- JSON API ----------

    def _json_reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self):
        length = int(self.headers.get("Content-Length", "0") or "0")
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        try:
            return json.loads(raw.decode())
        except (json.JSONDecodeError, UnicodeDecodeError):
            return {}

    def do_POST(self):
        if self.path == "/api/toggle-like":
            return self._handle_toggle_like()
        if self.path == "/api/delete":
            return self._handle_delete()
        if self.path == "/api/config":
            return self._handle_save_config()
        if self.path == "/api/config/reset":
            return self._handle_reset_config()
        self._json_reply(404, {"error": "not found"})

    def _handle_save_config(self):
        data = self._read_body()
        content = data.get("content")
        if not isinstance(content, str):
            return self._json_reply(400, {"error": "content (string) required"})
        # Refuse pathological payloads. 64 KB is comfortably above the default
        # CONFIG.md size (~5 KB) but stops accidental log-paste mishaps.
        if len(content) > 64 * 1024:
            return self._json_reply(413, {"error": "config too large (>64KB)"})
        with FILE_LOCK:
            tmp = CONFIG_FILE + ".tmp"
            with open(tmp, "w") as f:
                f.write(content)
            os.replace(tmp, CONFIG_FILE)
        return self._json_reply(200, {"ok": True, "bytes": len(content)})

    def _handle_reset_config(self):
        if not os.path.exists(CONFIG_DEFAULT):
            return self._json_reply(404, {"error": "no default config available"})
        with FILE_LOCK:
            # Copy the default over — CONFIG.default.md is read-only, CONFIG.md is not.
            shutil.copyfile(CONFIG_DEFAULT, CONFIG_FILE)
        content = open(CONFIG_FILE).read()
        return self._json_reply(200, {"ok": True, "content": content})

    def _handle_toggle_like(self):
        data = self._read_body()
        card_id = data.get("id")
        if not card_id:
            return self._json_reply(400, {"error": "id required"})

        now = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
        with FILE_LOCK:
            cards = _read_cards()
            updated = None
            for c in cards:
                if c.get("id") == card_id:
                    liked = not bool(c.get("liked", False))
                    c["liked"] = liked
                    c["liked_at"] = now if liked else None
                    updated = c
                    break
            if updated is None:
                return self._json_reply(404, {"error": "card not found"})
            _write_cards(cards)

        return self._json_reply(200, {"ok": True, "card": updated})

    def _handle_delete(self):
        data = self._read_body()
        card_id = data.get("id")
        if not card_id:
            return self._json_reply(400, {"error": "id required"})

        with FILE_LOCK:
            cards = _read_cards()
            before = len(cards)
            cards = [c for c in cards if c.get("id") != card_id]
            if len(cards) == before:
                return self._json_reply(404, {"error": "card not found"})
            _write_cards(cards)

        return self._json_reply(200, {"ok": True})


def main():
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
        url = f"http://127.0.0.1:{PORT}/"
        print(f"learnFromClaude dashboard: {url}")
        print("Ctrl-C to stop.")
        if "--no-open" not in sys.argv:
            try:
                webbrowser.open(url)
            except Exception:
                pass
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nbye")


if __name__ == "__main__":
    main()
