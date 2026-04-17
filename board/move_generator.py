#move_generator.py

from board.move import Move


def generate_all_moves(board, color):

    moves = []

    for r in range(8):
        for c in range(8):

            piece = board.board[r][c]

            if piece == "":
                continue

            if color == "white" and piece[0] != "w":
                continue

            if color == "black" and piece[0] != "b":
                continue

            p = piece[1]

            if p == "P":
                pawn_moves(board, r, c, moves)

            elif p == "N":
                knight_moves(board, r, c, moves)

            elif p == "B":
                bishop_moves(board, r, c, moves)

            elif p == "R":
                rook_moves(board, r, c, moves)

            elif p == "Q":
                bishop_moves(board, r, c, moves)
                rook_moves(board, r, c, moves)

            elif p == "K":
                king_moves(board, r, c, moves)

    return moves


def pawn_moves(board, r, c, moves):

    piece = board.board[r][c]

    direction = -1 if piece[0] == "w" else 1
    start_row = 6 if piece[0] == "w" else 1

    if 0 <= r + direction < 8 and board.board[r + direction][c] == "":
        end_row = r + direction

        if end_row == 0 or end_row == 7:
            moves.append(Move((r,c),(end_row,c),piece,"",promotion="Q"))
        else:
            moves.append(Move((r,c),(end_row,c),piece,""))

            if r == start_row and 0 <= r + 2*direction < 8 and board.board[r + 2*direction][c] == "":
                moves.append(Move((r,c),(r + 2*direction,c),piece,""))

    for dc in [-1,1]:

        col = c + dc
        row = r + direction

        if 0 <= col < 8 and 0 <= row < 8:

            target = board.board[row][col]

            if target != "" and target[0] != piece[0]:
                moves.append(Move((r,c),(row,col),piece,target))

            # ✅ EN PASSANT FIX
            if board.en_passant_target == (row, col):

                captured = "bP" if piece[0] == "w" else "wP"

                move = Move((r, c), (row, col), piece, captured)
                move.is_en_passant = True

                if piece[0] == "w":
                    move.en_passant_capture_pos = (row + 1, col)
                else:
                    move.en_passant_capture_pos = (row - 1, col)

                moves.append(move)


def knight_moves(board, r, c, moves):

    piece = board.board[r][c]

    dirs = [
        (-2, -1), (-2, 1),
        (-1, -2), (-1, 2),
        (1, -2), (1, 2),
        (2, -1), (2, 1)
    ]

    for dr, dc in dirs:

        row = r + dr
        col = c + dc

        if 0 <= row < 8 and 0 <= col < 8:

            target = board.board[row][col]

            if target == "" or target[0] != piece[0]:
                moves.append(Move((r, c), (row, col), piece, target))


def rook_moves(board, r, c, moves):
    slide(board, r, c, moves, [(1, 0), (-1, 0), (0, 1), (0, -1)])


def bishop_moves(board, r, c, moves):
    slide(board, r, c, moves, [(1, 1), (1, -1), (-1, 1), (-1, -1)])


def slide(board, r, c, moves, dirs):

    piece = board.board[r][c]

    for dr, dc in dirs:

        row = r + dr
        col = c + dc

        while 0 <= row < 8 and 0 <= col < 8:

            target = board.board[row][col]

            if target == "":
                moves.append(Move((r, c), (row, col), piece, ""))

            else:
                if target[0] != piece[0]:
                    moves.append(Move((r, c), (row, col), piece, target))
                break

            row += dr
            col += dc


# move_generator.py
# replace only the king_moves function

