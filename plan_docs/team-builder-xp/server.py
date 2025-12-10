import http.server
import socketserver
import os

PORT = 8000

# The directory where the built site is located
web_dir = os.path.join(os.path.dirname(__file__), 'team-builder-xp', 'dist')
os.chdir(web_dir)

Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving '{os.getcwd()}' at http://localhost:{PORT}")
    print(f"You can open the site at http://localhost:{PORT}")
    httpd.serve_forever()