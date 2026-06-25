import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class PersistentTurnMovementResult {
  final PersistentGameState state;
  final bool changed;

  const PersistentTurnMovementResult({
    required this.state,
    this.changed = false,
  });
}

abstract final class PersistentTurnMovementProcessor {
  static PersistentTurnMovementResult resetForPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MapData mapData,
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final playerSet = _playerSet(playerIds);
    if (playerSet.isEmpty) {
      return PersistentTurnMovementResult(state: state);
    }

    final currentUnits = state.units;
    final resetUnits = [
      for (final unit in currentUnits)
        playerSet.contains(unit.ownerPlayerId)
            ? _resetForNewTurn(unit, mapData: mapData, allUnits: currentUnits)
            : unit,
    ];

    var changed = false;
    for (var i = 0; i < resetUnits.length; i++) {
      if (resetUnits[i] != currentUnits[i]) {
        changed = true;
        break;
      }
    }

    var finalUnits = <GameUnit>[];
    for (var i = 0; i < resetUnits.length; i++) {
      final unit = resetUnits[i];
      if (!playerSet.contains(unit.ownerPlayerId)) {
        finalUnits.add(unit);
        continue;
      }

      final currentAllUnits = [...finalUnits, ...resetUnits.sublist(i)];
      final routed = MerchantTradeRouteRules.advanceUnit(
        unit: unit,
        units: currentAllUnits,
        cities: state.cities,
        mapData: mapData,
      ).unit;
      if (routed != unit) changed = true;
      if (routed.type == GameUnitType.merchant &&
          routed.merchantTradeRoute != null) {
        finalUnits.add(routed);
        continue;
      }

      final moved = _advanceQueuedPath(
        unit: routed,
        mapData: mapData,
        allUnits: currentAllUnits,
        cities: state.cities,
      );
      if (moved != routed) changed = true;
      finalUnits.add(moved);
    }

    var workingFog = state.fogOfWar;
    if (changed) {
      workingFog = fogOfWarService.recompute(
        current: state.fogOfWar,
        mapData: mapData,
        playerIds: _knownPlayerIds(state),
        units: finalUnits,
        cities: state.cities,
      );
    }

    final autoExplore = _advanceAutoExplore(
      units: finalUnits,
      fogOfWar: workingFog,
      cities: state.cities,
      playerSet: playerSet,
      mapData: mapData,
      fogOfWarService: fogOfWarService,
    );
    if (autoExplore.changed) {
      finalUnits = autoExplore.units;
      workingFog = autoExplore.fogOfWar;
      changed = true;
    }

    if (!changed) return PersistentTurnMovementResult(state: state);

