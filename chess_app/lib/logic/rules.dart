import '../models/board.dart';
import 'move_generator.dart';
import 'rule_checker.dart';

bool isCheckmate(Board board, String color) {
  List moves = generateLegalMoves(board);
  return moves.isEmpty && isInCheck(board, color);
}

bool isStalemate(Board board, String color) {
  List moves = generateLegalMoves(board);
  return moves.isEmpty && !isInCheck(board, color);
}