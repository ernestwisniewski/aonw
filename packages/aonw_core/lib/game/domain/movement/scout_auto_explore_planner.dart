import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

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
    required MapData mapData,
    required Iterable<GameUnit> units,
    required FogOfWarState fogOfWar,
    bool Function(TileData tile)? canEnterTile,
  }) {
    if (!_canAutoExplore(unit)) return null;

    final reservedHexes = _reservedExplorationHexes(unit: unit, units: units);
    final pathCanEnterTile = reservedHexes.isEmpty && canEnterTile == null
        ? null
        : (TileData tile) {
            if (reservedHexes.contains(HexCoordinate.fromTile(tile))) {
              return false;
            }
            return canEnterTile?.call(tile) ?? true;
          };
    final pathfinder = UnitMovementPathfinder(
      mapData: mapData,
      units: units,
      canEnterTile: pathCanEnterTile,
    );
    final movementCosts = pathfinder.movementCostsFrom(unit: unit);
    final playerFog = fogOfWar.fogForPlayer(unit.ownerPlayerId);
    final origin = HexCoordinate(col: unit.col, row: unit.row);

    _AutoExploreCandidate? best;
    for (final tile in mapData.tiles) {
      if (unit.occupies(tile.col, tile.row)) continue;

      final movementCost = movementCosts[(col: tile.col, row: tile.row)];
      if (movementCost == null) continue;

      final targetHex = HexCoordinate.fromTile(tile);
      if (reservedHexes.contains(targetHex)) continue;
      final targetUndiscovered = !playerFog.discoveredHexes.contains(targetHex);
      final candidateUnit = unit.copyWith(col: tile.col, row: tile.row);
      final reveal = revealCalculator.visibleHexesFor(
        mapData: mapData,
        sources: [
          FogOfWarService.unitRevealSource(
            playerId: unit.ownerPlayerId,
            unit: candidateUnit,
            mapData: mapData,
          ),
        ],
      );
      final newlyDiscovered = reveal
          .where((hex) => !playerFog.discoveredHexes.contains(hex))
          .length;
      if (!targetUndiscovered &&
          newlyDiscovered <
              ScoutAutoExploreBalance.minimumNewlyDiscoveredHexes) {
        continue;
      }

      final distanceFromStart = HexDistance.between(
        origin,
        HexCoordinate.fromTile(tile),
      );
      final candidate = _AutoExploreCandidate(
        command: MoveUnitCommand(unit.id, tile.col, tile.row),
        newlyDiscoveredHexes: newlyDiscovered,
        targetUndiscovered: targetUndiscovered,
        visibleHexes: reveal.length,
        movementCost: movementCost,
        distanceFromStart: distanceFromStart,
      );
      if (best == null || candidate.compareTo(best) > 0) {
        best = candidate;
      }
    }

    return best?.command;
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
