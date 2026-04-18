import 'package:flutter/material.dart';
import '../widgets/chess_board.dart';
import '../models/board.dart';
import '../logic/move_generator.dart';
import '../logic/rule_checker.dart';
import '../models/move.dart';
import '../logic/game_state_checker.dart';
import '../logic/game_state.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Board board = Board();

  int? selectedRow;
  int? selectedCol;

  String status = "White to move";

  bool gameOver = false;

  List<Move> currentLegalMoves = [];

  // =========================
  // 🖱️ HANDLE TAP
  // =========================
  void onSquareTap(int row, int col) {
    if (gameOver) return;

    setState(() {
      String piece = board.board[row][col];

      // =========================
      // SELECT PIECE
      // =========================
      if (selectedRow == null) {
        if (piece == "") return;
        if (board.turn == "white" && piece[0] != "w") return;
        if (board.turn == "black" && piece[0] != "b") return;

        selectedRow = row;
        selectedCol = col;

        List<Move> moves = generateLegalMoves(board);
        moves = filterLegalMoves(board, moves);

        currentLegalMoves = moves
            .where((m) => m.startRow == row && m.startCol == col)
            .toList();
      }

      // =========================
      // MOVE OR RESELECT
      // =========================
      else {
        Move? chosen;

        for (var m in currentLegalMoves) {
          if (m.endRow == row && m.endCol == col) {
            chosen = m;
            break;
          }
        }

        if (chosen != null) {
          // ✅ VALID MOVE
          board.makeMove(chosen);

          var state = evaluateGameState(board);
          _handleGameState(state);
        } else {
          // 🔥 IMPROVED UX: reselect if tapping another piece
          if (piece != "" &&
              ((board.turn == "white" && piece[0] == "w") ||
               (board.turn == "black" && piece[0] == "b"))) {

            selectedRow = row;
            selectedCol = col;

            List<Move> moves = generateLegalMoves(board);
            moves = filterLegalMoves(board, moves);

            currentLegalMoves = moves
                .where((m) => m.startRow == row && m.startCol == col)
                .toList();

            return;
          }

          // otherwise clear selection
          selectedRow = null;
          selectedCol = null;
          currentLegalMoves = [];
          return;
        }

        selectedRow = null;
        selectedCol = null;
        currentLegalMoves = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text("Chess AI"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ChessBoard(
                  board: board,
                  selectedRow: selectedRow,
                  selectedCol: selectedCol,
                  onTap: onSquareTap,
                  legalMoves: currentLegalMoves,
                  lastMove: board.lastMove,
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            child: Text(
              status,
              style: const TextStyle(fontSize: 18),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: board.moveHistory.isEmpty? null : _undoMove,
                icon: const Icon(Icons.arrow_back),
                tooltip: "Undo Move",
              ),
              IconButton(
                onPressed: _resetGame,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // =========================
  // 🔥 GAME STATE
  // =========================
  void _handleGameState(GameState state) {
    switch (state) {
      case GameState.check:
        status = "${board.turn == "white" ? "White" : "Black"} in check";
        break;

      case GameState.checkmate:
        status = "${board.turn == "white" ? "Black" : "White"} wins by checkmate";
        gameOver = true;
        _showGameOverDialog(status);
        break;

      case GameState.stalemate:
        status = "Draw by stalemate";
        gameOver = true;
        _showGameOverDialog(status);
        break;

      case GameState.draw50Move:
        status = "Draw by 50-move rule";
        gameOver = true;
        _showGameOverDialog(status);
        break;

      case GameState.drawRepetition:
        status = "Draw by repetition";
        gameOver = true;
        _showGameOverDialog(status);
        break;

      case GameState.drawInsufficientMaterial:
        status = "Draw by insufficient material";
        gameOver = true;
        _showGameOverDialog(status);
        break;

      case GameState.playing:
        status = board.turn == "white"
            ? "White to move"
            : "Black to move";
        break;
    }
  }

  // =========================
  // 🔥 GAME OVER DIALOG
  // =========================
  void _showGameOverDialog(String message) {
    if (!mounted) return; // ✅ FIX

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Game Over"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text("Play Again"),
          ),
        ],
      ),
    );
  }
  // =========================
  void _resetGame() {
    setState(() {
      board = Board();
      selectedRow = null;
      selectedCol = null;
      currentLegalMoves = [];
      status = "White to move";
      gameOver = false;
    });
  }

  void _undoMove() {
    setState(() {
      if (board.moveHistory.isEmpty) return;

      board.undoMove();

      var state = evaluateGameState(board);
      gameOver = false;
      _handleGameState(state);

      selectedRow = null;
      selectedCol = null;
      currentLegalMoves = [];
    });
  }
}