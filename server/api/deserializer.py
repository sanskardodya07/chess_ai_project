from board.board import Board

def board_from_json(data):

    b = Board()

    b.board = data["board"]
    b.turn = data["turn"]

    b.white_king = tuple(data["whiteKing"])
    b.black_king = tuple(data["blackKing"])

    b.castling_rights = data["castlingRights"].copy()

    if data["enPassantTarget"] is not None:
        b.en_passant_target = tuple(data["enPassantTarget"])
    else:
        b.en_passant_target = None

    if "halfMoveClock" in data:
        b.half_move_clock = data["halfMoveClock"]

    return b