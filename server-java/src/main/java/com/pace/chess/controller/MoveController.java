package com.pace.chess.controller;

import com.pace.chess.engine.AlphaBeta;
import com.pace.chess.model.Board;
import com.pace.chess.model.Move;
import com.pace.chess.service.BoardDeserializer;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import java.util.logging.Logger;

@CrossOrigin(origins = "https://pace-chessai.vercel.app")
@RestController
public class MoveController {

    private static final Logger log = Logger.getLogger("PACE");
    private static final ExecutorService executor = Executors.newCachedThreadPool();

    // In-memory request log (persists across requests - unlike serverless)
    private static final List<Map<String, Object>> requestLog = Collections.synchronizedList(new ArrayList<>());
    private static final int MAX_LOG = 20;

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
            Move move = executor.submit(() -> AlphaBeta.getBestMove(board, depth))
                                .get(8, TimeUnit.SECONDS);

            if (move == null)
                return ResponseEntity.internalServerError().body(Map.of("error", "No legal moves"));

            Map<String, Object> result = serializeMove(move);
            addLog(time, turn, depth, "ok", move.pieceMoved + " → (" + move.endRow + "," + move.endCol + ")");
            return ResponseEntity.ok(Map.of("move", result));

        } catch (TimeoutException e) {
            log.warning("[" + time + "] Timeout at depth " + depth + ", retrying at depth 2");
            addLog(time, turn, depth, "timeout", null);
            try {
                Move move = executor.submit(() -> AlphaBeta.getBestMove(board, 2))
                                    .get(5, TimeUnit.SECONDS);
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
        r.put("startRow",      m.startRow);
        r.put("startCol",      m.startCol);
        r.put("endRow",        m.endRow);
        r.put("endCol",        m.endCol);
        r.put("pieceMoved",    m.pieceMoved);
        r.put("pieceCaptured", m.pieceCaptured);
        r.put("promotion",     m.promotion);
        r.put("isEnPassant",   m.isEnPassant);
        r.put("isCastling",    m.isCastling);
        return r;
    }

    private void addLog(String time, String turn, int depth, String status, String move) {
        synchronized (requestLog) {
            requestLog.add(0, Map.of(
                "time", time, "turn", turn, "depth", depth,
                "status", status, "move", move != null ? move : "—"
            ));
            if (requestLog.size() > MAX_LOG) requestLog.remove(requestLog.size() - 1);
        }
    }

    public static List<Map<String, Object>> getRequestLog() { return requestLog; }
}