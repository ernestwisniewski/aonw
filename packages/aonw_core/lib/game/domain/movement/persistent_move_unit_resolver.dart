import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement/queued_move_path.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_feasibility.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class PersistentMoveUnitResult {
  const PersistentMoveUnitResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}

class PersistentMoveUnitResolver {
  const PersistentMoveUnitResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  PersistentMoveUnitResult resolve({
    required PersistentGameState state,
    required MoveUnitCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
  }) {
    final unitIndex = _unitIndexById(state.units, command.unitId);
    if (unitIndex == null) return _reject(state, 'unit_not_found');

    final unit = state.units[unitIndex];
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }
    if (unit.isWorking) return _reject(state, 'unit_unavailable');
    if (unit.type == GameUnitType.merchant) {
      return _reject(state, 'unit_uses_trade_routes');
    }

    final mapData = _mapDataFromDefinition(mapDefinition);
    if (mapData.tileAt(unit.col, unit.row) == null) {
      return _reject(state, 'unit_out_of_bounds');
    }

    final targetTile = mapData.tileAt(command.targetCol, command.targetRow);
    if (targetTile == null) return _reject(state, 'move_target_out_of_bounds');
    if (unit.occupies(targetTile.col, targetTile.row)) {
      return _reject(state, 'move_target_is_current_tile');
    }
    if (_isForeignCityCenter(state, unit, targetTile.col, targetTile.row)) {
      return _reject(state, 'move_target_is_foreign_city_center');
    }
    final targetBlocker = _unitAt(state.units, targetTile.col, targetTile.row);
    final pathfinder = UnitMovementPathfinder(
      mapData: mapData,
      units: state.units,
    );
    var plan = pathfinder.plan(unit: unit, targetTile: targetTile);
    if (plan == null && targetBlocker != null && targetBlocker.id != unit.id) {
      final approach = pathfinder.planTowardBlockedTarget(
        unit: unit,
        targetTile: targetTile,
      );
      final targetHidden = _targetIsHiddenFromActor(
        state: state,
        actorPlayerId: actorPlayerId,
        col: targetTile.col,
        row: targetTile.row,
      );
      final targetBlockedByOpponent =
          targetBlocker.ownerPlayerId != unit.ownerPlayerId;
      if (approach != null &&
          (targetHidden ||
              targetBlockedByOpponent ||
              approach.totalCost > unit.movementPoints)) {
        plan = approach;
      }
    }

    if (plan == null) {
      if (targetBlocker != null && targetBlocker.id != unit.id) {
        if (_targetIsHiddenFromActor(
          state: state,
          actorPlayerId: actorPlayerId,
          col: targetTile.col,
          row: targetTile.row,
        )) {
          return PersistentMoveUnitResult(accepted: true, state: state);
        }
        return _reject(state, 'move_target_occupied');
      }
      if (_pathWasBlockedByHiddenUnit(
        state: state,
        actorPlayerId: actorPlayerId,
        unit: unit,
        targetTile: targetTile,
        mapData: mapData,
      )) {
        return PersistentMoveUnitResult(accepted: true, state: state);
      }
      return _reject(state, 'move_path_not_found');
    }
    if (!UnitMovementFeasibility.canEventuallyTraverse(
      unit: unit,
      plan: plan,
      canEnterStepBeyondCapacity: (step) => _canCarryArtifactIntoTargetCity(
        state: state,
        unit: unit,
        targetTile: targetTile,
        step: step,
      ),
    )) {
      return _reject(state, 'unit_movement_capacity_insufficient');
    }

    final reachable = plan.canMoveNow;
    final destinationStep = reachable
        ? plan.steps.last
        : plan.furthestReachableStep;

    if (destinationStep == null ||
        (destinationStep.col == unit.col && destinationStep.row == unit.row)) {
      final queued = unit
          .copyWith(posture: UnitPosture.active)
          .copyWithQueuedPath(_queuedPathFor(plan));
      return PersistentMoveUnitResult(
        accepted: true,
        state: state.copyWith(units: _replaceUnit(state.units, queued)),
      );
    }

