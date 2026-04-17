import '../models/board.dart';
import '../models/move.dart';

class ChessEngine {
  static List<Move> generateAllMoves(Board board) {
    List<Move> moves = [];

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String piece = board.board[r][c];
        if (piece == "") continue;
        if (!_isTurnPiece(piece, board.turn)) continue;

        moves.addAll(_pseudoMoves(board, r, c, piece));
      }
    }

    return moves;
  }

  static List<Move> filterLegalMoves(Board board, List<Move> moves) {
    List<Move> legal = [];

    for (Move move in moves) {
      board.makeMove(move);
      String color = board.turn == "white" ? "black" : "white";
      
      if (!isInCheck(board, color)) {
        legal.add(move);
      }

      board.undoMove();
    }

    return legal;
  }

  static bool isInCheck(Board board, String color) {
    var king = (color == "white") ? board.whiteKing : board.blackKing;
    String enemy = color == "white" ? "b" : "w";

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String piece = board.board[r][c];
        if (piece == "" || !piece.startsWith(enemy)) continue;

        List<Move> pseudoMoves = _pseudoMoves(board, r, c, piece);
        for (Move move in pseudoMoves) {
          if (move.endRow == king.$1 && move.endCol == king.$2) {
            return true;
          }
        }
      }
    }

    return false;
  }

  static bool isCheckmate(Board board, String color) {
    if (!isInCheck(board, color)) {
      return false;
    }
    
    List<Move> allMoves = generateAllMoves(board);
    allMoves = filterLegalMoves(board, allMoves);
    
    return allMoves.isEmpty;
  }

  static bool isStalemate(Board board, String color) {
    if (isInCheck(board, color)) {
      return false;
    }
    
    List<Move> allMoves = generateAllMoves(board);
    allMoves = filterLegalMoves(board, allMoves);
    
    return allMoves.isEmpty;
  }

  // ================== DRAW CONDITIONS ==================

  static bool isFiftyMoveRule(Board board) {
    return board.halfMoveCount >= 100; // 50 moves = 100 half-moves
  }

  static bool isThreefoldRepetition(Board board) {
    String posKey = board.getBoardHash();
    return (board.positionHistory[posKey] ?? 0) >= 3;
  }

  static bool isInsufficientMaterial(Board board) {
    // Count pieces
    int wQ = 0, wR = 0, wB = 0, wN = 0, wP = 0;
    int bQ = 0, bR = 0, bB = 0, bN = 0, bP = 0;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String p = board.board[r][c];
        if (p == "") {
          continue;
        }
        if (p == "wQ") {
          wQ++;
        } else if (p == "wR") {
          wR++;
        } else if (p == "wB") {
          wB++;
        } else if (p == "wN") {
          wN++;
        } else if (p == "wP") {
          wP++;
        } else if (p == "bQ") {
          bQ++;
        } else if (p == "bR") {
          bR++;
        } else if (p == "bB") {
          bB++;
        } else if (p == "bN") {
          bN++;
        } else if (p == "bP") {
          bP++;
        }
      }
    }

    // K vs K
    if (wQ == 0 && wR == 0 && wB == 0 && wN == 0 && wP == 0 &&
        bQ == 0 && bR == 0 && bB == 0 && bN == 0 && bP == 0) {
      return true;
    }

    // K+N vs K, K+B vs K
    if (wP == 0 && bP == 0 && wQ == 0 && wR == 0 && bQ == 0 && bR == 0) {
      int wMinor = wB + wN;
      int bMinor = bB + bN;
      if ((wMinor == 0 && bMinor <= 1) || (wMinor <= 1 && bMinor == 0)) {
        return true;
      }
      // K+N vs K+N or K+B vs K+B (both same color pieces)
      if ((wN == 1 && bN == 1 && wB == 0 && bB == 0) ||
          (wB == 1 && bB == 1 && wN == 0 && bN == 0)) {
        return true;
      }
    }

    return false;
  }

  static bool isDraw(Board board, String color) {
    return isFiftyMoveRule(board) || isThreefoldRepetition(board) || 
           isInsufficientMaterial(board) || isStalemate(board, color);
  }

  // ================== HELPERS ==================

  static bool _isTurnPiece(String piece, String turn) {
    if (turn == "white") {
      return piece.startsWith("w");
    }
    if (turn == "black") {
      return piece.startsWith("b");
    }
    return false;
  }

  static List<Move> _pseudoMoves(Board board, int r, int c, String piece) {
    List<Move> moves = [];
    String type = piece.substring(1);

    if (type == "P") moves.addAll(_pawnMoves(board, r, c, piece));
    if (type == "N") moves.addAll(_knightMoves(board, r, c, piece));
    if (type == "B") moves.addAll(_bishopMoves(board, r, c, piece));
    if (type == "R") moves.addAll(_rookMoves(board, r, c, piece));
    if (type == "Q") moves.addAll(_queenMoves(board, r, c, piece));
    if (type == "K") moves.addAll(_kingMoves(board, r, c, piece));

    return moves;
  }

  // ================== PAWN MOVES ==================
  static List<Move> _pawnMoves(Board board, int r, int c, String piece) {
    List<Move> moves = [];
    int dir = piece.startsWith("w") ? -1 : 1;
    int startRow = piece.startsWith("w") ? 6 : 1;
    int promoteRow = piece.startsWith("w") ? 0 : 7;

    // Forward 1
    int nr = r + dir;
    if (_inBounds(nr, c) && board.board[nr][c] == "") {
      if (nr == promoteRow) {
        for (String p in ["Q", "R", "B", "N"]) {
          moves.add(Move(
            startRow: r, startCol: c, endRow: nr, endCol: c,
            pieceMoved: piece, pieceCaptured: "", promotion: p,
          ));
        }
      } else {
        moves.add(Move(
          startRow: r, startCol: c, endRow: nr, endCol: c,
          pieceMoved: piece, pieceCaptured: "",
        ));
      }

      // Forward 2 (first move)
      if (r == startRow) {
        int nr2 = r + 2 * dir;
        if (board.board[nr2][c] == "") {
          moves.add(Move(
            startRow: r, startCol: c, endRow: nr2, endCol: c,
            pieceMoved: piece, pieceCaptured: "",
          ));
        }
      }
    }

    // Capture diagonal
    for (int dc in [-1, 1]) {
      int nc = c + dc;
      int nr = r + dir;
      if (_inBounds(nr, nc)) {
        String target = board.board[nr][nc];
        
        if (target != "" && !_sameColor(piece, target)) {
          if (nr == promoteRow) {
            for (String p in ["Q", "R", "B", "N"]) {
              moves.add(Move(
                startRow: r, startCol: c, endRow: nr, endCol: nc,
                pieceMoved: piece, pieceCaptured: target, promotion: p,
              ));
            }
          } else {
            moves.add(Move(
              startRow: r, startCol: c, endRow: nr, endCol: nc,
              pieceMoved: piece, pieceCaptured: target,
            ));
          }
        }

        // En passant
        if (board.moveHistory.isNotEmpty) {
          Move lastMove = board.moveHistory.last;
          if (lastMove.pieceMoved.substring(1) == "P" &&
              (lastMove.endRow - lastMove.startRow).abs() == 2 &&
              lastMove.endRow == r && lastMove.endCol == nc) {
            moves.add(Move(
              startRow: r, startCol: c, endRow: nr, endCol: nc,
              pieceMoved: piece, pieceCaptured: lastMove.pieceMoved,
              isEnPassant: true,
            ));
          }
        }
      }
    }

    return moves;
  }

  // ================== KNIGHT MOVES ==================
  static List<Move> _knightMoves(Board board, int r, int c, String piece) {
    List<Move> moves = [];
    List<List<int>> dirs = [
      [-2, -1], [-2, 1], [2, -1], [2, 1],
      [-1, -2], [-1, 2], [1, -2], [1, 2],
    ];

    for (var d in dirs) {
      int nr = r + d[0];
      int nc = c + d[1];
      if (_inBounds(nr, nc)) {
        String target = board.board[nr][nc];
        if (target == "" || !_sameColor(piece, target)) {
          moves.add(Move(
            startRow: r, startCol: c, endRow: nr, endCol: nc,
            pieceMoved: piece, pieceCaptured: target,
          ));
        }
      }
    }

    return moves;
  }

  // ================== BISHOP MOVES ==================
  static List<Move> _bishopMoves(Board board, int r, int c, String piece) {
    List<Move> moves = [];
    List<List<int>> dirs = [[-1, -1], [-1, 1], [1, -1], [1, 1]];

    for (var d in dirs) {
      for (int i = 1; i < 8; i++) {
        int nr = r + d[0] * i;
        int nc = c + d[1] * i;
        if (!_inBounds(nr, nc)) break;

        String target = board.board[nr][nc];
        if (target == "") {
          moves.add(Move(
            startRow: r, startCol: c, endRow: nr, endCol: nc,
            pieceMoved: piece, pieceCaptured: "",
          ));
        } else {
          if (!_sameColor(piece, target)) {
            moves.add(Move(
              startRow: r, startCol: c, endRow: nr, endCol: nc,
              pieceMoved: piece, pieceCaptured: target,
            ));
          }
          break;
        }
      }
    }

    return moves;
  }

  // ================== ROOK MOVES ==================
  static List<Move> _rookMoves(Board board, int r, int c, String piece) {
    List<Move> moves = [];
    List<List<int>> dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];

    for (var d in dirs) {
      for (int i = 1; i < 8; i++) {
        int nr = r + d[0] * i;
        int nc = c + d[1] * i;
        if (!_inBounds(nr, nc)) break;

        String target = board.board[nr][nc];
        if (target == "") {
          moves.add(Move(
            startRow: r, startCol: c, endRow: nr, endCol: nc,
            pieceMoved: piece, pieceCaptured: "",
          ));
        } else {
          if (!_sameColor(piece, target)) {
            moves.add(Move(
              startRow: r, startCol: c, endRow: nr, endCol: nc,
              pieceMoved: piece, pieceCaptured: target,
            ));
          }
          break;
        }
      }
    }

    return moves;
  }

  // ================== QUEEN MOVES ==================
  static List<Move> _queenMoves(Board board, int r, int c, String piece) {
    List<Move> moves = [];
    moves.addAll(_bishopMoves(board, r, c, piece));
    moves.addAll(_rookMoves(board, r, c, piece));
    return moves;
  }

  // ================== KING MOVES ==================
  static List<Move> _kingMoves(Board board, int r, int c, String piece) {
    List<Move> moves = [];
    List<List<int>> dirs = [
      [-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1],
    ];

    // Normal king moves
    for (var d in dirs) {
      int nr = r + d[0];
      int nc = c + d[1];
      if (_inBounds(nr, nc)) {
        String target = board.board[nr][nc];
        if (target == "" || !_sameColor(piece, target)) {
          moves.add(Move(
            startRow: r, startCol: c, endRow: nr, endCol: nc,
            pieceMoved: piece, pieceCaptured: target,
          ));
        }
      }
    }

    // Castling
    if (board.moveHistory.isEmpty || !_hasPieceMoved(board, piece, r, c)) {
      // Kingside castling
      if (_inBounds(r, 7) && board.board[r][7] == (piece.startsWith("w") ? "wR" : "bR")) {
        if (!_hasPieceMoved(board, board.board[r][7], r, 7) &&
            board.board[r][5] == "" && board.board[r][6] == "") {
          moves.add(Move(
            startRow: r, startCol: c, endRow: r, endCol: 6,
            pieceMoved: piece, pieceCaptured: "", isCastle: true,
          ));
        }
      }

      // Queenside castling
      if (_inBounds(r, 0) && board.board[r][0] == (piece.startsWith("w") ? "wR" : "bR")) {
        if (!_hasPieceMoved(board, board.board[r][0], r, 0) &&
            board.board[r][1] == "" && board.board[r][2] == "" && board.board[r][3] == "") {
          moves.add(Move(
            startRow: r, startCol: c, endRow: r, endCol: 2,
            pieceMoved: piece, pieceCaptured: "", isCastle: true,
          ));
        }
      }
    }

    return moves;
  }

  // ================== UTILITY ==================

  static bool _inBounds(int r, int c) {
    return r >= 0 && r < 8 && c >= 0 && c < 8;
  }

  static bool _sameColor(String a, String b) {
    return a.isNotEmpty && b.isNotEmpty && a[0] == b[0];
  }

  static bool _hasPieceMoved(Board board, String piece, int r, int c) {
    for (Move move in board.moveHistory) {
      if (move.pieceMoved == piece && move.startRow == r && move.startCol == c) {
        return true;
      }
    }
    return false;
  }
}