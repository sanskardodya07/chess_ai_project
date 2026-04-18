from fastapi import FastAPI
from api.deserializer import board_from_json
from api.serializer import move_to_json
from agent.reasoning.alpha_beta import get_best_move

app = FastAPI()

@app.post("/api/move")
async def get_move(request: dict):
    board_data = request["board"]
    depth = request.get("depth", 3)

    board = board_from_json(board_data)
    move = get_best_move(board, depth)

    return {
        "move": move_to_json(move)
    }