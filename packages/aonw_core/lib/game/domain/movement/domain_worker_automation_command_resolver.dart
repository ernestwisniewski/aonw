import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/movement_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/movement_command_result.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_visibility_mode.dart';
import 'package:aonw_core/game/domain/movement/movement_hidden_obstacle_rules.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_visibility_rules.dart';
import 'package:aonw_core/game/domain/movement/worker_automation_command_phase.dart';
import 'package:aonw_core/game/domain/state/domain_action_unit_rules.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

final class DomainWorkerAutomationCommandResult {
  const DomainWorkerAutomationCommandResult({
    required this.accepted,
    required this.state,
    required this.interaction,
    this.events = const [],
    this.execution,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final DomainActionState interaction;
  final List<GameEvent> events;
  final MovementCommandExecution? execution;
  final String? reason;
}

/// Canonical command resolver for deterministic automated worker activity.
final class DomainWorkerAutomationCommandResolver {
  const DomainWorkerAutomationCommandResolver({
    this.planner = const WorkerAutomationPlanner(),
    this.workerResolver = const DomainWorkerCommandResolver(),
    this.fogOfWarService = const FogOfWarService(),
  });

  final WorkerAutomationPlanner planner;
  final DomainWorkerCommandResolver workerResolver;
  final FogOfWarService fogOfWarService;

  DomainWorkerAutomationCommandResult resolve({
    required DomainState state,
    required DomainActionState interaction,
    required AutomateWorkerCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required WorkerAutomationCommandPhase phase,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
    MovementCommandVisibilityMode visibilityMode =
        MovementCommandVisibilityMode.authoritative,
    bool canAct = true,
  }) {
    final unitIndex = _unitIndexById(state.units, command.unitId);
    if (unitIndex == null) {
      return _reject(state, interaction, 'worker_not_found');
    }
    final worker = state.units[unitIndex];
    final guardReason = _guardReason(
      worker: worker,
      actorPlayerId: actorPlayerId,
      phase: phase,
      canAct: canAct,
    );
    if (guardReason != null) return _reject(state, interaction, guardReason);

    final target = _targetFor(
      state: state,
      worker: worker,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
      visibilityMode: visibilityMode,
    );
    if (target == null) {
      return phase.isContinuation
          ? _finishContinuation(state, interaction, unitIndex, worker)
          : _reject(state, interaction, 'worker_automation_no_target');
    }
    return _executeTarget(
      state: state,
      interaction: interaction,
      worker: worker,
      unitIndex: unitIndex,
      target: target,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
      visibilityMode: visibilityMode,
    );
  }

  DomainWorkerAutomationCommandResult _executeTarget({
    required DomainState state,
    required DomainActionState interaction,
    required GameUnit worker,
    required int unitIndex,
    required WorkerAutomationTarget target,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
    required MovementCommandVisibilityMode visibilityMode,
  }) {
    if (worker.occupies(target.hex.col, target.hex.row)) {
      return _startWork(
        state: state,
        interaction: interaction,
        workerId: worker.id,
        target: target,
        actorPlayerId: actorPlayerId,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      );
    }
    return _moveTowardTarget(
      state: state,
      interaction: interaction,
      worker: worker,
      unitIndex: unitIndex,
      target: target,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
      visibilityMode: visibilityMode,
    );
  }

  WorkerAutomationTarget? _targetFor({
    required DomainState state,
    required GameUnit worker,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
    required MovementCommandVisibilityMode visibilityMode,
  }) {
    final visibility = UnitMovementVisibilityRules.visibilityForActor(
      fogOfWar: state.fogOfWar,
      actorPlayerId: actorPlayerId,
      ignoreDynamicFog: visibilityMode.ignoresDynamicFog,
    );
    final knownUnits = UnitMovementVisibilityRules.planningUnitsForActor(
      units: state.units,
      movingUnit: worker,
      actorPlayerId: actorPlayerId,
      visibility: visibility,
    ).toList(growable: false);
    bool canEnterTile(MapTileView tile) {
      final terrainKnown =
          visibilityMode.ignoresPathingFog ||
          UnitMovementVisibilityRules.canPlanThroughTile(
            unit: worker,
            tile: tile,
            visibility: visibility,
          );
      return terrainKnown &&
          MovementHiddenObstacleRules.canPlanThroughCity(
            cities: state.cities,
            diplomacy: state.diplomacy,
            unit: worker,
            tile: tile,
            visibility: visibility,
          );
    }

    return planner.targetFor(
      unit: worker,
      units: state.units,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      mapTiles: mapData,
      pathfinder: UnitMovementPathfinder(
        mapData: mapData,
        units: knownUnits,
        canEnterTile: canEnterTile,
      ),
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  DomainWorkerAutomationCommandResult _moveTowardTarget({
    required DomainState state,
    required DomainActionState interaction,
    required GameUnit worker,
    required int unitIndex,
    required WorkerAutomationTarget target,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
    required MovementCommandVisibilityMode visibilityMode,
  }) {
    final clearedInteraction = DomainActionUnitRules.clearOwnedByUnit(
      interaction,
      worker.id,
    );
    final primedUnits = _replaceUnit(
      state.units,
      unitIndex,
      worker.copyWithPosture(UnitPosture.autoWorking).copyWithQueuedPath(null),
    );
    final moved = _resolveMovement(
      state: state,
      primedUnits: primedUnits,
      worker: worker,
      target: target,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      visibilityMode: visibilityMode,
    );
    if (!moved.accepted) {
      return _reject(state, interaction, moved.reason ?? 'move_failed');
    }
    return _acceptMovement(
      previousState: state,
      interaction: clearedInteraction,
      moved: moved,
      workerId: worker.id,
      target: target,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  MovementCommandResult _resolveMovement({
    required DomainState state,
    required List<GameUnit> primedUnits,
    required GameUnit worker,
    required WorkerAutomationTarget target,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required MovementCommandVisibilityMode visibilityMode,
  }) {
    final playerIds = {
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
    };
    return MovementCommandResolver(fogOfWarService: fogOfWarService).resolve(
      state: MovementCommandState(
        units: primedUnits,
        cities: state.cities,
        fogOfWar: state.fogOfWar,
        diplomacy: state.diplomacy,
        playerIds: playerIds,
      ),
      command: MoveUnitCommand(worker.id, target.hex.col, target.hex.row),
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      visibilityMode: visibilityMode,
    );
  }

  DomainWorkerAutomationCommandResult _acceptMovement({
    required DomainState previousState,
    required DomainActionState interaction,
    required MovementCommandResult moved,
    required String workerId,
    required WorkerAutomationTarget target,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    final movedState = previousState.copyWith(
      units: moved.units,
      fogOfWar: moved.fogOfWar,
      diplomacy: moved.diplomacy,
    );
    final movedIndex = _unitIndexById(moved.units, workerId);
    if (movedIndex == null) {
      return _reject(previousState, interaction, 'worker_not_found');
    }
    final movedWorker = moved.units[movedIndex];
    if (_canStartWork(movedWorker, target)) {
      final started = _startWork(
        state: movedState,
        interaction: interaction,
        workerId: workerId,
        target: target,
        actorPlayerId: actorPlayerId,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      );
      if (started.accepted) {
        return DomainWorkerAutomationCommandResult(
          accepted: true,
          state: started.state,
          interaction: started.interaction,
          events: moved.events,
          execution: moved.execution,
        );
      }
    }
    final automaticUnits = _replaceUnit(
      moved.units,
      movedIndex,
      movedWorker.copyWithPosture(UnitPosture.autoWorking),
    );
    return DomainWorkerAutomationCommandResult(
      accepted: true,
      state: identical(automaticUnits, movedState.units)
          ? movedState
          : movedState.copyWith(units: automaticUnits),
      interaction: interaction,
      events: moved.events,
      execution: moved.execution,
    );
  }

  DomainWorkerAutomationCommandResult _startWork({
    required DomainState state,
    required DomainActionState interaction,
    required String workerId,
    required WorkerAutomationTarget target,
    required String actorPlayerId,
    required MapTileLookup mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    final result = switch (target) {
      WorkerAutomationBuildTarget(:final improvementType) =>
        workerResolver.selectWorkerImprovement(
          state: state,
          interaction: interaction,
          command: SelectWorkerImprovementCommand(workerId, improvementType),
          actorPlayerId: actorPlayerId,
          mapTiles: mapData,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          paceBalance: paceBalance,
        ),
      WorkerAutomationAssignmentTarget() => workerResolver.assignWorkerToHex(
        state: state,
        interaction: interaction,
        command: AssignWorkerToHexCommand(workerId),
        actorPlayerId: actorPlayerId,
        mapTiles: mapData,
      ),
    };
    if (!result.accepted) {
      return _reject(
        state,
        interaction,
        result.reason ?? 'worker_automation_target_invalid',
      );
    }
    return DomainWorkerAutomationCommandResult(
      accepted: true,
      state: result.state,
      interaction: result.interaction,
    );
  }
}

bool _canStartWork(GameUnit worker, WorkerAutomationTarget target) {
  return worker.occupies(target.hex.col, target.hex.row) &&
      worker.movementPoints > 0 &&
      worker.queuedPath == null;
}

String? _guardReason({
  required GameUnit worker,
  required String actorPlayerId,
  required WorkerAutomationCommandPhase phase,
  required bool canAct,
}) {
  return _controlGuardReason(worker, actorPlayerId, canAct) ??
      _activityGuardReason(worker, phase);
}

String? _controlGuardReason(
  GameUnit worker,
  String actorPlayerId,
  bool canAct,
) {
  if (!canAct || worker.ownerPlayerId != actorPlayerId) {
    return 'worker_not_controlled';
  }
  return worker.isWorker ? null : 'worker_not_found';
}

String? _activityGuardReason(
  GameUnit worker,
  WorkerAutomationCommandPhase phase,
) {
  if (worker.isWorking || worker.isFortified) return 'worker_unavailable';
  if (worker.movementPoints <= 0) return 'worker_no_movement_points';
  if (!phase.isContinuation && worker.queuedPath != null) {
    return 'worker_queued_path_active';
  }
  if (phase.isContinuation && !worker.isAutoWorking) {
    return 'worker_automation_not_active';
  }
  return null;
}

DomainWorkerAutomationCommandResult _finishContinuation(
  DomainState state,
  DomainActionState interaction,
  int unitIndex,
  GameUnit worker,
) {
  final units = _replaceUnit(
    state.units,
    unitIndex,
    worker.copyWithPosture(UnitPosture.active).copyWithQueuedPath(null),
  );
  return DomainWorkerAutomationCommandResult(
    accepted: true,
    state: identical(units, state.units) ? state : state.copyWith(units: units),
    interaction: DomainActionUnitRules.clearOwnedByUnit(interaction, worker.id),
  );
}

DomainWorkerAutomationCommandResult _reject(
  DomainState state,
  DomainActionState interaction,
  String reason,
) {
  return DomainWorkerAutomationCommandResult(
    accepted: false,
    state: state,
    interaction: interaction,
    reason: reason,
  );
}

List<GameUnit> _replaceUnit(
  List<GameUnit> units,
  int unitIndex,
  GameUnit updated,
) {
  if (units[unitIndex] == updated) return units;
  return List.unmodifiable([
    for (var index = 0; index < units.length; index++)
      if (index == unitIndex) updated else units[index],
  ]);
}

int? _unitIndexById(List<GameUnit> units, String unitId) {
  for (var index = 0; index < units.length; index++) {
    if (units[index].id == unitId) return index;
  }
  return null;
}
