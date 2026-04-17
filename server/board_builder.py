from board.board import Board


def build_board_from_json(payload: dict) -> Board:

    board = Board.__new__(Board)

    board.board = payload["board"]
    board.turn = payload["turn"]

    wk = payload["white_king"]
    bk = payload["black_king"]

    board.white_king = (wk[0], wk[1])
    board.black_king = (bk[0], bk[1])

    board.en_passant_target = payload.get("en_passant_target")

    board.castling_rights = payload.get("castling_rights", {
        "wK": True,
        "wQ": True,
        "bK": True,
        "bQ": True
    })

    board.move_history = []

    return board