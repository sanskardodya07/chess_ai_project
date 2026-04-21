package com.pace.chess.model;

import java.util.Map;

public class Move {
    public int startRow, startCol, endRow, endCol;
    public String pieceMoved, pieceCaptured;
    public String promotion;
    public boolean isEnPassant;
    public boolean isCastling;
    public int[] enPassantCapturePos;

    // saved for undo
    public int[] prevEnPassant;
    public Map<String, Boolean> prevCastlingRights;
    public int[] prevWhiteKing;
    public int[] prevBlackKing;

    public Move(int[] start, int[] end, String pieceMoved, String pieceCaptured) {
        this.startRow = start[0]; this.startCol = start[1];
        this.endRow   = end[0];   this.endCol   = end[1];
        this.pieceMoved    = pieceMoved;
        this.pieceCaptured = pieceCaptured != null ? pieceCaptured : "";
        this.promotion     = null;
        this.isEnPassant   = false;
        this.isCastling    = false;
    }

    public Move(int[] start, int[] end, String pieceMoved, String pieceCaptured, String promotion) {
        this(start, end, pieceMoved, pieceCaptured);
        this.promotion = promotion;
    }

    @Override
    public String toString() {
        return pieceMoved + ": (" + startRow + "," + startCol + ")->(" + endRow + "," + endCol + ")";
    }
}