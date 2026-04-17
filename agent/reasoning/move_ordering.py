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


def creates_threat(board, move):

    # Save original turn
    original_turn = board.turn

    board.make_move(move)

    # After move, turn switched → revert temporarily
    board.turn = original_turn

    next_moves = generate_all_moves(board, board.turn)

    threat_found = any(m.piece_captured != "" for m in next_moves)

    # Restore turn properly
    board.turn = "black" if original_turn == "white" else "white"

    board.undo_move()

    return threat_found