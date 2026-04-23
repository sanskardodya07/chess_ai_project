package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Move;
import com.pace.chess.model.Piece;

import java.util.ArrayList;
import java.util.List;

public class RuleChecker {

    // 0x88 Directional Offsets
    private static final int[] KNIGHT_DIRS = {-33, -31, -18, -14, 14, 18, 31, 33};
    private static final int[] BISHOP_DIRS = {-17, -15, 15, 17};
    private static final int[] ROOK_DIRS   = {-16, -1, 1, 16};
    private static final int[] KING_DIRS   = {-17, -16, -15, -1, 1, 15, 16, 17};

    public static boolean isInCheck(Board board, int color) {
        int kingSq = (color == Piece.WHITE) ? board.whiteKing : board.blackKing;
        int enemyColor = (color == Piece.WHITE) ? Piece.BLACK : Piece.WHITE;
        return isSquareAttacked(board, kingSq, enemyColor);
    }

    public static boolean isSquareAttacked(Board board, int sq, int enemyColor) {
        // 1. Pawn Attacks (Reverse perspective: if a White pawn attacks sq, 
        // it means looking from sq 'down' (+15, +17) we should see a White pawn)
        int[] pawnDirs = (enemyColor == Piece.WHITE) ? new int[]{15, 17} : new int[]{-15, -17};
        for (int d : pawnDirs) {
            int target = sq + d;
            if ((target & 0x88) == 0 && board.board[target] == (enemyColor | Piece.PAWN)) return true;
        }

        // 2. Knight Attacks
        for (int d : KNIGHT_DIRS) {
            int target = sq + d;
            if ((target & 0x88) == 0 && board.board[target] == (enemyColor | Piece.KNIGHT)) return true;
        }

        // 3. Bishop / Queen Attacks (Sliding Diagonals)
        for (int d : BISHOP_DIRS) {
            int target = sq + d;
            while ((target & 0x88) == 0) {
                int p = board.board[target];
                if (p != Piece.EMPTY) {
                    if (p == (enemyColor | Piece.BISHOP) || p == (enemyColor | Piece.QUEEN)) return true;
                    break; // Blocked by something else
                }
                target += d;
            }
        }

        // 4. Rook / Queen Attacks (Sliding Straights)
        for (int d : ROOK_DIRS) {
            int target = sq + d;
            while ((target & 0x88) == 0) {
                int p = board.board[target];
                if (p != Piece.EMPTY) {
                    if (p == (enemyColor | Piece.ROOK) || p == (enemyColor | Piece.QUEEN)) return true;
                    break;
                }
                target += d;
            }
        }

        // 5. King Attacks (For adjacent kings)
        for (int d : KING_DIRS) {
            int target = sq + d;
            if ((target & 0x88) == 0 && board.board[target] == (enemyColor | Piece.KING)) return true;
        }

        return false;
    }

    public static List<Move> filterLegalMoves(Board board, List<Move> pseudoLegalMoves, int color) {
        List<Move> legal = new ArrayList<>();
        for (Move m : pseudoLegalMoves) {
            board.makeMove(m);
            if (!isInCheck(board, color)) {
                legal.add(m);
            }
            board.undoMove();
        }
        return legal;
    }
}