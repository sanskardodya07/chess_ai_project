import './slide.dart';
import '../../models/board.dart';
import '../../models/move.dart';

void bishopMoves(Board b, int r, int c, List<Move> m) =>
  slide(b, r, c, m, [[1,1],[1,-1],[-1,1],[-1,-1]]);
