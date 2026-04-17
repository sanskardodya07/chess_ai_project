class Move {
  final int startRow, startCol;
  final int endRow, endCol;

  final String pieceMoved;
  final String pieceCaptured;
  
  final bool isCastle;
  final bool isEnPassant;
  final String? promotion; // 'Q', 'R', 'B', 'N'

  Move({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
    required this.pieceMoved,
    required this.pieceCaptured,
    this.isCastle = false,
    this.isEnPassant = false,
    this.promotion,
  });
}