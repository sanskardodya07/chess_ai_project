import 'dart:convert';
import 'dart:io';

import '../models/board.dart';
import '../models/move.dart';

Map<String, dynamic> _moveToJson(Move move) {
  return {
    'start': [move.startRow, move.startCol],
    'end': [move.endRow, move.endCol],
    'promotion': move.promotion,
    'is_castle': move.isCastle,
    'is_en_passant': move.isEnPassant,
  };
}

Map<String, bool> _calculateCastlingRights(Board board) {
  bool wK = true;
  bool wQ = true;
  bool bK = true;
  bool bQ = true;

  for (final move in board.moveHistory) {
    if (move.pieceMoved == 'wK') {
      wK = false;
      wQ = false;
    } else if (move.pieceMoved == 'bK') {
      bK = false;
      bQ = false;
    } else if (move.pieceMoved == 'wR') {
      if (move.startRow == 7 && move.startCol == 7) {
        wK = false;
      } else if (move.startRow == 7 && move.startCol == 0) {
        wQ = false;
      }
    } else if (move.pieceMoved == 'bR') {
      if (move.startRow == 0 && move.startCol == 7) {
        bK = false;
      } else if (move.startRow == 0 && move.startCol == 0) {
        bQ = false;
      }
    }

    if (move.pieceCaptured == 'wR') {
      if (move.endRow == 7 && move.endCol == 7) {
        wK = false;
      } else if (move.endRow == 7 && move.endCol == 0) {
        wQ = false;
      }
    } else if (move.pieceCaptured == 'bR') {
      if (move.endRow == 0 && move.endCol == 7) {
        bK = false;
      } else if (move.endRow == 0 && move.endCol == 0) {
        bQ = false;
      }
    }
  }

  return {
    'wK': wK,
    'wQ': wQ,
    'bK': bK,
    'bQ': bQ,
  };
}

List<int>? _calculateEnPassantTarget(Board board) {
  if (board.moveHistory.isEmpty) return null;

  final Move lastMove = board.moveHistory.last;
  if (lastMove.pieceMoved.length < 2 || lastMove.pieceMoved[1] != 'P') {
    return null;
  }

  if ((lastMove.endRow - lastMove.startRow).abs() != 2) {
    return null;
  }

  final int middleRow = (lastMove.startRow + lastMove.endRow) ~/ 2;
  return [middleRow, lastMove.startCol];
}

// ignore: non_constant_identifier_names
Map<String, dynamic> json_builder(
  Board board, {
  Move? humanMove,
  List<Move>? legalMoves,
}) {
  return {
    'board': board.board,
    'turn': board.turn,
    'white_king': [board.whiteKing.$1, board.whiteKing.$2],
    'black_king': [board.blackKing.$1, board.blackKing.$2],
    'castling_rights': _calculateCastlingRights(board),
    'en_passant_target': _calculateEnPassantTarget(board),
    if (humanMove != null) 'human_move': _moveToJson(humanMove),
    if (legalMoves != null)
      'legal_moves': legalMoves.map(_moveToJson).toList(),
  };
}

/// Sends the current board state to the backend AI server over WebSocket.
///
/// The [url] should be the full WebSocket endpoint, for example:
/// `ws://example.onrender.com`.
///
/// Returns the decoded JSON response from the server.
// ignore: non_constant_identifier_names
Future<Map<String, dynamic>> ai_move(
  Board board,
  String url, {
  Move? humanMove,
  List<Move>? legalMoves,
}) async {
  final payload = json_builder(
    board,
    humanMove: humanMove,
    legalMoves: legalMoves,
  );

  final socket = await WebSocket.connect(url);

  try {
    socket.add(jsonEncode(payload));

    final dynamic rawResponse = await socket.first;
    if (rawResponse is String) {
      return jsonDecode(rawResponse) as Map<String, dynamic>;
    }

    if (rawResponse is List<int>) {
      return jsonDecode(utf8.decode(rawResponse)) as Map<String, dynamic>;
    }

    throw FormatException('Unexpected WebSocket response payload type.');
  } finally {
    await socket.close();
  }
}
