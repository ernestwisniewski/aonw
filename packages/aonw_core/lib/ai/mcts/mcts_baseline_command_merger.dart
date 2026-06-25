import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_baseline_unit_command_policy.dart';
import 'package:aonw_core/ai/mcts/mcts_command_candidate_guard.dart';
import 'package:aonw_core/ai/mcts/mcts_command_reconciliation_rules.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/mcts_simulator.dart';
import 'package:aonw_core/game/domain/command.dart';

const _defaultRules = MctsCommandReconciliationRules();

final class MctsBaselineCommandMerger {
  final MctsCommandReconciliationRules _rules;

  const MctsBaselineCommandMerger({
    MctsCommandReconciliationRules rules = _defaultRules,
  }) : _rules = rules;
  List<GameCommand> withBaselineSupportCommands(
    List<GameCommand> commands,
    List<GameCommand> baseline,
    GameView view,
    AiContext context, {
    required MctsSimulator simulator,
  }) {
    final unitCommandPolicy = _unitCommandPolicy;
    final baselinePriorityUnitIds = unitCommandPolicy.baselinePriorityUnitIds(
      baseline,
      view,
      context,
    );
    final merged = [
      for (final command in commands)
        if (!unitCommandPolicy.isFortifyBlockedByPriorityFallback(
          command,
          baselinePriorityUnitIds,
        ))
          command,
    ];
    final actedUnitIds = <String>{};
    final reservedMoveTargets = <String>{};
    final attackedTargets = <String>{};
    var mergeState = SimulatedState.fromView(
      view,
      maxPlanningDepth: commands.length + baseline.length + 8,
    );
    var hasResearchSelection = merged.any((command) {
      return command is SelectTechnologyCommand;
    });
    final productionCityIds = <String>{};
    for (final command in merged) {
      final currentView = mergeState.view;
      final actingUnitId = _rules.actingUnitId(command);
      if (actingUnitId != null) actedUnitIds.add(actingUnitId);
      if (command case final MoveUnitCommand moveCommand) {
        reservedMoveTargets.addAll(
          _rules.reservedMoveTargetsForCommand(moveCommand, currentView),
        );
      }
      if (command case AttackHexCommand()) {
        attackedTargets.addAll(
          _rules.reservedFollowUpAttackHexesForAttack(command, currentView),
        );
        reservedMoveTargets.addAll(
          _rules.reservedCombatHexesForAttack(command, currentView),
        );
      }
      final cityId = _productionCityId(command);
      if (cityId != null) productionCityIds.add(cityId);
      final nextState = _applyMergeCommand(mergeState, command, simulator);
      if (command case final MoveUnitCommand moveCommand) {
        _rules.reserveActualMoveDestination(
          moveCommand,
          after: nextState,
          reservedMoveTargets: reservedMoveTargets,
        );
      }
      mergeState = nextState;
    }
    final specializationCityIds = {
      for (final command in merged)
        if (command case SetCitySpecializationCommand(:final cityId)) cityId,
    };

    for (final command in baseline) {
      if (!isLegalMctsCommandCandidate(
        command,
        mergeState.view,
        allowNonVisibleMoveTarget: true,
      )) {
        continue;
      }

      if (command is SelectTechnologyCommand) {
        if (hasResearchSelection) continue;
        final nextState = _applyMergeCommand(mergeState, command, simulator);
        if (_commandDidNotChangeState(
          command,
          before: mergeState,
          after: nextState,
        )) {
          continue;
        }
        merged.add(command);
        mergeState = nextState;
        hasResearchSelection = true;
        continue;
      }

      final productionCityId = _productionCityId(command);
      if (productionCityId != null) {
        if (productionCityIds.contains(productionCityId)) continue;
        final nextState = _applyMergeCommand(mergeState, command, simulator);
        if (_commandDidNotChangeState(
          command,
          before: mergeState,
          after: nextState,
        )) {
          continue;
        }
        merged.add(command);
        mergeState = nextState;
        productionCityIds.add(productionCityId);
        continue;
      }

      if (command case SetCitySpecializationCommand(:final cityId)) {
        if (specializationCityIds.contains(cityId)) continue;
        final nextState = _applyMergeCommand(mergeState, command, simulator);
        if (_commandDidNotChangeState(
          command,
          before: mergeState,
          after: nextState,
        )) {
          continue;
        }
        merged.add(command);
        mergeState = nextState;
        specializationCityIds.add(cityId);
        continue;
      }

      if (unitCommandPolicy.canAppendBaselineUnitCommand(
        command,
        view: mergeState.view,
        context: context,
        actedUnitIds: actedUnitIds,
        reservedMoveTargets: reservedMoveTargets,
        attackedTargets: attackedTargets,
      )) {
        final nextState = _applyMergeCommand(mergeState, command, simulator);
        if (_commandDidNotChangeState(
          command,
          before: mergeState,
          after: nextState,
        )) {
          continue;
        }
        final actingUnitId = _rules.actingUnitId(command);
        if (actingUnitId != null) actedUnitIds.add(actingUnitId);
        if (command case final MoveUnitCommand moveCommand) {
          reservedMoveTargets.addAll(
            _rules.reservedMoveTargetsForCommand(moveCommand, mergeState.view),
          );
          _rules.reserveActualMoveDestination(
            moveCommand,
            after: nextState,
            reservedMoveTargets: reservedMoveTargets,
          );
        }
        if (command case AttackHexCommand()) {
          attackedTargets.addAll(
            _rules.reservedFollowUpAttackHexesForAttack(
              command,
              mergeState.view,
            ),
          );
          reservedMoveTargets.addAll(
            _rules.reservedCombatHexesForAttack(command, mergeState.view),
          );
        }
        merged.add(command);
        mergeState = nextState;
      }
    }

    return List.unmodifiable(merged);
  }

  MctsBaselineUnitCommandPolicy get _unitCommandPolicy {
    return MctsBaselineUnitCommandPolicy(rules: _rules);
  }

  SimulatedState _applyMergeCommand(
    SimulatedState state,
    GameCommand command,
    MctsSimulator simulator,
  ) {
    return simulator.applyAction(state, CommandMctsAction(command));
  }

  bool _commandDidNotChangeState(
    GameCommand command, {
    required SimulatedState before,
    required SimulatedState after,
  }) {
    return switch (command) {
      MoveUnitCommand() => _rules.moveDidNotChangeUnit(
        command,
        before: before,
        after: after,
      ),
      AttackHexCommand() => _rules.attackDidNotChangeCombatState(
        command,
        before: before,
        after: after,
      ),
      SelectTechnologyCommand() => before.ownResearch == after.ownResearch,
      StartBuildingCommand() ||
      StartUnitProductionCommand() ||
      StartCityProjectCommand() ||
      SetCitySpecializationCommand() ||
      FoundCityCommand() ||
      SelectWorkerImprovementCommand() ||
      AssignWorkerToHexCommand() =>
        before.ownUnits == after.ownUnits &&
            before.visibleEnemyUnits == after.visibleEnemyUnits &&
            before.ownCities == after.ownCities &&
            before.rememberedEnemyCities == after.rememberedEnemyCities &&
            before.ownResearch == after.ownResearch,
      StartArtifactExcavationCommand() || StoreArtifactInCityCommand() => false,
      _ => true,
    };
  }

  String? _productionCityId(GameCommand command) {
    return switch (command) {
      StartUnitProductionCommand(:final cityId) => cityId,
      StartBuildingCommand(:final cityId) => cityId,
      StartCityProjectCommand(:final cityId) => cityId,
      _ => null,
    };
  }
}
