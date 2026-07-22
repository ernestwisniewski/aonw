import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement/movement_command_path_constraints.dart';
import 'package:aonw_core/game/domain/movement/scout_auto_explore_target.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

abstract final class ScoutAutoExploreBalance {
  static const minimumNewlyDiscoveredHexes = 1;
  static const newlyDiscoveredHexScore = 1000;
  static const undiscoveredTargetScore = 500;
  static const visibleHexScore = 2;
}

class ScoutAutoExplorePlanner {
  final FogRevealCalculator revealCalculator;

  const ScoutAutoExplorePlanner({
    this.revealCalculator = const FogRevealCalculator(),
  });

  MoveUnitCommand? commandFor({
    required GameUnit unit,
    required MapTraversalView mapData,
    required Iterable<GameUnit> units,
    required FogOfWarState fogOfWar,
    bool Function(MapTileView tile)? canEnterTile,
  }) {
    return targetFor(
      unit: unit,
      mapData: mapData,
      units: units,
      fogOfWar: fogOfWar,
      canEnterTile: canEnterTile,
    )?.command;
  }

  ScoutAutoExploreTarget? targetFor({
    required GameUnit unit,
    required MapTraversalView mapData,
    required Iterable<GameUnit> units,
    required FogOfWarState fogOfWar,
    bool Function(MapTileView tile)? canEnterTile,
  }) {
    if (!_canAutoExplore(unit)) return null;

    final reservedHexes = _reservedExplorationHexes(unit: unit, units: units);
    final pathfinder = UnitMovementPathfinder(
      mapData: mapData,
      units: units,
      canEnterTile: _pathPolicyFor(
        reservedHexes: reservedHexes,
        canEnterTile: canEnterTile,
      ),
    );
    final best = _bestCandidate(
      unit: unit,
      mapData: mapData,
      pathfinder: pathfinder,
      playerFog: fogOfWar.fogForPlayer(unit.ownerPlayerId),
    );
    if (best == null) return null;
    return ScoutAutoExploreTarget(
      command: best.command,
      pathConstraints: reservedHexes.isEmpty
          ? const MovementCommandPathConstraints.none()
          : MovementCommandPathConstraints.excluding(
              excludedHexes: reservedHexes,
            ),
    );
  }

  bool Function(MapTileView tile)? _pathPolicyFor({
    required Set<HexCoordinate> reservedHexes,
    required bool Function(MapTileView tile)? canEnterTile,
  }) {
    if (reservedHexes.isEmpty && canEnterTile == null) return null;
    return (tile) {
      if (reservedHexes.contains(HexCoordinate.fromTile(tile))) return false;
      return canEnterTile?.call(tile) ?? true;
    };
  }

  _AutoExploreCandidate? _bestCandidate({
    required GameUnit unit,
    required MapTraversalView mapData,
    required UnitMovementPathfinder pathfinder,
    required PlayerFogOfWar playerFog,
  }) {
    final origin = HexCoordinate(col: unit.col, row: unit.row);
    _AutoExploreCandidate? best;
    for (final movement in pathfinder.movementCostsFrom(unit: unit).entries) {
      final candidate = _candidateFor(
        unit: unit,
        mapData: mapData,
        pathfinder: pathfinder,
        playerFog: playerFog,
        origin: origin,
        coordinate: movement.key,
        movementCost: movement.value,
      );
      if (candidate != null &&
          (best == null || candidate.compareTo(best) > 0)) {
        best = candidate;
      }
    }
    return best;
  }

