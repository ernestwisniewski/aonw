import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';

abstract final class HexDistance {
  static int between(HexCoordinate a, HexCoordinate b) {
    return _betweenValues(a.col, a.row, b.col, b.row);
  }

  static int betweenCoords(HexCoord a, HexCoord b) {
    return _betweenValues(a.col, a.row, b.col, b.row);
  }

  static int _betweenValues(int aCol, int aRow, int bCol, int bRow) {
    final ac = _oddQToCube(aCol, aRow);
    final bc = _oddQToCube(bCol, bRow);
    return ((ac.x - bc.x).abs() + (ac.y - bc.y).abs() + (ac.z - bc.z).abs()) ~/
        2;
  }

  static _Cube _oddQToCube(int col, int row) {
    final x = col;
    final z = row - ((col - (col & 1)) ~/ 2);
    final y = -x - z;
    return _Cube(x: x, y: y, z: z);
  }

  static int maxFrom(
    HexCoordinate origin,
    Iterable<HexCoordinate> coordinates,
  ) {
    var maxDistance = 0;
    for (final coordinate in coordinates) {
      final distance = between(origin, coordinate);
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }
    return maxDistance;
  }
}

class _Cube {
  final int x;
  final int y;
  final int z;

  const _Cube({required this.x, required this.y, required this.z});
}
