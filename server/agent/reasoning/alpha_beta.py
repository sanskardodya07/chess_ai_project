# alpha_beta.py

import math
import random
from server.agent.knowledge.evaluation import evaluate
from server.board.rule_checker import is_in_check


# =========================================
# ALPHA-BETA CORE
# =========================================

def alphabeta(board, depth, alpha, beta, maximizing):

    status = board.game_status()

    if status != "ongoing":

        if "checkmate" in status:
            if "White wins" in status:
                return 100000 - depth
            else:
                return -100000 + depth

        # stalemate or anything else = draw
        return 0

    if depth == 0:
        return evaluate(board)

    moves = get_ordered_moves(board)

    # safety net — no moves but status said ongoing
    if not moves:
        return 0

    if maximizing:

        max_eval = -math.inf

        for move in moves:

            board.make_move(move)
            eval = alphabeta(board, depth - 1, alpha, beta, False)

            if move.promotion:
                eval += 500

            board.undo_move()

            max_eval = max(max_eval, eval)
            alpha = max(alpha, eval)

            if beta <= alpha:
                break

        return max_eval

    else:

        min_eval = math.inf

        for move in moves:

            board.make_move(move)
            eval = alphabeta(board, depth - 1, alpha, beta, True)

            if move.promotion:
                eval -= 500

            board.undo_move()

            min_eval = min(min_eval, eval)
            beta = min(beta, eval)

            if beta <= alpha:
                break

        return min_eval


# =========================================
# BEST MOVE FINDER
# =========================================

def get_best_move(board, depth):

    maximizing = True if board.turn == "white" else False

    alpha = -math.inf
    beta = math.inf

    moves = board.get_all_legal_moves()
    moves.sort(key=lambda m: m.piece_captured != "", reverse=True)

    best_moves = []

    if maximizing:

        max_eval = -math.inf

        for move in moves:

            board.make_move(move)
            eval = alphabeta(board, depth - 1, alpha, beta, False)
            board.undo_move()

            if eval is None:
                continue

            print(eval)

            if eval > max_eval:
                max_eval = eval
                best_moves = [move]
            elif eval == max_eval:
                best_moves.append(move)

            alpha = max(alpha, eval)

    else:

        min_eval = math.inf

        for move in moves:

            board.make_move(move)
            eval = alphabeta(board, depth - 1, alpha, beta, True)
            board.undo_move()

            if eval is None:
                continue

            print(eval)

            if eval < min_eval:
                min_eval = eval
                best_moves = [move]
            elif eval == min_eval:
                best_moves.append(move)

            beta = min(beta, eval)

    return random.choice(best_moves) if best_moves else None


# =========================================
# MOVE ORDERING
# =========================================

def get_ordered_moves(board):

    all_moves = board.get_all_legal_moves()

    # if already in check, don't bother ordering
    if is_in_check(board, board.turn):
        return all_moves

    capture_moves = []
    check_moves = []
    attack_moves = []
    other_moves = []

    for move in all_moves:

        # captures always go first
        if move.piece_captured != "":
            capture_moves.append(move)
            continue

        board.make_move(move)

        # after make_move turn switches to opponent
        # so board.turn IS the opponent — check if we put them in check
        opponent = board.turn
        in_check = is_in_check(board, opponent)

        board.undo_move()  # always undo immediately

        if in_check:
            check_moves.append(move)
            continue

        if is_attacking_move(board, move):
            attack_moves.append(move)
        else:
            other_moves.append(move)

    return capture_moves + check_moves + attack_moves + other_moves


# =========================================
# ATTACK DETECTION (for ordering)
# =========================================

def is_attacking_move(board, move):

    r, c = move.end_row, move.end_col
    piece = move.piece_moved  # ✅ use move data, not board state

    opponent_color = "b" if piece[0] == "w" else "w"

    directions = [
        (-1, 0), (1, 0), (0, -1), (0, 1),
        (-1, -1), (-1, 1), (1, -1), (1, 1)
    ]

    for dr, dc in directions:
        nr = r + dr
        nc = c + dc

        if 0 <= nr < 8 and 0 <= nc < 8:
            target = board.board[nr][nc]
            if target != "" and target[0] == opponent_color:
                return True

    return False