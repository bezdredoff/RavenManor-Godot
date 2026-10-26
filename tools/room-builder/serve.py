#!/usr/bin/env python3
"""Serve the Room Builder locally with correct module MIME types.

On Windows `python -m http.server` can serve `.mjs` as `application/octet-stream`, and the
browser then refuses the ES module, leaving the editor stuck on "Загрузка каталога…".
Run this from `tools/room-builder` (or pass `--directory`).
"""
import argparse
import http.server
import socketserver


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".mjs": "text/javascript",
        ".js": "text/javascript",
        ".json": "application/json",
        ".webmanifest": "application/manifest+json",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=4173)
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--directory", default=".")
    args = parser.parse_args()
    handler = lambda *a, **kw: Handler(*a, directory=args.directory, **kw)
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer((args.bind, args.port), handler) as server:
        print(f"Room Builder: http://{args.bind}:{args.port}/")
        server.serve_forever()


if __name__ == "__main__":
    main()
