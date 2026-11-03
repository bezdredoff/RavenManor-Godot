#!/usr/bin/env python3
"""Real-browser smoke for the generated production dashboard Pages artifact.

No external network, playwright package, or document rewriting. Chrome's
headless DOM dump executes the *actual* index.html / app.mjs via local HTTP.
"""
from __future__ import annotations
import argparse
import http.server
import re
import shutil
import subprocess
import tempfile
import threading
from functools import partial
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    for name in ["index.html", "app.mjs", "status.json"]:
        if not (root / name).is_file():
            raise SystemExit(f"Missing dashboard artifact: {name}")
    chrome = next((shutil.which(c) for c in ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser") if shutil.which(c)), None)
    if not chrome:
        raise SystemExit("Dashboard browser smoke requires installed Chrome/Chromium")
    handler = partial(http.server.SimpleHTTPRequestHandler, directory=str(root))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    worker = threading.Thread(target=server.serve_forever, daemon=True)
    worker.start()
    try:
        with tempfile.TemporaryDirectory(prefix="raven-dashboard-chrome-") as profile:
            url = f"http://127.0.0.1:{server.server_port}/"
            proc = subprocess.run([chrome, "--headless=new", "--no-sandbox",
                "--disable-gpu", "--disable-dev-shm-usage",
                "--disable-background-networking", "--no-first-run",
                "--user-data-dir=" + profile, "--virtual-time-budget=8000",
                "--dump-dom", url], capture_output=True, text=True, timeout=45)
            if proc.returncode:
                raise AssertionError(f"Chrome failed ({proc.returncode}): {proc.stderr[-2000:]}")
            doc = proc.stdout
            full = re.search(r'id="tasks"[^>]*data-rendered-count="(\d+)"', doc)
            brief = re.search(r'id="quick-tasks"[^>]*data-spotlight-count="(\d+)"', doc)
            if not full or int(full.group(1)) < 1:
                raise AssertionError("Dashboard failed to render visible task cards. Page: " + doc[:3000])
            if not brief or int(brief.group(1)) < 1:
                raise AssertionError("Dashboard failed to render the visible P0 shortlist. Page: " + doc[:3000])
            if 'Не удалось' in doc and 'Загрузка не удалась:' in doc:
                raise AssertionError("Dashboard showed an error instead of task cards")
            print(f"Dashboard real-browser PASS: {full.group(1)} task cards and {brief.group(1)} P0 shortcuts visible")
    finally:
        server.shutdown()
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
