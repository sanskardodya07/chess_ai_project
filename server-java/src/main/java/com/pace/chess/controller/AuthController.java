package com.pace.chess.controller;

import com.pace.chess.service.AuthService;
import com.pace.chess.service.RedisService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import redis.clients.jedis.Tuple;

import java.util.*;

@CrossOrigin(origins = "https://pace-chessai.vercel.app")
@RestController
public class AuthController {

    @Autowired AuthService auth;
    @Autowired RedisService redis;

    @PostMapping("/api/auth/register")
    public ResponseEntity<?> register(@RequestBody Map<String, String> body) {
        String username = body.getOrDefault("username", "").trim();
        String password = body.getOrDefault("password", "").trim();

        if (!auth.isValidUsername(username))
            return ResponseEntity.badRequest().body(Map.of("error", "Username must be 1-7 letters only"));
        if (password.length() < 4)
            return ResponseEntity.badRequest().body(Map.of("error", "Password must be at least 4 characters"));
        if (auth.userExists(username))
            return ResponseEntity.status(409).body(Map.of("error", "Username already taken"));

        auth.createUser(username, password);
        return ResponseEntity.ok(Map.of("token", auth.createToken(username), "username", username));
    }

    @PostMapping("/api/auth/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {
        String username = body.getOrDefault("username", "").trim();
        String password = body.getOrDefault("password", "").trim();

        if (!auth.checkPassword(password, username))
            return ResponseEntity.status(401).body(Map.of("error", "Invalid username or password"));

        Map<String, String> stats = auth.getUserStats(username);
        return ResponseEntity.ok(Map.of(
            "token",        auth.createToken(username),
            "username",     username,
            "total_points", Integer.parseInt(stats.getOrDefault("total_points", "0")),
            "wins",         Integer.parseInt(stats.getOrDefault("wins", "0")),
            "losses",       Integer.parseInt(stats.getOrDefault("losses", "0")),
            "draws",        Integer.parseInt(stats.getOrDefault("draws", "0"))
        ));
    }

    @PostMapping("/api/score/update")
    public ResponseEntity<?> updateScore(@RequestHeader("Authorization") String authHeader,
                                          @RequestBody Map<String, Object> body) {
        String token    = authHeader.replace("Bearer ", "").trim();
        String username = auth.verifyToken(token);
        if (username == null)
            return ResponseEntity.status(401).body(Map.of("error", "Invalid or expired token"));

        String result = (String) body.get("result");
        int margin     = body.containsKey("margin") ? (int) body.get("margin") : 0;

        if (!List.of("win","loss","draw").contains(result))
            return ResponseEntity.badRequest().body(Map.of("error", "result must be win/loss/draw"));

        long points = 0;
        if ("win".equals(result))
            points = 1 + (long) Math.ceil(Math.max(margin, 0) / 2.0);

        redis.updateScore(username, points, result + "s");

        String totalStr = redis.hget("user:" + username, "total_points");
        int total = totalStr != null ? Integer.parseInt(totalStr) : 0;

        return ResponseEntity.ok(Map.of("points_earned", points, "total_points", total));
    }

    @GetMapping("/api/leaderboard")
    public ResponseEntity<?> leaderboard() {
        List<Tuple> entries = redis.zrevrangeWithScores("leaderboard", 0, 9);
        List<Map<String, Object>> board = new ArrayList<>();
        for (int i = 0; i < entries.size(); i++) {
            Tuple t = entries.get(i);
            board.add(Map.of("rank", i+1, "username", t.getElement(), "points", (int) t.getScore()));
        }
        return ResponseEntity.ok(Map.of("leaderboard", board));
    }
}