// lib/api/ai_service.dart

import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../models/board.dart';
import '../models/move.dart';

class AIService {
  // ⚠️ Replace with your actual deployed Vercel URL
  static const String baseUrl = "https://your-app.vercel.app/api";

  // =========================
  // ♟️ GET BEST MOVE
  // =========================
  static Future<Move?> getBestMove(Board board) async {
    try {
      final url = Uri.parse("$baseUrl/move");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(board.toJson()),
      );

      if (response.statusCode != 200) {
        debugPrint("AI Error: ${response.body}");
        return null;
      }

      final data = jsonDecode(response.body);

      return _moveFromJson(data);
    } catch (e) {
      debugPrint("AI Exception: $e");
      return null;
    }
  }

  // =========================
  // 🔄 JSON → MOVE
  // =========================
  static Move _moveFromJson(Map<String, dynamic> json) {
    return Move(
      startRow: json["start_row"],
      startCol: json["start_col"],
      endRow: json["end_row"],
      endCol: json["end_col"],
      pieceMoved: json["piece_moved"],
      pieceCaptured: json["piece_captured"] ?? "",
      promotion: json["promotion"],
      isEnPassant: json["is_en_passant"] ?? false,
      isCastling: json["is_castling"] ?? false,
    );
  }
}