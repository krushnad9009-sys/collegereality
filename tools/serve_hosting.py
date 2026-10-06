"""Local preview of hosting/public with Firebase-style clean URLs (/terms -> terms.html)."""
import http.server
import os
import sys

ROOT = os.path.join(os.path.dirname(__file__), '..', 'hosting', 'public')


class CleanUrlHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def translate_path(self, path):
        local = super().translate_path(path)
        if not os.path.exists(local) and os.path.exists(local + '.html'):
            return local + '.html'
        return local


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
    http.server.ThreadingHTTPServer(('127.0.0.1', port), CleanUrlHandler).serve_forever()
