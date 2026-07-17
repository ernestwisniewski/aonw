import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/movement/queued_move_path.dart';
import 'package:aonw_core/game/domain/movement/scout_auto_explore_planner.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class TurnAutoExploreAdvance {
  const TurnAutoExploreAdvance({
    required this.units,
    required this.fogOfWar,
    this.changed = false,
  });

  final List<GameUnit> units;
  final FogOfWarState fogOfWar;
  final bool changed;
}

abstract final class TurnAutoExploreAdvancer {
  static TurnAutoExploreAdvance advance({
    required List<GameUnit> units,
    required FogOfWarState fogOfWar,
    required List<GameCity> cities,
    required Set<String> playerIds,
    required MapTraversalView mapData,
    required FogOfWarService fogOfWarService,
  }) {
    var currentUnits = List<GameUnit>.of(units);
    var currentFog = fogOfWar;
    var changed = false;
    for (var index = 0; index < currentUnits.length; index++) {
      final unit = currentUnits[index];
      if (!_canAdvance(unit, playerIds)) continue;
      final command = const ScoutAutoExplorePlanner().commandFor(
        unit: unit,
        mapData: mapData,
        units: currentUnits,
        fogOfWar: currentFog,
      );
      if (command == null) continue;
      final moved = _moveUnit(
        unit: unit,
        command: command,
        units: currentUnits,
        mapData: mapData,
      );
      if (moved == unit) continue;
      currentUnits = _replaceUnit(currentUnits, moved);
      currentFog = _recomputeFog(
        current: currentFog,
        units: currentUnits,
        cities: cities,
        mapData: mapData,
        fogOfWarService: fogOfWarService,
      );
      changed = true;
    }
    return TurnAutoExploreAdvance(
      units: currentUnits,
      fogOfWar: currentFog,
      changed: changed,
    );
  }

  static bool _canAdvance(GameUnit unit, Set<String> playerIds) {
    return playerIds.contains(unit.ownerPlayerId) &&
        unit.isAutoExploring &&
        unit.movementPoints > 0 &&
        unit.queuedPath == null &&
        !unit.isWorking &&
        !unit.isFortified;
  }

  static GameUnit _moveUnit({
    required GameUnit unit,
    required MoveUnitCommand command,
    required List<GameUnit> units,
    required MapTraversalView mapData,
  }) {
    final targetTile = mapData.tileAt(command.targetCol, command.targetRow);
    if (targetTile == null) return unit;
    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: units,
    ).plan(unit: unit, targetTile: targetTile);
    if (plan == null) return unit;
    return _moveAlongPlan(unit, plan);
  }

  static GameUnit _moveAlongPlan(GameUnit unit, UnitMovementPlan plan) {
    final reachable = plan.canMoveNow;
    final destination = reachable
        ? plan.steps.last
        : plan.furthestReachableStep;
    if (destination == null ||
        (destination.col == unit.col && destination.row == unit.row)) {
      return unit
          .copyWith(posture: UnitPosture.autoExploring)
          .copyWithQueuedPath(reachable ? null : _queuedPathFor(plan));
    }
    final moved = unit.copyWith(
      col: destination.col,
      row: destination.row,
      movementPoints: plan.remainingMovementPointsAfterStep(destination),
      posture: UnitPosture.autoExploring,
    );
    return reachable
        ? moved.copyWithQueuedPath(null)
        : moved.copyWithQueuedPath(_queuedPathFor(plan));
  }

  static FogOfWarState _recomputeFog({
    required FogOfWarState current,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required MapTraversalView mapData,
    required FogOfWarService fogOfWarService,
  }) {
    return fogOfWarService.recompute(
      current: current,
      mapData: mapData,
      playerIds: _liveKnownPlayerIds(
        cities: cities,
        fogOfWar: current,
        units: units,
      ),
      units: units,
      cities: cities,
    );
  }

  static Set<String> _liveKnownPlayerIds({
    required Iterable<GameCity> cities,
    required FogOfWarState fogOfWar,
    required Iterable<GameUnit> units,
  }) {
    return {
      ...fogOfWar.playerIds,
      for (final unit in units) unit.ownerPlayerId,
      for (final city in cities) city.ownerPlayerId,
    };
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
}
