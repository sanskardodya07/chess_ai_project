import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from api.deserializer import board_from_json
from api.serializer import move_to_json
from agent.reasoning.alpha_beta import get_best_move

app = FastAPI()

# ✅ Add this — allows Flutter web to call your API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # or restrict to your domain later
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/move")
async def get_move(request: Request):
    body = await request.json()
    board_data = body["board"]
    depth = body.get("depth", 3)

    board = board_from_json(board_data)
    move = get_best_move(board, depth)

    return {"move": move_to_json(move)}