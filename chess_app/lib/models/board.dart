import 'move.dart';

class Board {
  List<List<String>> board;

  String turn;

  (int, int) whiteKing;
  (int, int) blackKing;

  List<Move> moveHistory = [];

  Board()
      : board = [
          ["bR","bN","bB","bQ","bK","bB","bN","bR"],
          ["bP","bP","bP","bP","bP","bP","bP","bP"],
          ["","","","","","","",""],
          ["","","","","","","",""],
          ["","","","","","","",""],
          ["","","","","","","",""],
          ["wP","wP","wP","wP","wP","wP","wP","wP"],
          ["wR","wN","wB","wQ","wK","wB","wN","wR"]
        ],
        turn = "white",
        whiteKing = (7, 4),
        blackKing = (0, 4);

  void makeMove(Move move) {
    board[move.startRow][move.startCol] = "";
    board[move.endRow][move.endCol] = move.pieceMoved;

    if (move.pieceMoved == "wK") whiteKing = (move.endRow, move.endCol);
    if (move.pieceMoved == "bK") blackKing = (move.endRow, move.endCol);

    moveHistory.add(move);

    turn = (turn == "white") ? "black" : "white";
  }

  void undoMove() {
    if (moveHistory.isEmpty) return;

    Move move = moveHistory.removeLast();

    board[move.startRow][move.startCol] = move.pieceMoved;
    board[move.endRow][move.endCol] = move.pieceCaptured;

    if (move.pieceMoved == "wK") whiteKing = (move.startRow, move.startCol);
    if (move.pieceMoved == "bK") blackKing = (move.startRow, move.startCol);

    turn = (turn == "white") ? "black" : "white";
  }
}