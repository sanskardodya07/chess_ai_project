package com.pace.chess.controller;

import com.pace.chess.engine.AlphaBeta;
import com.pace.chess.model.Board;
import com.pace.chess.model.Move;
import com.pace.chess.model.Piece;
import com.pace.chess.service.BoardDeserializer;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import java.util.logging.Logger;

@CrossOrigin(origins = "https://pace-chessai.vercel.app")
@RestController
public class MoveController {

    @Autowired private com.pace.chess.service.RedisService redis;
    @Autowired private com.fasterxml.jackson.databind.ObjectMapper mapper;

    private static final Logger log = Logger.getLogger("PACE");
    private static final ExecutorService executor = Executors.newCachedThreadPool();

    // In-memory request log (persists across requests - unlike serverless)
    private static final List<Map<String, Object>> requestLog = Collections.synchronizedList(new ArrayList<>());

    @PostMapping("/api/move")
    public ResponseEntity<?> getMove(@RequestBody Map<String, Object> body) {
        String time  = Instant.now().toString().substring(11, 19) + " UTC";
        int depth    = body.containsKey("depth") ? (int) body.get("depth") : 3;

        @SuppressWarnings("unchecked")
        Map<String, Object> boardData = (Map<String, Object>) body.get("board");
        String turn = (String) boardData.getOrDefault("turn", "?");
        log.info("[" + time + "] Move | turn=" + turn + " depth=" + depth);

        Board board = BoardDeserializer.fromJson(boardData);

        try {
             // --- START TIMER ---
            long startTime = System.currentTimeMillis();

            Move move = executor.submit(() -> AlphaBeta.getBestMove(board, depth))
                                .get(10000, TimeUnit.SECONDS);

            // --- STOP TIMER ---
            long duration = System.currentTimeMillis() - startTime;

            if (move == null)
                return ResponseEntity.internalServerError().body(Map.of("error", "No legal moves"));

            // Print the calculation time clearly in the logs
            log.info("[" + time + "] Engine Took: " + duration + "ms");

            Map<String, Object> result = serializeMove(move);
            // Updated to use the 1D to 2D math for logging
            addLog(time, turn, depth, "ok", pieceIntToString(move.pieceMoved) + " → (" + (move.endSquare / 16) + "," + (move.endSquare % 16) + ")");
            return ResponseEntity.ok(Map.of("move", result));

        } catch (TimeoutException e) {
            log.warning("[" + time + "] Timeout at depth " + depth + ", retrying at depth 2");
            addLog(time, turn, depth, "timeout", null);
            try {
                Move move = executor.submit(() -> AlphaBeta.getBestMove(board, depth - 1))
                                    .get(30, TimeUnit.SECONDS);
                if (move == null)
                    return ResponseEntity.status(504).body(Map.of("error", "Engine timeout"));
                return ResponseEntity.ok(Map.of("move", serializeMove(move)));
            } catch (Exception ex) {
                return ResponseEntity.status(504).body(Map.of("error", "Engine timeout"));
            }
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", e.getMessage()));
        }
    }

    private Map<String, Object> serializeMove(Move m) {
        Map<String, Object> r = new LinkedHashMap<>();
        // Translate 0x88 index back to Row/Col
        r.put("startRow",      m.startSquare / 16);
        r.put("startCol",      m.startSquare % 16);
        r.put("endRow",        m.endSquare / 16);
        r.put("endCol",        m.endSquare % 16);
        
        // Translate piece integers back to Strings for the frontend
        r.put("pieceMoved",    pieceIntToString(m.pieceMoved));
        r.put("pieceCaptured", m.pieceCaptured != Piece.EMPTY ? pieceIntToString(m.pieceCaptured) : "");
        r.put("promotion",     m.promotion != Piece.EMPTY ? promoIntToString(m.promotion) : null);
        
        r.put("isEnPassant",   m.isEnPassant);
        r.put("isCastling",    m.isCastling);
        return r;
    }

    private void addLog(String time, String turn, int depth, String status, String move) {
        try {
            Map<String, Object> logEntry = Map.of(
                "time", time, "turn", turn, "depth", depth,
                "status", status, "move", move != null ? move : "—"
            );
            // Convert to JSON and push to Redis async so it doesn't block the HTTP response
            String json = mapper.writeValueAsString(logEntry);
            executor.submit(() -> redis.pushLog(json)); 
        } catch (Exception e) {
            log.warning("Failed to write log to Redis: " + e.getMessage());
        }
    }

    public static List<Map<String, Object>> getRequestLog() { return requestLog; }

    // --- Helper Methods to translate Integers back to JSON Strings ---

    private String pieceIntToString(int piece) {
        if (piece == Piece.EMPTY) return "";
        String color = (piece & Piece.WHITE) != 0 ? "w" : "b";
        String type = switch (piece & 7) {
            case Piece.PAWN -> "P";
            case Piece.KNIGHT -> "N";
            case Piece.BISHOP -> "B";
            case Piece.ROOK -> "R";
            case Piece.QUEEN -> "Q";
            case Piece.KING -> "K";
            default -> "";
        };
        return color + type;
    }

    private String promoIntToString(int promo) {
        return switch (promo & 7) {
            case Piece.QUEEN -> "Q";
            case Piece.ROOK -> "R";
            case Piece.BISHOP -> "B";
            case Piece.KNIGHT -> "N";
            default -> null;
        };
    }
}