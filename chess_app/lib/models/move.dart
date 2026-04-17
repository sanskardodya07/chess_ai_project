class Move {
  final int startRow, startCol;
  final int endRow, endCol;

  final String pieceMoved;
  final String pieceCaptured;

  Move({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
    required this.pieceMoved,
    required this.pieceCaptured,
  });
}