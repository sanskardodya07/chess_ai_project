import 'package:flutter/material.dart';
import '../widgets/chess_board.dart';
import '../models/board.dart';
import '../logic/move_generator.dart';
import '../logic/rule_checker.dart';
import '../models/move.dart';
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
  Board board = Board();

  int? selectedRow;
  int? selectedCol;

  String status = "White to move";
  bool gameOver = false;

  List<Move> currentLegalMoves = [];

  String playerColor = "white";
  String aiColor = "black";

  bool aiThinking = false;

  @override
  void initState() {
    super.initState();
    _askColorChoice();
  }

  void _askColorChoice() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Choose Your Side"),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  playerColor = "white";
                  aiColor = "black";
                });
                Navigator.pop(context);
              },
              child: const Text("Play White"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  playerColor = "black";
                  aiColor = "white";
                });
                Navigator.pop(context);

                // AI starts if black
                _maybeTriggerAI();
              },
              child: const Text("Play Black"),
            ),
          ],
        ),
      );
    });
  }

  // =========================
  List<Widget> _buildMoveHistory() {
    List<Widget> rows = [];

    for (int i = 0; i < board.moveHistory.length; i += 2) {
      String moveNumber = "${(i ~/ 2) + 1}.";

      String whiteMove = getMoveNotation(board.moveHistory[i]);

      String blackMove = "";
      if (i + 1 < board.moveHistory.length) {
        blackMove = getMoveNotation(board.moveHistory[i + 1]);
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 30, child: Text(moveNumber)),
              Expanded(child: Text(whiteMove)),
              Expanded(child: Text(blackMove)),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  // =========================
  void onSquareTap(int row, int col) {
    if (gameOver) return;
    if (aiThinking) return;

    setState(() {
      String piece = board.board[row][col];

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
      } else {
        Move? chosen;

        for (var m in currentLegalMoves) {
          if (m.endRow == row && m.endCol == col) {
            chosen = m;
            break;
          }
        }

        if (chosen != null) {
          board.makeMove(chosen);
          var state = evaluateGameState(board);
          _handleGameState(state);

          setState(() {});
          _maybeTriggerAI();
        }

        selectedRow = null;
        selectedCol = null;
        currentLegalMoves = [];
      }
    });
  }

  Future<void> _maybeTriggerAI() async {
    if (gameOver) return;

    if (board.turn != aiColor) return;

    setState(() {
      aiThinking = true;
      status = "AI is thinking...";
    });

    final move = await AIService.getBestMove(board);

    if (move == null) {
      setState(() {
        aiThinking = false;
        status = "AI failed";
      });
      return;
    }

    setState(() {
      board.makeMove(move);
      aiThinking = false;

      var state = evaluateGameState(board);
      _handleGameState(state);

      status = "Your move";
    });
  }

  // =========================
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(title: const Text("Chess"), centerTitle: true),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // =========================
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(12),
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

        _buildStatus(),
        _buildMoveHistoryPanel(),
        _buildControls(),
      ],
    );
  }

  // =========================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
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

        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildMoveHistoryPanel(),
              _buildStatus(),
              _buildControls(),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Text(
        aiThinking ? "AI is thinking..." : status,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildMoveHistoryPanel() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(children: _buildMoveHistory()),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: board.moveHistory.isEmpty ? null : _undoMove,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          IconButton(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // =========================
  void _handleGameState(GameState state) {
    switch (state) {
      case GameState.check:
        status = "${board.turn == "white" ? "White" : "Black"} in check";
        break;
      case GameState.checkmate:
        status = "${board.turn == "white" ? "Black" : "White"} wins";
        gameOver = true;
        _showGameOverDialog(status);
        break;
      case GameState.stalemate:
        status = "Draw";
        gameOver = true;
        _showGameOverDialog(status);
        break;
      default:
        status = board.turn == "white"
            ? "White to move"
            : "Black to move";
    }
  }

  void _showGameOverDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
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

      // undo AI move first if present
      board.undoMove();

      // undo player move
      if (board.moveHistory.isNotEmpty) {
        board.undoMove();
      }

      var state = evaluateGameState(board);

      gameOver = false;
      _handleGameState(state);

      selectedRow = null;
      selectedCol = null;
      currentLegalMoves = [];
    });
  }
}