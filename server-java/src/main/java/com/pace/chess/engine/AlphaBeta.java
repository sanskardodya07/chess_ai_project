package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Move;
import java.util.List;

public class AlphaBeta {

    public static Move getBestMove(Board board, int depth) {
        int color = "white".equals(board.turn) ? 1 : -1;
        double alpha = Double.NEGATIVE_INFINITY;
        double beta = Double.POSITIVE_INFINITY;

        List<Move> moves = board.getAllLegalMoves();
        MoveSorter.sortMoves(moves, board);

        Move bestMove = null;
        double bestValue = Double.NEGATIVE_INFINITY;

        for (Move m : moves) {
            board.makeMove(m);
            // Evaluation is ALWAYS from White's perspective, negamax flips it
            double value = -negamax(board, depth - 1, -beta, -alpha, -color);
            board.undoMove();

            if (value > bestValue) {
                bestValue = value;
                bestMove = m;
            }
            alpha = Math.max(alpha, value);
        }
        return bestMove;
    }

    private static double negamax(Board board, int depth, double alpha, double beta, int color) {
        List<Move> moves = board.getAllLegalMoves();

        // PERFORMANCE FIX: Check if game is over without calling expensive gameStatus()
        if (moves.isEmpty()) {
            if (RuleChecker.isInCheck(board, board.turn)) {
                return -1000000; // Checkmate: Current player loses
            }
            return 0; // Stalemate: Draw
        }

        if (depth == 0) return color * Evaluation.evaluate(board);

        MoveSorter.sortMoves(moves, board); // Pass board to check for endgame phase

        double max = Double.NEGATIVE_INFINITY;
        for (Move m : moves) {
            board.makeMove(m);
            double score = -negamax(board, depth - 1, -beta, -alpha, -color);
            board.undoMove();

            max = Math.max(max, score);
            alpha = Math.max(alpha, score);
            if (alpha >= beta) break;
        }
        return max;
    }
}