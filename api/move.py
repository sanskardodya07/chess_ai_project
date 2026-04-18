import json
import os
import sys

# Ensure repo root is on the import path for Vercel runtime
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from server.board_builder import build_board_from_json
from agent.reasoning.alpha_beta import get_best_move


def _json_body(request):
    body = getattr(request, "body", None)
    if body is None:
        raise ValueError("Missing request body")
    if isinstance(body, (bytes, bytearray)):
        body = body.decode("utf-8")
    return json.loads(body)


def handler(request):
    """Vercel serverless function handler for AI move calculation."""
    if request.method == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
        }

    if request.method != "POST":
        return {
            "statusCode": 405,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Method not allowed"})
        }

    try:
        payload = _json_body(request)
        board = build_board_from_json(payload)
        ai_move = get_best_move(board, depth=3)

        if ai_move is None:
            return {
                "statusCode": 200,
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": json.dumps({"status": "no_move", "ai_move": None})
            }

        return {
            "statusCode": 200,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({
                "status": "ok",
                "ai_move": {
                    "start": [ai_move.start_row, ai_move.start_col],
                    "end": [ai_move.end_row, ai_move.end_col],
                    "piece_moved": ai_move.piece_moved,
                    "piece_captured": ai_move.piece_captured,
                    "promotion": ai_move.promotion,
                    "is_castle": ai_move.is_castling,
                    "is_en_passant": ai_move.is_en_passant,
                }
            })
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"status": "error", "message": str(e)})
        }


# Expose aliases for Vercel runtime compatibility
app = handler
application = handler
