import 'package:flutter/material.dart';

class ChessBoard extends StatelessWidget {

  final List<List<String>> board;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onTap;

  const ChessBoard({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onTap,
  });

  Color getSquareColor(int row, int col) {

    if (selectedRow == row && selectedCol == col) {
      return Colors.yellow;
    }

    if ((row + col) % 2 == 0) {
      return const Color(0xFFEEEED2);
    } else {
      return const Color(0xFF769656);
    }
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

          String piece = board[row][col];

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