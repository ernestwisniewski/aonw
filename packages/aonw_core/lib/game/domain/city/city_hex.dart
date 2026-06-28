import 'package:aonw_core/game/domain/hex.dart';

class CityHex {
  final int col;
  final int row;

  const CityHex({required this.col, required this.row});

  factory CityHex.fromJson(Map<String, dynamic> json) {
    return CityHex(
      col: (json['col'] as num).toInt(),
      row: (json['row'] as num).toInt(),
    );
  }

  factory CityHex.fromCoordinate(HexCoordinate coordinate) =>
      CityHex(col: coordinate.col, row: coordinate.row);

  Map<String, dynamic> toJson() => {'col': col, 'row': row};

  CityHex copyWith({int? col, int? row}) {
    return CityHex(col: col ?? this.col, row: row ?? this.row);
  }

  HexCoordinate toCoordinate() => HexCoordinate(col: col, row: row);

  HexCoordinate get coordinate => toCoordinate();

  bool occupies(int targetCol, int targetRow) =>
      col == targetCol && row == targetRow;

  @override
  bool operator ==(Object other) =>
      other is CityHex && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => 'CityHex(col: $col, row: $row)';
}
