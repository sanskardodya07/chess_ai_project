# server/test_client.py

import asyncio
import websockets
import json


async def test():

    uri = "ws://localhost:8765"

    async with websockets.connect(uri) as websocket:

        # same test board you used earlier
        data = {
            "board": [
                ["bR","bN","bB","bQ","bK","bB","bN","bR"],
                ["bP","bP","bP","bP","bP","bP","bP","bP"],
                ["","","","","","","",""],
                ["","","","","","","",""],
                ["","","","","","","",""],
                ["","","","","","","",""],
                ["wP","wP","wP","wP","wP","wP","wP","wP"],
                ["wR","wN","wB","wQ","wK","wB","wN","wR"]
            ],
            "turn": "black",
            "white_king": [7,4],
            "black_king": [0,4],
            "castling_rights": {
                "wK": True, "wQ": True,
                "bK": True, "bQ": True
            },
            "en_passant_target": None
        }

        # 1. send board
        await websocket.send(json.dumps(data))

        print("Sent board to server")

        # 2. receive move
        response = await websocket.recv()

        print("Received move from server:")
        print(response)


asyncio.run(test())