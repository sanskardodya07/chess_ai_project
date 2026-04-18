import '../../models/move.dart';

void addPromotionMoves(List<Move> moves) {
  List<Move> expanded = [];

  for (var m in moves) {
    String piece = m.pieceMoved;

    if (piece[1] == "P" &&
        (m.endRow == 0 || m.endRow == 7)) {

      for (String promo in ["Q", "R", "B", "N"]) {
        expanded.add(Move(
          startRow: m.startRow,
          startCol: m.startCol,
          endRow: m.endRow,
          endCol: m.endCol,
          pieceMoved: piece,
          pieceCaptured: m.pieceCaptured,
          promotion: promo,
        ));
      }
    } else {
      expanded.add(m);
    }
  }

  moves
    ..clear()
    ..addAll(expanded);
}