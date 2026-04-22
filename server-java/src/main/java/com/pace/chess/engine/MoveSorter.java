package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Move;
import java.util.Comparator;
import java.util.List;

public class MoveSorter {

    public static void sortMoves(List<Move> moves, Board board) {
        moves.sort(new Comparator<Move>() {
            @Override
            public int compare(Move m1, Move m2) {
                return Integer.compare(scoreMove(m2, board), scoreMove(m1, board));
            }
        });
    }

    private static int scoreMove(Move move, Board board) {
        int score = 0;

        // Priority 1: Captures (MVV-LVA logic)
        if (!move.pieceCaptured.isEmpty()) {
            score += 100 + getPieceValue(move.pieceCaptured.charAt(1)) 
                         - (getPieceValue(move.pieceMoved.charAt(1)) / 10);
        }

        // Priority 2: Promotion
        if (move.promotion != null) {
            score += 90;
        }

        return score;
    }

    private static int getPieceValue(char type) {
        return switch (type) {
            case 'P' -> 10;
            case 'N', 'B' -> 30;
            case 'R' -> 50;
            case 'Q' -> 90;
            case 'K' -> 900;
            default -> 0;
        };
    }
}