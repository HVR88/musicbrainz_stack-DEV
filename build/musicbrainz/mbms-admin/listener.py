#!/usr/bin/env python3
import json
import os
import subprocess
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Optional

HOST = os.getenv("MBMS_ADMIN_HOST", "0.0.0.0")
PORT = int(os.getenv("MBMS_ADMIN_PORT", "8099"))
KEY = os.getenv("MBMS_ADMIN_KEY", "")
HEADER = os.getenv("MBMS_ADMIN_HEADER", "X-MBMS-Key")
NOTIFY_URL = os.getenv(
    "MBMS_ADMIN_NOTIFY_URL", "http://limbo:5001/replication/notify"
).strip()
NOTIFY_HEADER = os.getenv("MBMS_ADMIN_NOTIFY_HEADER", "X-MBMS-Key")
NOTIFY_KEY = os.getenv("MBMS_ADMIN_NOTIFY_KEY", "") or KEY
try:
    NOTIFY_TIMEOUT = int(os.getenv("MBMS_ADMIN_NOTIFY_TIMEOUT", "5"))
except ValueError:
    NOTIFY_TIMEOUT = 5
LOCK = os.getenv("MBMS_ADMIN_LOCK", "/tmp/replication.pid")
SCRIPT = (
    os.getenv("MBMS_ADMIN_REPL_SCRIPT")
    or os.getenv("MBMS_REPL_SCRIPT")
    or "/usr/local/bin/replication.sh"
)


def pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def read_lock_pid() -> Optional[int]:
    try:
        with open(LOCK, "r", encoding="utf-8") as fh:
            return int(fh.read().strip())
    except Exception:
        return None


def write_lock_pid(pid: int) -> None:
    with open(LOCK, "w", encoding="utf-8") as fh:
        fh.write(str(pid))


def clear_lock() -> None:
    try:
        os.remove(LOCK)
    except OSError:
        pass


def start_replication() -> int:
    proc = subprocess.Popen([SCRIPT], cwd=os.path.dirname(SCRIPT) or None)
    write_lock_pid(proc.pid)
    return proc.pid


def notify_replication(pid: int, exit_code: int, duration: int) -> None:
    if not NOTIFY_URL:
        return
    payload = {
        "pid": pid,
        "exit_code": exit_code,
        "status": "ok" if exit_code == 0 else "error",
        "duration": duration,
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(NOTIFY_URL, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    if NOTIFY_KEY:
        req.add_header(NOTIFY_HEADER, NOTIFY_KEY)
    try:
        with urllib.request.urlopen(req, timeout=NOTIFY_TIMEOUT):
            pass
    except Exception:
        pass


def wait_and_clear(pid: int, start_time: float) -> None:
    exit_code = -1
    try:
        _, status = os.waitpid(pid, 0)
        exit_code = os.waitstatus_to_exitcode(status)
    except Exception:
        exit_code = -1
    duration = max(0, int(time.monotonic() - start_time))
    try:
        notify_replication(pid, exit_code, duration)
    finally:
        clear_lock()


class Handler(BaseHTTPRequestHandler):
    def _json(self, code, payload):
        data = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _drain_body(self):
        length = self.headers.get("Content-Length")
        try:
            n = int(length or 0)
        except ValueError:
            n = 0
        if n:
            self.rfile.read(n)

    def do_POST(self):
        self._drain_body()
        if self.path != "/replication/start":
            return self._json(404, {"ok": False, "error": "not found"})
        if KEY and self.headers.get(HEADER) != KEY:
            return self._json(401, {"ok": False, "error": "unauthorized"})

        pid = read_lock_pid()
        if pid and pid_alive(pid):
            return self._json(409, {"ok": False, "error": "already running", "pid": pid})
        if pid:
            clear_lock()

        try:
            start_time = time.monotonic()
            pid = start_replication()
        except Exception as exc:
            clear_lock()
            return self._json(500, {"ok": False, "error": str(exc)})

        threading.Thread(
            target=wait_and_clear, args=(pid, start_time), daemon=True
        ).start()
        return self._json(200, {"ok": True, "pid": pid})

    def do_GET(self):
        if self.path != "/replication/status":
            return self._json(404, {"ok": False, "error": "not found"})
        pid = read_lock_pid()
        running = bool(pid and pid_alive(pid))
        payload = {"running": running}
        if pid:
            payload["pid"] = pid
        return self._json(200, payload)

    def log_message(self, fmt, *args):
        return


if __name__ == "__main__":
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    server.serve_forever()
