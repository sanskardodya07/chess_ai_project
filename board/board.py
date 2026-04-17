from board.constants import *
from board.move import Move
from board.move_generator import generate_all_moves
from board.rule_checker import filter_legal_moves, is_in_check


class Board:

    def __init__(self):

        self.board = [
            ["bR","bN","bB","bQ","bK","bB","bN","bR"],
            ["bP","bP","bP","bP","bP","bP","bP","bP"],
            ["","","","","","","",""],
            ["","","","","","","",""],
            ["","","","","","","",""],
            ["","","","","","","",""],
            ["wP","wP","wP","wP","wP","wP","wP","wP"],
            ["wR","wN","wB","wQ","wK","wB","wN","wR"]
        ]

        self.turn = WHITE

        self.white_king = (7,4)
        self.black_king = (0,4)

        self.move_history = []

        self.en_passant_target = None

        self.castling_rights = {
            "wK": True,
            "wQ": True,
            "bK": True,
            "bQ": True
        }

    def make_move(self,move):

        move.prev_en_passant = (None if self.en_passant_target is None else tuple(self.en_passant_target))
        move.prev_castling_rights = self.castling_rights.copy()  # ✅ FIX
        move.prev_white_king = self.white_king
        move.prev_black_king = self.black_king

        self.board[move.start_row][move.start_col] = ""
        self.board[move.end_row][move.end_col] = move.piece_moved

        if move.promotion:
            self.board[move.end_row][move.end_col] = move.piece_moved[0] + move.promotion

        # ✅ EN PASSANT
        if move.is_en_passant:
            r, c = move.en_passant_capture_pos
            self.board[r][c] = ""

        # ✅ UPDATE EN PASSANT TARGET
        self.en_passant_target = None
        if move.piece_moved[1] == "P" and abs(move.start_row - move.end_row) == 2:
            mid_row = (move.start_row + move.end_row) // 2
            self.en_passant_target = (mid_row, move.start_col)

        # ✅ CASTLING
        if move.is_castling:
            if move.end_col == 6:  # kingside
                self.board[move.end_row][7] = ""
                self.board[move.end_row][5] = move.piece_moved[0] + "R"
            else:  # queenside
                self.board[move.end_row][0] = ""
                self.board[move.end_row][3] = move.piece_moved[0] + "R"

        # KING UPDATE
        if move.piece_moved == "wK":
            self.white_king = (move.end_row, move.end_col)
        elif move.piece_moved == "bK":
            self.black_king = (move.end_row, move.end_col)

        # CASTLING RIGHTS
        if move.piece_moved == "wK":
            self.castling_rights["wK"] = False
            self.castling_rights["wQ"] = False

        elif move.piece_moved == "bK":
            self.castling_rights["bK"] = False
            self.castling_rights["bQ"] = False

        elif move.piece_moved == "wR":
            if move.start_col == 0:
                self.castling_rights["wQ"] = False
            elif move.start_col == 7:
                self.castling_rights["wK"] = False

        elif move.piece_moved == "bR":
            if move.start_col == 0:
                self.castling_rights["bQ"] = False
            elif move.start_col == 7:
                self.castling_rights["bK"] = False

        self.move_history.append(move)
        self.turn = BLACK if self.turn == WHITE else WHITE


    def undo_move(self):

        if not self.move_history:
            return

        move = self.move_history.pop()

        self.board[move.start_row][move.start_col] = move.piece_moved

        if move.is_en_passant:
            self.board[move.end_row][move.end_col] = ""
            r, c = move.en_passant_capture_pos
            self.board[r][c] = move.piece_captured
        else:
            self.board[move.end_row][move.end_col] = move.piece_captured

        # undo castling rook
        if move.is_castling:
            if move.end_col == 6:
                self.board[move.end_row][5] = ""
                self.board[move.end_row][7] = move.piece_moved[0] + "R"
            else:
                self.board[move.end_row][3] = ""
                self.board[move.end_row][0] = move.piece_moved[0] + "R"

        self.en_passant_target = move.prev_en_passant
        self.castling_rights = move.prev_castling_rights
        self.white_king = move.prev_white_king
        self.black_king = move.prev_black_king

        self.turn = BLACK if self.turn == WHITE else WHITE


    def get_all_legal_moves(self):

        moves = generate_all_moves(self, self.turn)
        return filter_legal_moves(self, moves, self.turn)


    def game_status(self):

        moves = self.get_all_legal_moves()

        if len(moves) == 0:

            if is_in_check(self, self.turn):
                winner = "White" if self.turn == BLACK else "Black"
                return f"{winner} wins by checkmate"
            else:
                return "Draw by stalemate"

        return "ongoing"