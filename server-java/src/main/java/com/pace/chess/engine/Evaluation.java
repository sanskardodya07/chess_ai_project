package com.pace.chess.engine;

import com.pace.chess.model.Board;
import java.util.Map;

public class Evaluation {

    private static final Map<Character, Integer> PIECE_VALUES = Map.of(
        'P', 100, 'N', 320, 'B', 330, 'R', 500, 'Q', 900, 'K', 1000000 
    );

    public static double evaluate(Board board) {
        double material = 0;
        double strategy = 0;
        int majorPieceCount = 0;

        // Pass 1: Count pieces and check for "Home Square" occupancy
        boolean whiteUndeveloped = board.board[7][1].equals("wN") || board.board[7][6].equals("wN") || 
                                 board.board[7][2].equals("wB") || board.board[7][5].equals("wB");
        
        boolean blackUndeveloped = board.board[0][1].equals("bN") || board.board[0][6].equals("bN") || 
                                 board.board[0][2].equals("bB") || board.board[0][5].equals("bB");

        for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
                String p = board.board[r][c];
                if (!p.isEmpty() && p.charAt(1) != 'P' && p.charAt(1) != 'K') majorPieceCount++;
            }
        }
        boolean isEndgame = majorPieceCount <= 4;

        // Pass 2: Main loop
        for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
                String p = board.board[r][c];
                if (p.isEmpty()) continue;

                char color = p.charAt(0);
                char type = p.charAt(1);
                
                // 1. Material
                material += (color == 'w') ? PIECE_VALUES.get(type) : -PIECE_VALUES.get(type);

                // 2. Strategy Weights
                double bonus = PositionWeights.getWeight(type, color, r, c, isEndgame) / 50.0;

                // 3. DEVELOPMENT RULE:
                // Penalty for moving a piece again if it's NOT on its starting square 
                // AND the minor pieces are still at home.
                if (color == 'w' && whiteUndeveloped && !isStartingSquare(type, 'w', r, c)) {
                    bonus -= 10.0; // Penalty makes the engine prefer developing a new piece
                } else if (color == 'b' && blackUndeveloped && !isStartingSquare(type, 'b', r, c)) {
                    bonus += 10.0; // Flipped for black
                }

                strategy += (color == 'w') ? bonus : -bonus;
            }
        }

        double tempo = (board.turn.equals("white")) ? 0.1 : -0.1;
        return material + strategy + tempo;
    }

    private static boolean isStartingSquare(char type, char color, int r, int c) {
        if (color == 'w') {
            return (type == 'N' && r == 7 && (c == 1 || c == 6)) ||
                   (type == 'B' && r == 7 && (c == 2 || c == 5)) ||
                   (type == 'R' && r == 7 && (c == 0 || c == 7)) ||
                   (type == 'Q' && r == 7 && c == 3) ||
                   (type == 'K' && r == 7 && c == 4);
        } else {
            return (type == 'N' && r == 0 && (c == 1 || c == 6)) ||
                   (type == 'B' && r == 0 && (c == 2 || c == 5)) ||
                   (type == 'R' && r == 0 && (c == 0 || c == 7)) ||
                   (type == 'Q' && r == 0 && c == 3) ||
                   (type == 'K' && r == 0 && c == 4);
        }
    }
}