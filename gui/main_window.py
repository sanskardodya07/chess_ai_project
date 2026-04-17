from PyQt6.QtWidgets import QMainWindow

from gui.chessboard_widget import ChessBoardWidget


class MainWindow(QMainWindow):

    def __init__(self, board, player_color):
        super().__init__()

        self.setWindowTitle("Chess")

        self.board_widget = ChessBoardWidget(board,player_color)

        self.setCentralWidget(self.board_widget)

        self.setFixedSize(640,640)