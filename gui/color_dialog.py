#color_dialog.py

from PyQt6.QtWidgets import QDialog, QPushButton, QVBoxLayout, QLabel


class ColorDialog(QDialog):

    def __init__(self):
        super().__init__()

        self.setWindowTitle("Choose Color")
        self.color = None

        layout = QVBoxLayout()

        label = QLabel("Choose your color")
        layout.addWidget(label)

        white_btn = QPushButton("Play White")
        black_btn = QPushButton("Play Black")

        white_btn.clicked.connect(self.choose_white)
        black_btn.clicked.connect(self.choose_black)

        layout.addWidget(white_btn)
        layout.addWidget(black_btn)

        self.setLayout(layout)

    def choose_white(self):
        self.color = "white"
        self.accept()

    def choose_black(self):
        self.color = "black"
        self.accept()