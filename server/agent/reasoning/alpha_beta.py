import math
from server.agent.knowledge.evaluation import evaluate


# =========================================
# ALPHA-BETA CORE
# =========================================

def alphabeta(board, depth, alpha, beta, maximizing):

    # Base case
    status = board.game_status()
    if depth == 0 or status != "ongoing":
        return evaluate(board)

    moves = board.get_all_legal_moves()

    if maximizing:

        max_eval = -math.inf

        for move in moves:

            board.make_move(move)

            eval = alphabeta(board, depth - 1, alpha, beta, False)

            board.undo_move()

            max_eval = max(max_eval, eval)
            alpha = max(alpha, eval)

            # PRUNE
            if beta <= alpha:
                break

        return max_eval

    else:

        min_eval = math.inf

        for move in moves:

            board.make_move(move)

            eval = alphabeta(board, depth - 1, alpha, beta, True)

            board.undo_move()

            min_eval = min(min_eval, eval)
            beta = min(beta, eval)

            # PRUNE
            if beta <= alpha:
                break

        return min_eval


# =========================================
# BEST MOVE FINDER
# =========================================

def get_best_move(board, depth):

    best_move = None

    maximizing = True if board.turn == "white" else False

    alpha = -math.inf
    beta = math.inf

    moves = board.get_all_legal_moves()

    # OPTIONAL: simple move ordering (captures first)
    moves.sort(key=lambda m: m.piece_captured != "", reverse=True)

    if maximizing:

        max_eval = -math.inf

        for move in moves:

            board.make_move(move)

            eval = alphabeta(board, depth - 1, alpha, beta, False)

            board.undo_move()

            if eval > max_eval:
                max_eval = eval
                best_move = move

            alpha = max(alpha, eval)

    else:

        min_eval = math.inf

        for move in moves:

            board.make_move(move)

            eval = alphabeta(board, depth - 1, alpha, beta, True)

            board.undo_move()

            if eval < min_eval:
                min_eval = eval
                best_move = move

            beta = min(beta, eval)

    return best_move