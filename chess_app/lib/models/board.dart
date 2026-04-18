import 'move.dart';

class Board {
  List<List<String>> board;

  String turn;

  (int, int) whiteKing;
  (int, int) blackKing;

  List<Move> moveHistory = [];
  Move? lastMove;

  bool whiteKingMoved;
  bool blackKingMoved;

  bool whiteRookAMoved;
  bool whiteRookHMoved;
  bool blackRookAMoved;
  bool blackRookHMoved;

  int halfMoveClock = 0;
  Map<String, int> positionCount = {};

  List<Map<String, bool>> castlingHistory = [];

  (int, int)? enPassantSquare;

  List<int> halfMoveHistory = [];
  List<(int, int)?> enPassantHistory = [];

  // =========================
  // 🔥 CONSTRUCTOR
  // =========================
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
        blackKing = (0, 4),
        whiteKingMoved = false,
        blackKingMoved = false,
        whiteRookAMoved = false,
        whiteRookHMoved = false,
        blackRookAMoved = false,
        blackRookHMoved = false {

    String key = getPositionKey();
    positionCount[key] = 1;
  }

  // =========================
  // 🔥 MAKE MOVE
  // =========================
  void makeMove(Move move) {

    String piece = move.pieceMoved;

    // SAVE STATE
    castlingHistory.add({
      "wK": whiteKingMoved,
      "bK": blackKingMoved,
      "wRA": whiteRookAMoved,
      "wRH": whiteRookHMoved,
      "bRA": blackRookAMoved,
      "bRH": blackRookHMoved,
    });

    halfMoveHistory.add(halfMoveClock);
    enPassantHistory.add(enPassantSquare);

    // REMOVE old repetition
    String oldKey = getPositionKey();
    if (positionCount.containsKey(oldKey)) {
      positionCount[oldKey] = positionCount[oldKey]! - 1;
      if (positionCount[oldKey]! <= 0) {
        positionCount.remove(oldKey);
      }
    }

    // MOVE PIECE
    board[move.startRow][move.startCol] = "";

    // EN PASSANT CAPTURE
    if (move.isEnPassant) {
      int dir = piece[0] == "w" ? 1 : -1;
      board[move.endRow + dir][move.endCol] = "";
    }

    // CASTLING
    if (move.isCastling) {
      if (move.endCol == 6) {
        board[move.endRow][5] = board[move.endRow][7];
        board[move.endRow][7] = "";
      } else {
        board[move.endRow][3] = board[move.endRow][0];
        board[move.endRow][0] = "";
      }
    }

    // PLACE PIECE
    if (move.promotion != null) {
      board[move.endRow][move.endCol] = "${piece[0]}${move.promotion}";
    } else {
      board[move.endRow][move.endCol] = piece;
    }

    // KING POSITION
    if (piece == "wK") whiteKing = (move.endRow, move.endCol);
    if (piece == "bK") blackKing = (move.endRow, move.endCol);

    // EN PASSANT TARGET
    enPassantSquare = null;
    if (piece[1] == "P" && (move.startRow - move.endRow).abs() == 2) {
      int midRow = (move.startRow + move.endRow) ~/ 2;
      enPassantSquare = (midRow, move.startCol);
    }

    // 50-MOVE RULE
    if (piece[1] == "P" || move.pieceCaptured != "") {
      halfMoveClock = 0;
    } else {
      halfMoveClock++;
    }

    _updateCastlingRights(move);

    moveHistory.add(move);
    lastMove = move;

    // SWITCH TURN
    turn = (turn == "white") ? "black" : "white";

    // ADD new repetition
    String newKey = getPositionKey();
    positionCount[newKey] = (positionCount[newKey] ?? 0) + 1;
  }

