import 'package:aonw_core/game/domain/fog/fog_balance.dart';
import 'package:aonw_core/game/domain/fog/fog_reveal_source.dart';
import 'package:aonw_core/game/domain/fog/fog_visibility_rules.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/terrain.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class FogRevealCalculator {
  const FogRevealCalculator();

  Set<HexCoordinate> visibleHexesFor({
    required MapData mapData,
    required Iterable<FogRevealSource> sources,
  }) {
    final visible = <HexCoordinate>{};
    for (final source in sources) {
      visible.addAll(_visibleFromSource(mapData: mapData, source: source));
    }
    return visible;
  }

  Set<HexCoordinate> _visibleFromSource({
    required MapData mapData,
    required FogRevealSource source,
  }) {
    if (mapData.tileAt(source.origin.col, source.origin.row) == null) {
      return const {};
    }

    final visible = <HexCoordinate>{source.origin};
    final bestCosts = <HexCoordinate, int>{source.origin: 0};
    final frontier = <_SightNode>[_SightNode(hex: source.origin, cost: 0)];

    while (frontier.isNotEmpty) {
      frontier.sort(_compareNodes);
      final current = frontier.removeAt(0);
      if (current.cost != bestCosts[current.hex]) continue;

      final isOrigin = current.hex == source.origin;

      for (final neighbor in HexNeighbors.existingAround(
        current.hex,
        mapData,
      )) {
        final tile = mapData.tileAt(neighbor.col, neighbor.row);
        if (tile == null) continue;

        final sightCost = FogVisibilityRules.sightCost(
          TileTerrainProfileRules.fromTile(tile),
        );
        final nextCost = current.cost + sightCost.value;

        // Direct neighbours of the observer are always revealed regardless of
        // sight cost — the player can always see what is immediately around them.
        final alwaysVisible = isOrigin;
        if (!alwaysVisible && nextCost > source.range) continue;

        visible.add(neighbor);

        final knownCost = bestCosts[neighbor];
        if (knownCost != null && knownCost <= nextCost) continue;
        bestCosts[neighbor] = nextCost;

        // Terrain blocking (mountain): takes priority over elevation check.
        if (sightCost.blocksPropagation) continue;

        // Elevation blocking: tiles significantly higher than the *original observer*
        // are visible (you see the ridge) but block propagation behind them.
        // Blocking is always relative to source.observerHeight (the unit's tile height),
        // not to the current BFS node — this is intentional: a unit at h=0 that sees
        // a h=1 intermediate tile cannot then "inherit" that height for further checks.
        if (tile.height >
            source.observerHeight + FogBalance.elevationBlockingThreshold) {
          continue;
        }

        // Only propagate further if within normal sight range.
        if (nextCost > source.range) continue;

        frontier.add(_SightNode(hex: neighbor, cost: nextCost));
      }
    }

    return visible;
  }

  int _compareNodes(_SightNode a, _SightNode b) {
    final cost = a.cost.compareTo(b.cost);
    if (cost != 0) return cost;
    final col = a.hex.col.compareTo(b.hex.col);
    if (col != 0) return col;
    return a.hex.row.compareTo(b.hex.row);
  }
}

class _SightNode {
  final HexCoordinate hex;
  final int cost;

  const _SightNode({required this.hex, required this.cost});
}
