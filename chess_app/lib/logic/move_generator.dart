import '../models/board.dart';
import '../models/move.dart';

List<Move> generateAllMoves(Board board) {
  List<Move> moves = [];

  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      String piece = board.board[r][c];

      if (piece == "") continue;

      if (board.turn == "white" && piece[0] != "w") continue;
      if (board.turn == "black" && piece[0] != "b") continue;

      String p = piece[1];

      if (p == "P") pawnMoves(board, r, c, moves);
      if (p == "N") knightMoves(board, r, c, moves);
      if (p == "B") bishopMoves(board, r, c, moves);
      if (p == "R") rookMoves(board, r, c, moves);
      if (p == "Q") {
        bishopMoves(board, r, c, moves);
        rookMoves(board, r, c, moves);
      }
      if (p == "K") kingMoves(board, r, c, moves);
    }
  }

  return moves;
}

void pawnMoves(Board board, int r, int c, List<Move> moves) {
  String piece = board.board[r][c];
  int dir = piece[0] == "w" ? -1 : 1;

  int startRow = piece[0] == "w" ? 6 : 1;

  int forward = r + dir;

  if (forward >= 0 && forward < 8 && board.board[forward][c] == "") {
    moves.add(Move(
      startRow: r,
      startCol: c,
      endRow: forward,
      endCol: c,
      pieceMoved: piece,
      pieceCaptured: "",
    ));

    if (r == startRow && board.board[r + 2 * dir][c] == "") {
      moves.add(Move(
        startRow: r,
        startCol: c,
        endRow: r + 2 * dir,
        endCol: c,
        pieceMoved: piece,
        pieceCaptured: "",
      ));
    }
  }

  for (int dc in [-1, 1]) {
    int col = c + dc;
    int row = r + dir;

    if (row >= 0 && row < 8 && col >= 0 && col < 8) {
      String target = board.board[row][col];

      if (target != "" && target[0] != piece[0]) {
        moves.add(Move(
          startRow: r,
          startCol: c,
          endRow: row,
          endCol: col,
          pieceMoved: piece,
          pieceCaptured: target,
        ));
      }
    }
  }
}

void slide(Board board, int r, int c, List<Move> moves, List<List<int>> dirs) {

  String piece = board.board[r][c];

  for (var d in dirs) {
    int nr = r + d[0];
    int nc = c + d[1];

    while (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {

      String target = board.board[nr][nc];

      if (target == "") {
        moves.add(Move(
          startRow: r, startCol: c,
          endRow: nr, endCol: nc,
          pieceMoved: piece,
          pieceCaptured: "",
        ));
      } else {
        if (target[0] != piece[0]) {
          moves.add(Move(
            startRow: r, startCol: c,
            endRow: nr, endCol: nc,
            pieceMoved: piece,
            pieceCaptured: target,
          ));
        }
        break;
      }

      nr += d[0];
      nc += d[1];
    }
  }
}

void rookMoves(Board b, int r, int c, List<Move> m) =>
  slide(b, r, c, m, [[1,0],[-1,0],[0,1],[0,-1]]);

void bishopMoves(Board b, int r, int c, List<Move> m) =>
  slide(b, r, c, m, [[1,1],[1,-1],[-1,1],[-1,-1]]);

void knightMoves(Board board, int r, int c, List<Move> moves) {
  List<List<int>> dirs = [
    [-2,-1],[-2,1],[-1,-2],[-1,2],
    [1,-2],[1,2],[2,-1],[2,1]
  ];

  String piece = board.board[r][c];

  for (var d in dirs) {
    int nr = r + d[0];
    int nc = c + d[1];

    if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
      String target = board.board[nr][nc];
      if (target == "" || target[0] != piece[0]) {
        moves.add(Move(
          startRow: r, startCol: c,
          endRow: nr, endCol: nc,
          pieceMoved: piece,
          pieceCaptured: target,
        ));
      }
    }
  }
}

void kingMoves(Board board, int r, int c, List<Move> moves) {
  List<List<int>> dirs = [
    [-1,-1],[-1,0],[-1,1],
    [0,-1],[0,1],
    [1,-1],[1,0],[1,1]
  ];

  String piece = board.board[r][c];

  for (var d in dirs) {
    int nr = r + d[0];
    int nc = c + d[1];

    if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
      String target = board.board[nr][nc];
      if (target == "" || target[0] != piece[0]) {
        moves.add(Move(
          startRow: r, startCol: c,
          endRow: nr, endCol: nc,
          pieceMoved: piece,
          pieceCaptured: target,
        ));
      }
    }
  }
}
