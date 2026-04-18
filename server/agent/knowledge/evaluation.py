#evaluation.py

import math
from server.board.constants import PIECE_VALUES

# ==============================
# GAME PHASE
# ==============================

def get_game_phase(board):

    total_material = 0

    for r in range(8):
        for c in range(8):
            piece = board.board[r][c]

            if piece == "":
                continue

            p = piece[1]

            if p == "P" or p == "K":
                continue

            total_material += PIECE_VALUES[p]

    if total_material > 4000:
        return "opening"
    elif total_material > 2000:
        return "middlegame"
    else:
        return "endgame"


# ==============================
# MAIN EVALUATION
# ==============================

def evaluate(board):

    phase = get_game_phase(board)

    score = 0

    score += material_score(board)

    if phase == "opening":
        score += opening_features(board)

    elif phase == "middlegame":
        score += middlegame_features(board)

    else:
        score += endgame_features(board)

    # clamp for stability
    score = max(min(score, 10000), -10000)

    return score


# ==============================
# MATERIAL
# ==============================

def material_score(board):

    score = 0

    for r in range(8):
        for c in range(8):

            piece = board.board[r][c]

            if piece == "":
                continue

            value = PIECE_VALUES[piece[1]]

            if piece[0] == "w":
                score += value
            else:
                score -= value

    return score


# ==============================
# OPENING FEATURES
# ==============================

def opening_features(board):

    score = 0

    for r in range(8):
        for c in range(8):

            piece = board.board[r][c]

            if piece == "":
                continue

            color = piece[0]
            p = piece[1]

            # development
            if p in ["N", "B"]:
                if color == "w" and r < 7:
                    score += 15
                if color == "b" and r > 0:
                    score -= 15

            # discourage undeveloped pieces
            if p in ["N", "B"] and ((color == "w" and r == 7) or (color == "b" and r == 0)):
                if color == "w":
                    score -= 10
                else:
                    score += 10

            # early queen move penalty
            if p == "Q":
                if color == "w" and r < 7:
                    score -= 20
                if color == "b" and r > 0:
                    score += 20

    # center control
    center = [(3,3),(3,4),(4,3),(4,4)]

    for r,c in center:
        piece = board.board[r][c]
        if piece == "":
            continue
        if piece[0] == "w":
            score += 20
        else:
            score -= 20

    return score


# ==============================
# MIDDLEGAME FEATURES
# ==============================

def middlegame_features(board):

    score = 0

    # ======================
    # POSITIONAL PRESSURE
    # ======================

    for r in range(8):
        for c in range(8):

            piece = board.board[r][c]

            if piece == "":
                continue

            if piece[0] == "w":
                score += (7 - r) * 1   # reduced from 2
            else:
                score -= r * 1

    wr, wc = board.white_king

    if wr > 1 and wc > 1 and wc < 6:
        score -= 40

    br, bc = board.black_king

    if br < 6 and bc > 1 and bc < 6:
        score += 40

    if wr == 7:
        shield = 0

        for dc in [-1, 0 , 1]:
            col = wc + dc

            if 0 <= col < 8:
                if board.board[6][col] == "wP":
                    shield += 1
        
        score += shield * 15

    if br == 7:
        shield = 0

        for dc in [-1, 0 , 1]:
            col = bc + dc

            if 0 <= col < 8:
                if board.board[1][col] == "bP":
                    shield += 1

        score -= shield * 15

    if wr == 7:
        if board.board[6][wc] != "wP":
            score -= 20

    if br == 7:
        if board.board[1][bc] != "bP":
            score += 20

    # ======================
    # PIECE ACTIVITY
    # ======================

    for r in range(8):
        for c in range(8):

            piece = board.board[r][c]

            if piece == "":
                continue

            if piece[0] == "w":
                score += (7 - r) * 2
            else:
                score -= r * 2

    # ======================
    # HANGING PIECES (SAFE)
    # ======================

    for r in range(8):
        for c in range(8):

            piece = board.board[r][c]

            if piece == "":
                continue

            value = PIECE_VALUES[piece[1]]

            if piece[0] == "w":
                if is_attacked_simple(board, r, c, "b"):
                    score -= value * 0.5
            else:
                if is_attacked_simple(board, r, c, "w"):
                    score += value * 0.5

    return score


# ==============================
# ENDGAME FEATURES
# ==============================

def endgame_features(board):

    score = 0

    wr, wc = board.white_king
    br, bc = board.black_king

    # king activity
    score += int((3.5 - abs(3.5 - wr)) * 10)
    score -= int((3.5 - abs(3.5 - br)) * 10)

    # king distance (force mate)
    dist = abs(wr - br) + abs(wc - bc)
    score -= dist * 2

    # pawn advancement
    for r in range(8):
        for c in range(8):

            piece = board.board[r][c]

            if piece == "":
                continue

            if piece == "wP":
                score += (6 - r) * 10

            elif piece == "bP":
                score -= (r - 1) * 10

    return score


# ==============================
# SIMPLE ATTACK DETECTION
# ==============================

def is_attacked_simple(board, row, col, attacker_color):

    directions = [
        (-1,0),(1,0),(0,-1),(0,1),
        (-1,-1),(-1,1),(1,-1),(1,1)
    ]

    for dr, dc in directions:
        r, c = row + dr, col + dc

        if 0 <= r < 8 and 0 <= c < 8:
            piece = board.board[r][c]

            if piece != "" and piece[0] == attacker_color:
                return True

    return False