import os
from PyQt6.QtWidgets import QWidget, QGridLayout, QPushButton, QMessageBox, QApplication
from PyQt6.QtGui import QIcon
from PyQt6.QtCore import QSize, QTimer

from board.rule_checker import is_in_check


class ChessBoardWidget(QWidget):

    def __init__(self, board, player_color):
        super().__init__()

        self.board = board
        self.player_color = player_color
        self.ai_color = "black" if self.player_color == "white" else "white"

        self.selected = None
        self.legal_moves = []

        self.grid = QGridLayout()
        self.setLayout(self.grid)

        self.squares = [[None for _ in range(8)] for _ in range(8)]

        self.load_pieces()
        self.create_board()
        self.update_board()

        if self.player_color == "black":
            from agent.reasoning.minimax import get_best_move

            ai_move = get_best_move(self.board, 3)

            if ai_move:
                self.board.make_move(ai_move)

            self.update_board()

    # ----------------------------
    # Load piece images
    # ----------------------------

    def load_pieces(self):

        base = os.path.join(os.path.dirname(__file__), "assets", "pieces")

        self.images = {}

        pieces = [
            "wP","wR","wN","wB","wQ","wK",
            "bP","bR","bN","bB","bQ","bK"
        ]

        for p in pieces:
            path = os.path.join(base, f"{p}.png")
            self.images[p] = QIcon(path)

    # ----------------------------
    # Create grid buttons
    # ----------------------------

    def create_board(self):

        for r in range(8):
            for c in range(8):

                btn = QPushButton()
                btn.setFixedSize(80, 80)

                btn.clicked.connect(lambda _, row=r, col=c: self.square_clicked(row, col))

                self.grid.addWidget(btn, r, c)
                self.squares[r][c] = btn

    # ----------------------------
    # Convert GUI coords to board
    # ----------------------------

    def to_board_coords(self, r, c):

        if self.player_color == "white":
            return r, c
        else:
            return 7 - r, 7 - c

    # ----------------------------
    # Update piece display
    # ----------------------------

    def update_board(self):

        last_move = None
        if self.board.move_history:
            last_move = self.board.move_history[-1]

        white_in_check = is_in_check(self.board, "white")
        black_in_check = is_in_check(self.board, "black")

        for r in range(8):
            for c in range(8):

                br, bc = self.to_board_coords(r, c)

                piece = self.board.board[br][bc]
                btn = self.squares[r][c]

                # 🎨 Better board colors
                if (r + c) % 2 == 0:
                    color = "#eeeed2"
                else:
                    color = "#769656"

                # last move highlight
                if last_move:
                    if (br, bc) == (last_move.start_row, last_move.start_col) or \
                       (br, bc) == (last_move.end_row, last_move.end_col):
                        color = "#f6f669"

                # check highlight
                if white_in_check and (br, bc) == self.board.white_king:
                    color = "#ff4d4d"

                if black_in_check and (br, bc) == self.board.black_king:
                    color = "#ff4d4d"

                # selection highlight
                if self.selected:
                    if (br, bc) == self.selected:
                        color = "#f7ec59"

                btn.setStyleSheet(f"background-color: {color};")

                if piece != "":
                    btn.setIcon(self.images[piece])
                    btn.setIconSize(QSize(60, 60))
                else:
                    btn.setIcon(QIcon())

    # ----------------------------
    # Handle click
    # ----------------------------

    def square_clicked(self, r, c):

        br, bc = self.to_board_coords(r, c)

        if self.selected is None:

            piece = self.board.board[br][bc]

            if piece == "":
                return

            if self.board.turn == "white" and piece[0] != "w":
                return

            if self.board.turn == "black" and piece[0] != "b":
                return

            self.selected = (br, bc)

            moves = self.board.get_all_legal_moves()
            self.legal_moves = [m for m in moves if (m.start_row, m.start_col) == self.selected]

            self.update_board()
            return

        else:

            # deselect
            if (br, bc) == self.selected:
                self.selected = None
                self.legal_moves = []
                self.update_board()
                return

            # switch selection
            piece = self.board.board[br][bc]

            if piece != "":
                if (self.board.turn == "white" and piece[0] == "w") or \
                   (self.board.turn == "black" and piece[0] == "b"):

                    self.selected = (br, bc)
                    moves = self.board.get_all_legal_moves()
                    self.legal_moves = [m for m in moves if (m.start_row, m.start_col) == self.selected]

                    self.update_board()
                    return

            # find move
            move = None
            for m in self.legal_moves:
                if (m.end_row, m.end_col) == (br, bc):
                    move = m
                    break

            if move:

                # 🔥 fake animation start (remove piece visually)
                self.board.board[move.start_row][move.start_col] = ""
                self.update_board()
                QApplication.processEvents()

                def finish_human_move():

                    # restore + apply move
                    self.board.board[move.start_row][move.start_col] = move.piece_moved
                    self.board.make_move(move)

                    self.selected = None
                    self.legal_moves = []

                    self.update_board()

                    status = self.board.game_status()

                    if status != 'ongoing':
                        self.setEnabled(False)
                        QTimer.singleShot(200, lambda: QMessageBox.information(self, "Game Over", status))
                        return

                    # AI TURN
                    if self.board.turn == self.ai_color:
                        QTimer.singleShot(200, self.make_ai_move)

                QTimer.singleShot(120, finish_human_move)

    # ----------------------------
    # AI MOVE (with animation)
    # ----------------------------

    def make_ai_move(self):

        from agent.reasoning.alpha_beta import get_best_move

        ai_move = get_best_move(self.board, depth=3)

        print("AI makes move")

        if ai_move:

            # fake animation start
            self.board.board[ai_move.start_row][ai_move.start_col] = ""
            self.update_board()
            QApplication.processEvents()

            def finish_ai_move():

                self.board.board[ai_move.start_row][ai_move.start_col] = ai_move.piece_moved
                self.board.make_move(ai_move)

                self.update_board()

                status = self.board.game_status()

                if status != 'ongoing':
                    self.setEnabled(False)
                    QTimer.singleShot(200, lambda: QMessageBox.information(self, 'Game Over', status))

            QTimer.singleShot(120, finish_ai_move)