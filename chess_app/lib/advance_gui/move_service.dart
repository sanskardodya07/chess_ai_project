import '../models/board.dart';
import '../models/move.dart';
import '../core/chess_engine.dart';

/// Service for handling chess moves and game state
/// Designed to be easily replaceable with server calls in the future
class MoveService {
  final Board board;

  MoveService(this.board);

  /// Get all legal moves for the current player
  List<Move> getLegalMoves() {
    List<Move> allMoves = ChessEngine.generateAllMoves(board);
    return ChessEngine.filterLegalMoves(board, allMoves);
  }

  /// Get legal moves for a specific piece
  List<Move> getLegalMovesForPiece(int row, int col) {
    List<Move> allMoves = getLegalMoves();
    return allMoves.where((move) =>
      move.startRow == row && move.startCol == col
    ).toList();
  }

  /// Make a move and return success status
  bool makeMove(Move move) {
    List<Move> legalMoves = getLegalMoves();
    bool isLegal = legalMoves.any((legalMove) =>
      legalMove.startRow == move.startRow &&
      legalMove.startCol == move.startCol &&
      legalMove.endRow == move.endRow &&
      legalMove.endCol == move.endCol
    );

    if (isLegal) {
      board.makeMove(move);
      return true;
    }
    return false;
  }

  /// Check if current player is in check
  bool isCurrentPlayerInCheck() {
    return ChessEngine.isInCheck(board, board.turn);
  }

  /// Check if game is over and return result
  GameResult? getGameResult() {
    String currentColor = board.turn;
    String opponentColor = currentColor == "white" ? "black" : "white";

    if (ChessEngine.isCheckmate(board, currentColor)) {
      return GameResult.checkmate(opponentColor);
    }

    if (ChessEngine.isDraw(board, currentColor)) {
      if (ChessEngine.isStalemate(board, currentColor)) {
        return GameResult.stalemate();
      }
      if (ChessEngine.isFiftyMoveRule(board)) {
        return GameResult.fiftyMoveDraw();
      }
      if (ChessEngine.isThreefoldRepetition(board)) {
        return GameResult.threefoldRepetition();
      }
      if (ChessEngine.isInsufficientMaterial(board)) {
        return GameResult.insufficientMaterial();
      }
    }

    return null; // Game continues
  }

  /// Get last move made
  Move? getLastMove() {
    return board.moveHistory.isNotEmpty ? board.moveHistory.last : null;
  }

  /// Get move history
  List<Move> getMoveHistory() {
    return List.unmodifiable(board.moveHistory);
  }

  /// Undo last move
  bool undoMove() {
    if (board.moveHistory.isNotEmpty) {
      board.undoMove();
      return true;
    }
    return false;
  }

  /// Reset game to initial state
  void resetGame() {
    board.board = [
      ["bR","bN","bB","bQ","bK","bB","bN","bR"],
      ["bP","bP","bP","bP","bP","bP","bP","bP"],
      ["","","","","","","",""],
      ["","","","","","","",""],
      ["","","","","","","",""],
      ["","","","","","","",""],
      ["wP","wP","wP","wP","wP","wP","wP","wP"],
      ["wR","wN","wB","wQ","wK","wB","wN","wR"]
    ];
    board.turn = "white";
    board.whiteKing = (7, 4);
    board.blackKing = (0, 4);
    board.moveHistory.clear();
    board.halfMoveCount = 0;
    board.positionHistory.clear();
  }
}

/// Represents the result of a chess game
class GameResult {
  final String type;
  final String? winner;

  GameResult._(this.type, this.winner);

  factory GameResult.checkmate(String winner) =>
    GameResult._('checkmate', winner);

  factory GameResult.stalemate() =>
    GameResult._('stalemate', null);

  factory GameResult.fiftyMoveDraw() =>
    GameResult._('fifty_move', null);

  factory GameResult.threefoldRepetition() =>
    GameResult._('threefold', null);

  factory GameResult.insufficientMaterial() =>
    GameResult._('insufficient_material', null);

  bool get isGameOver => type != 'ongoing';
  bool get isDraw => winner == null && type != 'checkmate';
  bool get isCheckmate => type == 'checkmate';

  String getMessage() {
    switch (type) {
      case 'checkmate':
        return '$winner wins by checkmate!';
      case 'stalemate':
        return 'Draw by stalemate!';
      case 'fifty_move':
        return 'Draw by 50-move rule!';
      case 'threefold':
        return 'Draw by threefold repetition!';
      case 'insufficient_material':
        return 'Draw by insufficient material!';
      default:
        return '';
    }
  }
}