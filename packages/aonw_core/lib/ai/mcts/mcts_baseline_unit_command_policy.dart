import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_baseline_attack_command_policy.dart';
import 'package:aonw_core/ai/mcts/mcts_baseline_movement_command_policy.dart';
import 'package:aonw_core/ai/mcts/mcts_command_reconciliation_rules.dart';
import 'package:aonw_core/game/domain/command.dart';

const _defaultRules = MctsCommandReconciliationRules();

final class MctsBaselineUnitCommandPolicy {
  final MctsCommandReconciliationRules _rules;

  const MctsBaselineUnitCommandPolicy({
    MctsCommandReconciliationRules rules = _defaultRules,
  }) : _rules = rules;

  Set<String> baselinePriorityUnitIds(
    List<GameCommand> baseline,
    GameView view,
    AiContext context,
  ) {
    final unitIds = <String>{};
    final actedUnitIds = <String>{};
    final reservedMoveTargets = <String>{};
    final attackedTargets = <String>{};
    final movementPolicy = _movementCommandPolicy;
    for (final command in baseline) {
      if (!canAppendBaselineUnitCommand(
        command,
        view: view,
        context: context,
        actedUnitIds: actedUnitIds,
        reservedMoveTargets: reservedMoveTargets,
        attackedTargets: attackedTargets,
      )) {
        continue;
      }
      if (command case AttackHexCommand(:final attackerUnitId)) {
        unitIds.add(attackerUnitId);
        actedUnitIds.add(attackerUnitId);
        attackedTargets.addAll(
          _rules.reservedFollowUpAttackHexesForAttack(command, view),
        );
        reservedMoveTargets.addAll(
          _rules.reservedCombatHexesForAttack(command, view),
        );
      } else if (command case MoveUnitCommand(:final unitId)) {
        final unit = _rules.unitById(view.ownUnits, unitId);
        if (unit == null ||
            !movementPolicy.isBaselinePressureMove(
              command,
              unit: unit,
              view: view,
            )) {
          continue;
        }
        unitIds.add(unitId);
        actedUnitIds.add(unitId);
        reservedMoveTargets.addAll(
          _rules.reservedMoveTargetsForCommand(command, view),
        );
      }
    }
    return unitIds;
  }

  bool isFortifyBlockedByPriorityFallback(
    GameCommand command,
    Set<String> priorityUnitIds,
  ) {
    return command is FortifyUnitCommand &&
        priorityUnitIds.contains(command.unitId);
  }

  bool canAppendBaselineUnitCommand(
    GameCommand command, {
    required GameView view,
    required AiContext context,
    required Set<String> actedUnitIds,
    required Set<String> reservedMoveTargets,
    required Set<String> attackedTargets,
  }) {
    final actingUnitId = _rules.actingUnitId(command);
    if (actingUnitId == null || actedUnitIds.contains(actingUnitId)) {
      return false;
    }
    final unit = _rules.unitById(view.ownUnits, actingUnitId);
    if (unit == null) return false;
    final attackPolicy = _attackCommandPolicy;
    final movementPolicy = _movementCommandPolicy;

    return switch (command) {
      AttackHexCommand()
          when attackPolicy.canAppendFounderPressureAttack(
            command,
            view: view,
            context: context,
            attackedTargets: attackedTargets,
          ) =>
        true,
      AttackHexCommand()
          when attackPolicy.canAppendWarGoalAttack(
            command,
            view: view,
            context: context,
            attackedTargets: attackedTargets,
          ) =>
        true,
      AttackHexCommand()
          when attackPolicy.canAppendPressureAttack(
            command,
            view: view,
            context: context,
            attackedTargets: attackedTargets,
          ) =>
        true,
      MoveUnitCommand()
          when movementPolicy.canAppendPressureMove(
            command,
            unit: unit,
            view: view,
            context: context,
            reservedMoveTargets: reservedMoveTargets,
          ) =>
        true,
      MoveUnitCommand() when _rules.isStrategicSupportUnit(unit) =>
        movementPolicy.canAppendBaselineMove(
          command,
          unit: unit,
          view: view,
          context: context,
          reservedMoveTargets: reservedMoveTargets,
        ),
      MoveUnitCommand()
          when _rules.isAssignedWarGoalMilitaryUnit(unit, context) =>
        movementPolicy.canAppendBaselineMove(
          command,
          unit: unit,
          view: view,
          context: context,
          reservedMoveTargets: reservedMoveTargets,
        ),
      FoundCityCommand() when _rules.isFounderUnit(unit) => true,
      SelectWorkerImprovementCommand() when unit.isWorker => true,
      AssignWorkerToHexCommand() when unit.isWorker => true,
      StartArtifactExcavationCommand() || StoreArtifactInCityCommand() => true,
      _ => false,
    };
  }

  MctsBaselineAttackCommandPolicy get _attackCommandPolicy {
    return MctsBaselineAttackCommandPolicy(rules: _rules);
  }

  MctsBaselineMovementCommandPolicy get _movementCommandPolicy {
    return MctsBaselineMovementCommandPolicy(rules: _rules);
  }
}