    return PersistentTurnMovementResult(
      state: state.copyWith(units: finalUnits, fogOfWar: workingFog),
      changed: true,
    );
  }

  static GameUnit _resetForNewTurn(
    GameUnit unit, {
    required MapData mapData,
    required Iterable<GameUnit> allUnits,
  }) {
    if (unit.isFortified) {
      return UnitFortificationRules.recoverForNewTurn(
        unit: unit,
        mapData: mapData,
        units: allUnits,
      );
    }

    final movementPoints = unit.isWorking
        ? 0
        : UnitMovementBalance.maxMovementPointsFor(
            type: unit.type,
            carriedArtifactId: unit.carriedArtifactId,
          );
    return unit
        .copyWith(movementPoints: movementPoints)
        .copyWithQueuedPath(
          _shouldKeepQueuedPath(unit) ? unit.queuedPath : null,
        );
  }

  static GameUnit _advanceQueuedPath({
    required GameUnit unit,
    required MapData mapData,
    required List<GameUnit> allUnits,
    required List<GameCity> cities,
  }) {
    final path = unit.queuedPath;
    if (path == null) return unit;
    if (!_shouldKeepQueuedPath(unit)) return unit.copyWithQueuedPath(null);
    if (unit.isFortified) return unit.copyWithQueuedPath(null);

    final targetTile = mapData.tileAt(path.targetCol, path.targetRow);
    if (targetTile == null) return unit.copyWithQueuedPath(null);

    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: allUnits,
      canEnterOccupiedTile:
          ({
            required movingUnit,
            required blockingUnit,
            required col,
            required row,
          }) => MerchantTradeRouteRules.canShareOccupiedCityTile(
            movingUnit: movingUnit,
            col: col,
            row: row,
            cities: cities,
          ),
    ).plan(unit: unit, targetTile: targetTile);
    if (plan == null) return unit.copyWithQueuedPath(null);

    final reachable = plan.canMoveNow;
    final destinationStep = reachable
        ? plan.steps.last
        : plan.furthestReachableStep;
    if (destinationStep == null ||
        (destinationStep.col == unit.col && destinationStep.row == unit.row)) {
      return unit;
    }

    final moved = unit.copyWith(
      col: destinationStep.col,
      row: destinationStep.row,
      movementPoints: plan.remainingMovementPointsAfterStep(destinationStep),
    );
    return reachable ? moved.copyWithQueuedPath(null) : moved;
  }

  static bool _shouldKeepQueuedPath(GameUnit unit) {
    if (unit.isWorking) return false;
    if (unit.type != GameUnitType.merchant) return true;
    return unit.merchantTradeRoute == null;
  }

  static _PersistentAutoExploreResult _advanceAutoExplore({
    required List<GameUnit> units,
    required FogOfWarState fogOfWar,
    required List<GameCity> cities,
    required Set<String> playerSet,
    required MapData mapData,
    required FogOfWarService fogOfWarService,
  }) {
    var currentUnits = List<GameUnit>.of(units);
    var currentFog = fogOfWar;
    var changed = false;

    for (var i = 0; i < currentUnits.length; i++) {
      final unit = currentUnits[i];
      if (!playerSet.contains(unit.ownerPlayerId)) continue;
      if (!unit.isAutoExploring) continue;
      if (unit.movementPoints <= 0 ||
          unit.queuedPath != null ||
          unit.isWorking ||
          unit.isFortified) {
        continue;
      }

      final command = const ScoutAutoExplorePlanner().commandFor(
        unit: unit,
        mapData: mapData,
        units: currentUnits,
        fogOfWar: currentFog,
      );
      if (command == null) continue;

      final moved = _moveAutoExploringUnit(
        unit: unit,
        command: command,
        units: currentUnits,
        mapData: mapData,
      );
      if (moved == unit) continue;

      currentUnits = _replaceUnit(currentUnits, moved);
      currentFog = fogOfWarService.recompute(
        current: currentFog,
        mapData: mapData,
        playerIds: _knownPlayerIdsFrom(
          cities: cities,
          fogOfWar: currentFog,
          units: currentUnits,
        ),
        units: currentUnits,
        cities: cities,
      );
      changed = true;
    }

    return _PersistentAutoExploreResult(
      units: currentUnits,
      fogOfWar: currentFog,
      changed: changed,
    );
  }

  static GameUnit _moveAutoExploringUnit({
    required GameUnit unit,
    required MoveUnitCommand command,
    required List<GameUnit> units,
    required MapData mapData,
  }) {
    final targetTile = mapData.tileAt(command.targetCol, command.targetRow);
    if (targetTile == null) return unit;

    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: units,
    ).plan(unit: unit, targetTile: targetTile);
    if (plan == null) return unit;

    final reachable = plan.canMoveNow;
    final destinationStep = reachable
        ? plan.steps.last
        : plan.furthestReachableStep;
    if (destinationStep == null ||
        (destinationStep.col == unit.col && destinationStep.row == unit.row)) {
      return unit
          .copyWith(posture: UnitPosture.autoExploring)
          .copyWithQueuedPath(reachable ? null : _queuedPathFor(plan));
    }

    final moved = unit.copyWith(
      col: destinationStep.col,
      row: destinationStep.row,
      movementPoints: plan.remainingMovementPointsAfterStep(destinationStep),
      posture: UnitPosture.autoExploring,
    );
    return reachable
        ? moved.copyWithQueuedPath(null)
        : moved.copyWithQueuedPath(_queuedPathFor(plan));
  }

  static QueuedMovePath _queuedPathFor(UnitMovementPlan plan) {
    return QueuedMovePath(
      targetCol: plan.targetCol,
      targetRow: plan.targetRow,
      steps: plan.steps,
    );
  }

  static Set<String> _playerSet(Iterable<String> playerIds) {
    return {
      for (final playerId in playerIds)
        if (playerId.isNotEmpty) playerId,
    };
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

  static Set<String> _knownPlayerIdsFrom({
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

  static List<GameUnit> _replaceUnit(List<GameUnit> units, GameUnit updated) {
    return [
      for (final unit in units)
        if (unit.id == updated.id) updated else unit,
    ];
  }
}

class _PersistentAutoExploreResult {
  final List<GameUnit> units;
  final FogOfWarState fogOfWar;
  final bool changed;

  const _PersistentAutoExploreResult({
    required this.units,
    required this.fogOfWar,
    required this.changed,
  });
}
