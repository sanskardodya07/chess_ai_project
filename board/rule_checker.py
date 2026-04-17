from board.move_generator import generate_all_moves
from board.constants import WHITE, BLACK


# ===============================
# CHECK DETECTION
# ===============================

def is_in_check(board, color):

    if color == "white":
        r, c = board.white_king
        enemy = "b"
    else:
        r, c = board.black_king
        enemy = "w"

    board_state = board.board

    # ---------------------------
    # PAWN ATTACKS
    # ---------------------------

    if enemy == "w":
        pawn_dirs = [(1,-1),(1,1)]
    else:
        pawn_dirs = [(-1,-1),(-1,1)]

    for dr, dc in pawn_dirs:
        row = r + dr
        col = c + dc

        if 0 <= row < 8 and 0 <= col < 8:
            piece = board_state[row][col]
            if piece == enemy + "P":
                return True


    # ---------------------------
    # KNIGHT ATTACKS
    # ---------------------------

    knight_moves = [
        (-2,-1),(-2,1),(-1,-2),(-1,2),
        (1,-2),(1,2),(2,-1),(2,1)
    ]

    for dr, dc in knight_moves:
        row = r + dr
        col = c + dc

        if 0 <= row < 8 and 0 <= col < 8:
            piece = board_state[row][col]
            if piece == enemy + "N":
                return True


    # ---------------------------
    # ROOK / QUEEN ATTACKS
    # ---------------------------

    directions = [(1,0),(-1,0),(0,1),(0,-1)]

    for dr, dc in directions:

        row = r + dr
        col = c + dc

        while 0 <= row < 8 and 0 <= col < 8:

            piece = board_state[row][col]

            if piece != "":
                if piece[0] == enemy and (piece[1] == "R" or piece[1] == "Q"):
                    return True
                break

            row += dr
            col += dc


    # ---------------------------
    # BISHOP / QUEEN ATTACKS
    # ---------------------------

    directions = [(1,1),(1,-1),(-1,1),(-1,-1)]

    for dr, dc in directions:

        row = r + dr
        col = c + dc

        while 0 <= row < 8 and 0 <= col < 8:

            piece = board_state[row][col]

            if piece != "":
                if piece[0] == enemy and (piece[1] == "B" or piece[1] == "Q"):
                    return True
                break

            row += dr
            col += dc


    # ---------------------------
    # KING ATTACK
    # ---------------------------

    king_dirs = [
        (-1,-1),(-1,0),(-1,1),
        (0,-1),(0,1),
        (1,-1),(1,0),(1,1)
    ]

    for dr, dc in king_dirs:
        row = r + dr
        col = c + dc

        if 0 <= row < 8 and 0 <= col < 8:
            piece = board_state[row][col]
            if piece == enemy + "K":
                return True

    return False

# ===============================
# LEGAL MOVE FILTER
# ===============================

def filter_legal_moves(board, moves, color):

    legal_moves = []

    for move in moves:

        board.make_move(move)
    
        if not is_in_check(board, color):
            legal_moves.append(move)

        board.undo_move()

    return legal_moves


# ===============================
# CHECKMATE
# ===============================

def is_checkmate(board, color):

    moves = generate_all_moves(board, color)
    legal = filter_legal_moves(board, moves, color)

    if len(legal) == 0 and is_in_check(board, color):
        return True

    return False


# ===============================
# STALEMATE
# ===============================

def is_stalemate(board, color):

    moves = generate_all_moves(board, color)
    legal = filter_legal_moves(board, moves, color)

    if len(legal) == 0 and not is_in_check(board, color):
        return True

    return False