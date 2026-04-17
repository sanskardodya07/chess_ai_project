import 'package:flutter/material.dart';
import '../widgets/chess_board.dart';
import '../models/board.dart';
import '../logic/move_generator.dart';
import '../logic/rule_checker.dart';
import '../models/move.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {

  Board board = Board();

  int? selectedRow;
  int? selectedCol;

  String currentTurn = "white"; // 🔥 NEW
  String status = "White to move";

  // 🧠 helper
  String getPieceColor(String piece) {
    if (piece.startsWith("w")) return "white";
    if (piece.startsWith("b")) return "black";
    return "";
  }

  void switchTurn() {
    currentTurn = (currentTurn == "white") ? "black" : "white";
    status = currentTurn == "white" ? "White to move" : "Black to move";
  }

  // 🖱️ HANDLE TAP
  void onSquareTap(int row, int col) {
    setState(() {
      String piece = board.board[row][col];

      if (selectedRow == null) {
        if (piece == "") return;
        if (board.turn == "white" && piece[0] != "w") return;
        if (board.turn == "black" && piece[0] != "b") return;

        selectedRow = row;
        selectedCol = col;
      } else {
        List<Move> moves = generateAllMoves(board);
        moves = filterLegalMoves(board, moves);

        Move? chosen;

        for (var m in moves) {
          if (m.startRow == selectedRow &&
              m.startCol == selectedCol &&
              m.endRow == row &&
              m.endCol == col) {
            chosen = m;
            break;
          }
        }

        if (chosen != null) {
          board.makeMove(chosen);
        }

        selectedRow = null;
        selectedCol = null;
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
                  board: board.board,
                  selectedRow: selectedRow,
                  selectedCol: selectedCol,
                  onTap: onSquareTap,
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
              IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.refresh)),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}