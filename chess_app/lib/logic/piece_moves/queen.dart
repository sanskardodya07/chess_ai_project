import '../../models/board.dart';
import '../../models/move.dart';
import 'slide.dart';

void queenMoves(Board board, int r, int c, List<Move> moves) {
  slide(board, r, c, moves, [
    [1,0], [-1,0], [0,1], [0,-1],
    [1,1], [1,-1], [-1,1], [-1,-1]
  ]);
}