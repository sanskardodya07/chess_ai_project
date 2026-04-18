import json
from server.board_builder import build_board_from_json
from agent.reasoning.alpha_beta import get_best_move

def handler(request):
    """Vercel serverless function handler for AI move calculation."""
    
    # Handle CORS preflight
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
        return {"statusCode": 405, "body": json.dumps({"error": "Method not allowed"})}
    
    try:
        payload = request.json
        board = build_board_from_json(payload)
        ai_move = get_best_move(board, depth=3)

        if ai_move is None:
            return {
                "statusCode": 200,
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": json.dumps({
                    "status": "no_move",
                    "ai_move": None
                })
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
