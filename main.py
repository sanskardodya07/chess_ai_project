# main.py

import sys

from PyQt6.QtWidgets import QApplication

from board.board import Board

from gui.main_window import MainWindow
from gui.color_dialog import ColorDialog


def main():

    app = QApplication(sys.argv)

    dialog = ColorDialog()

    if dialog.exec():

        color = dialog.color

        board = Board()

        window = MainWindow(board,color)

        window.show()

        sys.exit(app.exec())


if __name__ == "__main__":
    main()