package com.pace.chess.controller;

import com.pace.chess.service.RedisService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import redis.clients.jedis.Tuple;

import java.util.List;
import java.util.Map;

@RestController
public class DashboardController {

    @Autowired RedisService redis;

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "ok", "engine", "PACE Alpha-Beta");
    }

    @GetMapping(value = "/", produces = "text/html")
    public String dashboard() {
        long totalUsers; String topRows;
        try {
            totalUsers = redis.zcard("leaderboard");
            List<Tuple> top = redis.zrevrangeWithScores("leaderboard", 0, 4);
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < top.size(); i++) {
                Tuple t = top.get(i);
                sb.append("<tr><td>#").append(i+1).append("</td><td>")
                  .append(t.getElement()).append("</td><td style='color:#4A90D9'>")
                  .append((int)t.getScore()).append("</td></tr>");
            }
            topRows = sb.isEmpty() ? "<tr><td colspan='3' style='color:#555;text-align:center'>No players yet</td></tr>" : sb.toString();
        } catch (Exception e) {
            totalUsers = -1;
            topRows = "<tr><td colspan='3' style='color:#555;text-align:center'>DB unavailable</td></tr>";
        }

        List<Map<String, Object>> log = MoveController.getRequestLog();
        StringBuilder logHtml = new StringBuilder();
        if (log.isEmpty()) {
            logHtml.append("<tr><td colspan='5' style='color:#555;text-align:center;padding:24px'>No requests yet</td></tr>");
        } else {
            for (Map<String, Object> e : log) {
                String color = "ok".equals(e.get("status")) ? "#4CAF50" : "#FF9800";
                logHtml.append("<tr><td>").append(e.get("time"))
                       .append("</td><td>").append(e.get("turn"))
                       .append("</td><td>").append(e.get("depth"))
                       .append("</td><td style='color:").append(color).append("'>").append(e.get("status"))
                       .append("</td><td>").append(e.get("move")).append("</td></tr>");
            }
        }

        return """
            <!DOCTYPE html><html><head><title>PACE Server</title>
            <meta http-equiv="refresh" content="5">
            <style>
              *{box-sizing:border-box;margin:0;padding:0}
              body{background:#0f0f0f;color:#e0e0e0;font-family:'Courier New',monospace;padding:32px}
              h1{font-size:22px;font-weight:600;letter-spacing:2px;color:#fff}
              .sub{color:#555;font-size:12px;margin-top:4px}
              .dot{width:10px;height:10px;border-radius:50%;background:#4CAF50;
                   animation:pulse 2s infinite;display:inline-block;margin-right:10px}
              @keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
              .grid{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin:28px 0}
              .card{background:#1a1a1a;border:1px solid #222;border-radius:10px;padding:20px}
              .card h2{font-size:11px;letter-spacing:1px;color:#555;text-transform:uppercase;margin-bottom:14px}
              .stat{font-size:32px;font-weight:700;color:#4A90D9}
              table{width:100%;border-collapse:collapse}
              th{background:#141414;padding:10px 14px;text-align:left;font-size:11px;letter-spacing:1px;color:#555;text-transform:uppercase}
              td{padding:10px 14px;border-top:1px solid #1e1e1e;font-size:13px;color:#ccc}
              tr:hover td{background:#1e1e1e}
              .badge{background:#1a1a1a;border:1px solid #2a2a2a;border-radius:6px;padding:3px 10px;font-size:11px;color:#4A90D9;margin-left:12px}
            </style></head><body>
            <div style="display:flex;align-items:center;margin-bottom:28px;border-bottom:1px solid #222;padding-bottom:20px">
              <span class="dot"></span>
              <div><h1>PACE Server Dashboard<span class="badge">v2.0-java</span></h1>
              <div class="sub">Portable Application Chess Engine · Spring Boot · Auto-refreshes every 5s</div></div>
            </div>
            <div class="grid">
              <div class="card"><h2>Registered Players</h2><div class="stat">%d</div></div>
              <div class="card"><h2>Requests This Session</h2><div class="stat">%d</div></div>
            </div>
            <div class="grid">
              <div class="card"><h2>Top 5 Leaderboard</h2>
                <table><thead><tr><th>Rank</th><th>Player</th><th>Points</th></tr></thead>
                <tbody>%s</tbody></table></div>
              <div class="card"><h2>Recent Move Requests</h2>
                <table><thead><tr><th>Time</th><th>Turn</th><th>Depth</th><th>Status</th><th>Move</th></tr></thead>
                <tbody>%s</tbody></table></div>
            </div></body></html>
            """.formatted(totalUsers, log.size(), topRows, logHtml.toString());
    }
}