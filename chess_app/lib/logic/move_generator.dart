import '../models/board.dart';
import '../models/move.dart';

import 'piece_moves/pawn.dart';
import 'piece_moves/knight.dart';
import 'piece_moves/bishop.dart';
import 'piece_moves/rook.dart';
import 'piece_moves/queen.dart';
import 'piece_moves/king.dart';

import 'special_moves/castling.dart';
import 'special_moves/en_passant.dart';
import 'special_moves/promotion.dart';

import 'move_validator.dart';

List<Move> generateLegalMoves(Board board) {
  List<Move> moves = [];

  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      String piece = board.board[r][c];
      if (piece == "") continue;

      if (!_isCurrentTurn(board, piece)) continue;

      switch (piece[1]) {
        case "P":
          pawnMoves(board, r, c, moves);
          addPromotionMoves(moves);
          addEnPassantMoves(board, r, c, moves);
          break;

        case "N":
          knightMoves(board, r, c, moves);
          break;

        case "B":
          bishopMoves(board, r, c, moves);
          break;

        case "R":
          rookMoves(board, r, c, moves);
          break;

        case "Q":
          queenMoves(board, r, c, moves);
          break;

        case "K":
          kingMoves(board, r, c, moves);
          addCastlingMoves(board, r, c, moves);
          break;
      }
    }
  }

  return filterLegalMoves(board, moves);
}

bool _isCurrentTurn(Board board, String piece) {
  return (board.turn == "white" && piece.startsWith("w")) ||
         (board.turn == "black" && piece.startsWith("b"));
}