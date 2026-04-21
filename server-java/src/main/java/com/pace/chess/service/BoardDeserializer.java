package com.pace.chess.service;

import com.pace.chess.model.Board;
import java.util.*;

public class BoardDeserializer {

    @SuppressWarnings("unchecked")
    public static Board fromJson(Map<String, Object> data) {
        Board b = new Board();

        List<List<String>> rows = (List<List<String>>) data.get("board");
        for (int r = 0; r < 8; r++)
            for (int c = 0; c < 8; c++)
                b.board[r][c] = rows.get(r).get(c);

        b.turn = (String) data.get("turn");

        List<Integer> wk = (List<Integer>) data.get("whiteKing");
        b.whiteKing = new int[]{wk.get(0), wk.get(1)};

        List<Integer> bk = (List<Integer>) data.get("blackKing");
        b.blackKing = new int[]{bk.get(0), bk.get(1)};

        Map<String, Boolean> cr = (Map<String, Boolean>) data.get("castlingRights");
        b.castlingRights = new HashMap<>(cr);

        Object ep = data.get("enPassantTarget");
        if (ep instanceof List) {
            List<Integer> epList = (List<Integer>) ep;
            b.enPassantTarget = new int[]{epList.get(0), epList.get(1)};
        }

        return b;
    }
}