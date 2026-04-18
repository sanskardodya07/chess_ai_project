import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../models/board.dart';
import '../models/move.dart';

class AIService {
  // ✅ No trailing slash
  static const String baseUrl = "https://chess-ai-project.vercel.app";

  static Future<Move?> getBestMove(Board board) async {
    try {
      final url = Uri.parse("$baseUrl/api/move");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "board": board.toJson(),
          "depth": 3,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("AI Error ${response.statusCode}: ${response.body}");
        return null;
      }

      final data = jsonDecode(response.body);
      return _moveFromJson(data);

    } catch (e, stackTrace) {          // ← also print stackTrace to see parse errors
      debugPrint("AI Exception: $e");
      debugPrint("Stack: $stackTrace");
      return null;
    }
  }

  static Move _moveFromJson(Map<String, dynamic> json) {
    final m = json["move"] as Map<String, dynamic>;
    return Move(
      startRow: m["startRow"],
      startCol: m["startCol"],
      endRow: m["endRow"],
      endCol: m["endCol"],
      pieceMoved: m["pieceMoved"],
      pieceCaptured: m["pieceCaptured"] ?? "",
      promotion: m["promotion"],
      isEnPassant: m["isEnPassant"] ?? false,
      isCastling: m["isCastling"] ?? false,
    );
  }
}