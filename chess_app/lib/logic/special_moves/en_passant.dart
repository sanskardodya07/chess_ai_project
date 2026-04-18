import '../../models/board.dart';
import '../../models/move.dart';

void addEnPassantMoves(Board board, int r, int c, List<Move> moves) {
  String piece = board.board[r][c];
  if (piece[1] != "P") return;

  if (board.lastMove == null) return;

  Move last = board.lastMove!;

  // must be enemy pawn double move
  if (last.pieceMoved[1] != "P") return;
  if ((last.startRow - last.endRow).abs() != 2) return;

  // must be adjacent pawn
  if (last.endRow != r) return;
  if ((last.endCol - c).abs() != 1) return;

  int dir = piece[0] == "w" ? -1 : 1;

  moves.add(Move(
    startRow: r,
    startCol: c,
    endRow: r + dir,
    endCol: last.endCol,
    pieceMoved: piece,
    pieceCaptured: last.pieceMoved,
    isEnPassant: true
  ));
}