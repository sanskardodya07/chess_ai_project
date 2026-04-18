class Move {
  final int startRow, startCol;
  final int endRow, endCol;

  final String pieceMoved;
  final String pieceCaptured;

  final String? promotion; // ⭐ ADD THIS

  final bool isEnPassant;
  final bool isCastling;

  Move({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
    required this.pieceMoved,
    required this.pieceCaptured,
    this.promotion,
    this.isEnPassant = false,
    this.isCastling = false
  });
}