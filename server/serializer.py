# server/serializer.py

from board.board import Board


# ==============================
# JSON → BOARD
# ==============================

def board_from_json(data):

    board = Board()

    # overwrite board state
    board.board = data["board"]
    board.turn = data["turn"]

    # king positions (convert list → tuple)
    board.white_king = tuple(data["white_king"])
    board.black_king = tuple(data["black_king"])

    # castling rights
    board.castling_rights = data["castling_rights"]

    # en passant
    ep = data.get("en_passant_target")
    board.en_passant_target = tuple(ep) if ep else None

    return board


# ==============================
# MOVE → JSON
# ==============================

def move_to_json(move):

    return {
        "start": [move.start_row, move.start_col],
        "end": [move.end_row, move.end_col],
        "promotion": move.promotion if move.promotion else None
    }