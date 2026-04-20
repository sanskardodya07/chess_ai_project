import 'package:flutter/material.dart';
import '../api/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _board = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AuthService.fetchLeaderboard();
    setState(() { _board = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "LEADERBOARD",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            fontSize: 14,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90D9)))
          : _board.isEmpty
              ? Center(
                  child: Text("No players yet",
                      style: TextStyle(color: Colors.grey[600])))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _board.length,
                  itemBuilder: (_, i) {
                    final e = _board[i];
                    final isMe = e["username"] ==
                        AuthService.currentUser?.username;
                    final rank = e["rank"] as int;

                    Color rankColor = Colors.grey[600]!;
                    String rankIcon = "#$rank";
                    if (rank == 1) { rankColor = const Color(0xFFFFD700); rankIcon = "🥇"; }
                    else if (rank == 2) { rankColor = const Color(0xFFC0C0C0); rankIcon = "🥈"; }
                    else if (rank == 3) { rankColor = const Color(0xFFCD7F32); rankIcon = "🥉"; }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFF4A90D9).withValues(alpha: 0.12)
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMe
                              ? const Color(0xFF4A90D9).withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              rankIcon,
                              style: TextStyle(
                                fontSize: rank <= 3 ? 20 : 14,
                                color: rankColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e["username"],
                              style: TextStyle(
                                color: isMe
                                    ? const Color(0xFF4A90D9)
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: isMe
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          Text(
                            "${e['points']} pts",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}