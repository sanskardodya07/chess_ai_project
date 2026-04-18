import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/board.dart';
import '../models/move.dart';

// REST API URL (update with your Vercel deployment URL)
// Example: https://your-project-name.vercel.app
const String _serverUrl = 'https://api.vercel.com/v1/integrations/deploy/prj_8y6dm5NFhyU6MdWVv4zeiifN1CRO/4yeb9Ggafz';

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

/// Sends the current board state to the backend AI server via REST API.
///
/// Returns the decoded JSON response from the server.
// ignore: non_constant_identifier_names
Future<Map<String, dynamic>> ai_move(
  Board board, {
  Move? humanMove,
  List<Move>? legalMoves,
}) async {
  final payload = json_builder(
    board,
    humanMove: humanMove,
    legalMoves: legalMoves,
  );

  try {
    final response = await http
        .post(
          Uri.parse('$_serverUrl/api/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Server error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    throw Exception('Failed to get AI move: $e');
  }
}
