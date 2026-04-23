package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Move;
import com.pace.chess.model.Piece;

import java.util.ArrayList;
import java.util.List;

public class MoveGenerator {

    private static final int[] KNIGHT_DIRS = {-33, -31, -18, -14, 14, 18, 31, 33};
    private static final int[] BISHOP_DIRS = {-17, -15, 15, 17};
    private static final int[] ROOK_DIRS   = {-16, -1, 1, 16};
    private static final int[] KING_DIRS   = {-17, -16, -15, -1, 1, 15, 16, 17};

    public static List<Move> generateAllMoves(Board board, int color) {
        List<Move> moves = new ArrayList<>();
        int enemyColor = (color == Piece.WHITE) ? Piece.BLACK : Piece.WHITE;

        // Loop through the 0x88 board
        for (int sq = 0; sq < 128; sq++) {
            // Skip "ghost" squares off the board
            if ((sq & 0x88) != 0) continue;

            int piece = board.board[sq];
            if (piece == Piece.EMPTY || (piece & (Piece.WHITE | Piece.BLACK)) != color) continue;

            int type = piece & 7; // Extract piece type (1-6)

            switch (type) {
                case Piece.PAWN -> pawnMoves(board, sq, color, enemyColor, moves);
                case Piece.KNIGHT -> stepMoves(board, sq, piece, enemyColor, KNIGHT_DIRS, moves);
                case Piece.BISHOP -> slideMoves(board, sq, piece, enemyColor, BISHOP_DIRS, moves);
                case Piece.ROOK -> slideMoves(board, sq, piece, enemyColor, ROOK_DIRS, moves);
                case Piece.QUEEN -> {
                    slideMoves(board, sq, piece, enemyColor, BISHOP_DIRS, moves);
                    slideMoves(board, sq, piece, enemyColor, ROOK_DIRS, moves);
                }
                case Piece.KING -> kingMoves(board, sq, piece, color, enemyColor, moves);
            }
        }
        return moves;
    }

    private static void pawnMoves(Board board, int sq, int color, int enemyColor, List<Move> moves) {
        int dir = (color == Piece.WHITE) ? -16 : 16;
        int startRank = (color == Piece.WHITE) ? 6 : 1;

        int piece = color | Piece.PAWN;
        int currentRank = sq / 16;

        // 1. Forward Push
        int target = sq + dir;
        if ((target & 0x88) == 0 && board.board[target] == Piece.EMPTY) {
            addPawnMove(sq, target, piece, Piece.EMPTY, currentRank == startRank + (dir > 0 ? 5 : -5), moves);
            
            // 2. Double Push
            int doubleTarget = sq + (dir * 2);
            if (currentRank == startRank && board.board[doubleTarget] == Piece.EMPTY) {
                moves.add(new Move(sq, doubleTarget, piece, Piece.EMPTY));
            }
        }

        // 3. Captures
        int[] capDirs = (color == Piece.WHITE) ? new int[]{-17, -15} : new int[]{15, 17};
        for (int cd : capDirs) {
            target = sq + cd;
            if ((target & 0x88) == 0) {
                int targetPiece = board.board[target];
                // Normal Capture
                if (targetPiece != Piece.EMPTY && (targetPiece & enemyColor) != 0) {
                    addPawnMove(sq, target, piece, targetPiece, currentRank == startRank + (dir > 0 ? 5 : -5), moves);
                }
                // En Passant
                else if (board.enPassantTarget != null && target == board.enPassantTarget) {
                    Move m = new Move(sq, target, piece, enemyColor | Piece.PAWN);
                    m.isEnPassant = true;
                    m.enPassantCapturePos = target - dir;
                    moves.add(m);
                }
            }
        }
    }

    private static void addPawnMove(int sq, int target, int piece, int captured, boolean isPromo, List<Move> moves) {
        if (isPromo) {
            moves.add(new Move(sq, target, piece, captured, Piece.QUEEN));
            moves.add(new Move(sq, target, piece, captured, Piece.ROOK));
            moves.add(new Move(sq, target, piece, captured, Piece.BISHOP));
            moves.add(new Move(sq, target, piece, captured, Piece.KNIGHT));
        } else {
            moves.add(new Move(sq, target, piece, captured));
        }
    }

    private static void stepMoves(Board board, int sq, int piece, int enemyColor, int[] dirs, List<Move> moves) {
        for (int d : dirs) {
            int target = sq + d;
            if ((target & 0x88) == 0) {
                int targetPiece = board.board[target];
                if (targetPiece == Piece.EMPTY || (targetPiece & enemyColor) != 0) {
                    moves.add(new Move(sq, target, piece, targetPiece));
                }
            }
        }
    }

    private static void slideMoves(Board board, int sq, int piece, int enemyColor, int[] dirs, List<Move> moves) {
        for (int d : dirs) {
            int target = sq + d;
            while ((target & 0x88) == 0) {
                int targetPiece = board.board[target];
                if (targetPiece == Piece.EMPTY) {
                    moves.add(new Move(sq, target, piece, Piece.EMPTY));
                } else {
                    if ((targetPiece & enemyColor) != 0) {
                        moves.add(new Move(sq, target, piece, targetPiece)); // Capture
                    }
                    break; // Hit a piece, stop sliding
                }
                target += d;
            }
        }
    }

    private static void kingMoves(Board board, int sq, int piece, int color, int enemyColor, List<Move> moves) {
        // Normal moves
        stepMoves(board, sq, piece, enemyColor, KING_DIRS, moves);

        // Castling (Cannot castle out of, through, or into check)
        if (RuleChecker.isInCheck(board, color)) return;

        if (color == Piece.WHITE) {
            if (board.castlingRights.getOrDefault("wK", false) && 
                board.board[sq + 1] == Piece.EMPTY && board.board[sq + 2] == Piece.EMPTY &&
                !RuleChecker.isSquareAttacked(board, sq + 1, enemyColor) && !RuleChecker.isSquareAttacked(board, sq + 2, enemyColor)) {
                Move m = new Move(sq, sq + 2, piece, Piece.EMPTY); m.isCastling = true; moves.add(m);
            }
            if (board.castlingRights.getOrDefault("wQ", false) && 
                board.board[sq - 1] == Piece.EMPTY && board.board[sq - 2] == Piece.EMPTY && board.board[sq - 3] == Piece.EMPTY &&
                !RuleChecker.isSquareAttacked(board, sq - 1, enemyColor) && !RuleChecker.isSquareAttacked(board, sq - 2, enemyColor)) {
                Move m = new Move(sq, sq - 2, piece, Piece.EMPTY); m.isCastling = true; moves.add(m);
            }
        } else {
            if (board.castlingRights.getOrDefault("bK", false) && 
                board.board[sq + 1] == Piece.EMPTY && board.board[sq + 2] == Piece.EMPTY &&
                !RuleChecker.isSquareAttacked(board, sq + 1, enemyColor) && !RuleChecker.isSquareAttacked(board, sq + 2, enemyColor)) {
                Move m = new Move(sq, sq + 2, piece, Piece.EMPTY); m.isCastling = true; moves.add(m);
            }
            if (board.castlingRights.getOrDefault("bQ", false) && 
                board.board[sq - 1] == Piece.EMPTY && board.board[sq - 2] == Piece.EMPTY && board.board[sq - 3] == Piece.EMPTY &&
                !RuleChecker.isSquareAttacked(board, sq - 1, enemyColor) && !RuleChecker.isSquareAttacked(board, sq - 2, enemyColor)) {
                Move m = new Move(sq, sq - 2, piece, Piece.EMPTY); m.isCastling = true; moves.add(m);
            }
        }
    }
}