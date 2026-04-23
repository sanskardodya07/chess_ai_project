package com.pace.chess.service;

import com.pace.chess.model.Board;
import com.pace.chess.model.Piece;
import java.util.*;

public class BoardDeserializer {

    @SuppressWarnings("unchecked")
    public static Board fromJson(Map<String, Object> data) {
        Board b = new Board();

        // 1. Translate the 8x8 String array into the 1D 0x88 Integer array
        List<List<String>> rows = (List<List<String>>) data.get("board");
        for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
                String pieceStr = rows.get(r).get(c);
                int index = (r * 16) + c; 
                b.board[index] = pieceStringToInt(pieceStr);
            }
        }

        // 2. Translate turn
        String turnStr = (String) data.get("turn");
        b.turn = "white".equals(turnStr) ? Piece.WHITE : Piece.BLACK;

        // 3. Translate King coordinates [row, col] to 0x88 index
        List<Integer> wk = (List<Integer>) data.get("whiteKing");
        b.whiteKing = (wk.get(0) * 16) + wk.get(1);

        List<Integer> bk = (List<Integer>) data.get("blackKing");
        b.blackKing = (bk.get(0) * 16) + bk.get(1);

        // 4. Castling rights remain unchanged (String keys are fine here)
        Map<String, Boolean> cr = (Map<String, Boolean>) data.get("castlingRights");
        b.castlingRights = new HashMap<>(cr);

        // 5. Translate En Passant Target [row, col] to 0x88 index
        Object ep = data.get("enPassantTarget");
        if (ep instanceof List) {
            List<Integer> epList = (List<Integer>) ep;
            b.enPassantTarget = (epList.get(0) * 16) + epList.get(1);
        } else {
            b.enPassantTarget = null; // Important to handle nulls correctly
        }

        return b;
    }

    // --- Helper Method ---
    // Converts "wP" to (Piece.WHITE | Piece.PAWN)
    private static int pieceStringToInt(String p) {
        if (p == null || p.isEmpty()) return Piece.EMPTY;
        
        int color = p.charAt(0) == 'w' ? Piece.WHITE : Piece.BLACK;
        int type = switch (p.charAt(1)) {
            case 'P' -> Piece.PAWN;
            case 'N' -> Piece.KNIGHT;
            case 'B' -> Piece.BISHOP;
            case 'R' -> Piece.ROOK;
            case 'Q' -> Piece.QUEEN;
            case 'K' -> Piece.KING;
            default -> Piece.EMPTY;
        };
        
        return color | type;
    }
}