import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class WorkerReducer {
  static GameStateTransition selectWorkerImprovement(
    GameState state,
    SelectWorkerImprovementCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final pending = state.pendingAction;
    if (pending is PendingWorkerActionSelection) {
      if (pending.unitId != command.unitId) {
        return GameStateTransition(state: state);
      }
      return GameStateTransition(
        state: state.copyWith(
          pendingAction: pending.copyWith(
            improvementType: command.improvementType,
          ),
        ),
      );
    }

    return _startImprovement(
      state,
      unitId: command.unitId,
      improvementType: command.improvementType,
      mapData: mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  static GameStateTransition confirmWorkerImprovement(
    GameState state,
    ConfirmWorkerImprovementCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final pending = state.pendingAction;
    if (pending is! PendingWorkerActionSelection ||
        pending.unitId != command.unitId ||
        pending.improvementType == null) {
      return GameStateTransition(state: state);
    }

    return _startImprovement(
      state,
      unitId: command.unitId,
      improvementType: pending.improvementType!,
      mapData: mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  static GameStateTransition _startImprovement(
    GameState state, {
    required String unitId,
    required FieldImprovementType improvementType,
    required MapData mapData,
    required GameCommandContext context,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    final unitIndex = state.units.indexWhere((unit) => unit.id == unitId);
    if (unitIndex == -1) return GameStateTransition(state: state);

    final worker = state.units[unitIndex];
    if (!context.canControlUnit(state, worker)) {
      return GameStateTransition(state: state);
    }

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
    if (!legality.allowed) return GameStateTransition(state: state);

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
    final updatedUnits = [...state.units]..[unitIndex] = updatedWorker;

    var next = state.copyWith(units: updatedUnits, moveCommandActive: false);
    next = next.copyWith(movePreview: null);
    next = next.copyWith(pendingAction: null);
    next = next.copyWith(
      selection: GameSelection.unit(
        updatedWorker,
        tile: mapData.tileAt(updatedWorker.col, updatedWorker.row),
      ),
    );

    return GameStateTransition(state: next);
  }

  static GameStateTransition cancelWorkerJob(
    GameState state,
    CancelWorkerJobCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final unitIndex = state.units.indexWhere(
      (unit) => unit.id == command.unitId,
    );
    if (unitIndex == -1) return GameStateTransition(state: state);

    final worker = state.units[unitIndex];
    if (!context.canControlUnit(state, worker) || worker.workerJob == null) {
      return GameStateTransition(state: state);
    }

    final updatedWorker = worker
        .copyWithWorkerJob(null)
        .copyWithQueuedPath(null);
    final updatedUnits = [...state.units]..[unitIndex] = updatedWorker;

    var next = state.copyWith(units: updatedUnits);
    next = next.copyWith(
      selection: GameSelection.unit(
        updatedWorker,
        tile: mapData.tileAt(updatedWorker.col, updatedWorker.row),
      ),
    );

    return GameStateTransition(state: next);
  }

  static GameStateTransition assignWorkerToHex(
    GameState state,
    AssignWorkerToHexCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final unitIndex = state.units.indexWhere(
      (unit) => unit.id == command.unitId,
    );
    if (unitIndex == -1) return GameStateTransition(state: state);

    final worker = state.units[unitIndex];
    if (!context.canControlUnit(state, worker)) {
      return GameStateTransition(state: state);
    }

    final legality = WorkerAssignmentRules.evaluate(
      unit: worker,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      mapData: mapData,
    );
    if (!legality.allowed) return GameStateTransition(state: state);

    final targetHex = CityHex(col: worker.col, row: worker.row);
    final updatedWorker = worker
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithWorkerAssignment(WorkerAssignment(targetHex: targetHex));
    final updatedUnits = [...state.units]..[unitIndex] = updatedWorker;

    var next = state.copyWith(
      units: updatedUnits,
      moveCommandActive: false,
      pendingAction: null,
    );
    next = next.copyWith(movePreview: null);
    next = next.copyWith(
      selection: GameSelection.unit(
        updatedWorker,
        tile: mapData.tileAt(updatedWorker.col, updatedWorker.row),
      ),
    );

    return GameStateTransition(state: next);
  }

  static GameStateTransition cancelWorkerAssignment(
    GameState state,
    CancelWorkerAssignmentCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final unitIndex = state.units.indexWhere(
      (unit) => unit.id == command.unitId,
    );
    if (unitIndex == -1) return GameStateTransition(state: state);

    final worker = state.units[unitIndex];
    if (!context.canControlUnit(state, worker) ||
        worker.workerAssignment == null) {
      return GameStateTransition(state: state);
    }

    final updatedWorker = worker
        .copyWithWorkerAssignment(null)
        .copyWithQueuedPath(null);
    final updatedUnits = [...state.units]..[unitIndex] = updatedWorker;

    var next = state.copyWith(units: updatedUnits);
    next = next.copyWith(
      selection: GameSelection.unit(
        updatedWorker,
        tile: mapData.tileAt(updatedWorker.col, updatedWorker.row),
      ),
    );

    return GameStateTransition(state: next);
  }
}
