import 'package:flutter/material.dart';
import '../models/move.dart';
import '../models/board.dart';
import '../models/board_snapshot.dart';
import '../logic/attack_map.dart';

class ChessBoard extends StatelessWidget {
  final Board board;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onTap;
  final List<Move> legalMoves;
  final Move? lastMove;
  final bool isFlipped;
  final BoardSnapshot? snapshot; 
  
  // NEW: Theme colors
  final Color lightSquareColor;
  final Color darkSquareColor;

  const ChessBoard({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onTap,
    required this.legalMoves,
    required this.lastMove,
    this.isFlipped = false,
    this.snapshot,
    this.lightSquareColor = const Color(0xFFEEEED2), // Default Cream
    this.darkSquareColor = const Color(0xFF769656),  // Default Green
  });

  bool get _viewMode => snapshot != null;

  List<List<String>> get _displayBoard  => snapshot?.board      ?? board.board;
  Move?              get _displayLast   => snapshot?.lastMove   ?? lastMove;
  (int, int)         get _wKing         => snapshot?.whiteKing  ?? board.whiteKing;
  (int, int)         get _bKing         => snapshot?.blackKing  ?? board.blackKing;
  String             get _turn          => snapshot?.turn       ?? board.turn;

  int _r(int dr) => isFlipped ? 7 - dr : dr;
  int _c(int dc) => isFlipped ? 7 - dc : dc;

  bool _isLastMove(int r, int c) {
    final lm = _displayLast;
    if (lm == null) return false;
    return (lm.startRow == r && lm.startCol == c) ||
           (lm.endRow   == r && lm.endCol   == c);
  }

  bool _isLegal(int r, int c) =>
      !_viewMode && legalMoves.any((m) => m.endRow == r && m.endCol == c);

  bool _isSelected(int r, int c) =>
      !_viewMode && selectedRow == r && selectedCol == c;

  bool _isInCheck(int r, int c) {
    if (_viewMode) return false;
    final enemy = _turn == "white" ? "b" : "w";
    if (_turn == "white" && r == _wKing.$1 && c == _wKing.$2) {
      return isSquareAttacked(board, r, c, enemy);
    }
    if (_turn == "black" && r == _bKing.$1 && c == _bKing.$2) {
      return isSquareAttacked(board, r, c, enemy);
    }
    return false;
  }

  // UPDATED: Use the passed in theme colors
  Color _base(int r, int c) => (r + c) % 2 == 0 ? lightSquareColor : darkSquareColor;
  Color _labelColor(int r, int c) => (r + c) % 2 == 0 ? darkSquareColor : lightSquareColor;

  Color _squareColor(int r, int c) {
    if (_isInCheck(r, c))   return Colors.redAccent.withValues(alpha: 0.85);
    if (_isSelected(r, c))  return const Color(0xFFF6F669).withValues(alpha: 0.9);
    if (_isLastMove(r, c))  return const Color(0xFFF6F669).withValues(alpha: 0.52);
    return _base(r, c);
  }

  String _rankLabel(int dr) => (isFlipped ? dr + 1 : 8 - dr).toString();

  String _fileLabel(int dc) {
    final fi = isFlipped ? 7 - dc : dc;
    return String.fromCharCode('a'.codeUnitAt(0) + fi);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 64,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemBuilder: (_, idx) {
          final dr = idx ~/ 8;
          final dc = idx %  8;
          final r  = _r(dr);
          final c  = _c(dc);

          final piece     = _displayBoard[r][c];
          final isLegal   = _isLegal(r, c);
          final hasPiece  = piece.isNotEmpty;

          return GestureDetector(
            onTap: _viewMode ? null : () => onTap(r, c),
            child: Container(
              color: _squareColor(r, c),
              child: Stack(
                children: [
                  if (hasPiece)
                    Padding(
                      padding: const EdgeInsets.all(3),
                      child: Image.asset(
                        "assets/pieces/$piece.png",
                        fit: BoxFit.contain,
                      ),
                    ),

                  if (isLegal && !hasPiece)
                    Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.18),
                        ),
                      ),
                    ),

                  if (isLegal && hasPiece)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.22),
                          width: 4.5,
                        ),
                      ),
                    ),

                  if (dc == 0)
                    Positioned(
                      top: 2, left: 2,
                      child: Text(
                        _rankLabel(dr),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _labelColor(r, c),
                        ),
                      ),
                    ),

                  if (dr == 7)
                    Positioned(
                      bottom: 2, right: 2,
                      child: Text(
                        _fileLabel(dc),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _labelColor(r, c),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}