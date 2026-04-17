import '../models/board.dart';
import '../models/move.dart';
import '../logic/move_generator.dart';
import '../logic/rules.dart';
import 'chess_engine.dart';

import 'game_state.dart';

class GameController {
  Board board = Board();

  GameStatus status = GameStatus.playing;

  Move? selectedMovePiece;

  /// Get legal moves for UI highlight
  List<Move> getLegalMoves() {
    return generateLegalMoves(board);
  }

  /// Called when user taps a square
  void handleTap(int row, int col) {
    String piece = board.board[row][col];

    // 1. If nothing selected → select piece
    if (selectedMovePiece == null) {
      if (piece == "") return;
      if (!_isCorrectTurn(piece)) return;

      selectedMovePiece = Move(
        startRow: row,
        startCol: col,
        endRow: row,
        endCol: col,
        pieceMoved: piece,
        pieceCaptured: "",
      );
      return;
    }

    // 2. Try to make move
    Move candidate = Move(
      startRow: selectedMovePiece!.startRow,
      startCol: selectedMovePiece!.startCol,
      endRow: row,
      endCol: col,
      pieceMoved: selectedMovePiece!.pieceMoved,
      pieceCaptured: board.board[row][col],
    );

    List<Move> legalMoves = generateLegalMoves(board);

    bool isLegal = legalMoves.any((m) =>
        m.startRow == candidate.startRow &&
        m.startCol == candidate.startCol &&
        m.endRow == candidate.endRow &&
        m.endCol == candidate.endCol);

    if (isLegal) {
      board.makeMove(candidate);
      _updateGameState();
    }

    selectedMovePiece = null;
  }

  bool _isCorrectTurn(String piece) {
    return board.turn == "white" ? piece.startsWith("w") : piece.startsWith("b");
  }

  void _updateGameState() {
    if (isCheckmate(board, board.turn)) {
      status = GameStatus.checkmate;
    } else if (isStalemate(board, board.turn)) {
      status = GameStatus.stalemate;
    } else if (ChessEngine.isInCheck(board, board.turn)) {
      status = GameStatus.check;
    } else {
      status = GameStatus.playing;
    }
  }
}