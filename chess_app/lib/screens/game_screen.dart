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
import '../logic/move_notation.dart';

import '../api/ai_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {

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
  Future<void> _maybeTriggerAI() async {
    if (gameOver || board.turn != aiColor) return;

    setState(() {
      aiThinking    = true;
      statusMessage = "AI is thinking";
    });

    final move = await AIService.getBestMove(board);

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
        break;
      case GameState.stalemate:
        statusMessage = "Draw — stalemate";
        gameOver = true;
        break;
      case GameState.draw50Move:
        statusMessage = "Draw — 50 move rule";
        gameOver = true;
        break;
      case GameState.drawRepetition:
        statusMessage = "Draw — threefold repetition";
        gameOver = true;
        break;
      case GameState.drawInsufficientMaterial:
        statusMessage = "Draw — insufficient material";
        gameOver = true;
        break;
      default:
        statusMessage = "$moving to move";
    }
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

  void _resetGame() {
    setState(() {
      board             = Board();
      selectedRow       = null;
      selectedCol       = null;
      currentLegalMoves = [];
      gameOver          = false;
      statusMessage     = "";
      snapshots         = [];
      viewingIndex      = null;
      aiThinking        = false;
      colorChosen       = false;
      playerColor       = "white";
      aiColor           = "black";
    });
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
          if (!colorChosen)       _buildColorPickerOverlay(),
          if (gameOver && colorChosen) _buildGameOverOverlay(),
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
          // Opponent captures (top)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: CapturedPiecesRow(
              pieces: byAI,
              advantage: aMat > pMat ? aMat - pMat : 0,
            ),
          ),
          // Board
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildBoardWidget(),
          ),
          // Player captures (bottom)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
            child: CapturedPiecesRow(
              pieces: byPlayer,
              advantage: pMat > aMat ? pMat - aMat : 0,
            ),
          ),
          // Status
          _buildStatusBar(),
          // Move history
          SizedBox(
            height: 76,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: MoveHistoryPanel(
                moves:        board.moveHistory,
                viewingIndex: viewingIndex,
                isDesktop:    false,
                onTap:        _onHistoryTap,
              ),
            ),
          ),
          // Controls
          _buildControls(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── Desktop layout ────────────────────────────────────
  Widget _buildDesktopLayout() {
    final (byPlayer, byAI, pMat, aMat) = _computeCaptures();

    return Row(
      children: [
        // Board column
        Expanded(
          flex: 3,
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
        // Sidebar
        Expanded(
          flex: 2,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ctrlBtn(
            icon:    Icons.undo_rounded,
            onTap:   board.moveHistory.isEmpty || aiThinking ? null : _undoMove,
            tooltip: "Undo",
          ),
          const SizedBox(width: 8),
          _ctrlBtn(
            icon:    Icons.refresh_rounded,
            onTap:   _confirmReset,
            tooltip: "New Game",
          ),
          if (viewingIndex != null) ...[
            const SizedBox(width: 8),
            _ctrlBtn(
              icon:        Icons.skip_next_rounded,
              onTap:       () => setState(() => viewingIndex = null),
              tooltip:     "Back to current",
              highlighted: true,
            ),
          ],
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
              Text(
                "Pick a color to start the game",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 30),
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
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
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
              Text(_gameOverEmoji(),
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 14),
              const Text(
                "GAME OVER",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                statusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _resetGame,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90D9),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Text(
                    "New Game",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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

  String _gameOverEmoji() {
    if (statusMessage.contains("wins"))     return "🏆";
    if (statusMessage.contains("stalemate")) return "🤝";
    return "⚖️";
  }
}