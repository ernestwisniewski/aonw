import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';

abstract final class CityTerritoryRules {
  static bool isConnected({
    required CityHex center,
    required Iterable<CityHex> controlledHexes,
  }) {
    return areHexesConnected([center, ...controlledHexes]);
  }

  static bool areHexesConnected(Iterable<CityHex> hexes) {
    final territory = hexes.toSet();
    if (territory.length < 2) return true;

    final start = territory.first;
    final visited = <CityHex>{start};
    final frontier = <CityHex>[start];

    while (frontier.isNotEmpty) {
      final current = frontier.removeLast();
      for (final neighbor in HexGridTopology.neighbors(
        col: current.col,
        row: current.row,
      )) {
        final hex = CityHex(col: neighbor.col, row: neighbor.row);
        if (!territory.contains(hex) || !visited.add(hex)) continue;
        frontier.add(hex);
      }
    }

    return visited.length == territory.length;
  }

  static int distance({
    required CityHex from,
    required CityHex to,
    required int maxDistance,
  }) {
    if (from == to) return 0;

    var frontier = <CityHex>[from];
    final visited = <CityHex>{from};

    for (var distance = 1; distance <= maxDistance; distance++) {
      final next = <CityHex>[];
      for (final current in frontier) {
        for (final neighbor in HexGridTopology.neighbors(
          col: current.col,
          row: current.row,
        )) {
          final hex = CityHex(col: neighbor.col, row: neighbor.row);
          if (!visited.add(hex)) continue;
          if (hex == to) return distance;
          next.add(hex);
        }
      }
      frontier = next;
    }

    return maxDistance + 1;
  }

  static bool hasExpansionSupport({
    required CityHex center,
    required Iterable<CityHex> controlledHexes,
    required CityHex target,
    required int maxDistance,
    int requiredPreviousRingNeighbors = 2,
  }) {
    final targetDistance = distance(
      from: center,
      to: target,
      maxDistance: maxDistance,
    );
    if (targetDistance > maxDistance) return false;
    if (targetDistance <= 1) return true;

    final controlled = controlledHexes.toSet();
    var supportCount = 0;
    for (final neighbor in HexGridTopology.neighbors(
      col: target.col,
      row: target.row,
    )) {
      final hex = CityHex(col: neighbor.col, row: neighbor.row);
      if (!controlled.contains(hex)) continue;
      final neighborDistance = distance(
        from: center,
        to: hex,
        maxDistance: targetDistance,
      );
      if (neighborDistance == targetDistance - 1) {
        supportCount += 1;
        if (supportCount >= requiredPreviousRingNeighbors) return true;
      }
    }

    return false;
  }
}
