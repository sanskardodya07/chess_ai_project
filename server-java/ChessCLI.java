import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Scanner;

public class ChessCLI {
    private static final String SERVER_URL = "http://localhost:8080/api/move";
    private static String[][] board = new String[8][8];

    public static void main(String[] args) {
        initializeBoard();
        HttpClient client = HttpClient.newHttpClient();

        try (Scanner scanner = new Scanner(System.in)) {
            System.out.println("╔══════════════════════════════╗");
            System.out.println("║   PACE CHESS: AI INTERFACE   ║");
            System.out.println("╚══════════════════════════════╝");

            while (true) {
                displayBoard();
                System.out.print("\nYour Move (e.g., e2e4): ");
                String input = scanner.nextLine().toLowerCase().trim();
                if (input.equals("exit")) break;
                if (input.length() != 4) continue;

                updateBoard(input);
                displayBoard();
                System.out.println("\n[WAITING] PACE AI is calculating...");

                try {
                    String jsonBody = generateJsonBody();
                    HttpRequest request = HttpRequest.newBuilder()
                            .uri(URI.create(SERVER_URL))
                            .header("Content-Type", "application/json")
                            .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                            .build();

                    HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
                    
                    if (response.statusCode() == 200) {
                        String aiMoveUci = extractMoveFromResponse(response.body());
                        System.out.println(">> AI MOVED: " + aiMoveUci);
                        updateBoard(aiMoveUci);
                    } else {
                        System.out.println(">> Server Error: " + response.statusCode());
                        System.out.println(">> Response: " + response.body());
                    }
                } catch (Exception e) {
                    System.out.println(">> Connection Error: " + e.getMessage());
                }
            }
        }
    }

    private static String generateJsonBody() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"depth\": 2,");
        sb.append("\"board\": {");
        
        // 1. The 2D Board Array
        sb.append("\"board\": [");
        for (int r = 0; r < 8; r++) {
            sb.append("[");
            for (int c = 0; c < 8; c++) {
                String p = board[r][c].equals(" .") ? "" : board[r][c];
                sb.append("\"").append(p).append("\"").append(c < 7 ? "," : "");
            }
            sb.append("]").append(r < 7 ? "," : "");
        }
        sb.append("],");

        // 2. Metadata required by your Deserializer
        sb.append("\"turn\": \"black\",");
        sb.append("\"whiteKing\": [7, 4],"); // Hardcoded for test
        sb.append("\"blackKing\": [0, 4],"); // Hardcoded for test
        sb.append("\"enPassantTarget\": null,");
        sb.append("\"castlingRights\": {\"wK\":true,\"wQ\":true,\"bK\":true,\"bQ\":true}");
        
        sb.append("}}");
        return sb.toString();
    }

    private static void initializeBoard() {
        String[] pieces = {"bR", "bN", "bB", "bQ", "bK", "bB", "bN", "bR"};
        for (int i = 0; i < 8; i++) {
            board[0][i] = pieces[i];
            board[1][i] = "bP";
            board[6][i] = "wP";
            board[7][i] = "w" + pieces[i].substring(1);
            for (int j = 2; j < 6; j++) board[j][i] = " .";
        }
    }

    private static void displayBoard() {
        System.out.println("\n   a  b  c  d  e  f  g  h");
        for (int i = 0; i < 8; i++) {
            System.out.print((8 - i) + " ");
            for (int j = 0; j < 8; j++) System.out.print("[" + board[i][j] + "]");
            System.out.println(" " + (8 - i));
        }
    }

    private static void updateBoard(String uci) {
        try {
            int sc = uci.charAt(0) - 'a';
            int sr = 8 - Character.getNumericValue(uci.charAt(1));
            int ec = uci.charAt(2) - 'a';
            int er = 8 - Character.getNumericValue(uci.charAt(3));
            board[er][ec] = board[sr][sc];
            board[sr][sc] = " .";
        } catch (Exception e) {}
    }

    private static String extractMoveFromResponse(String json) {
        // Extracts the move from the nested "move" object your controller returns
        try {
            int sr = Integer.parseInt(findVal(json, "startRow"));
            int sc = Integer.parseInt(findVal(json, "startCol"));
            int er = Integer.parseInt(findVal(json, "endRow"));
            int ec = Integer.parseInt(findVal(json, "endCol"));
            return "" + (char)('a' + sc) + (8 - sr) + (char)('a' + ec) + (8 - er);
        } catch (Exception e) { return "error"; }
    }

    private static String findVal(String json, String key) {
        int start = json.indexOf("\"" + key + "\":") + key.length() + 3;
        int end = json.indexOf(",", start);
        if (end == -1) end = json.indexOf("}", start);
        return json.substring(start, end).trim().replace("\"", "");
    }
}