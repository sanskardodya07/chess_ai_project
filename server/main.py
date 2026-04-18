import json
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from server.board_builder import build_board_from_json
from agent.reasoning.alpha_beta import get_best_move

app = FastAPI()

# Enable CORS for Flutter web and mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def health():
    return {"status": "Chess AI server running"}


@app.post("/api/move")
async def get_ai_move(payload: dict):
    """
    POST endpoint for AI move calculation.
    Expects board state JSON in request body.
    Returns AI move as JSON response.
    """
    try:
        board = build_board_from_json(payload)
        ai_move = get_best_move(board, depth=3)

        if ai_move is None:
            return {
                "status": "no_move",
                "ai_move": None
            }

        return {
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
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }