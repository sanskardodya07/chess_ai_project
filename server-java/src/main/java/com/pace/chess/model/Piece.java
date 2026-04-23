package com.pace.chess.model;

public class Piece {
    public static final int EMPTY = 0;

    // Piece Types (1 to 6)
    public static final int PAWN   = 1;
    public static final int KNIGHT = 2;
    public static final int BISHOP = 3;
    public static final int ROOK   = 4;
    public static final int QUEEN  = 5;
    public static final int KING   = 6;

    // Colors (Bit flags)
    public static final int WHITE  = 8;  // 1000 in binary
    public static final int BLACK  = 16; // 10000 in binary
}