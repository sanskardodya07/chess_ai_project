package com.pace.chess.engine;

import com.pace.chess.model.Board;
import java.util.Map;

public class Evaluation {

    private static final Map<Character,Integer> VALUES =
        Map.of('P',100,'N',300,'B',300,'R',500,'Q',900,'K',0);

    public static double evaluate(Board board) {
        String phase = detectPhase(board);
        return materialScore(board)
             + developmentScore(board, phase)
             + kingScore(board, phase)
             + attackScore(board);
    }

    private static String detectPhase(Board board) {
        int total = 0;
        for (String[] row : board.board)
            for (String p : row)
                if (!p.isEmpty() && p.charAt(1) != 'K')
                    total += VALUES.get(p.charAt(1));
        int s = total / 100;
        return s > 40 ? "opening" : s > 20 ? "middlegame" : "endgame";
    }

    private static double materialScore(Board board) {
        double score = 0;
        for (String[] row : board.board)
            for (String p : row)
                if (!p.isEmpty())
                    score += p.charAt(0)=='w' ? VALUES.get(p.charAt(1)) : -VALUES.get(p.charAt(1));
        return score;
    }

    private static double developmentScore(Board board, String phase) {
        if (!"opening".equals(phase)) return 0;
        double s = 0;
        if (!board.board[7][1].equals("wN")) s += 0.3;
        if (!board.board[7][6].equals("wN")) s += 0.3;
        if (!board.board[7][2].equals("wB")) s += 0.3;
        if (!board.board[7][5].equals("wB")) s += 0.3;
        if (!board.board[0][1].equals("bN")) s -= 0.3;
        if (!board.board[0][6].equals("bN")) s -= 0.3;
        if (!board.board[0][2].equals("bB")) s -= 0.3;
        if (!board.board[0][5].equals("bB")) s -= 0.3;
        return s;
    }

    private static double kingScore(Board board, String phase) {
        double s = 0;
        int[] wk = board.whiteKing, bk = board.blackKing;
        if (!"endgame".equals(phase)) {
            if (wk[1]==3||wk[1]==4) s -= 0.5;
            if (bk[1]==3||bk[1]==4) s += 0.5;
        } else {
            s += centerBonus(wk) - centerBonus(bk);
        }
        return s;
    }

    private static double centerBonus(int[] pos) {
        return (4 - Math.abs(3.5-pos[0]) - Math.abs(3.5-pos[1])) * 0.2;
    }

    private static double attackScore(Board board) {
        double s = 0;
        for (int r=0; r<8; r++)
            for (int c=0; c<8; c++) {
                String p = board.board[r][c];
                if (p.isEmpty()) continue;
                s += p.charAt(0)=='w' ? (6-r)*0.05 : -(r-1)*0.05;
            }
        return s;
    }
}