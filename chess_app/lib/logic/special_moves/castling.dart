import '../../models/board.dart';
import '../../models/move.dart';
import '../attack_map.dart';

void addCastlingMoves(Board board, int r, int c, List<Move> moves) {
  String king = board.board[r][c];

  if (king[1] != "K") return;

  _tryCastle(board, moves, r, c, true);   // king side
  _tryCastle(board, moves, r, c, false);  // queen side
}

void _tryCastle(Board board, List<Move> moves, int r, int c, bool kingSide) {
  String color = board.board[r][c][0];
  String enemy = color == "w" ? "b" : "w";

  // ❌ king already moved
  if (color == "w" && board.whiteKingMoved) return;
  if (color == "b" && board.blackKingMoved) return;

  // ❌ king in check
  if (isSquareAttacked(board, r, c, enemy)) return;

  if (kingSide) {
    // ❌ rook moved check
    if (color == "w" && board.whiteRookHMoved) return;
    if (color == "b" && board.blackRookHMoved) return;

    // ❌ squares must be empty
    if (board.board[r][5] != "" || board.board[r][6] != "") return;

    // ❌ rook must exist
    if (board.board[r][7] != "${color}R") return;

    // ❌ path must not be attacked
    if (isSquareAttacked(board, r, 5, enemy)) return;
    if (isSquareAttacked(board, r, 6, enemy)) return;

    moves.add(Move(
      startRow: r,
      startCol: c,
      endRow: r,
      endCol: 6,
      pieceMoved: "${color}K",
      pieceCaptured: "",
      isCastling: true,
    ));

  } else {
    // ❌ rook moved check
    if (color == "w" && board.whiteRookAMoved) return;
    if (color == "b" && board.blackRookAMoved) return;

    // ❌ squares must be empty
    if (board.board[r][1] != "" ||
        board.board[r][2] != "" ||
        board.board[r][3] != "") {
          return;
        }

    // ❌ rook must exist
    if (board.board[r][0] != "${color}R") return;

    // ❌ path must not be attacked
    if (isSquareAttacked(board, r, 2, enemy)) return;
    if (isSquareAttacked(board, r, 3, enemy)) return;

    moves.add(Move(
      startRow: r,
      startCol: c,
      endRow: r,
      endCol: 2,
      pieceMoved: "${color}K",
      pieceCaptured: "",
      isCastling: true,
    ));
  }
}