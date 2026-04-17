#minimax.py

from agent.knowledge.evaluation import evaluate
from agent.reasoning.move_ordering import order_moves


# ==============================
# MAIN ENTRY FUNCTION
# ==============================

def get_best_move(board, depth):

    best_move = None

    if board.turn == "white":
        best_score = float("-inf")
    else:
        best_score = float("inf")

    moves = board.get_all_legal_moves()
    moves = order_moves(board, moves)

    for move in moves:

        board.make_move(move)

        score = minimax(board, depth - 1)

        board.undo_move()

        if board.turn == "white":
            if score > best_score:
                best_score = score
                best_move = move
        else:
            if score < best_score:
                best_score = score
                best_move = move

    return best_move


# ==============================
# MINIMAX FUNCTION
# ==============================

def minimax(board, depth):

    status = board.game_status()

    # TERMINAL STATES
    if status == "checkmate":
        return float("-inf") if board.turn == "white" else float("inf")

    if status == "stalemate":
        return 0

    if depth == 0:
        return evaluate(board)

    moves = board.get_all_legal_moves()
    moves = order_moves(board, moves)

    # ✅ NEW — both branches use make_move/undo_move consistently
    if board.turn == "white":

        best_score = float("-inf")

        for move in moves:

            board.make_move(move)
            score = minimax(board, depth - 1)
            board.undo_move()

            best_score = max(best_score, score)

        return best_score
    else:

        best_score = float("inf")

        for move in moves:

            board.make_move(move)
            score = minimax(board, depth - 1)
            board.undo_move()

            best_score = min(best_score, score)

        return best_score