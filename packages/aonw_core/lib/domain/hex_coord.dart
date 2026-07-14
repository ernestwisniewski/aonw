/// Dependency-free odd-q coordinate owned by the world foundation.
final class HexCoord {
  const HexCoord({required this.col, required this.row});

  final int col;
  final int row;

  @override
  bool operator ==(Object other) {
    return other is HexCoord && other.col == col && other.row == row;
  }

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => 'HexCoord(col: $col, row: $row)';
}
