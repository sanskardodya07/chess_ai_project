import java.net.URI;
import java.net.http.*;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpResponse.BodyHandlers;

public class TestServer {
    static final String BASE   = "http://localhost:8080";
    static final HttpClient    C = HttpClient.newHttpClient();

    static String savedToken = null;

    public static void main(String[] args) throws Exception {
        System.out.println("╔══════════════════════════════╗");
        System.out.println("║   PACE Java Server Tests     ║");
        System.out.println("╚══════════════════════════════╝\n");

        test("Health",      "GET",  "/health",            null);
        test("Dashboard",   "GET",  "/",                  null);
        test("Register",    "POST", "/api/auth/register",
            "{\"username\":\"testx\",\"password\":\"pass123\"}");
        test("Login",       "POST", "/api/auth/login",
            "{\"username\":\"testx\",\"password\":\"pass123\"}");
        test("Bad login",   "POST", "/api/auth/login",
            "{\"username\":\"testx\",\"password\":\"wrong\"}");
        test("Leaderboard", "GET",  "/api/leaderboard",   null);
        testMove();
        if (savedToken != null) testScore();

        System.out.println("\n✅ All tests done.");
    }

    static void test(String name, String method, String path, String body) throws Exception {
        HttpRequest.Builder b = HttpRequest.newBuilder()
            .uri(URI.create(BASE + path))
            .header("Content-Type", "application/json");

        if ("GET".equals(method)) b.GET();
        else b.POST(BodyPublishers.ofString(body != null ? body : "{}"));

        HttpResponse<String> res = C.send(b.build(), BodyHandlers.ofString());
        String status = res.statusCode() < 300 ? "✅" : "⚠️";
        System.out.printf("%s [%s] %s %s%n", status, res.statusCode(), name,
            res.body().length() > 120 ? res.body().substring(0, 120) + "..." : res.body());

        // Capture token from register/login
        if (res.body().contains("\"token\"")) {
            int s = res.body().indexOf("\"token\":\"") + 9;
            int e = res.body().indexOf("\"", s);
            if (s > 8 && e > s) savedToken = res.body().substring(s, e);
        }
    }

    static void testMove() throws Exception {
        String board = """
        {
          "board": {
            "board": [
              ["bR","bN","bB","bQ","bK","bB","bN","bR"],
              ["bP","bP","bP","bP","bP","bP","bP","bP"],
              ["","","","","","","",""],
              ["","","","","","","",""],
              ["","","","","","","",""],
              ["","","","","","","",""],
              ["wP","wP","wP","wP","wP","wP","wP","wP"],
              ["wR","wN","wB","wQ","wK","wB","wN","wR"]
            ],
            "turn": "black",
            "whiteKing": [7,4],
            "blackKing": [0,4],
            "castlingRights": {"wK":true,"wQ":true,"bK":true,"bQ":true},
            "enPassantTarget": null
          },
          "depth": 2
        }
        """;

        System.out.print("⏳ [Move] Waiting for AI (depth 2)... ");
        long t = System.currentTimeMillis();
        test("Move", "POST", "/api/move", board);
        System.out.printf("    Time: %dms%n", System.currentTimeMillis() - t);
    }

    static void testScore() throws Exception {
        HttpRequest req = HttpRequest.newBuilder()
            .uri(URI.create(BASE + "/api/score/update"))
            .header("Content-Type", "application/json")
            .header("Authorization", "Bearer " + savedToken)
            .POST(BodyPublishers.ofString("{\"result\":\"win\",\"margin\":8}"))
            .build();
        HttpResponse<String> res = C.send(req, BodyHandlers.ofString());
        System.out.printf("%s [%s] Score update %s%n",
            res.statusCode() < 300 ? "✅" : "⚠️", res.statusCode(), res.body());
    }
}