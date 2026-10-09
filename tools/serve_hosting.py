"""Local preview with Firebase-style clean URLs (/terms -> terms.html).

Usage: python tools/serve_hosting.py [port] [dir]  (dir defaults to hosting/public;
use build/web to preview the full deploy after tools/build_web_hosting.py).
"""
import http.server
import os
import sys

ROOT = os.path.join(os.path.dirname(__file__), '..', 'hosting', 'public')
if len(sys.argv) > 2:
    ROOT = os.path.abspath(sys.argv[2])


class CleanUrlHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def translate_path(self, path):
        local = super().translate_path(path)
        if not os.path.exists(local) and os.path.exists(local + '.html'):
            return local + '.html'
        return local

    def end_headers(self):
        # Local preview only: make browsers recheck every file, so a page
        # edited (or served from a different folder) earlier never sticks
        # around from cache.
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
    http.server.ThreadingHTTPServer(('127.0.0.1', port), CleanUrlHandler).serve_forever()
