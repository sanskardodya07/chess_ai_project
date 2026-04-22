package com.pace.chess.engine;

import com.pace.chess.model.Board;
import com.pace.chess.model.Move;
import java.util.ArrayList;
import java.util.List;

public class MoveGenerator {

    public static List<Move> generateAllMoves(Board board, String color) {
        List<Move> moves = new ArrayList<>();
        for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
                String piece = board.board[r][c];
                if (piece.isEmpty()) continue;
                if ("white".equals(color) && piece.charAt(0) != 'w') continue;
                if ("black".equals(color) && piece.charAt(0) != 'b') continue;
                switch (piece.charAt(1)) {
                    case 'P' -> pawnMoves(board, r, c, moves);
                    case 'N' -> knightMoves(board, r, c, moves);
                    case 'B' -> slide(board, r, c, moves, new int[][]{{1,1},{1,-1},{-1,1},{-1,-1}});
                    case 'R' -> slide(board, r, c, moves, new int[][]{{1,0},{-1,0},{0,1},{0,-1}});
                    case 'Q' -> {
                        slide(board, r, c, moves, new int[][]{{1,1},{1,-1},{-1,1},{-1,-1}});
                        slide(board, r, c, moves, new int[][]{{1,0},{-1,0},{0,1},{0,-1}});
                    }
                    case 'K' -> kingMoves(board, r, c, moves);
                }
            }
        }
        return moves;
    }

    private static void pawnMoves(Board board, int r, int c, List<Move> moves) {
        String piece = board.board[r][c];
        int dir      = piece.charAt(0) == 'w' ? -1 : 1;
        int startRow = piece.charAt(0) == 'w' ?  6 : 1;

        // Forward moves
        int nr = r + dir;
        if (nr >= 0 && nr < 8 && board.board[nr][c].isEmpty()) {
            if (nr == 0 || nr == 7) {
                moves.add(new Move(new int[]{r,c}, new int[]{nr,c}, piece, "", "Q"));
                moves.add(new Move(new int[]{r,c}, new int[]{nr,c}, piece, "", "R"));
                moves.add(new Move(new int[]{r,c}, new int[]{nr,c}, piece, "", "B"));
                moves.add(new Move(new int[]{r,c}, new int[]{nr,c}, piece, "", "N"));
            } else {
                moves.add(new Move(new int[]{r,c}, new int[]{nr,c}, piece, ""));
                if (r == startRow && board.board[r + 2*dir][c].isEmpty())
                    moves.add(new Move(new int[]{r,c}, new int[]{r+2*dir,c}, piece, ""));
            }
        }

        // Captures
        for (int dc : new int[]{-1, 1}) {
            int nc = c + dc;
            if (nc < 0 || nc >= 8 || nr < 0 || nr >= 8) continue;
            String target = board.board[nr][nc];
            
            if (!target.isEmpty() && target.charAt(0) != piece.charAt(0)) {
                if (nr == 0 || nr == 7) {
                    moves.add(new Move(new int[]{r,c}, new int[]{nr,nc}, piece, target, "Q"));
                } else {
                    moves.add(new Move(new int[]{r,c}, new int[]{nr,nc}, piece, target));
                }
            }
            
            // En Passant
            if (board.enPassantTarget != null && board.enPassantTarget[0] == nr && board.enPassantTarget[1] == nc) {
                String captured = piece.charAt(0) == 'w' ? "bP" : "wP";
                Move m = new Move(new int[]{r,c}, new int[]{nr,nc}, piece, captured);
                m.isEnPassant = true;
                m.enPassantCapturePos = piece.charAt(0) == 'w' ? new int[]{nr+1, nc} : new int[]{nr-1, nc};
                moves.add(m);
            }
        }
    }

    private static void knightMoves(Board board, int r, int c, List<Move> moves) {
        String piece = board.board[r][c];
        for (int[] d : new int[][]{{-2,-1},{-2,1},{-1,-2},{-1,2},{1,-2},{1,2},{2,-1},{2,1}}) {
            int nr = r+d[0], nc = c+d[1];
            if (nr<0||nr>=8||nc<0||nc>=8) continue;
            String t = board.board[nr][nc];
            if (t.isEmpty() || t.charAt(0) != piece.charAt(0))
                moves.add(new Move(new int[]{r,c}, new int[]{nr,nc}, piece, t));
        }
    }

    private static void slide(Board board, int r, int c, List<Move> moves, int[][] dirs) {
        String piece = board.board[r][c];
        for (int[] d : dirs) {
            int nr = r+d[0], nc = c+d[1];
            while (nr>=0&&nr<8&&nc>=0&&nc<8) {
                String t = board.board[nr][nc];
                if (t.isEmpty()) {
                    moves.add(new Move(new int[]{r,c}, new int[]{nr,nc}, piece, ""));
                } else {
                    if (t.charAt(0) != piece.charAt(0))
                        moves.add(new Move(new int[]{r,c}, new int[]{nr,nc}, piece, t));
                    break;
                }
                nr += d[0]; nc += d[1];
            }
        }
    }

    private static void kingMoves(Board board, int r, int c, List<Move> moves) {
        String piece  = board.board[r][c];
        String color  = piece.charAt(0)=='w' ? "white" : "black";

        for (int[] d : new int[][]{{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}}) {
            int nr = r+d[0], nc = c+d[1];
            if (nr<0||nr>=8||nc<0||nc>=8) continue;
            String t = board.board[nr][nc];
            if (t.isEmpty() || t.charAt(0) != piece.charAt(0))
                moves.add(new Move(new int[]{r,c}, new int[]{nr,nc}, piece, t));
        }

        if (RuleChecker.isInCheck(board, color)) return;
        String enemy = piece.charAt(0)=='w' ? "b" : "w";

        if ("wK".equals(piece)) {
            if (Boolean.TRUE.equals(board.castlingRights.get("wK"))
                    && board.board[7][5].isEmpty() && board.board[7][6].isEmpty()
                    && !isSquareAttacked(board,7,5,enemy) && !isSquareAttacked(board,7,6,enemy)) {
                Move m = new Move(new int[]{7,4}, new int[]{7,6}, piece, ""); m.isCastling=true; moves.add(m);
            }
            if (Boolean.TRUE.equals(board.castlingRights.get("wQ"))
                    && board.board[7][3].isEmpty() && board.board[7][2].isEmpty() && board.board[7][1].isEmpty()
                    && !isSquareAttacked(board,7,3,enemy) && !isSquareAttacked(board,7,2,enemy)) {
                Move m = new Move(new int[]{7,4}, new int[]{7,2}, piece, ""); m.isCastling=true; moves.add(m);
            }
        } else if ("bK".equals(piece)) {
            if (Boolean.TRUE.equals(board.castlingRights.get("bK"))
                    && board.board[0][5].isEmpty() && board.board[0][6].isEmpty()
                    && !isSquareAttacked(board,0,5,enemy) && !isSquareAttacked(board,0,6,enemy)) {
                Move m = new Move(new int[]{0,4}, new int[]{0,6}, piece, ""); m.isCastling=true; moves.add(m);
            }
            if (Boolean.TRUE.equals(board.castlingRights.get("bQ"))
                    && board.board[0][3].isEmpty() && board.board[0][2].isEmpty() && board.board[0][1].isEmpty()
                    && !isSquareAttacked(board,0,3,enemy) && !isSquareAttacked(board,0,2,enemy)) {
                Move m = new Move(new int[]{0,4}, new int[]{0,2}, piece, ""); m.isCastling=true; moves.add(m);
            }
        }
    }

    public static boolean isSquareAttacked(Board board, int row, int col, String attacker) {
        int[][] pawnDirs = attacker.equals("w") ? new int[][]{{1,-1},{1,1}} : new int[][]{{-1,-1},{-1,1}};
        for (int[] d : pawnDirs) {
            int r=row+d[0], c=col+d[1];
            if (r>=0&&r<8&&c>=0&&c<8 && board.board[r][c].equals(attacker+"P")) return true;
        }
        for (int[] d : new int[][]{{-2,-1},{-2,1},{-1,-2},{-1,2},{1,-2},{1,2},{2,-1},{2,1}}) {
            int r=row+d[0], c=col+d[1];
            if (r>=0&&r<8&&c>=0&&c<8 && board.board[r][c].equals(attacker+"N")) return true;
        }
        for (int[] d : new int[][]{{1,0},{-1,0},{0,1},{0,-1}}) {
            int r=row+d[0], c=col+d[1];
            while (r>=0&&r<8&&c>=0&&c<8) {
                String p=board.board[r][c];
                if (!p.isEmpty()) {
                    if (p.charAt(0)==attacker.charAt(0) && (p.charAt(1)=='R'||p.charAt(1)=='Q')) return true;
                    break;
                } r+=d[0]; c+=d[1];
            }
        }
        for (int[] d : new int[][]{{1,1},{1,-1},{-1,1},{-1,-1}}) {
            int r=row+d[0], c=col+d[1];
            while (r>=0&&r<8&&c>=0&&c<8) {
                String p=board.board[r][c];
                if (!p.isEmpty()) {
                    if (p.charAt(0)==attacker.charAt(0) && (p.charAt(1)=='B'||p.charAt(1)=='Q')) return true;
                    break;
                } r+=d[0]; c+=d[1];
            }
        }
        for (int[] d : new int[][]{{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}}) {
            int r=row+d[0], c=col+d[1];
            if (r>=0&&r<8&&c>=0&&c<8 && board.board[r][c].equals(attacker+"K")) return true;
        }
        return false;
    }
}