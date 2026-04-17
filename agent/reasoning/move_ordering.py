#move_ordering.py

from agent.knowledge.evaluation import evaluate
from board.rule_checker import is_in_check
from board.move_generator import generate_all_moves


# ==============================
# MAIN ORDER FUNCTION
# ==============================

def order_moves(board, moves):

    tactical = []
    threats = []
    quiet = []

    for move in moves:

        if is_capture(move) or gives_check(board, move):
            tactical.append(move)

        elif creates_threat(board, move):
            threats.append(move)

        else:
            quiet.append(move)

    # Evaluate quiet moves
    scored_quiet = []

    for move in quiet:
        board.make_move(move)
        score = evaluate(board)
        board.undo_move()

        scored_quiet.append((score, move))

    reverse = (board.turn == "white")
    scored_quiet.sort(key=lambda x: x[0], reverse=reverse)

    top_quiet = [m for _, m in scored_quiet[:10]]

    return tactical + threats + top_quiet


# ==============================
# HELPERS
# ==============================

def is_capture(move):
    return move.piece_captured != ""


def gives_check(board, move):

    board.make_move(move)

    opponent = board.turn  # after move, turn already switched

    check = is_in_check(board, opponent)

    board.undo_move()

    return check


# ✅ NEW — clean, no manual turn mutation
def creates_threat(board, move):

    board.make_move(move)

    # after make_move, turn has switched to opponent
    # we want to check what the MOVING side can do next turn
    # so we generate moves for the side that just moved
    moving_side = "white" if board.turn == "black" else "white"

    next_moves = generate_all_moves(board, moving_side)

    threat_found = any(m.piece_captured != "" for m in next_moves)

    board.undo_move()

    return threat_found