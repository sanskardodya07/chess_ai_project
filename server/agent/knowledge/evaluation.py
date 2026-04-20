from server.board.constants import PIECE_VALUES


# ==============================
# MAIN EVALUATION FUNCTION
# ==============================

def evaluate(board):

    phase = detect_phase(board)

    score = 0

    score += material_score(board)
    score += development_score(board, phase)
    score += king_score(board, phase)
    score += attack_score(board)

    return score


# ==============================
# GAME PHASE DETECTION
# ==============================

def detect_phase(board):

    total = 0

    for row in board.board:
        for piece in row:
            if piece == "":
                continue

            if piece[1] != "K":
                total += PIECE_VALUES[piece[1]]

    if total > 40:
        return "opening"
    elif total > 20:
        return "middlegame"
    else:
        return "endgame"


# ==============================
# MATERIAL
# ==============================

def material_score(board):

    score = 0

    for row in board.board:
        for piece in row:
            if piece == "":
                continue

            value = PIECE_VALUES[piece[1]]

            if piece[0] == "w":
                score += value
            else:
                score -= value

    return score


# ==============================
# DEVELOPMENT (OPENING)
# ==============================

def development_score(board, phase):

    if phase != "opening":
        return 0

    score = 0

    # White
    if board.board[7][1] != "wN": score += 0.3
    if board.board[7][6] != "wN": score += 0.3
    if board.board[7][2] != "wB": score += 0.3
    if board.board[7][5] != "wB": score += 0.3

    # Black
    if board.board[0][1] != "bN": score -= 0.3
    if board.board[0][6] != "bN": score -= 0.3
    if board.board[0][2] != "bB": score -= 0.3
    if board.board[0][5] != "bB": score -= 0.3

    return score


# ==============================
# KING SAFETY / ACTIVITY
# ==============================

def king_score(board, phase):

    score = 0

    wk = board.white_king
    bk = board.black_king

    # OPENING / MIDGAME → safety
    if phase in ["opening", "middlegame"]:

        # Penalize center kings
        if wk[1] in [3,4]:
            score -= 0.5
        if bk[1] in [3,4]:
            score += 0.5

    # ENDGAME → activity
    else:

        # Reward central king
        score += center_bonus(wk)
        score -= center_bonus(bk)

    return score


def center_bonus(pos):

    r, c = pos

    center_distance = abs(3.5 - r) + abs(3.5 - c)

    return (4 - center_distance) * 0.2


# ==============================
# ATTACKING STYLE 😈
# ==============================

def attack_score(board):

    score = 0

    for r in range(8):
        for c in range(8):

            piece = board.board[r][c]

            if piece == "":
                continue

            # Encourage forward play
            if piece[0] == "w":
                score += (6 - r) * 0.05
            else:
                score -= (r - 1) * 0.05

    return score