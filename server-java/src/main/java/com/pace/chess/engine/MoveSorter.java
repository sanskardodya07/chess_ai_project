package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Move;
import com.pace.chess.model.Piece;
import java.util.List;

public class MoveSorter {

    public static void sortMoves(List<Move> moves, Board board) {
        // Sort in descending order based on the move score
        moves.sort((m1, m2) -> Integer.compare(scoreMove(m2), scoreMove(m1)));
    }

    private static int scoreMove(Move move) {
        int score = 0;

        // Priority 1: Captures (MVV-LVA logic)
        if (move.pieceCaptured != Piece.EMPTY) {
            int victimType = move.pieceCaptured & 7;   // Extract type 1-6
            int attackerType = move.pieceMoved & 7;    // Extract type 1-6
            
            // Big bonus for capturing a high-value piece with a low-value piece
            score += 100 + getPieceValue(victimType) - (getPieceValue(attackerType) / 10);
        }

        // Priority 2: Promotion
        if (move.promotion != Piece.EMPTY) {
            score += 90; // Encourage pushing pawns to the end
        }

        return score;
    }

    private static int getPieceValue(int type) {
        return switch (type) {
            case Piece.PAWN -> 10;
            case Piece.KNIGHT, Piece.BISHOP -> 30;
            case Piece.ROOK -> 50;
            case Piece.QUEEN -> 90;
            case Piece.KING -> 900;
            default -> 0;
        };
    }
}