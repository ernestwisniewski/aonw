import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_command_candidate_guard.dart';
import 'package:aonw_core/ai/mcts/mcts_command_reconciliation_rules.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/mcts_simulator.dart';
import 'package:aonw_core/game/domain/command.dart';

const _defaultRules = MctsCommandReconciliationRules();

final class MctsCommandValidator {
  final MctsCommandReconciliationRules _rules;

  const MctsCommandValidator({
    MctsCommandReconciliationRules rules = _defaultRules,
  }) : _rules = rules;
  List<GameCommand> validatedCommands(
    List<MctsAction> actions, {
    required SimulatedState rootState,
    required MctsSimulator simulator,
  }) {
    var state = rootState;
    final commands = <GameCommand>[];
    final actedUnitIds = <String>{};
    final attackedTargets = <String>{};
    final reservedMoveTargets = <String>{};
    for (final action in actions) {
      final command = action.toCommand();
      if (command == null) continue;
      if (!isLegalMctsCommandCandidate(command, state.view)) continue;
      final actingUnitId = _rules.actingUnitId(command);
      if (actingUnitId != null && actedUnitIds.contains(actingUnitId)) {
        continue;
      }
      if (command is AttackHexCommand &&
          attackedTargets.contains(
            _rules.hexKey(command.defenderCol, command.defenderRow),
          )) {
        continue;
      }
      if (command is MoveUnitCommand &&
          _rules.moveWouldBeNoOp(command, state)) {
        continue;
      }
      if (command is MoveUnitCommand &&
          reservedMoveTargets.contains(
            _rules.hexKey(command.targetCol, command.targetRow),
          )) {
        continue;
      }
      if (command is AttackHexCommand &&
          _rules.attackWouldBeNoOp(command, state)) {
        continue;
      }
      final next = simulator.applyAction(state, action);
      if (command is MoveUnitCommand &&
          _rules.moveDidNotChangeUnit(command, before: state, after: next)) {
        state = next;
        continue;
      }
      if (command is AttackHexCommand &&
          _rules.attackDidNotChangeCombatState(
            command,
            before: state,
            after: next,
          )) {
        state = next;
        continue;
      }
      commands.add(command);
      if (actingUnitId != null) actedUnitIds.add(actingUnitId);
      if (command is AttackHexCommand) {
        attackedTargets.addAll(
          _rules.reservedFollowUpAttackHexesForAttack(command, state.view),
        );
        reservedMoveTargets.addAll(
          _rules.reservedCombatHexesForAttack(command, state.view),
        );
      }
      if (command is MoveUnitCommand) {
        reservedMoveTargets.addAll(
          _rules.reservedMoveTargetsForCommand(command, state.view),
        );
        _rules.reserveActualMoveDestination(
          command,
          after: next,
          reservedMoveTargets: reservedMoveTargets,
        );
      }
      state = next;
    }
    return commands;
  }
}
