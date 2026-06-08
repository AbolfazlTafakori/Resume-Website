import http.server, os, sys

port = int(os.environ.get('PORT', 3000))
os.chdir(os.path.join(os.path.dirname(__file__), 'Frontend'))
handler = http.server.SimpleHTTPRequestHandler
with http.server.HTTPServer(('', port), handler) as httpd:
    print(f'Serving Frontend on port {port}', flush=True)
    httpd.serve_forever()
