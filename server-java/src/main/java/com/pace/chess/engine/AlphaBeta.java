package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Move;

import java.util.List;

public class AlphaBeta {

    public static double alphaBeta(Board board, int depth, double alpha, double beta, boolean max) {
        if (depth == 0 || !"ongoing".equals(board.gameStatus()))
            return Evaluation.evaluate(board);

        List<Move> moves = board.getAllLegalMoves();

        if (max) {
            double best = Double.NEGATIVE_INFINITY;
            for (Move m : moves) {
                board.makeMove(m);
                best  = Math.max(best, alphaBeta(board, depth-1, alpha, beta, false));
                alpha = Math.max(alpha, best);
                board.undoMove();
                if (beta <= alpha) break;
            }
            return best;
        } else {
            double best = Double.POSITIVE_INFINITY;
            for (Move m : moves) {
                board.makeMove(m);
                best = Math.min(best, alphaBeta(board, depth-1, alpha, beta, true));
                beta = Math.min(beta, best);
                board.undoMove();
                if (beta <= alpha) break;
            }
            return best;
        }
    }

    public static Move getBestMove(Board board, int depth) {
        boolean max = "white".equals(board.turn);
        double alpha = Double.NEGATIVE_INFINITY, beta = Double.POSITIVE_INFINITY;
        List<Move> moves = board.getAllLegalMoves();
        moves.sort((a, b) -> Boolean.compare(!a.pieceCaptured.isEmpty(), !b.pieceCaptured.isEmpty()));

        Move best = null;
        double bestEval = max ? Double.NEGATIVE_INFINITY : Double.POSITIVE_INFINITY;

        for (Move m : moves) {
            board.makeMove(m);
            double eval = alphaBeta(board, depth-1, alpha, beta, !max);
            board.undoMove();
            if ((max && eval > bestEval) || (!max && eval < bestEval)) {
                bestEval = eval; best = m;
            }
            if (max) alpha = Math.max(alpha, eval);
            else     beta  = Math.min(beta,  eval);
        }
        return best;
    }
}