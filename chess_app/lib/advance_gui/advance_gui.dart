import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/move.dart';
import 'move_service.dart';

/// Advanced Chess GUI with modern features
/// Responsive design for mobile, tablet, and desktop
class AdvancedChessBoard extends StatefulWidget {
  final Board board;
  final Function(int row, int col) onSquareTap;
  final int? selectedRow;
  final int? selectedCol;
  final Move? lastMove;
  final bool isKingInCheck;
  final (int, int)? kingInCheckPosition;

  const AdvancedChessBoard({
    super.key,
    required this.board,
    required this.onSquareTap,
    this.selectedRow,
    this.selectedCol,
    this.lastMove,
    this.isKingInCheck = false,
    this.kingInCheckPosition,
  });

  @override
  State<AdvancedChessBoard> createState() => _AdvancedChessBoardState();
}

class _AdvancedChessBoardState extends State<AdvancedChessBoard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1200;

        double boardSize = isMobile
            ? screenWidth * 0.95
            : isTablet
                ? screenWidth * 0.7
                : screenHeight * 0.8;

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildBoard(boardSize),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard(double boardSize) {
    double squareSize = boardSize / 8;

    return Stack(
      children: [
        // Board squares
        for (int row = 0; row < 8; row++)
          for (int col = 0; col < 8; col++)
            Positioned(
              left: col * squareSize,
              top: row * squareSize,
              child: _buildSquare(row, col, squareSize),
            ),

        // Coordinates
        _buildCoordinates(squareSize),
      ],
    );
  }

  Widget _buildSquare(int row, int col, double squareSize) {
    bool isLight = (row + col) % 2 == 0;
    Color baseColor = isLight ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);

    // Highlight logic
    Color? highlightColor;

    // Selected piece highlight
    if (widget.selectedRow == row && widget.selectedCol == col) {
      highlightColor = const Color.fromRGBO(33, 150, 243, 0.6);
    }
    // Last move highlight
    else if (widget.lastMove != null &&
        ((widget.lastMove!.startRow == row && widget.lastMove!.startCol == col) ||
         (widget.lastMove!.endRow == row && widget.lastMove!.endCol == col))) {
      highlightColor = const Color.fromRGBO(255, 235, 59, 0.4);
    }
    // King in check highlight
    else if (widget.isKingInCheck &&
        widget.kingInCheckPosition != null &&
        widget.kingInCheckPosition!.$1 == row &&
        widget.kingInCheckPosition!.$2 == col) {
      highlightColor = const Color.fromRGBO(244, 67, 54, 0.7);
    }

    return GestureDetector(
      onTap: () => widget.onSquareTap(row, col),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: (widget.selectedRow == row && widget.selectedCol == col)
                ? _scaleAnimation.value
                : 1.0,
            child: Container(
              width: squareSize,
              height: squareSize,
              color: highlightColor ?? baseColor,
              child: _buildPiece(row, col, squareSize),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPiece(int row, int col, double squareSize) {
    String piece = widget.board.board[row][col];
    if (piece.isEmpty) return const SizedBox.shrink();

    // Get the image path for the piece
    String imagePath = 'assets/pieces/$piece.png';

    return Center(
      child: Container(
        width: squareSize * 0.85, // Slightly smaller to fit nicely
        height: squareSize * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.2),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain, // This will scale the image to fit within the container
          errorBuilder: (context, error, stackTrace) {
            // Fallback to text if image fails to load
            return Container(
              decoration: BoxDecoration(
                color: piece.startsWith('w') ? Colors.white : Colors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  piece.substring(1),
                  style: TextStyle(
                    color: piece.startsWith('w') ? Colors.black : Colors.white,
                    fontSize: squareSize * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoordinates(double squareSize) {
    List<String> files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    List<String> ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    return Stack(
      children: [
        // File labels (bottom)
        for (int i = 0; i < 8; i++)
          Positioned(
            left: i * squareSize + squareSize * 0.05,
            top: 7 * squareSize + squareSize * 0.7,
            child: Text(
              files[i],
              style: TextStyle(
                color: Colors.black87,
                fontSize: squareSize * 0.15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Rank labels (left)
        for (int i = 0; i < 8; i++)
          Positioned(
            left: squareSize * 0.05,
            top: i * squareSize + squareSize * 0.05,
            child: Text(
              ranks[i],
              style: TextStyle(
                color: Colors.black87,
                fontSize: squareSize * 0.15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

/// Enhanced Game Screen with advanced features
class AdvancedGameScreen extends StatefulWidget {
  const AdvancedGameScreen({super.key});

  @override
  State<AdvancedGameScreen> createState() => _AdvancedGameScreenState();
}

class _AdvancedGameScreenState extends State<AdvancedGameScreen>
    with TickerProviderStateMixin {
  late Board board;
  late MoveService moveService;

  int? selectedRow;
  int? selectedCol;
  Move? lastMove;
  bool isKingInCheck = false;
  (int, int)? kingInCheckPosition;

  List<String> moveHistory = [];
  List<String> capturedPieces = [];
  List<String> capturedPiecesPerMove = []; // Track captured pieces per move

  late AnimationController _statusAnimationController;
  late Animation<double> _statusAnimation;

  @override
  void initState() {
    super.initState();
    board = Board();
    moveService = MoveService(board);

    _statusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _statusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statusAnimationController, curve: Curves.elasticOut),
    );

    _updateGameState();
  }

  @override
  void dispose() {
    _statusAnimationController.dispose();
    super.dispose();
  }

  void _updateGameState() {
    setState(() {
      isKingInCheck = moveService.isCurrentPlayerInCheck();
      if (isKingInCheck) {
        kingInCheckPosition = board.turn == "white" ? board.whiteKing : board.blackKing;
      } else {
        kingInCheckPosition = null;
      }
    });
  }

  void _onSquareTap(int row, int col) {
    setState(() {
      String piece = board.board[row][col];

      // First tap - select piece
      if (selectedRow == null) {
        if (piece.isNotEmpty && _isCurrentPlayerPiece(piece)) {
          selectedRow = row;
          selectedCol = col;
          _statusAnimationController.forward(from: 0.0);
        }
        return;
      }

      // Second tap - try move
      if (selectedRow == row && selectedCol == col) {
        // Deselect if tapping same square
        selectedRow = null;
        selectedCol = null;
        return;
      }

      // Create move
      Move attemptedMove = Move(
        startRow: selectedRow!,
        startCol: selectedCol!,
        endRow: row,
        endCol: col,
        pieceMoved: board.board[selectedRow!][selectedCol!],
        pieceCaptured: piece,
      );

      // Try to make move
      if (moveService.makeMove(attemptedMove)) {
        lastMove = attemptedMove;
        _addToMoveHistory(attemptedMove);
        if (attemptedMove.pieceCaptured.isNotEmpty) {
          capturedPieces.add(attemptedMove.pieceCaptured);
          capturedPiecesPerMove.add(attemptedMove.pieceCaptured);
        } else {
          capturedPiecesPerMove.add(""); // No capture for this move
        }

        // Check for game end
        GameResult? result = moveService.getGameResult();
        if (result != null) {
          _showGameEndDialog(result);
        }
      }

      selectedRow = null;
      selectedCol = null;
      _updateGameState();
    });
  }

  bool _isCurrentPlayerPiece(String piece) {
    return (board.turn == "white" && piece.startsWith("w")) ||
           (board.turn == "black" && piece.startsWith("b"));
  }

  void _addToMoveHistory(Move move) {
    String moveNotation = _getAlgebraicNotation(move);
    moveHistory.add(moveNotation);
  }

  String _getAlgebraicNotation(Move move) {
    // Simple algebraic notation (can be enhanced)
    String piece = move.pieceMoved.substring(1);
    String endFile = String.fromCharCode(97 + move.endCol);
    String endRank = (8 - move.endRow).toString();

    String notation = piece;
    if (piece == "P") notation = ""; // Pawns don't show piece letter

    notation += endFile + endRank;

    if (move.pieceCaptured.isNotEmpty) {
      notation = "x" + notation;
    }

    return notation;
  }

  void _showGameEndDialog(GameResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(result.isDraw ? 'Draw!' : 'Game Over!'),
        content: Text(result.getMessage()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      moveService.resetGame();
      selectedRow = null;
      selectedCol = null;
      lastMove = null;
      isKingInCheck = false;
      kingInCheckPosition = null;
      moveHistory.clear();
      capturedPieces.clear();
      capturedPiecesPerMove.clear();
    });
  }

  void _undoMove() {
    setState(() {
      if (moveService.undoMove()) {
        // Remove last move from history
        if (moveHistory.isNotEmpty) {
          moveHistory.removeLast();
        }
        // Remove captured piece if the last move captured something
        if (capturedPiecesPerMove.isNotEmpty) {
          String lastCaptured = capturedPiecesPerMove.removeLast();
          if (lastCaptured.isNotEmpty && capturedPieces.isNotEmpty) {
            capturedPieces.removeLast();
          }
        }
        selectedRow = null;
        selectedCol = null;
        lastMove = moveHistory.isNotEmpty ? moveService.getLastMove() : null;
        _updateGameState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        title: const Text("Advanced Chess"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          bool isLandscape = orientation == Orientation.landscape;
          bool isWideScreen = MediaQuery.of(context).size.width > 1200;

          return isLandscape || isWideScreen
              ? _buildLandscapeLayout()
              : _buildPortraitLayout();
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Game status
        _buildGameStatus(),

        // Chess board
        Expanded(
          flex: 3,
          child: AdvancedChessBoard(
            board: board,
            onSquareTap: _onSquareTap,
            selectedRow: selectedRow,
            selectedCol: selectedCol,
            lastMove: lastMove,
            isKingInCheck: isKingInCheck,
            kingInCheckPosition: kingInCheckPosition,
          ),
        ),

        // Controls
        _buildControls(),

        // Move history
        _buildMoveHistory(),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left panel
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildGameStatus(),
              _buildMoveHistory(),
            ],
          ),
        ),

        // Chess board
        Expanded(
          flex: 2,
          child: AdvancedChessBoard(
            board: board,
            onSquareTap: _onSquareTap,
            selectedRow: selectedRow,
            selectedCol: selectedCol,
            lastMove: lastMove,
            isKingInCheck: isKingInCheck,
            kingInCheckPosition: kingInCheckPosition,
          ),
        ),

        // Right panel
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildCapturedPieces(),
              _buildControls(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameStatus() {
    String statusText = isKingInCheck
        ? "${board.turn} is in check!"
        : "${board.turn}'s turn";

    return AnimatedBuilder(
      animation: _statusAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isKingInCheck
                ? const Color.fromRGBO(244, 67, 54, 0.2)
                : const Color.fromRGBO(33, 150, 243, 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isKingInCheck ? Colors.red : Colors.blue,
              width: 2,
            ),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isKingInCheck ? Colors.red : Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.undo,
            label: "Undo",
            onPressed: _undoMove,
          ),
          _buildControlButton(
            icon: Icons.refresh,
            label: "Reset",
            onPressed: _resetGame,
          ),
          _buildControlButton(
            icon: Icons.info,
            label: "Info",
            onPressed: () => _showGameInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[800],
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMoveHistory() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Move History",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: moveHistory.length,
                itemBuilder: (context, index) {
                  return Text(
                    '${index + 1}. ${moveHistory[index]}',
                    style: const TextStyle(color: Colors.white70),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedPieces() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Captured Pieces",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: capturedPieces.map((piece) {
              return Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/pieces/$piece.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: piece.startsWith('w') ? Colors.white : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          piece.substring(1),
                          style: TextStyle(
                            color: piece.startsWith('w') ? Colors.black : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showGameInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Turn: ${board.turn}"),
            Text("Moves: ${moveHistory.length}"),
            Text("Half-moves: ${board.halfMoveCount}"),
            if (isKingInCheck) const Text("King is in check!", style: TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}