  // =========================
  // 🔥 UNDO MOVE (FIXED)
  // =========================
  void undoMove() {
    if (moveHistory.isEmpty) return;

    Move move = moveHistory.removeLast();
    String piece = move.pieceMoved;

    // REMOVE current position
    String currentKey = getPositionKey();
    if (positionCount.containsKey(currentKey)) {
      positionCount[currentKey] = positionCount[currentKey]! - 1;
      if (positionCount[currentKey]! <= 0) {
        positionCount.remove(currentKey);
      }
    }

    // SWITCH TURN BACK
    turn = (turn == "white") ? "black" : "white";

    // RESTORE BOARD
    board[move.startRow][move.startCol] = piece;

    if (move.isEnPassant) {
      board[move.endRow][move.endCol] = "";
      int dir = piece[0] == "w" ? 1 : -1;
      board[move.endRow + dir][move.endCol] = move.pieceCaptured;
    } else if (move.isCastling) {
      board[move.endRow][move.endCol] = "";

      if (move.endCol == 6) {
        board[move.endRow][7] = board[move.endRow][5];
        board[move.endRow][5] = "";
      } else {
        board[move.endRow][0] = board[move.endRow][3];
        board[move.endRow][3] = "";
      }
    } else {
      board[move.endRow][move.endCol] = move.pieceCaptured;
    }

    // KING POSITION
    if (piece == "wK") whiteKing = (move.startRow, move.startCol);
    if (piece == "bK") blackKing = (move.startRow, move.startCol);

    // RESTORE FLAGS
    var lastFlags = castlingHistory.removeLast();

    whiteKingMoved = lastFlags["wK"]!;
    blackKingMoved = lastFlags["bK"]!;
    whiteRookAMoved = lastFlags["wRA"]!;
    whiteRookHMoved = lastFlags["wRH"]!;
    blackRookAMoved = lastFlags["bRA"]!;
    blackRookHMoved = lastFlags["bRH"]!;

    // RESTORE STATE
    halfMoveClock = halfMoveHistory.removeLast();
    enPassantSquare = enPassantHistory.removeLast();

    lastMove = moveHistory.isNotEmpty ? moveHistory.last : null;

    // ADD BACK previous position
    String prevKey = getPositionKey();
    positionCount[prevKey] = (positionCount[prevKey] ?? 0) + 1;
  }

  // =========================
  // 🔥 CASTLING RIGHTS
  // =========================
  void _updateCastlingRights(Move move) {
    String piece = move.pieceMoved;

    if (piece == "wK") whiteKingMoved = true;
    if (piece == "bK") blackKingMoved = true;

    if (piece == "wR") {
      if (move.startCol == 0) whiteRookAMoved = true;
      if (move.startCol == 7) whiteRookHMoved = true;
    }

    if (piece == "bR") {
      if (move.startCol == 0) blackRookAMoved = true;
      if (move.startCol == 7) blackRookHMoved = true;
    }

    String captured = move.pieceCaptured;

    if (captured == "wR") {
      if (move.endCol == 0) whiteRookAMoved = true;
      if (move.endCol == 7) whiteRookHMoved = true;
    }

    if (captured == "bR") {
      if (move.endCol == 0) blackRookAMoved = true;
      if (move.endCol == 7) blackRookHMoved = true;
    }
  }

  // =========================
  // 🔥 POSITION KEY (FULLY CORRECT)
  // =========================
  String getPositionKey() {
    String key = "";

    // board
    for (var row in board) {
      for (var sq in row) {
        key += sq.isEmpty ? "." : sq;
      }
    }

    // turn
    key += "_$turn";

    // castling
    String castling = "";
    if (!whiteKingMoved && !whiteRookHMoved) castling += "K";
    if (!whiteKingMoved && !whiteRookAMoved) castling += "Q";
    if (!blackKingMoved && !blackRookHMoved) castling += "k";
    if (!blackKingMoved && !blackRookAMoved) castling += "q";
    key += "_${castling.isEmpty ? "-" : castling}";

    // en passant
    if (enPassantSquare != null) {
      key += "_${enPassantSquare!.$1}${enPassantSquare!.$2}";
    } else {
      key += "_-";
    }

    return key;
  }

  Map<String, dynamic> toJson() {
    return {
      "board": board,
      "turn": turn,

      "whiteKing": [whiteKing.$1, whiteKing.$2],
      "blackKing": [blackKing.$1, blackKing.$2],

      // ✅ reconstruct castling rights (Python-compatible)
      "castlingRights": {
        "wK": !whiteKingMoved && !whiteRookHMoved,
        "wQ": !whiteKingMoved && !whiteRookAMoved,
        "bK": !blackKingMoved && !blackRookHMoved,
        "bQ": !blackKingMoved && !blackRookAMoved,
      },

      // ✅ correct field name
      "enPassantTarget": enPassantSquare == null
          ? null
          : [enPassantSquare!.$1, enPassantSquare!.$2],

      // optional but VERY useful for AI
      "halfMoveClock": halfMoveClock,
    };
  }
}