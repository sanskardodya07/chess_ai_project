class Move:

    def __init__(self,start,end,piece_moved,piece_captured,promotion=None):

        self.start_row = start[0]
        self.start_col = start[1]

        self.end_row = end[0]
        self.end_col = end[1]

        self.piece_moved = piece_moved
        self.piece_captured = piece_captured

        self.promotion = promotion

        self.prev_en_passant = None
        self.prev_castling_rights = None
        self.prev_white_king = None
        self.prev_black_king = None

        # ✅ EN PASSANT
        self.is_en_passant = False
        self.en_passant_capture_pos = None

        # ✅ CASTLING
        self.is_castling = False

    def __repr__(self):
        return f"{self.piece_moved}: ({self.start_row},{self.start_col}) -> ({self.end_row},{self.end_col})"