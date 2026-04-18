import '../models/board.dart';
import '../models/move.dart';
//import 'move_generator.dart';
import 'attack_map.dart';

bool isInCheck(Board board, String color) {
  var king = (color == "white") ? board.whiteKing : board.blackKing;
  String enemy = color == "white" ? "b" : "w";

  return isSquareAttacked(board, king.$1, king.$2, enemy);
}

List<Move> filterLegalMoves(Board board, List<Move> moves) {
  List<Move> legalMoves = [];

  for (var move in moves) {

    // 🔥 SPECIAL CASE: en passant
    if (move.isEnPassant) {
      if (isEnPassantSafe(board, move)) {
        legalMoves.add(move);
      }
      continue;
    }

    board.makeMove(move);

    String color = move.pieceMoved[0];
    if (!isInCheck(board, color)) {
      legalMoves.add(move);
    }

    board.undoMove();
  }

  return legalMoves;
}

bool isEnPassantSafe(Board board, Move move) {
  board.makeMove(move);

  String color = move.pieceMoved[0];
  bool inCheck = isInCheck(board, color);

  board.undoMove();

  return !inCheck;
}