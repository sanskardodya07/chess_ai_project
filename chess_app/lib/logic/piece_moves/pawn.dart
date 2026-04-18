import '../../models/board.dart';
import '../../models/move.dart';

void pawnMoves(Board board, int r, int c, List<Move> moves) {
  String piece = board.board[r][c];
  int dir = piece[0] == "w" ? -1 : 1;

  int forward = r + dir;

  // forward move
  if (_inBounds(forward, c) && board.board[forward][c] == "") {
    moves.add(Move(
      startRow: r,
      startCol: c,
      endRow: forward,
      endCol: c,
      pieceMoved: piece,
      pieceCaptured: "",
    ));

    // double move
    int startRow = piece[0] == "w" ? 6 : 1;
    if (r == startRow &&
        board.board[r + 2 * dir][c] == "") {
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

  // captures
  for (int dc in [-1, 1]) {
    int nr = r + dir;
    int nc = c + dc;

    if (_inBounds(nr, nc)) {
      String target = board.board[nr][nc];
      if (target != "" && target[0] != piece[0]) {
        moves.add(Move(
          startRow: r,
          startCol: c,
          endRow: nr,
          endCol: nc,
          pieceMoved: piece,
          pieceCaptured: target,
        ));
      }
    }
  }
}

bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;