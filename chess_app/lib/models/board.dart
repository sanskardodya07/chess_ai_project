import 'move.dart';

class Board {
  List<List<String>> board;

  String turn;

  (int, int) whiteKing;
  (int, int) blackKing;

  List<Move> moveHistory = [];
  int halfMoveCount = 0; // For 50-move rule
  Map<String, int> positionHistory = {}; // For threefold repetition

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
    // Record position for threefold repetition
    String posKey = getBoardHash();
    positionHistory[posKey] = (positionHistory[posKey] ?? 0) + 1;

    board[move.startRow][move.startCol] = "";
    board[move.endRow][move.endCol] = move.pieceMoved;

    // Reset halfMoveCount if pawn move or capture
    if (move.pieceMoved.substring(1) == "P" || move.pieceCaptured != "") {
      halfMoveCount = 0;
    } else {
      halfMoveCount++;
    }

    // Handle pawn promotion
    if (move.promotion != null) {
      String color = move.pieceMoved.substring(0, 1);
      board[move.endRow][move.endCol] = color + move.promotion!;
    }

    // Handle castling
    if (move.isCastle) {
      if (move.endCol > move.startCol) {
        // Kingside castling
        String rook = board[move.endRow][7];
        board[move.endRow][5] = rook;
        board[move.endRow][7] = "";
      } else {
        // Queenside castling
        String rook = board[move.endRow][0];
        board[move.endRow][3] = rook;
        board[move.endRow][0] = "";
      }
    }

    // Handle en passant
    if (move.isEnPassant) {
      board[move.startRow][move.endCol] = "";
    }

    if (move.pieceMoved == "wK") whiteKing = (move.endRow, move.endCol);
    if (move.pieceMoved == "bK") blackKing = (move.endRow, move.endCol);

    moveHistory.add(move);

    turn = (turn == "white") ? "black" : "white";
  }

  void undoMove() {
    if (moveHistory.isEmpty) return;

    Move move = moveHistory.removeLast();

    // Undo position history
    String posKey = getBoardHash();
    positionHistory[posKey] = (positionHistory[posKey] ?? 1) - 1;
    if (positionHistory[posKey] == 0) {
      positionHistory.remove(posKey);
    }

    // Handle en passant undo FIRST (before standard restoration)
    if (move.isEnPassant) {
      board[move.startRow][move.startCol] = move.pieceMoved;
      board[move.startRow][move.endCol] = move.pieceCaptured;
      board[move.endRow][move.endCol] = "";
    } else {
      board[move.startRow][move.startCol] = move.pieceMoved;
      board[move.endRow][move.endCol] = move.pieceCaptured;
    }

    // Reset halfMoveCount to what it was before
    if (move.pieceMoved.substring(1) == "P" || move.pieceCaptured != "") {
      halfMoveCount = 0;
    } else {
      halfMoveCount--;
      if (halfMoveCount < 0) halfMoveCount = 0;
    }

    // Handle pawn promotion undo
    if (move.promotion != null) {
      board[move.startRow][move.startCol] = move.pieceMoved;
    }

    // Handle castling undo
    if (move.isCastle) {
      if (move.endCol > move.startCol) {
        // Kingside castling undo
        board[move.endRow][7] = board[move.endRow][5];
        board[move.endRow][5] = "";
      } else {
        // Queenside castling undo
        board[move.endRow][0] = board[move.endRow][3];
        board[move.endRow][3] = "";
      }
    }

    if (move.pieceMoved == "wK") whiteKing = (move.startRow, move.startCol);
    if (move.pieceMoved == "bK") blackKing = (move.startRow, move.startCol);

    turn = (turn == "white") ? "black" : "white";
  }

  String getBoardHash() {
    StringBuffer sb = StringBuffer();
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        sb.write(board[r][c]);
      }
    }
    sb.write(turn);
    return sb.toString();
  }
}