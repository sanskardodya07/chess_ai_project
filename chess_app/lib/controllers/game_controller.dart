import '../models/board.dart';
import '../models/move.dart';
import '../core/chess_engine.dart';

class GameController {

  Board board = Board();

  List<Move> getLegalMoves(int row, int col) {

    List<Move> allMoves = ChessEngine.generateAllMoves(board);

    return allMoves.where((m) =>
      m.startRow == row && m.startCol == col
    ).toList();
  }

  void makeMove(Move move) {
    board.makeMove(move);
  }
}