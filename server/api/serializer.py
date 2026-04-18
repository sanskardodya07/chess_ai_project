def move_to_json(move):
    return {
        "startRow": move.start_row,
        "startCol": move.start_col,
        "endRow": move.end_row,
        "endCol": move.end_col,
        "pieceMoved": move.piece_moved,
        "pieceCaptured": move.piece_captured,
        "promotion": move.promotion,
        "isEnPassant": move.is_en_passant,
        "isCastling": move.is_castling,
    }
