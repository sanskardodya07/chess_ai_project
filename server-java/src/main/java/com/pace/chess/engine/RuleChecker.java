package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Move;

import java.util.ArrayList;
import java.util.List;

public class RuleChecker {

    public static boolean isInCheck(Board board, String color) {
        int[] king  = "white".equals(color) ? board.whiteKing : board.blackKing;
        String enemy = "white".equals(color) ? "b" : "w";

        int[][] pawnDirs = "white".equals(color)
            ? new int[][]{{-1,-1},{-1,1}}
            : new int[][]{{1,-1},{1,1}};
        for (int[] d : pawnDirs) {
            int r=king[0]+d[0], c=king[1]+d[1];
            if (r>=0&&r<8&&c>=0&&c<8 && board.board[r][c].equals(enemy+"P")) return true;
        }
        for (int[] d : new int[][]{{-2,-1},{-2,1},{-1,-2},{-1,2},{1,-2},{1,2},{2,-1},{2,1}}) {
            int r=king[0]+d[0], c=king[1]+d[1];
            if (r>=0&&r<8&&c>=0&&c<8 && board.board[r][c].equals(enemy+"N")) return true;
        }
        for (int[] d : new int[][]{{1,0},{-1,0},{0,1},{0,-1}}) {
            int r=king[0]+d[0], c=king[1]+d[1];
            while (r>=0&&r<8&&c>=0&&c<8) {
                String p=board.board[r][c];
                if (!p.isEmpty()) {
                    if (p.charAt(0)==enemy.charAt(0)&&(p.charAt(1)=='R'||p.charAt(1)=='Q')) return true;
                    break;
                } r+=d[0]; c+=d[1];
            }
        }
        for (int[] d : new int[][]{{1,1},{1,-1},{-1,1},{-1,-1}}) {
            int r=king[0]+d[0], c=king[1]+d[1];
            while (r>=0&&r<8&&c>=0&&c<8) {
                String p=board.board[r][c];
                if (!p.isEmpty()) {
                    if (p.charAt(0)==enemy.charAt(0)&&(p.charAt(1)=='B'||p.charAt(1)=='Q')) return true;
                    break;
                } r+=d[0]; c+=d[1];
            }
        }
        for (int[] d : new int[][]{{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}}) {
            int r=king[0]+d[0], c=king[1]+d[1];
            if (r>=0&&r<8&&c>=0&&c<8 && board.board[r][c].equals(enemy+"K")) return true;
        }
        return false;
    }

    public static List<Move> filterLegalMoves(Board board, List<Move> moves, String color) {
        List<Move> legal = new ArrayList<>();
        for (Move m : moves) {
            board.makeMove(m);
            if (!isInCheck(board, color)) legal.add(m);
            board.undoMove();
        }
        return legal;
    }
}