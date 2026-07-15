import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class HexNeighbors {
  static List<HexCoordinate> around(HexCoordinate coordinate) {
    return [
      for (final neighbor in HexGridTopology.neighbors(
        col: coordinate.col,
        row: coordinate.row,
      ))
        HexCoordinate(col: neighbor.col, row: neighbor.row),
    ];
  }

  static Iterable<HexCoordinate> existingAround(
    HexCoordinate coordinate,
    MapTileLookup mapTiles,
  ) sync* {
    for (final neighbor in around(coordinate)) {
      if (mapTiles.tileAt(neighbor.col, neighbor.row) == null) continue;
      yield neighbor;
    }
  }
}
