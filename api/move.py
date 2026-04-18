from http.server import BaseHTTPRequestHandler
import json

class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        response = {
            'message': 'Function works!',
            'ai_move': {
                'start': [6, 4],
                'end': [4, 4],
                'piece_moved': 'wP'
            }
        }
        self.wfile.write(json.dumps(response).encode('utf-8'))
        return

    def do_POST(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        response = {
            'message': 'Function works!',
            'ai_move': {
                'start': [6, 4],
                'end': [4, 4],
                'piece_moved': 'wP'
            }
        }
        self.wfile.write(json.dumps(response).encode('utf-8'))
        return