  _AutoExploreCandidate? _candidateFor({
    required GameUnit unit,
    required MapTraversalView mapData,
    required UnitMovementPathfinder pathfinder,
    required PlayerFogOfWar playerFog,
    required HexCoordinate origin,
    required ({int col, int row}) coordinate,
    required int movementCost,
  }) {
    final tile = pathfinder.tileAt(coordinate.col, coordinate.row);
    if (tile == null) return null;
    final targetHex = HexCoordinate.fromTile(tile);
    final targetUndiscovered = !playerFog.discoveredHexes.contains(targetHex);
    final reveal = revealCalculator.visibleHexesFor(
      mapData: mapData,
      sources: [
        FogOfWarService.unitRevealSource(
          playerId: unit.ownerPlayerId,
          unit: unit.copyWith(col: tile.col, row: tile.row),
          mapData: mapData,
        ),
      ],
    );
    final newlyDiscovered = reveal
        .where((hex) => !playerFog.discoveredHexes.contains(hex))
        .length;
    if (!targetUndiscovered &&
        newlyDiscovered < ScoutAutoExploreBalance.minimumNewlyDiscoveredHexes) {
      return null;
    }
    return _AutoExploreCandidate(
      command: MoveUnitCommand(unit.id, tile.col, tile.row),
      newlyDiscoveredHexes: newlyDiscovered,
      targetUndiscovered: targetUndiscovered,
      visibleHexes: reveal.length,
      movementCost: movementCost,
      distanceFromStart: HexDistance.between(origin, targetHex),
    );
  }

  Set<HexCoordinate> _reservedExplorationHexes({
    required GameUnit unit,
    required Iterable<GameUnit> units,
  }) {
    final reserved = <HexCoordinate>{};
    for (final other in units) {
      if (other.id == unit.id ||
          other.ownerPlayerId != unit.ownerPlayerId ||
          !other.isAutoExploring) {
        continue;
      }

      final path = other.queuedPath;
      if (path == null) continue;

      var foundCurrentStep = false;
      for (final step in path.steps) {
        if (!foundCurrentStep) {
          foundCurrentStep = other.occupies(step.col, step.row);
          continue;
        }
        reserved.add(HexCoordinate(col: step.col, row: step.row));
      }
      if (!foundCurrentStep) {
        for (final step in path.steps) {
          if (!other.occupies(step.col, step.row)) {
            reserved.add(HexCoordinate(col: step.col, row: step.row));
          }
        }
      }
      reserved.add(HexCoordinate(col: path.targetCol, row: path.targetRow));
    }
    return reserved;
  }

  bool _canAutoExplore(GameUnit unit) {
    return unit.type == GameUnitType.scout &&
        unit.movementPoints > 0 &&
        unit.queuedPath == null &&
        !unit.isWorking &&
        !unit.isFortified;
  }
}

class _AutoExploreCandidate {
  final MoveUnitCommand command;
  final int newlyDiscoveredHexes;
  final bool targetUndiscovered;
  final int visibleHexes;
  final int movementCost;
  final int distanceFromStart;

  const _AutoExploreCandidate({
    required this.command,
    required this.newlyDiscoveredHexes,
    required this.targetUndiscovered,
    required this.visibleHexes,
    required this.movementCost,
    required this.distanceFromStart,
  });

  int get score =>
      newlyDiscoveredHexes * ScoutAutoExploreBalance.newlyDiscoveredHexScore +
      (targetUndiscovered
          ? ScoutAutoExploreBalance.undiscoveredTargetScore
          : 0) +
      visibleHexes * ScoutAutoExploreBalance.visibleHexScore;

  int compareTo(_AutoExploreCandidate other) {
    final scoreOrder = score.compareTo(other.score);
    if (scoreOrder != 0) return scoreOrder;
    final newlyDiscoveredOrder = newlyDiscoveredHexes.compareTo(
      other.newlyDiscoveredHexes,
    );
    if (newlyDiscoveredOrder != 0) return newlyDiscoveredOrder;
    final targetOrder = targetUndiscovered == other.targetUndiscovered
        ? 0
        : targetUndiscovered
        ? 1
        : -1;
    if (targetOrder != 0) return targetOrder;
    final movementOrder = other.movementCost.compareTo(movementCost);
    if (movementOrder != 0) return movementOrder;
    final distanceOrder = other.distanceFromStart.compareTo(distanceFromStart);
    if (distanceOrder != 0) return distanceOrder;
    final colOrder = other.command.targetCol.compareTo(command.targetCol);
    if (colOrder != 0) return colOrder;
    return other.command.targetRow.compareTo(command.targetRow);
  }
}
