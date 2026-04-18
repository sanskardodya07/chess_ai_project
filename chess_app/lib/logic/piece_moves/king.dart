import '../../models/board.dart';
import '../../models/move.dart';

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
