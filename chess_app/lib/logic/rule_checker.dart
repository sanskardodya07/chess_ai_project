import '../models/board.dart';
import '../models/move.dart';
import '../core/chess_engine.dart';

bool isInCheck(Board board, String color) {
  var king = (color == "white") ? board.whiteKing : board.blackKing;
  String enemy = color == "white" ? "b" : "w";

  for (var move in ChessEngine.generateAllMoves(board)) {
    if (move.pieceMoved[0] == enemy &&
        move.endRow == king.$1 &&
        move.endCol == king.$2) {
      return true;
    }
  }

  return false;
}

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