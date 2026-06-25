import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';

enum CityHexEdge { northEast, southEast, south, southWest, northWest, north }

class CityTerritoryBoundaryEdge {
  final CityHex hex;
  final CityHexEdge side;

  const CityTerritoryBoundaryEdge({required this.hex, required this.side});

  @override
  bool operator ==(Object other) =>
      other is CityTerritoryBoundaryEdge &&
      other.hex == hex &&
      other.side == side;

  @override
  int get hashCode => Object.hash(hex, side);
}

abstract final class CityTerritoryBoundary {
  static const List<CityHexEdge> _neighborSides = [
    CityHexEdge.northEast,
    CityHexEdge.southEast,
    CityHexEdge.south,
    CityHexEdge.southWest,
    CityHexEdge.northWest,
    CityHexEdge.north,
  ];

  static List<CityTerritoryBoundaryEdge> edgesFor(Iterable<CityHex> hexes) {
    final territory = hexes.toSet();
    if (territory.isEmpty) return const [];

    final edges = <CityTerritoryBoundaryEdge>[];

    for (final hex in territory) {
      final neighbors = HexGridTopology.neighbors(col: hex.col, row: hex.row);
      for (var i = 0; i < neighbors.length; i++) {
        final neighbor = neighbors[i];
        final neighborHex = CityHex(col: neighbor.col, row: neighbor.row);
        if (territory.contains(neighborHex)) continue;

        edges.add(CityTerritoryBoundaryEdge(hex: hex, side: _neighborSides[i]));
      }
    }

    return List.unmodifiable(edges);
  }
}
