import './slide.dart';
import '../../models/board.dart';
import '../../models/move.dart';

void rookMoves(Board b, int r, int c, List<Move> m) =>
  slide(b, r, c, m, [[1,0],[-1,0],[0,1],[0,-1]]);