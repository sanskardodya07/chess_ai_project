import '../../models/board.dart';
import '../../models/move.dart';
import 'rule_checker.dart';

List<Move> filterLegalMoves(Board board, List<Move> moves) {
  List<Move> legal = [];

  for (var move in moves) {
    board.makeMove(move);

    if (!isInCheck(board, board.turn == "white" ? "black" : "white")) {
      legal.add(move);
    }

    board.undoMove();
  }

  return legal;
}