def king_moves(board, r, c, moves):

    piece = board.board[r][c]
    color = "white" if piece[0] == "w" else "black"

    dirs = [
        (-1,-1),(-1,0),(-1,1),
        (0,-1),(0,1),
        (1,-1),(1,0),(1,1)
    ]

    for dr, dc in dirs:

        row = r + dr
        col = c + dc

        if 0 <= row < 8 and 0 <= col < 8:

            target = board.board[row][col]

            if target == "" or target[0] != piece[0]:
                moves.append(Move((r,c),(row,col),piece,target))

    # ✅ CASTLING — all 3 rules enforced
    from board.rule_checker import is_in_check

    # Rule 1 — cannot castle while in check
    if is_in_check(board, color):
        return

    if piece == "wK":

        if board.castling_rights["wK"]:
            if board.board[7][5] == "" and board.board[7][6] == "":

                # Rule 2 — king cannot pass through attacked square
                if not _square_attacked(board, 7, 5, "b") and \
                   not _square_attacked(board, 7, 6, "b"):

                    move = Move((7,4),(7,6),piece,"")
                    move.is_castling = True
                    moves.append(move)

        if board.castling_rights["wQ"]:
            if board.board[7][3] == "" and board.board[7][2] == "" and board.board[7][1] == "":

                # Rule 2 — king cannot pass through attacked square
                if not _square_attacked(board, 7, 3, "b") and \
                   not _square_attacked(board, 7, 2, "b"):

                    move = Move((7,4),(7,2),piece,"")
                    move.is_castling = True
                    moves.append(move)

    elif piece == "bK":

        if board.castling_rights["bK"]:
            if board.board[0][5] == "" and board.board[0][6] == "":

                # Rule 2 — king cannot pass through attacked square
                if not _square_attacked(board, 0, 5, "w") and \
                   not _square_attacked(board, 0, 6, "w"):

                    move = Move((0,4),(0,6),piece,"")
                    move.is_castling = True
                    moves.append(move)

        if board.castling_rights["bQ"]:
            if board.board[0][3] == "" and board.board[0][2] == "" and board.board[0][1] == "":

                # Rule 2 — king cannot pass through attacked square
                if not _square_attacked(board, 0, 3, "w") and \
                   not _square_attacked(board, 0, 2, "w"):

                    move = Move((0,4),(0,2),piece,"")
                    move.is_castling = True
                    moves.append(move)

# move_generator.py
# add at the bottom of the file

def _square_attacked(board, row, col, attacker_color):
    """
    Check if a specific square is attacked by any piece of attacker_color.
    Used for castling validation only.
    """

    # pawn attacks
    if attacker_color == "w":
        pawn_dirs = [(-1, -1), (-1, 1)]
    else:
        pawn_dirs = [(1, -1), (1, 1)]

    for dr, dc in pawn_dirs:
        r, c = row + dr, col + dc
        if 0 <= r < 8 and 0 <= c < 8:
            if board.board[r][c] == attacker_color + "P":
                return True

    # knight attacks
    for dr, dc in [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)]:
        r, c = row + dr, col + dc
        if 0 <= r < 8 and 0 <= c < 8:
            if board.board[r][c] == attacker_color + "N":
                return True

    # rook / queen (straight lines)
    for dr, dc in [(1,0),(-1,0),(0,1),(0,-1)]:
        r, c = row + dr, col + dc
        while 0 <= r < 8 and 0 <= c < 8:
            piece = board.board[r][c]
            if piece != "":
                if piece[0] == attacker_color and piece[1] in ["R", "Q"]:
                    return True
                break
            r += dr
            c += dc

    # bishop / queen (diagonals)
    for dr, dc in [(1,1),(1,-1),(-1,1),(-1,-1)]:
        r, c = row + dr, col + dc
        while 0 <= r < 8 and 0 <= c < 8:
            piece = board.board[r][c]
            if piece != "":
                if piece[0] == attacker_color and piece[1] in ["B", "Q"]:
                    return True
                break
            r += dr
            c += dc

    # king attacks
    for dr, dc in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]:
        r, c = row + dr, col + dc
        if 0 <= r < 8 and 0 <= c < 8:
            if board.board[r][c] == attacker_color + "K":
                return True

    return False