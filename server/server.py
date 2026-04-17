# server/server.py

import asyncio
import websockets
import json

from server.serializer import board_from_json, move_to_json
from agent.reasoning.alpha_beta import get_best_move


# =========================================
# CLIENT HANDLER
# =========================================

async def handle_client(websocket):

    print("Client connected")

    try:
        while True:

            # 1. Receive message
            message = await websocket.recv()

            # 2. Parse JSON
            data = json.loads(message)

            # 3. Convert to Board object
            board = board_from_json(data)

            # 4. Run engine
            move = get_best_move(board, depth=3)

            # 5. Convert move to JSON
            response = move_to_json(move)

            # 6. Send back result
            await websocket.send(json.dumps(response))

    except websockets.exceptions.ConnectionClosed:
        print("Client disconnected")

    except Exception as e:
        print("Error:", e)


# =========================================
# SERVER START
# =========================================

async def main():

    print("Starting server on ws://localhost:8765")

    async with websockets.serve(handle_client, "localhost", 8765):
        await asyncio.Future()  # run forever


if __name__ == "__main__":
    asyncio.run(main())