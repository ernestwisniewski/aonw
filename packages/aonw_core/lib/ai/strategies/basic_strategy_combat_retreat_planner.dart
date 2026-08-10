part of 'basic_strategy_combat_reactions_planner.dart';

extension _BasicStrategyCombatRetreatPlanner
    on BasicStrategyCombatReactionsPlanner {
  MoveUnitCommand? _moveAwayFromEnemies({
    required GameUnit unit,
    required GameView view,
    required AiContext context,
    required Set<String> occupied,
  }) {
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: view.movementBlockingUnits,
      canEnterTile: (tile) =>
          view.visibility.canSeeDynamicAt(tile.col, tile.row) &&
          !occupied.contains(_key(tile.col, tile.row)),
    );

    final candidates = <_RetreatCandidate>[];
    for (final hex in HexNeighbors.existingAround(
      HexCoordinate(col: unit.col, row: unit.row),
      context.mapData,
    )) {
      if (occupied.contains(_key(hex.col, hex.row))) continue;
      final tile = context.mapData.tileAt(hex.col, hex.row);
      if (tile == null ||
          !view.visibility.canSeeDynamicAt(tile.col, tile.row)) {
        continue;
      }

      final plan = pathfinder.plan(unit: unit, targetTile: tile);
      if (plan == null || plan.totalCost > unit.movementPoints) continue;
      candidates.add(
        _RetreatCandidate(
          tile: tile,
          nearestEnemyDistance: _nearestEnemyDistance(tile, view),
        ),
      );
    }

    candidates.sort((a, b) {
      final distanceCompare = b.nearestEnemyDistance.compareTo(
        a.nearestEnemyDistance,
      );
      if (distanceCompare != 0) return distanceCompare;
      final colCompare = a.tile.col.compareTo(b.tile.col);
      if (colCompare != 0) return colCompare;
      return a.tile.row.compareTo(b.tile.row);
    });

    if (candidates.isEmpty) return null;
    final target = candidates.first.tile;
    return MoveUnitCommand(unit.id, target.col, target.row);
  }

  int _nearestEnemyDistance(MapTileView tile, GameView view) {
    final origin = HexCoordinate(col: tile.col, row: tile.row);
    var nearest = 1 << 30;
    for (final enemy in view.visibleTargetableEnemyUnits) {
      if (!AiUnitRoles.isMilitaryUnit(enemy)) continue;
      final distance = HexDistance.between(
        origin,
        HexCoordinate(col: enemy.col, row: enemy.row),
      );
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }
}

final class _RetreatCandidate {
  const _RetreatCandidate({
    required this.tile,
    required this.nearestEnemyDistance,
  });

  final MapTileView tile;
  final int nearestEnemyDistance;
}
