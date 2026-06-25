import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class PersistentWorkerCommandResult {
  const PersistentWorkerCommandResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

class PersistentWorkerCommandResolver {
  const PersistentWorkerCommandResolver();

  PersistentWorkerCommandResult selectWorkerImprovement({
    required PersistentGameState state,
    required SelectWorkerImprovementCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return _startImprovement(
      state,
      unitId: command.unitId,
      improvementType: command.improvementType,
      actorPlayerId: actorPlayerId,
      mapDefinition: mapDefinition,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  PersistentWorkerCommandResult confirmWorkerImprovement({
    required PersistentGameState state,
    required ConfirmWorkerImprovementCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final pending = state.runtimeState.pendingAction;
    if (pending is! PendingWorkerActionSelection ||
        pending.unitId != command.unitId ||
        pending.improvementType == null) {
      return _reject(state, 'worker_improvement_not_selected');
    }
    if (pending.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'worker_action_not_controlled');
    }

    return _startImprovement(
      state,
      unitId: command.unitId,
      improvementType: pending.improvementType!,
      actorPlayerId: actorPlayerId,
      mapDefinition: mapDefinition,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  PersistentWorkerCommandResult cancelWorkerJob({
    required PersistentGameState state,
    required CancelWorkerJobCommand command,
    required String actorPlayerId,
  }) {
    final unitIndex = _unitIndexById(state.units, command.unitId);
    if (unitIndex == null) return _reject(state, 'worker_not_found');

    final worker = state.units[unitIndex];
    if (worker.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'worker_not_controlled');
    }
    if (worker.workerJob == null) {
      return _reject(state, 'worker_job_not_active');
    }

    final updatedWorker = worker
        .copyWithWorkerJob(null)
        .copyWithQueuedPath(null);
    return PersistentWorkerCommandResult(
      accepted: true,
      state: state.copyWith(
        units: _replaceUnitAt(state.units, unitIndex, updatedWorker),
      ),
    );
  }

  PersistentWorkerCommandResult assignWorkerToHex({
    required PersistentGameState state,
    required AssignWorkerToHexCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
  }) {
    final unitIndex = _unitIndexById(state.units, command.unitId);
    if (unitIndex == null) return _reject(state, 'worker_not_found');

    final worker = state.units[unitIndex];
    if (worker.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'worker_not_controlled');
    }

    final mapData = _mapDataFromDefinition(mapDefinition);
    final legality = WorkerAssignmentRules.evaluate(
      unit: worker,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      mapData: mapData,
    );
    if (!legality.allowed) {
      return _reject(state, 'worker_assignment_unavailable');
    }

    final targetHex = CityHex(col: worker.col, row: worker.row);
    final updatedWorker = worker
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithWorkerAssignment(WorkerAssignment(targetHex: targetHex));
    return PersistentWorkerCommandResult(
      accepted: true,
      state: state.copyWith(
        units: _replaceUnitAt(state.units, unitIndex, updatedWorker),
        runtimeState: _clearMatchingWorkerPendingAction(
          state.runtimeState,
          actorPlayerId: actorPlayerId,
          unitId: worker.id,
        ),
      ),
    );
  }

  PersistentWorkerCommandResult cancelWorkerAssignment({
    required PersistentGameState state,
    required CancelWorkerAssignmentCommand command,
    required String actorPlayerId,
  }) {
    final unitIndex = _unitIndexById(state.units, command.unitId);
    if (unitIndex == null) return _reject(state, 'worker_not_found');

    final worker = state.units[unitIndex];
    if (worker.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'worker_not_controlled');
    }
    if (worker.workerAssignment == null) {
      return _reject(state, 'worker_assignment_not_active');
    }

    final updatedWorker = worker
        .copyWithWorkerAssignment(null)
        .copyWithQueuedPath(null);
    return PersistentWorkerCommandResult(
      accepted: true,
      state: state.copyWith(
        units: _replaceUnitAt(state.units, unitIndex, updatedWorker),
      ),
    );
  }

  PersistentWorkerCommandResult _startImprovement(
    PersistentGameState state, {
    required String unitId,
    required FieldImprovementType improvementType,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    final unitIndex = _unitIndexById(state.units, unitId);
    if (unitIndex == null) return _reject(state, 'worker_not_found');

    final worker = state.units[unitIndex];
    if (worker.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'worker_not_controlled');
    }

    final mapData = _mapDataFromDefinition(mapDefinition);
    final legality = WorkerImprovementRules.evaluate(
      unit: worker,
      improvementType: improvementType,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapData: mapData,
      research: state.research,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
    if (!legality.allowed) {
      return _reject(state, 'worker_improvement_unavailable');
    }

    final totalTurns = FieldImprovementRules.buildTurnsFor(
      improvementType,
      ruleset: cityRuleset,
      paceBalance: paceBalance,
    );
    final updatedWorker = worker
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithWorkerAssignment(null)
        .copyWithWorkerJob(
          WorkerJob(
            targetHex: CityHex(col: worker.col, row: worker.row),
            improvementType: improvementType,
            remainingTurns: totalTurns,
            totalTurns: totalTurns,
          ),
        );
    return PersistentWorkerCommandResult(
      accepted: true,
      state: state.copyWith(
        units: _replaceUnitAt(state.units, unitIndex, updatedWorker),
        runtimeState: _clearMatchingWorkerPendingAction(
          state.runtimeState,
          actorPlayerId: actorPlayerId,
          unitId: worker.id,
        ),
      ),
    );
  }

  PersistentWorkerCommandResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentWorkerCommandResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static GameRuntimeState _clearMatchingWorkerPendingAction(
    GameRuntimeState runtimeState, {
    required String actorPlayerId,
    required String unitId,
  }) {
    final pending = runtimeState.pendingAction;
    if (pending is PendingWorkerActionSelection &&
        pending.ownerPlayerId == actorPlayerId &&
        pending.unitId == unitId) {
      return GameRuntimeState(
        cityFoundingDraft: runtimeState.cityFoundingDraft,
        submittedPlayerIds: runtimeState.submittedPlayerIds,
        timeoutStreaksByPlayerId: runtimeState.timeoutStreaksByPlayerId,
        afkPlayerIds: runtimeState.afkPlayerIds,
        kickedPlayerIds: runtimeState.kickedPlayerIds,
        intendedAttacks: runtimeState.intendedAttacks,
        diplomacy: runtimeState.diplomacy,
        dominationHoldTurnsByPlayerId:
            runtimeState.dominationHoldTurnsByPlayerId,
        culturalVictoryHoldTurnsByPlayerId:
            runtimeState.culturalVictoryHoldTurnsByPlayerId,
        turnStartedAt: runtimeState.turnStartedAt,
      );
    }
    return runtimeState;
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

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].id == unitId) return i;
    }
    return null;
  }

  static List<GameUnit> _replaceUnitAt(
    List<GameUnit> units,
    int index,
    GameUnit updated,
  ) {
    return [...units]..[index] = updated;
  }
}
