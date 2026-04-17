from server.serializer import board_from_json, move_to_json
from agent.reasoning.alpha_beta import get_best_move

# minimal test data
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

board = board_from_json(data)

move = get_best_move(board, 3)

print(move_to_json(move))