import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Scanner;
import java.util.Arrays;

public class ChessCLI {
    private static final String SERVER_URL = "http://localhost:8080/api/move";
    private static String[][] board = new String[8][8];
    
    // State tracking to stay in sync with PACE engine
    private static String currentTurn = "white";
    private static int[] whiteKingPos = {7, 4};
    private static int[] blackKingPos = {0, 4};

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
                if (input.length() != 4) {
                    System.out.println("Invalid format. Use UCI (e.g., e2e4).");
                    continue;
                }

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
                    String aiMove = extractMoveFromResponse(response.body());

                    if (!aiMove.equals("error")) {
                        System.out.println("PACE AI played: " + aiMove);
                        updateBoard(aiMove);
                    } else {
                        System.out.println("AI Error: Check server logs.");
                    }
                } catch (Exception e) {
                    System.out.println("Connection error: " + e.getMessage());
                }
            }
        }
    }

    private static void initializeBoard() {
        String[] pieces = {"R", "N", "B", "Q", "K", "B", "N", "R"};
        for (int i = 0; i < 8; i++) {
            board[0][i] = "b" + pieces[i];
            board[1][i] = "bP";
            for (int j = 2; j < 6; j++) board[j][i] = ""; // Now synced with Board.java
            board[6][i] = "wP";
            board[7][i] = "w" + pieces[i];
        }
    }

    private static void displayBoard() {
        System.out.println("\n   a  b  c  d  e  f  g  h");
        for (int i = 0; i < 8; i++) {
            System.out.print((8 - i) + " ");
            for (int j = 0; j < 8; j++) {
                String p = board[i][j].isEmpty() ? "  " : board[i][j];
                System.out.print("[" + p + "]");
            }
            System.out.println(" " + (8 - i));
        }
        System.out.println("   a  b  c  d  e  f  g  h");
        System.out.println("Turn: " + currentTurn.toUpperCase());
    }

    private static void updateBoard(String uci) {
        try {
            int sc = uci.charAt(0) - 'a';
            int sr = 8 - Character.getNumericValue(uci.charAt(1));
            int ec = uci.charAt(2) - 'a';
            int er = 8 - Character.getNumericValue(uci.charAt(3));
            
            String piece = board[sr][sc];
            
            // Track King moves for metadata sync
            if (piece.equals("wK")) { whiteKingPos[0] = er; whiteKingPos[1] = ec; }
            if (piece.equals("bK")) { blackKingPos[0] = er; blackKingPos[1] = ec; }

            board[er][ec] = piece;
            board[sr][sc] = "";
            
            // Toggle turn
            currentTurn = currentTurn.equals("white") ? "black" : "white";
            
        } catch (Exception e) {
            System.out.println("Move failed to update internally.");
        }
    }

    private static String generateJsonBody() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        
        // 1. Root level 'depth'
        sb.append("\"depth\": 3,");

        // 2. The 'board' key containing the object (matching Flutter's board.toJson())
        sb.append("\"board\": {");
        
        // Internal board array
        sb.append("\"board\": [");
        for (int i = 0; i < 8; i++) {
            sb.append("[");
            for (int j = 0; j < 8; j++) {
                sb.append("\"").append(board[i][j]).append("\"").append(j < 7 ? "," : "");
            }
            sb.append("]").append(i < 7 ? "," : "");
        }
        sb.append("],");

        // Turn metadata
        sb.append("\"turn\": \"").append(currentTurn).append("\",");

        // King positions as ARRAYS (to satisfy your server's BoardDeserializer)
        sb.append("\"whiteKing\": [").append(whiteKingPos[0]).append(",").append(whiteKingPos[1]).append("],");
        sb.append("\"blackKing\": [").append(blackKingPos[0]).append(",").append(blackKingPos[1]).append("]");

        sb.append("}"); // Close "board" object
        
        sb.append("}"); // Close root object
        return sb.toString();
    }

    private static String extractMoveFromResponse(String json) {
        try {
            // Very simple parsing for the structure: {"move": {"startRow":x, "startCol":y...}}
            int sr = Integer.parseInt(findVal(json, "startRow"));
            int sc = Integer.parseInt(findVal(json, "startCol"));
            int er = Integer.parseInt(findVal(json, "endRow"));
            int ec = Integer.parseInt(findVal(json, "endCol"));
            
            return "" + (char)('a' + sc) + (8 - sr) + (char)('a' + ec) + (8 - er);
        } catch (Exception e) { 
            return "error"; 
        }
    }

    private static String findVal(String json, String key) {
        String pattern = "\"" + key + "\":";
        int start = json.indexOf(pattern) + pattern.length();
        int end = json.indexOf(",", start);
        if (end == -1) end = json.indexOf("}", start);
        return json.substring(start, end).trim().replace("\"", "");
    }
}