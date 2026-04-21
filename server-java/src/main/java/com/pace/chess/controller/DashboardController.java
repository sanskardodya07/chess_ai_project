package com.pace.chess.controller;

import com.pace.chess.service.RedisService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import redis.clients.jedis.Tuple;
import java.util.concurrent.atomic.AtomicLong;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "https://pace-chessai.vercel.app")
@RestController
public class DashboardController {

    @Autowired RedisService redis;
    
    // Tracks pings to the health endpoint
    private static final AtomicLong healthPings = new AtomicLong(0);
    private final String ADMIN_PASS = "pace2026"; // Change this!

    @GetMapping("/health")
    public Map<String, Object> health() {
        healthPings.incrementAndGet(); // Count the cron hit
        return Map.of(
            "status", "ok", 
            "engine", "PACE Alpha-Beta",
            "uptime_signal", "received"
        );
    }

    @GetMapping(value = "/", produces = "text/html")
    public String dashboard(@RequestParam(name = "pass", required = false) String pass) {
        
        // SIMPLE SECURITY GATE
        if (!ADMIN_PASS.equals(pass)) {
            return "<body style='background:#0f0f0f;color:red;font-family:monospace;padding:50px'>" +
                   "<h1>403 ACCESS DENIED</h1><p>Invalid or missing access key.</p></body>";
        }

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
        for (Map<String, Object> e : log) {
            String color = "ok".equals(e.get("status")) ? "#4CAF50" : "#FF9800";
            logHtml.append("<tr><td>").append(e.get("time"))
                   .append("</td><td>").append(e.get("turn"))
                   .append("</td><td>").append(e.get("depth"))
                   .append("</td><td style='color:").append(color).append("'>").append(e.get("status"))
                   .append("</td><td>").append(e.get("move")).append("</td></tr>");
        }

        return """
            <!DOCTYPE html><html><head><title>PACE Admin</title>
            <meta http-equiv="refresh" content="10">
            <style>
              *{box-sizing:border-box;margin:0;padding:0}
              body{background:#0f0f0f;color:#e0e0e0;font-family:'Courier New',monospace;padding:32px}
              .dot{width:10px;height:10px;border-radius:50%%;background:#4CAF50;display:inline-block;margin-right:10px;animation:pulse 2s infinite}
              @keyframes pulse{0%%,100%%{opacity:1}50%%{opacity:.4}}
              .grid{display:grid;grid-template-columns:repeat(3, 1fr);gap:20px;margin:28px 0}
              .card{background:#161616;border:1px solid #222;border-radius:10px;padding:20px}
              .stat{font-size:32px;font-weight:700;color:#4A90D9}
              table{width:100%%;border-collapse:collapse}
              td, th{padding:12px;text-align:left;border-bottom:1px solid #222;font-size:13px}
              .cron-hit{color:#4CAF50;font-weight:bold}
            </style></head><body>
              <div style="border-bottom:1px solid #222;padding-bottom:20px;margin-bottom:20px">
                <span class="dot"></span><h1>PACE Server Monitor</h1>
              </div>
              <div class="grid">
                <div class="card"><h2>Players</h2><div class="stat">%d</div></div>
                <div class="card"><h2>Session Requests</h2><div class="stat">%d</div></div>
                <div class="card"><h2>Cron-Job Pings</h2><div class="stat cron-hit">%d</div></div>
              </div>
              <div class="grid" style="grid-template-columns: 1fr 2fr;">
                <div class="card"><h3>Leaderboard</h3><table>%s</table></div>
                <div class="card"><h3>Recent Activity</h3><table>%s</table></div>
              </div>
            </body></html>
            """.formatted(totalUsers, log.size(), healthPings.get(), topRows, logHtml.toString());
    }
}