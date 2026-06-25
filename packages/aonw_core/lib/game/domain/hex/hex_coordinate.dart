import 'package:aonw_core/map/domain/map_data.dart';

class HexCoordinate {
  final int col;
  final int row;

  const HexCoordinate({required this.col, required this.row});

  factory HexCoordinate.fromTile(TileData tile) {
    return HexCoordinate(col: tile.col, row: tile.row);
  }

  factory HexCoordinate.fromJson(Map<String, dynamic> json) {
    return HexCoordinate(
      col: (json['col'] as num).toInt(),
      row: (json['row'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {'col': col, 'row': row};

  ({int col, int row}) toRecord() => (col: col, row: row);

  bool occupies(int targetCol, int targetRow) {
    return col == targetCol && row == targetRow;
  }

  @override
  bool operator ==(Object other) {
    return other is HexCoordinate && other.col == col && other.row == row;
  }

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => 'HexCoordinate(col: $col, row: $row)';
}
