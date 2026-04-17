import math
import random
from agent.knowledge.evaluation import evaluate
from board.rule_checker import is_in_check

# =========================================
# ALPHA-BETA CORE
# =========================================

def alphabeta(board, depth, alpha, beta, maximizing):

    # Base case
    status = board.game_status()
    
    if status != "ongoing":
        if "wins by checkmate" in status:
            if board.turn == "white":
                return -100000 + depth if maximizing else 100000 - depth
            else:
                return 0

    if depth == 0:
        return evaluate(board)

    moves = get_ordered_moves(board)

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

            # PRUNE
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

            # PRUNE
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

    # keep your ordering
    moves.sort(key=lambda m: m.piece_captured != "", reverse=True)

    best_moves = []

    if maximizing:

        max_eval = -math.inf

        for move in moves:

            board.make_move(move)

            eval = alphabeta(board, depth - 1, alpha, beta, False)

            print(eval)

            board.undo_move()

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

            print(eval)

            board.undo_move()

            if eval < min_eval:
                min_eval = eval
                best_moves = [move]

            elif eval == min_eval:
                best_moves.append(move)

            beta = min(beta, eval)

    return random.choice(best_moves) if best_moves else None


def get_ordered_moves (board):
    
    all_moves = board.get_all_legal_moves()

    if is_in_check(board, board.turn):
        return all_moves
    
    capture_moves = []
    check_moves = []
    attack_moves = []
    other_moves = []

    for move in all_moves:
        
        if move.piece_captured != "":
            capture_moves.append(move)
            continue

        board.make_move(move)

        if is_in_check(board, board.turn):
            check_moves.append(move)
            board.undo_move()
            continue

        if is_attacking_move(board, move):
            attack_moves.append(move)
        else:
            other_moves.append(move)

        board.undo_move()

    return capture_moves + check_moves + attack_moves + other_moves

def is_attacking_move (board, move):
    r, c = move.end_row, move.end_col
    piece = board.board[r][c]

    opponent_color = "b" if piece[0] == "w" else "w"

    directions = [
        (-1,0),(1,0),(0,-1),(0,1),
        (-1,-1),(-1,1),(1,-1),(1,1)
    ]

    for dr,dc in directions:

        nr = r + dr
        nc = c + dc

        if 0 <= nr < 8 and 0 <= nc < 8:
            target = board.board[nr][nc]

            if target != "" and target[0] == opponent_color:
                return True
    return False