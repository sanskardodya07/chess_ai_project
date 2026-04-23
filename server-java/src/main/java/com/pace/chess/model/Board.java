package com.pace.chess.model;

import java.util.*;

public class Board {
    public int[] board;
    public int turn; // Piece.WHITE or Piece.BLACK
    public int whiteKing;
    public int blackKing;
    public Map<String, Boolean> castlingRights;
    public Integer enPassantTarget;
    public List<Move> moveHistory;

    public Board() {
        board = new int[128];
        turn = Piece.WHITE;
        whiteKing = 116; // e1 in 0x88 (7*16 + 4)
        blackKing = 4;   // e8 in 0x88 (0*16 + 4)
        castlingRights = new HashMap<>(Map.of("wK",true,"wQ",true,"bK",true,"bQ",true));
        enPassantTarget = null;
        moveHistory = new ArrayList<>();
        // The board array is left empty here because BoardDeserializer will fill it from the API!
    }

    public void makeMove(Move move) {
        move.prevEnPassant      = enPassantTarget;
        move.prevCastlingRights = new HashMap<>(castlingRights);
        move.prevWhiteKing      = whiteKing;
        move.prevBlackKing      = blackKing;

        board[move.startSquare] = Piece.EMPTY;
        board[move.endSquare]   = move.pieceMoved;

        if (move.promotion != 0) {
            int color = move.pieceMoved & (Piece.WHITE | Piece.BLACK);
            board[move.endSquare] = color | move.promotion;
        }

        if (move.isEnPassant && move.enPassantCapturePos != -1) {
            board[move.enPassantCapturePos] = Piece.EMPTY;
        }

        enPassantTarget = null;
        // Pawn double push -> set en passant target
        if ((move.pieceMoved & 7) == Piece.PAWN && Math.abs(move.startSquare - move.endSquare) == 32) {
            enPassantTarget = (move.startSquare + move.endSquare) / 2;
        }

        if (move.isCastling) {
            int color = move.pieceMoved & (Piece.WHITE | Piece.BLACK);
            if (move.endSquare % 16 == 6) { // Kingside
                board[move.endSquare + 1] = Piece.EMPTY;
                board[move.endSquare - 1] = color | Piece.ROOK;
            } else { // Queenside
                board[move.endSquare - 2] = Piece.EMPTY;
                board[move.endSquare + 1] = color | Piece.ROOK;
            }
        }

        if ((move.pieceMoved & 7) == Piece.KING) {
            if ((move.pieceMoved & Piece.WHITE) != 0) whiteKing = move.endSquare;
            else blackKing = move.endSquare;
        }

        // Castling rights invalidation based on square endpoints
        if (move.endSquare == 0) castlingRights.put("bQ", false);
        if (move.endSquare == 7) castlingRights.put("bK", false);
        if (move.endSquare == 112) castlingRights.put("wQ", false);
        if (move.endSquare == 119) castlingRights.put("wK", false);

        if ((move.pieceMoved & 7) == Piece.KING) {
            if ((move.pieceMoved & Piece.WHITE) != 0) { castlingRights.put("wK", false); castlingRights.put("wQ", false); }
            else { castlingRights.put("bK", false); castlingRights.put("bQ", false); }
        } else if ((move.pieceMoved & 7) == Piece.ROOK) {
            if (move.startSquare == 112) castlingRights.put("wQ", false);
            if (move.startSquare == 119) castlingRights.put("wK", false);
            if (move.startSquare == 0) castlingRights.put("bQ", false);
            if (move.startSquare == 7) castlingRights.put("bK", false);
        }

        moveHistory.add(move);
        turn = (turn == Piece.WHITE) ? Piece.BLACK : Piece.WHITE;
    }

    public void undoMove() {
        if (moveHistory.isEmpty()) return;
        Move move = moveHistory.remove(moveHistory.size() - 1);

        board[move.startSquare] = move.pieceMoved;

        if (move.isEnPassant && move.enPassantCapturePos != -1) {
            board[move.endSquare] = Piece.EMPTY;
            board[move.enPassantCapturePos] = move.pieceCaptured;
        } else {
            board[move.endSquare] = move.pieceCaptured;
        }

        if (move.isCastling) {
            int color = move.pieceMoved & (Piece.WHITE | Piece.BLACK);
            if (move.endSquare % 16 == 6) { 
                board[move.endSquare - 1] = Piece.EMPTY; 
                board[move.endSquare + 1] = color | Piece.ROOK; 
            } else { 
                board[move.endSquare + 1] = Piece.EMPTY; 
                board[move.endSquare - 2] = color | Piece.ROOK; 
            }
        }

        enPassantTarget  = move.prevEnPassant;
        castlingRights   = move.prevCastlingRights;
        whiteKing        = move.prevWhiteKing;
        blackKing        = move.prevBlackKing;
        turn = (turn == Piece.WHITE) ? Piece.BLACK : Piece.WHITE;
    }
}