import 'move.dart';

class BoardSnapshot {
  final List<List<String>> board;
  final Move? lastMove;
  final (int, int) whiteKing;
  final (int, int) blackKing;
  final String turn;

  BoardSnapshot({
    required this.board,
    required this.lastMove,
    required this.whiteKing,
    required this.blackKing,
    required this.turn,
  });
}