    final moved = unit.copyWith(
      col: destinationStep.col,
      row: destinationStep.row,
      movementPoints: plan.remainingMovementPointsAfterStep(destinationStep),
      posture: UnitPosture.active,
    );
    final movedWithPath = reachable
        ? moved.copyWithQueuedPath(null)
        : moved.copyWithQueuedPath(_queuedPathFor(plan));
    final updatedUnits = _replaceUnit(state.units, movedWithPath);
    final updatedFog = fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: _knownPlayerIds(state),
      units: updatedUnits,
      cities: state.cities,
    );

    return PersistentMoveUnitResult(
      accepted: true,
      state: state.copyWith(units: updatedUnits, fogOfWar: updatedFog),
      events: [
        UnitMovedEvent(
          unitId: unit.id,
          fromCol: unit.col,
          fromRow: unit.row,
          toCol: movedWithPath.col,
          toRow: movedWithPath.row,
        ),
      ],
    );
  }

  PersistentMoveUnitResult _reject(PersistentGameState state, String reason) {
    return PersistentMoveUnitResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static MapData _mapDataFromDefinition(MapDefinition mapDefinition) {
    return MapData(
      cols: mapDefinition.cols,
      rows: mapDefinition.rows,
      mapName: mapDefinition.mapName,
      defaultZoom: mapDefinition.defaultZoom,
      tiles: [
        for (final tile in mapDefinition.tiles)
          TileData(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }

  static QueuedMovePath _queuedPathFor(UnitMovementPlan plan) {
    return QueuedMovePath(
      targetCol: plan.targetCol,
      targetRow: plan.targetRow,
      steps: plan.steps,
    );
  }

  static List<GameUnit> _replaceUnit(List<GameUnit> units, GameUnit updated) {
    return [
      for (final unit in units)
        if (unit.id == updated.id) updated else unit,
    ];
  }

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].id == unitId) return i;
    }
    return null;
  }

  static GameUnit? _unitAt(List<GameUnit> units, int col, int row) {
    for (final unit in units) {
      if (unit.col == col && unit.row == row) return unit;
    }
    return null;
  }

  static bool _isForeignCityCenter(
    PersistentGameState state,
    GameUnit unit,
    int col,
    int row,
  ) {
    for (final city in state.cities) {
      if (!city.occupiesCenter(col, row)) continue;
      return city.ownerPlayerId != unit.ownerPlayerId;
    }
    return false;
  }

  static bool _canCarryArtifactIntoTargetCity({
    required PersistentGameState state,
    required GameUnit unit,
    required TileData targetTile,
    required UnitMovementStep step,
  }) {
    if (unit.carriedArtifactId == null) return false;
    if (step.col != targetTile.col || step.row != targetTile.row) {
      return false;
    }
    for (final city in state.cities) {
      if (!city.occupiesCenter(step.col, step.row)) continue;
      return city.ownerPlayerId == unit.ownerPlayerId;
    }
    return false;
  }

  static bool _targetIsHiddenFromActor({
    required PersistentGameState state,
    required String actorPlayerId,
    required int col,
    required int row,
  }) {
    if (!state.fogOfWar.players.containsKey(actorPlayerId)) return false;
    return !state.fogOfWar.isVisible(
      actorPlayerId,
      HexCoordinate(col: col, row: row),
    );
  }

  static bool _pathWasBlockedByHiddenUnit({
    required PersistentGameState state,
    required String actorPlayerId,
    required GameUnit unit,
    required TileData targetTile,
    required MapData mapData,
  }) {
    if (!state.fogOfWar.players.containsKey(actorPlayerId)) return false;

    final knownUnits = <GameUnit>[
      for (final candidate in state.units)
        if (candidate.id == unit.id ||
            candidate.ownerPlayerId == actorPlayerId ||
            state.fogOfWar.isVisible(
              actorPlayerId,
              HexCoordinate(col: candidate.col, row: candidate.row),
            ))
          candidate,
    ];
    if (knownUnits.length == state.units.length) return false;

    final knownPathfinder = UnitMovementPathfinder(
      mapData: mapData,
      units: knownUnits,
    );
    return knownPathfinder.plan(unit: unit, targetTile: targetTile) != null;
  }

  static Set<String> _knownPlayerIds(PersistentGameState state) {
    return {
      ...state.playerColors.keys,
      ...state.playerGold.keys,
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
    };
  }
}
