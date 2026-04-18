import '../models/board.dart';

bool isSquareAttacked(Board board, int r, int c, String attacker) {
  // 1. Pawn attacks
  int dir = attacker == "w" ? -1 : 1;

  for (int dc in [-1, 1]) {
    int nr = r - dir;
    int nc = c + dc;

    if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
      String p = board.board[nr][nc];
      if (p == "${attacker}P") return true;
    }
  }

  // 2. Knight attacks
  List<List<int>> knightDirs = [
    [-2,-1],[-2,1],[-1,-2],[-1,2],
    [1,-2],[1,2],[2,-1],[2,1]
  ];

  for (var d in knightDirs) {
    int nr = r + d[0];
    int nc = c + d[1];

    if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
      if (board.board[nr][nc] == "${attacker}N") return true;
    }
  }

  // 3. Sliding pieces (rook/bishop/queen)
  List<List<int>> directions = [
    [1,0],[-1,0],[0,1],[0,-1],
    [1,1],[1,-1],[-1,1],[-1,-1]
  ];

  for (var d in directions) {
    int nr = r + d[0];
    int nc = c + d[1];

    while (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
      String p = board.board[nr][nc];

      if (p != "") {
        if (p[0] == attacker) {
          String type = p[1];

          if ((d[0] == 0 || d[1] == 0) && (type == "R" || type == "Q")) return true;
          if ((d[0] != 0 && d[1] != 0) && (type == "B" || type == "Q")) return true;
        }
        break;
      }

      nr += d[0];
      nc += d[1];
    }
  }

  // 4. King attacks
  for (int dr = -1; dr <= 1; dr++) {
    for (int dc = -1; dc <= 1; dc++) {
      if (dr == 0 && dc == 0) continue;

      int nr = r + dr;
      int nc = c + dc;

      if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
        if (board.board[nr][nc] == "${attacker}K") return true;
      }
    }
  }

  return false;
}