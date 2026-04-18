import '../models/board.dart';
import '../models/move.dart';
import '../logic/move_generator.dart';
import '../logic/rule_checker.dart';

class GameController {

  Board board = Board();

  List<Move> getLegalMoves(int row, int col) {

    List<Move> allMoves = filterLegalMoves(
        board,
        generateLegalMoves(board)
      );

    return allMoves.where((m) =>
      m.startRow == row && m.startCol == col
    ).toList();
  }

  void makeMove(Move move) {
    board.makeMove(move);
  }
}