import '../models/board.dart';
import 'rule_checker.dart';
import 'move_generator.dart';
import 'game_state.dart';

GameState evaluateGameState(Board board) {
  var moves = generateLegalMoves(board);
  moves = filterLegalMoves(board, moves);

  bool inCheck = isInCheck(board, board.turn);

  // 🔥 checkmate
  if (moves.isEmpty && inCheck) {
    return GameState.checkmate;
  }

  // 🔥 stalemate
  if (moves.isEmpty && !inCheck) {
    return GameState.stalemate;
  }

  // 🔥 50 move rule
  if (board.halfMoveClock >= 100) {
    return GameState.draw50Move;
  }

  // 🔥 repetition
  if ((board.positionCount[board.getPositionKey()] ?? 0) >= 3) {
    return GameState.drawRepetition;
  }

  // 🔥 insufficient material
  if (_isInsufficientMaterial(board)) {
    return GameState.drawInsufficientMaterial;
  }

  // 🔥 just check
  if (inCheck) {
    return GameState.check;
  }

  return GameState.playing;
}

bool _isInsufficientMaterial(Board board) {
  List<String> pieces = [];

  for (var row in board.board) {
    for (var p in row) {
      if (p != "") pieces.add(p);
    }
  }

  // remove kings
  pieces.removeWhere((p) => p[1] == "K");

  if (pieces.isEmpty) return true; // K vs K

  if (pieces.length == 1) {
    String p = pieces.first[1];
    if (p == "B" || p == "N") return true;
  }

  if (pieces.length == 2) {
    // B vs B same color (simplified version)
    if (pieces.every((p) => p[1] == "B")) return true;
  }

  return false;
}