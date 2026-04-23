package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Piece;

public class Evaluation {

    // Array index corresponds directly to piece type:
    // 0=EMPTY, 1=PAWN, 2=KNIGHT, 3=BISHOP, 4=ROOK, 5=QUEEN, 6=KING
    private static final int[] PIECE_VALUES = {
        0, 100, 320, 330, 500, 900, 1000000 
    };

    public static double evaluate(Board board) {
        double material = 0;
        double strategy = 0;
        int majorPieceCount = 0;

        int wN = Piece.WHITE | Piece.KNIGHT;
        int wB = Piece.WHITE | Piece.BISHOP;
        int bN = Piece.BLACK | Piece.KNIGHT;
        int bB = Piece.BLACK | Piece.BISHOP;

        // Check for "Home Square" occupancy using 0x88 indices
        // White home rank starts at 112, Black home rank starts at 0
        boolean whiteUndeveloped = board.board[113] == wN || board.board[118] == wN || 
                                   board.board[114] == wB || board.board[117] == wB;
        
        boolean blackUndeveloped = board.board[1] == bN || board.board[6] == bN || 
                                   board.board[2] == bB || board.board[5] == bB;

        // Pass 1: Count major pieces for endgame phase detection
        for (int sq = 0; sq < 128; sq++) {
            if ((sq & 0x88) != 0) continue;
            int p = board.board[sq];
            if (p != Piece.EMPTY) {
                int type = p & 7;
                if (type != Piece.PAWN && type != Piece.KING) majorPieceCount++;
            }
        }
        boolean isEndgame = majorPieceCount <= 4;

        // Pass 2: Main loop
        for (int sq = 0; sq < 128; sq++) {
            if ((sq & 0x88) != 0) continue;
            
            int p = board.board[sq];
            if (p == Piece.EMPTY) continue;

            int color = p & (Piece.WHITE | Piece.BLACK);
            int type = p & 7;
            
            // 1. Material
            double pieceValue = PIECE_VALUES[type];
            material += (color == Piece.WHITE) ? pieceValue : -pieceValue;

            // 2. Strategy Weights
            double bonus = PositionWeights.getWeight(type, color, sq, isEndgame) / 50.0;

            // 3. DEVELOPMENT RULE:
            if (color == Piece.WHITE && whiteUndeveloped && !isStartingSquare(type, Piece.WHITE, sq)) {
                bonus -= 10.0; 
            } else if (color == Piece.BLACK && blackUndeveloped && !isStartingSquare(type, Piece.BLACK, sq)) {
                bonus += 10.0; 
            }

            strategy += (color == Piece.WHITE) ? bonus : -bonus;
        }

        double tempo = (board.turn == Piece.WHITE) ? 0.1 : -0.1;
        return material + strategy + tempo;
    }

    private static boolean isStartingSquare(int type, int color, int sq) {
        if (color == Piece.WHITE) {
            return (type == Piece.KNIGHT && (sq == 113 || sq == 118)) ||
                   (type == Piece.BISHOP && (sq == 114 || sq == 117)) ||
                   (type == Piece.ROOK   && (sq == 112 || sq == 119)) ||
                   (type == Piece.QUEEN  && sq == 115) ||
                   (type == Piece.KING   && sq == 116);
        } else {
            return (type == Piece.KNIGHT && (sq == 1 || sq == 6)) ||
                   (type == Piece.BISHOP && (sq == 2 || sq == 5)) ||
                   (type == Piece.ROOK   && (sq == 0 || sq == 7)) ||
                   (type == Piece.QUEEN  && sq == 3) ||
                   (type == Piece.KING   && sq == 4);
        }
    }
}