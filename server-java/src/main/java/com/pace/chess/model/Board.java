package com.pace.chess.model;

import com.pace.chess.engine.MoveGenerator;
import com.pace.chess.engine.RuleChecker;

import java.util.*;

public class Board {
    public String[][] board;
    public String turn;
    public int[] whiteKing;
    public int[] blackKing;
    public Map<String, Boolean> castlingRights;
    public int[] enPassantTarget;
    public List<Move> moveHistory;

    public Board() {
        board = new String[][]{
            {"bR","bN","bB","bQ","bK","bB","bN","bR"},
            {"bP","bP","bP","bP","bP","bP","bP","bP"},
            {"","","","","","","",""},
            {"","","","","","","",""},
            {"","","","","","","",""},
            {"","","","","","","",""},
            {"wP","wP","wP","wP","wP","wP","wP","wP"},
            {"wR","wN","wB","wQ","wK","wB","wN","wR"}
        };
        turn = "white";
        whiteKing = new int[]{7, 4};
        blackKing = new int[]{0, 4};
        castlingRights = new HashMap<>(Map.of("wK",true,"wQ",true,"bK",true,"bQ",true));
        enPassantTarget = null;
        moveHistory = new ArrayList<>();
    }

    public void makeMove(Move move) {
        move.prevEnPassant      = enPassantTarget == null ? null : Arrays.copyOf(enPassantTarget, 2);
        move.prevCastlingRights = new HashMap<>(castlingRights);
        move.prevWhiteKing      = Arrays.copyOf(whiteKing, 2);
        move.prevBlackKing      = Arrays.copyOf(blackKing, 2);

        board[move.startRow][move.startCol] = "";
        board[move.endRow][move.endCol]     = move.pieceMoved;

        if (move.promotion != null)
            board[move.endRow][move.endCol] = move.pieceMoved.charAt(0) + move.promotion;

        if (move.isEnPassant && move.enPassantCapturePos != null)
            board[move.enPassantCapturePos[0]][move.enPassantCapturePos[1]] = "";

        enPassantTarget = null;
        if (move.pieceMoved.charAt(1) == 'P' && Math.abs(move.startRow - move.endRow) == 2) {
            int midRow = (move.startRow + move.endRow) / 2;
            enPassantTarget = new int[]{midRow, move.startCol};
        }

        if (move.isCastling) {
            char c = move.pieceMoved.charAt(0);
            if (move.endCol == 6) { board[move.endRow][7] = ""; board[move.endRow][5] = c + "R"; }
            else                  { board[move.endRow][0] = ""; board[move.endRow][3] = c + "R"; }
        }

        if ("wK".equals(move.pieceMoved)) whiteKing = new int[]{move.endRow, move.endCol};
        if ("bK".equals(move.pieceMoved)) blackKing = new int[]{move.endRow, move.endCol};

        switch (move.pieceMoved) {
            case "wK" -> { castlingRights.put("wK",false); castlingRights.put("wQ",false); }
            case "bK" -> { castlingRights.put("bK",false); castlingRights.put("bQ",false); }
            case "wR" -> { if (move.startCol==0) castlingRights.put("wQ",false);
                           if (move.startCol==7) castlingRights.put("wK",false); }
            case "bR" -> { if (move.startCol==0) castlingRights.put("bQ",false);
                           if (move.startCol==7) castlingRights.put("bK",false); }
        }

        moveHistory.add(move);
        turn = "white".equals(turn) ? "black" : "white";
    }

    public void undoMove() {
        if (moveHistory.isEmpty()) return;
        Move move = moveHistory.remove(moveHistory.size() - 1);

        board[move.startRow][move.startCol] = move.pieceMoved;

        if (move.isEnPassant && move.enPassantCapturePos != null) {
            board[move.endRow][move.endCol] = "";
            board[move.enPassantCapturePos[0]][move.enPassantCapturePos[1]] = move.pieceCaptured;
        } else {
            board[move.endRow][move.endCol] = move.pieceCaptured;
        }

        if (move.isCastling) {
            char c = move.pieceMoved.charAt(0);
            if (move.endCol == 6) { board[move.endRow][5]=""; board[move.endRow][7]=c+"R"; }
            else                  { board[move.endRow][3]=""; board[move.endRow][0]=c+"R"; }
        }

        enPassantTarget  = move.prevEnPassant;
        castlingRights   = move.prevCastlingRights;
        whiteKing        = move.prevWhiteKing;
        blackKing        = move.prevBlackKing;
        turn = "white".equals(turn) ? "black" : "white";
    }

    public List<Move> getAllLegalMoves() {
        List<Move> moves = MoveGenerator.generateAllMoves(this, turn);
        return RuleChecker.filterLegalMoves(this, moves, turn);
    }

    public String gameStatus() {
        List<Move> moves = getAllLegalMoves();
        if (moves.isEmpty()) {
            String winner = "white".equals(turn) ? "Black" : "White";
            return RuleChecker.isInCheck(this, turn)
                ? winner + " wins by checkmate"
                : "Draw by stalemate";
        }
        return "ongoing";
    }
}