import '../models/board.dart';
import '../models/move.dart';
import 'rule_checker.dart';
import '../core/chess_engine.dart';

List<Move> generateLegalMoves(Board board) {
  List<Move> allMoves = ChessEngine.generateAllMoves(board);

  List<Move> legal = [];

  for (Move move in allMoves) {
    board.makeMove(move);

    if (!isInCheck(board, board.turn == "white" ? "black" : "white")) {
      legal.add(move);
    }

    board.undoMove();
  }

  return legal;
}