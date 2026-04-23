package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Move;
import com.pace.chess.model.Piece;
import java.util.List;

public class AlphaBeta {

    public static Move getBestMove(Board board, int depth) {
        // 'mathColor' flips the evaluation perspective (1 for White, -1 for Black)
        int mathColor = (board.turn == Piece.WHITE) ? 1 : -1;
        
        double alpha = Double.NEGATIVE_INFINITY;
        double beta = Double.POSITIVE_INFINITY;

        // Generate and filter legal moves directly
        List<Move> pseudoMoves = MoveGenerator.generateAllMoves(board, board.turn);
        List<Move> moves = RuleChecker.filterLegalMoves(board, pseudoMoves, board.turn);
        
        MoveSorter.sortMoves(moves, board);

        Move bestMove = null;
        double bestValue = Double.NEGATIVE_INFINITY;

        for (Move m : moves) {
            board.makeMove(m);
            // Evaluation is always from White's perspective, negamax flips it
            double value = -negamax(board, depth - 1, -beta, -alpha, -mathColor);
            board.undoMove();

            if (value > bestValue) {
                bestValue = value;
                bestMove = m;
            }
            alpha = Math.max(alpha, value);
        }
        return bestMove;
    }

    private static double negamax(Board board, int depth, double alpha, double beta, int mathColor) {
        List<Move> pseudoMoves = MoveGenerator.generateAllMoves(board, board.turn);
        List<Move> moves = RuleChecker.filterLegalMoves(board, pseudoMoves, board.turn);

        // PERFORMANCE FIX: Check if game is over without expensive separate calls
        if (moves.isEmpty()) {
            if (RuleChecker.isInCheck(board, board.turn)) {
                return -1000000; // Checkmate: Current player loses
            }
            return 0; // Stalemate: Draw
        }

        // Base case: return the static evaluation
        if (depth == 0) return mathColor * Evaluation.evaluate(board);

        MoveSorter.sortMoves(moves, board);

        double max = Double.NEGATIVE_INFINITY;
        for (Move m : moves) {
            board.makeMove(m);
            double score = -negamax(board, depth - 1, -beta, -alpha, -mathColor);
            board.undoMove();

            max = Math.max(max, score);
            alpha = Math.max(alpha, score);
            if (alpha >= beta) break; // Alpha-Beta Pruning
        }
        return max;
    }
}