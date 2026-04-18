import '../models/move.dart';

String getMoveNotation(Move move) {
  String piece = move.pieceMoved[1];

  String pieceSymbol = "";
  if (piece == "N") pieceSymbol = "N";
  if (piece == "B") pieceSymbol = "B";
  if (piece == "R") pieceSymbol = "R";
  if (piece == "Q") pieceSymbol = "Q";
  if (piece == "K") pieceSymbol = "K";

  String file = String.fromCharCode('a'.codeUnitAt(0) + move.endCol);
  String rank = (8 - move.endRow).toString();

  String capture = move.pieceCaptured != "" ? "x" : "";

  // pawn special case
  if (piece == "P") {
    if (capture != "") {
      String startFile =
          String.fromCharCode('a'.codeUnitAt(0) + move.startCol);
      return "$startFile$capture$file$rank";
    }
    return "$file$rank";
  }

  return "$pieceSymbol$capture$file$rank";
}