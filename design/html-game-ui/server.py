#!/usr/bin/env python3
"""Serve the repository root so the design sandbox can use canonical assets."""

from __future__ import annotations

import argparse
import functools
import http.server
from pathlib import Path
import socketserver


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=4173)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[2]
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=repo_root)

    class ReusableTCPServer(socketserver.TCPServer):
        allow_reuse_address = True

    with ReusableTCPServer((args.host, args.port), handler) as server:
        print(
            f"Serving {repo_root}\n"
            f"Open http://{args.host}:{args.port}/design/html-game-ui/"
        )
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nStopped.")


if __name__ == "__main__":
    main()
