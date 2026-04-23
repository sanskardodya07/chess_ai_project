package com.pace.chess.model;

import java.util.Map;

public class Move {
    public int startSquare, endSquare;
    public int pieceMoved, pieceCaptured; 
    public int promotion; 
    public boolean isEnPassant;
    public boolean isCastling;
    public int enPassantCapturePos = -1;

    // Saved for undo
    public Integer prevEnPassant;
    public Map<String, Boolean> prevCastlingRights;
    public int prevWhiteKing;
    public int prevBlackKing;

    public Move(int startSquare, int endSquare, int pieceMoved, int pieceCaptured) {
        this.startSquare = startSquare;
        this.endSquare = endSquare;
        this.pieceMoved = pieceMoved;
        this.pieceCaptured = pieceCaptured;
        this.promotion = 0;
        this.isEnPassant = false;
        this.isCastling = false;
    }

    public Move(int startSquare, int endSquare, int pieceMoved, int pieceCaptured, int promotion) {
        this(startSquare, endSquare, pieceMoved, pieceCaptured);
        this.promotion = promotion;
    }

    @Override
    public String toString() {
        return "Piece " + pieceMoved + ": " + startSquare + " -> " + endSquare;
    }
}