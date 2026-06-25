/// Pure odd-q flat-top hex grid topology helpers.
abstract final class HexGridTopology {
  /// Returns the six adjacent coordinates for the odd-q layout used by the map.
  static List<({int col, int row})> neighbors({
    required int col,
    required int row,
  }) {
    if (col.isOdd) {
      return [
        (col: col + 1, row: row),
        (col: col + 1, row: row + 1),
        (col: col, row: row + 1),
        (col: col - 1, row: row + 1),
        (col: col - 1, row: row),
        (col: col, row: row - 1),
      ];
    }

    return [
      (col: col + 1, row: row - 1),
      (col: col + 1, row: row),
      (col: col, row: row + 1),
      (col: col - 1, row: row),
      (col: col - 1, row: row - 1),
      (col: col, row: row - 1),
    ];
  }

  static bool areNeighbors({
    required int col,
    required int row,
    required int targetCol,
    required int targetRow,
  }) => neighbors(
    col: col,
    row: row,
  ).any((tile) => tile.col == targetCol && tile.row == targetRow);
}
