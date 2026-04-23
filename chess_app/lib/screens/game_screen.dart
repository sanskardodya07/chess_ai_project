import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../widgets/chess_board.dart';
import '../widgets/move_history_panel.dart';
import '../widgets/captured_pieces_row.dart';
import '../widgets/thinking_dots.dart';

import '../models/board.dart';
import '../models/move.dart';
import '../models/board_snapshot.dart';

import '../logic/move_generator.dart';
import '../logic/game_state_checker.dart';
import '../logic/game_state.dart';

import '../api/ai_service.dart';

import 'dart:math';
import '../api/auth_service.dart';
import '../screens/auth_screen.dart';
import '../screens/leaderboard_screen.dart';

class BoardTheme {
  final String name;
  final Color light;
  final Color dark;
  const BoardTheme(this.name, this.light, this.dark);
}

const List<BoardTheme> _themes = [
  BoardTheme("Classic", Color(0xFFEEEED2), Color(0xFF769656)), // Chess.com Green
  BoardTheme("Walnut",  Color(0xFFEADDCA), Color(0xFFB58863)), // Lichess Brown
  BoardTheme("Ocean",   Color(0xFFDFE3E8), Color(0xFF7B9EBD)), // Cool Blue
  BoardTheme("Dusk",    Color(0xFFCCCED4), Color(0xFF767F8B)), // Dark Grey
];

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showAuthOverlay = false;
  bool _showGameOverOverlay = false; // Controls the delayed popup
  int  _pendingMargin   = 0;
  String _pendingResult = "";

  // ── Difficulty Level & Theme ──────────────────────────
  int _selectedDepth = 4; // Default Intermediate
  int _themeIndex    = 0; // Default Classic Green

  // ── Game ────────────────────────────────────────────
  Board  board    = Board();
  bool   gameOver = false;
  String statusMessage = "";

  // ── Selection ───────────────────────────────────────
  int?       selectedRow, selectedCol;
  List<Move> currentLegalMoves = [];

  // ── Players ─────────────────────────────────────────
  String playerColor = "white";
  String aiColor     = "black";
  bool   colorChosen = false;

  // ── AI ──────────────────────────────────────────────
  bool aiThinking = false;

  // ── History / view mode ─────────────────────────────
  List<BoardSnapshot> snapshots = [];
  int? viewingIndex; // null = live game

  // ── Sound ───────────────────────────────────────────
  final AudioPlayer _sfx = AudioPlayer();

  // ── Piece values ────────────────────────────────────
  static const Map<String, int> _values = {
    'Q': 9, 'R': 5, 'B': 3, 'N': 3, 'P': 1
  };

  @override
  void initState() {
    super.initState();
    AuthService.loadSession().then((_) => setState(() {}));
  }
  
  // ────────────────────────────────────────────────────
  @override
  void dispose() {
    _sfx.dispose();
    super.dispose();
  }

  // ── Sound ────────────────────────────────────────────
  Future<void> _play(String name) async {
    try { await _sfx.play(AssetSource('sounds/$name.mp3')); } catch (_) {}
  }

  // ── Captured pieces ──────────────────────────────────
  List<String> _capturedBy(String capturingColor, {int? upTo}) {
    final moves = upTo != null
        ? board.moveHistory.take(upTo + 1)
        : board.moveHistory as Iterable<Move>;
    return moves
        .where((m) =>
            m.pieceCaptured.isNotEmpty &&
            m.pieceMoved[0] == capturingColor[0])
        .map((m) => m.pieceCaptured)
        .toList();
  }

  int _material(List<String> pieces) =>
      pieces.fold(0, (s, p) => s + (_values[p[1]] ?? 0));

  // ── Snapshot ──────────────────────────────────────────
  void _saveSnapshot() {
    snapshots.add(BoardSnapshot(
      board:      board.board.map((r) => List<String>.from(r)).toList(),
      lastMove:   board.lastMove,
      whiteKing:  board.whiteKing,
      blackKing:  board.blackKing,
      turn:       board.turn,
    ));
  }

  // ── Color choice ──────────────────────────────────────
  void _chooseColor(String color) {
    setState(() {
      playerColor = color;
      aiColor     = color == "white" ? "black" : "white";
      colorChosen = true;
    });
    if (color == "black") _maybeTriggerAI();
  }

  // ── Tap handler ───────────────────────────────────────
  void onSquareTap(int row, int col) {
    if (gameOver || aiThinking || !colorChosen) return;
    if (viewingIndex != null) return;

    final piece = board.board[row][col];

    if (selectedRow == null) {
      if (piece.isEmpty) return;
      if (board.turn == "white" && piece[0] != "w") return;
      if (board.turn == "black" && piece[0] != "b") return;

      setState(() {
        selectedRow = row;
        selectedCol = col;
        currentLegalMoves = generateLegalMoves(board)
            .where((m) => m.startRow == row && m.startCol == col)
            .toList();
      });
    } else {
      final chosen = currentLegalMoves
          .where((m) => m.endRow == row && m.endCol == col)
          .firstOrNull;

      if (chosen != null) {
        // Apply move synchronously inside setState
        setState(() {
          board.makeMove(chosen);
          _saveSnapshot();
          selectedRow        = null;
          selectedCol        = null;
          currentLegalMoves  = [];
          final state = evaluateGameState(board);
          _handleGameState(state);
        });

        // Sound and AI after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = evaluateGameState(board);
          _playSoundForState(chosen, state);
          if (!gameOver) _maybeTriggerAI();
        });
      } else {
        // Re-select if tapping own piece, otherwise deselect
        if (piece.isNotEmpty &&
            ((board.turn == "white" && piece[0] == "w") ||
             (board.turn == "black" && piece[0] == "b"))) {
          setState(() {
            selectedRow = row;
            selectedCol = col;
            currentLegalMoves = generateLegalMoves(board)
                .where((m) => m.startRow == row && m.startCol == col)
                .toList();
          });
        } else {
          setState(() {
            selectedRow       = null;
            selectedCol       = null;
            currentLegalMoves = [];
          });
        }
      }
    }
  }

  void _playSoundForState(Move move, GameState state) {
    if ([GameState.checkmate, GameState.stalemate,
         GameState.draw50Move, GameState.drawRepetition,
         GameState.drawInsufficientMaterial].contains(state)) {
      _play("game_over");
    } else if (state == GameState.check) {
      _play("check");
    } else if (move.pieceCaptured.isNotEmpty) {
      _play("capture");
    } else {
      _play("move");
    }
  }

  // ── AI ────────────────────────────────────────────────
  void _resetGame() {
    setState(() {
      board             = Board();
      selectedRow       = null;
      selectedCol       = null;
      currentLegalMoves = [];
      gameOver          = false;
      _showGameOverOverlay = false; // Reset the overlay
      statusMessage     = "";
      snapshots         = [];
      viewingIndex      = null;
      aiThinking        = false;
      colorChosen       = false;
      playerColor       = "white";
      aiColor           = "black";
    });
  }

  Future<void> _maybeTriggerAI() async {
    if (gameOver || board.turn != aiColor) return;

    setState(() {
      aiThinking    = true;
      statusMessage = "AI is thinking...";
    });

    // Pass the selected depth here!
    final move = await AIService.getBestMove(board, _selectedDepth);

    // ... (rest of the method remains the same)

    if (!mounted) return;

    if (move == null) {
      setState(() {
        aiThinking    = false;
        statusMessage = "AI failed — check connection";
      });
      return;
    }

    setState(() {
      board.makeMove(move);
      _saveSnapshot();
      aiThinking = false;

      final state = evaluateGameState(board);
      _handleGameState(state);
      if (!gameOver) statusMessage = "Your move";
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (move.pieceCaptured.isNotEmpty) {
        _play("capture");
      } else {
        _play("move");
      }
    });
  }

  // ── Game state ────────────────────────────────────────
  void _handleGameState(GameState state) {
    final moving = board.turn == "white" ? "White" : "Black";
    final other  = board.turn == "white" ? "Black" : "White";

    switch (state) {
      case GameState.check:
        statusMessage = "$moving in check";
        break;
      case GameState.checkmate:
        statusMessage = "$other wins by checkmate";
        gameOver = true;
        _onGameOver(state);
        break;
      case GameState.stalemate:
        statusMessage = "Draw — stalemate";
        gameOver = true;
        _onGameOver(state);
        break;
      case GameState.draw50Move:
        statusMessage = "Draw — 50 move rule";
        gameOver = true;
        _onGameOver(state);
        break;
      case GameState.drawRepetition:
        statusMessage = "Draw — threefold repetition";
        gameOver = true;
        _onGameOver(state);
        break;
      case GameState.drawInsufficientMaterial:
        statusMessage = "Draw — insufficient material";
        gameOver = true;
        _onGameOver(state);
        break;
      default:
        statusMessage = "$moving to move";
    }
  }

  void _onGameOver(GameState state) {
    final (byPlayer, byAI, pMat, aMat) = _computeCaptures();
    final margin = pMat - aMat;

    String result = "draw";
    if (state == GameState.checkmate) {
      result = board.turn == aiColor ? "win" : "loss";
    }

    _pendingMargin  = max(margin, 0);
    _pendingResult  = result;

    if (AuthService.currentUser != null) {
      _submitScore();
    }

    // Delay the popup by 2 seconds so the user can look at the board
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showGameOverOverlay = true;
        });
      }
    });
  }

  Future<void> _submitScore() async {
    final earned = await AuthService.submitScore(
      result: _pendingResult,
      margin: _pendingMargin,
    );
    if (earned != null && earned > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          content: Text(
            "+$earned points earned! Total: ${AuthService.currentUser!.totalPoints}",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _confirmResign() {
    if (aiThinking || gameOver || !colorChosen) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Resign?", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to forfeit this match?", style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                gameOver = true;
                statusMessage = "${playerColor == 'white' ? 'White' : 'Black'} resigned";
                _pendingResult = "loss";
                _pendingMargin = 0;
              });
              
              if (AuthService.currentUser != null) _submitScore();

              // Delay popup
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) setState(() => _showGameOverOverlay = true);
              });
            },
            child: const Text("Resign", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Reset ────────────────────────────────────────────
  void _confirmReset() {
    if (aiThinking) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("New Game?",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Start a new game from scratch?",
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text("New Game",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Undo ─────────────────────────────────────────────
  void _undoMove() {
    if (board.moveHistory.isEmpty || aiThinking) return;

    setState(() {
      board.undoMove();
      if (snapshots.isNotEmpty) snapshots.removeLast();

      // Also undo the AI move so it's player's turn again
      if (board.moveHistory.isNotEmpty && board.turn == aiColor) {
        board.undoMove();
        if (snapshots.isNotEmpty) snapshots.removeLast();
      }

      viewingIndex      = null;
      gameOver          = false;
      selectedRow       = null;
      selectedCol       = null;
      currentLegalMoves = [];

      _handleGameState(evaluateGameState(board));
    });
  }

  // ── View mode ─────────────────────────────────────────
  BoardSnapshot? get _activeSnapshot =>
      viewingIndex != null ? snapshots[viewingIndex!] : null;

  void _onHistoryTap(int? index) {
    setState(() {
      viewingIndex = (index != null && index < snapshots.length)
          ? index
          : null;
    });
  }

  // ── Material computation ──────────────────────────────
  (List<String>, List<String>, int, int) _computeCaptures() {
    final limit = viewingIndex; // null = full history
    final byPlayer = _capturedBy(playerColor, upTo: limit);
    final byAI     = _capturedBy(aiColor,     upTo: limit);
    final pMat = _material(byPlayer);
    final aMat = _material(byAI);
    return (byPlayer, byAI, pMat, aMat);
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Chess AI",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontSize: 17,
          ),
        ),
      ),
      body: Stack(
        children: [
          isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          if (!colorChosen) _buildColorPickerOverlay(),
          // Use the new delayed variable here!
          if (_showGameOverOverlay && colorChosen) _buildGameOverOverlay(), 
          if (_showAuthOverlay && !gameOver) _fullScreenAuth(),
        ],
      ),
    );
  }

  // ── Mobile layout ─────────────────────────────────────
  Widget _buildMobileLayout() {
    final (byPlayer, byAI, pMat, aMat) = _computeCaptures();

    return SafeArea(
      child: Column(
        children: [
          // Move history ABOVE board — slim
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: MoveHistoryPanel(
                moves:        board.moveHistory,
                viewingIndex: viewingIndex,
                isDesktop:    false,
                onTap:        _onHistoryTap,
              ),
            ),
          ),

          // Opponent captures
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
            child: CapturedPiecesRow(
              pieces:    byAI,
              advantage: aMat > pMat ? aMat - pMat : 0,
            ),
          ),

          // Board
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildBoardWidget(),
          ),

          // Player captures
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
            child: CapturedPiecesRow(
              pieces:    byPlayer,
              advantage: pMat > aMat ? pMat - aMat : 0,
            ),
          ),

          _buildStatusBar(),
          _buildControls(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── Desktop layout ────────────────────────────────────
  // ── Desktop layout ────────────────────────────────────
  Widget _buildDesktopLayout() {
    final (byPlayer, byAI, pMat, aMat) = _computeCaptures();

    return Row(
      children: [
        // Board column gets ALL the remaining space
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CapturedPiecesRow(
                  pieces: byAI,
                  advantage: aMat > pMat ? aMat - pMat : 0,
                ),
                const SizedBox(height: 6),
                Expanded(child: _buildBoardWidget()),
                const SizedBox(height: 6),
                CapturedPiecesRow(
                  pieces: byPlayer,
                  advantage: pMat > aMat ? pMat - aMat : 0,
                ),
              ],
            ),
          ),
        ),
        // Sidebar is now a fixed width so it wraps text tightly
        SizedBox(
          width: 340, // Industry standard sidebar width
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
            child: Column(
              children: [
                _buildStatusBar(),
                const SizedBox(height: 10),
                Expanded(
                  child: MoveHistoryPanel(
                    moves:        board.moveHistory,
                    viewingIndex: viewingIndex,
                    isDesktop:    true,
                    onTap:        _onHistoryTap,
                  ),
                ),
                const SizedBox(height: 10),
                _buildControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Board widget ──────────────────────────────────────
  Widget _buildBoardWidget() {
    final theme = _themes[_themeIndex]; // Get active theme
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ChessBoard(
        board:        board,
        selectedRow:  selectedRow,
        selectedCol:  selectedCol,
        onTap:        onSquareTap,
        legalMoves:   currentLegalMoves,
        lastMove:     board.lastMove,
        isFlipped:    playerColor == "black",
        snapshot:     _activeSnapshot,
        lightSquareColor: theme.light, // Pass light color
        darkSquareColor:  theme.dark,  // Pass dark color
      ),
    );
  }

  // ── Status bar ────────────────────────────────────────
  Widget _buildStatusBar() {
    final msg = viewingIndex != null
        ? "Move ${viewingIndex! + 1} of ${snapshots.length}"
        : (aiThinking ? "AI is thinking" : statusMessage);

    final color = _statusColor(msg);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (aiThinking && viewingIndex == null) ...[
            const ThinkingDots(),
            const SizedBox(width: 8),
          ],
          Text(
            msg,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String msg) {
    if (msg.contains("check") && !msg.contains("checkmate")) return Colors.orangeAccent;
    if (msg.contains("wins"))   return Colors.greenAccent;
    if (msg.contains("Draw"))   return const Color(0xFF64B5F6);
    if (msg.contains("failed")) return Colors.redAccent;
    if (msg.contains("Move "))  return Colors.white38; // history view
    return Colors.white70;
  }

  // ── Controls ──────────────────────────────────────────
  Widget _buildControls() {
    final currentThemeName = _themes[_themeIndex].name;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,    // Horizontal space between buttons
        runSpacing: 8.0, // Vertical space if they wrap to a second line
        children: [
          _ctrlBtn(
            icon:    Icons.undo_rounded,
            onTap:   board.moveHistory.isEmpty || aiThinking ? null : _undoMove,
            tooltip: "Undo",
          ),
          _ctrlBtn(
            icon:    Icons.refresh_rounded,
            onTap:   _confirmReset,
            tooltip: "New Game",
          ),
          _ctrlBtn(
            icon:    Icons.flag_rounded,
            onTap:   (gameOver || aiThinking || !colorChosen) ? null : _confirmResign,
            tooltip: "Resign",
          ),
          _ctrlBtn(
            icon:    Icons.palette_rounded,
            onTap:   () => setState(() => _themeIndex = (_themeIndex + 1) % _themes.length),
            tooltip: "Theme: $currentThemeName",
          ),
          _ctrlBtn(
            icon:    Icons.leaderboard_rounded,
            onTap:   () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            tooltip: "Leaderboard",
          ),
          if (AuthService.currentUser != null) 
            _ctrlBtn(
              icon:    Icons.logout_rounded,
              onTap:   () async {
                await AuthService.logout();
                setState(() {});
              },
              tooltip: "Sign Out",
            )
          else 
            _ctrlBtn(
              icon:    Icons.person_outline_rounded,
              onTap:   () => setState(() => _showAuthOverlay = true),
              tooltip: "Sign In",
            ),
          if (viewingIndex != null) 
            _ctrlBtn(
              icon:        Icons.skip_next_rounded,
              onTap:       () => setState(() => viewingIndex = null),
              tooltip:     "Back to current",
              highlighted: true,
            ),
        ],
      ),
    );
  }

  Widget _ctrlBtn({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool highlighted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFF4A90D9).withValues(alpha: 0.18)
                : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(10),
            border: highlighted
                ? Border.all(color: const Color(0xFF4A90D9), width: 1)
                : null,
          ),
          child: Icon(
            icon,
            size: 22,
            color: onTap == null
                ? Colors.grey[700]
                : (highlighted
                    ? const Color(0xFF4A90D9)
                    : Colors.white70),
          ),
        ),
      ),
    );
  }

  // ── Color picker overlay ──────────────────────────────
  Widget _buildColorPickerOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFF232323),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 48,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("♟", style: TextStyle(fontSize: 48)),
              const SizedBox(height: 14),
              const Text(
                "Choose Your Side",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              // ... existing text ...
              Text(
                "Select difficulty and choose your side.",
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 24),
              
              // Difficulty Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _difficultyBtn("Beginner", 3),
                  _difficultyBtn("Medium", 4),
                  _difficultyBtn("Advance", 5),
                ],
              ),
              const SizedBox(height: 24),

              _colorBtn(
                label: "Play as White",
                icon:  "♔",
                bg:    const Color(0xFFF0EDE0),
                fg:    const Color(0xFF1A1A1A),
                onTap: () => _chooseColor("white"),
              ),
              const SizedBox(height: 12),
              _colorBtn(
                label:  "Play as Black",
                icon:   "♚",
                bg:     const Color(0xFF1E1E1E),
                fg:     Colors.white,
                onTap:  () => _chooseColor("black"),
                border: Border.all(color: Colors.white24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _difficultyBtn(String label, int depth) {
    final isSelected = _selectedDepth == depth;
    return GestureDetector(
      onTap: () => setState(() => _selectedDepth = depth),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A90D9) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A90D9) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _colorBtn({
    required String label,
    required String icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    BoxBorder? border,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: border,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon,
                style: TextStyle(fontSize: 22, color: fg)),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  // ── Game over overlay ─────────────────────────────────
  Widget _buildGameOverOverlay() {
    final isAnon  = AuthService.currentUser == null;
    final isWin   = _pendingResult == "win";
    final bonus   = isWin ? (1 + ((_pendingMargin + 1) / 2).ceil()) : 0;

    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF232323),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 48,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: _showAuthOverlay
              ? AuthScreen(
                  onSuccess: () {
                    setState(() => _showAuthOverlay = false);
                    _submitScore();
                  },
                  onSkip: () =>
                      setState(() => _showAuthOverlay = false),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_gameOverEmoji(),
                        style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      "GAME OVER",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Points preview for wins
                    if (isWin) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90D9)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "+$bonus points",
                          style: const TextStyle(
                            color: Color(0xFF4A90D9),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Sign in prompt for anonymous
                    if (isAnon && isWin) ...[
                      const Text(
                        "Sign in to save your score",
                        style: TextStyle(
                            color: Colors.white60, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showAuthOverlay = true),
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90D9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Sign In / Register",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    GestureDetector(
                      onTap: _resetGame,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: isAnon && isWin
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFF4A90D9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "New Game",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _fullScreenAuth() {
    return AuthScreen(
      onSuccess: () => setState(() => _showAuthOverlay = false),
      onSkip:    () => setState(() => _showAuthOverlay = false),
    );
  }

  String _gameOverEmoji() {
    if (statusMessage.contains("wins"))     return "🏆";
    if (statusMessage.contains("stalemate")) return "🤝";
    return "⚖️";
  }
}