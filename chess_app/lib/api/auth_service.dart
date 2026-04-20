import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String username;
  final String token;
  int totalPoints;
  int wins;

  AuthUser({
    required this.username,
    required this.token,
    this.totalPoints = 0,
    this.wins = 0,
  });
}

class AuthService {
  static const String _baseUrl = "https://chess-ai-project.vercel.app";
  static const String _tokenKey = "pace_token";
  static const String _userKey  = "pace_username";

  static AuthUser? currentUser;

  // ── Load saved session ──────────────────────────────
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token    = prefs.getString(_tokenKey);
    final username = prefs.getString(_userKey);
    if (token != null && username != null) {
      currentUser = AuthUser(username: username, token: token);
    }
  }

  // ── Register ────────────────────────────────────────
  static Future<String?> register(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveSession(data["token"], username);
        currentUser = AuthUser(
          username: username,
          token: data["token"],
        );
        return null; // null = success
      }
      return data["error"] ?? "Registration failed";
    } catch (e) {
      debugPrint("Register error: $e");
      return "Connection error";
    }
  }

  // ── Login ───────────────────────────────────────────
  static Future<String?> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveSession(data["token"], username);
        currentUser = AuthUser(
          username:     username,
          token:        data["token"],
          totalPoints:  data["total_points"] ?? 0,
          wins:         data["wins"] ?? 0,
        );
        return null;
      }
      return data["error"] ?? "Login failed";
    } catch (e) {
      debugPrint("Login error: $e");
      return "Connection error";
    }
  }

  // ── Logout ──────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    currentUser = null;
  }

  // ── Submit score ────────────────────────────────────
  static Future<int?> submitScore({
    required String result,
    required int margin,
  }) async {
    if (currentUser == null) return null;
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/api/score/update"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${currentUser!.token}",
        },
        body: jsonEncode({"result": result, "margin": margin}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        currentUser!.totalPoints = data["total_points"];
        return data["points_earned"];
      }
    } catch (e) {
      debugPrint("Score error: $e");
    }
    return null;
  }

  // ── Leaderboard ─────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      final res = await http.get(
          Uri.parse("$_baseUrl/api/leaderboard"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data["leaderboard"]);
      }
    } catch (e) {
      debugPrint("Leaderboard error: $e");
    }
    return [];
  }

  static Future<void> _saveSession(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, username);
  }
}