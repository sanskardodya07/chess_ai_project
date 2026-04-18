import 'package:flutter/material.dart';
import '../models/move.dart';
import '../models/board.dart';          // ✅ ADD THIS
import '../logic/attack_map.dart';

class ChessBoard extends StatelessWidget {

  final Board board;                    // ✅ CHANGED (was List<List<String>>)
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onTap;

  final List<Move> legalMoves;
  final Move? lastMove;

  const ChessBoard({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onTap,
    required this.legalMoves,
    required this.lastMove,
  });

  Color getBaseColor(int row, int col) {
    return (row + col) % 2 == 0
        ? const Color(0xFFEEEED2)
        : const Color(0xFF769656);
  }

  bool isLegalMoveSquare(int row, int col) {
    return legalMoves.any((m) => m.endRow == row && m.endCol == col);
  }

  bool isLastMoveSquare(int row, int col) {
    if (lastMove == null) return false;
    return (lastMove!.startRow == row && lastMove!.startCol == col) ||
           (lastMove!.endRow == row && lastMove!.endCol == col);
  }

  bool isKingInCheck(int row, int col) {
    String enemy = board.turn == "white" ? "b" : "w";

    if (board.turn == "white" &&
        row == board.whiteKing.$1 &&
        col == board.whiteKing.$2) {
      return isSquareAttacked(board, row, col, enemy);
    }

    if (board.turn == "black" &&
        row == board.blackKing.$1 &&
        col == board.blackKing.$2) {
      return isSquareAttacked(board, row, col, enemy);
    }

    return false;
  }

  Color getSquareColor(int row, int col) {
    Color base = getBaseColor(row, col);

    // 🔴 check
    if (isKingInCheck(row, col)) {
      return Colors.redAccent;
    }

    // 🟡 selected
    if (selectedRow == row && selectedCol == col) {
      return Colors.yellow;
    }

    // 🟢 legal move
    if (isLegalMoveSquare(row, col)) {
      return Colors.greenAccent.withValues(alpha: 0.6); // ✅ FIXED
    }

    // 🔵 last move
    if (isLastMoveSquare(row, col)) {
      return Colors.blue.withValues(alpha: 0.4); // ✅ FIXED
    }

    return base;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        itemCount: 64,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemBuilder: (context, index) {

          int row = index ~/ 8;
          int col = index % 8;

          String piece = board.board[row][col]; // ✅ UPDATED

          return GestureDetector(
            onTap: () => onTap(row, col),
            child: Container(
              decoration: BoxDecoration(
                color: getSquareColor(row, col),
              ),
              child: Center(
                child: piece != ""
                    ? Image.asset(
                        "assets/pieces/$piece.png",
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}