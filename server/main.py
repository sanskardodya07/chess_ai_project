import json
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

from server.board_builder import build_board_from_json
from agent.reasoning.alpha_beta import get_best_move

app = FastAPI()


@app.get("/")
def health():
    return {"status": "Chess AI server running"}


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):

    await websocket.accept()

    try:
        while True:

            raw = await websocket.receive_text()
            payload = json.loads(raw)

            board = build_board_from_json(payload)

            ai_move = get_best_move(board, depth=3)

            if ai_move is None:
                await websocket.send_text(json.dumps({
                    "status": "no_move",
                    "move": None
                }))
                continue

            await websocket.send_text(json.dumps({
                "status": "ok",
                "move": {
                    "start": [ai_move.start_row, ai_move.start_col],
                    "end": [ai_move.end_row, ai_move.end_col],
                    "piece_moved": ai_move.piece_moved,
                    "piece_captured": ai_move.piece_captured,
                    "promotion": ai_move.promotion,
                    "is_castle": ai_move.is_castling,
                    "is_en_passant": ai_move.is_en_passant,
                }
            }))

    except WebSocketDisconnect:
        print("Client disconnected")