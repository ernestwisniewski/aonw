import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_command_reconciliation_rules.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';

const _defaultRules = MctsCommandReconciliationRules();

final class MctsBaselineAttackCommandPolicy {
  final MctsCommandReconciliationRules _rules;

  const MctsBaselineAttackCommandPolicy({
    MctsCommandReconciliationRules rules = _defaultRules,
  }) : _rules = rules;

  bool canAppendFounderPressureAttack(
    AttackHexCommand command, {
    required GameView view,
    required AiContext context,
    required Set<String> attackedTargets,
  }) {
    if (attackedTargets.contains(
      _rules.hexKey(command.defenderCol, command.defenderRow),
    )) {
      return false;
    }
    final attacker = _rules.unitById(view.ownUnits, command.attackerUnitId);
    if (attacker == null ||
        attacker.isWorking ||
        attacker.movementPoints <= 0) {
      return false;
    }
    final defender = _rules.unitAt(
      view.visibleEnemyUnits,
      command.defenderCol,
      command.defenderRow,
    );
    if (defender == null || !_rules.canServeAsMilitaryUnit(defender, context)) {
      return false;
    }
    if (!_isEnemyNearActiveFounder(
      view,
      command.defenderCol,
      command.defenderRow,
    )) {
      return false;
    }

    final evaluation = AiCombatTactics.evaluateAttack(
      view: view,
      context: context,
      command: command,
    );
    return evaluation != null &&
        AiCombatTactics.shouldConsiderAttack(
          evaluation,
          context,
          protectsCivilian: true,
        );
  }

  bool canAppendWarGoalAttack(
    AttackHexCommand command, {
    required GameView view,
    required AiContext context,
    required Set<String> attackedTargets,
  }) {
    if (attackedTargets.contains(
      _rules.hexKey(command.defenderCol, command.defenderRow),
    )) {
      return false;
    }
    final attacker = _rules.unitById(view.ownUnits, command.attackerUnitId);
    if (attacker == null ||
        attacker.isWorking ||
        attacker.movementPoints <= 0 ||
        !_rules.isAssignedWarGoalMilitaryUnit(attacker, context)) {
      return false;
    }
    final defender = _rules.unitAt(
      view.visibleEnemyUnits,
      command.defenderCol,
      command.defenderRow,
    );
    final targetPlayerIds = _rules.warTargetsForUnit(attacker.id, context);
    if (defender != null) {
      if (!targetPlayerIds.contains(defender.ownerPlayerId)) return false;
      final evaluation = AiCombatTactics.evaluateAttack(
        view: view,
        context: context,
        command: command,
      );
      return evaluation != null &&
          AiCombatTactics.shouldConsiderAttack(
            evaluation,
            context,
            matchesWarGoal: true,
          );
    }

    final city = _rules.cityAt(
      view.rememberedEnemyCities,
      command.defenderCol,
      command.defenderRow,
    );
    if (city == null || !targetPlayerIds.contains(city.ownerPlayerId)) {
      return false;
    }
    final evaluation = AiCombatTactics.evaluateCityAttack(
      view: view,
      context: context,
      command: command,
    );
    return evaluation != null &&
        AiCombatTactics.shouldConsiderCityAttack(
          evaluation,
          context,
          matchesWarGoal: true,
        );
  }

  bool canAppendPressureAttack(
    AttackHexCommand command, {
    required GameView view,
    required AiContext context,
    required Set<String> attackedTargets,
  }) {
    if (attackedTargets.contains(
      _rules.hexKey(command.defenderCol, command.defenderRow),
    )) {
      return false;
    }
    final attacker = _rules.unitById(view.ownUnits, command.attackerUnitId);
    if (attacker == null ||
        attacker.isWorking ||
        attacker.movementPoints <= 0 ||
        !_rules.canServeAsMilitaryUnit(attacker, context)) {
      return false;
    }
    final defender = _rules.unitAt(
      view.visibleEnemyUnits,
      command.defenderCol,
      command.defenderRow,
    );
    if (defender != null) {
      if (!_isPressureTarget(view, defender.ownerPlayerId)) return false;
      final evaluation = AiCombatTactics.evaluateAttack(
        view: view,
        context: context,
        command: command,
      );
      return evaluation != null &&
          AiCombatTactics.shouldConsiderAttack(
            evaluation,
            context,
            matchesWarGoal: true,
          );
    }

    final city = _rules.cityAt(
      view.rememberedEnemyCities,
      command.defenderCol,
      command.defenderRow,
    );
    if (city == null || !_isPressureTarget(view, city.ownerPlayerId)) {
      return false;
    }
    final evaluation = AiCombatTactics.evaluateCityAttack(
      view: view,
      context: context,
      command: command,
    );
    return evaluation != null &&
        AiCombatTactics.shouldConsiderCityAttack(
          evaluation,
          context,
          matchesWarGoal: true,
        );
  }

  bool _isPressureTarget(GameView view, String playerId) {
    return view.activeHostilePlayerIds.contains(playerId) ||
        view.pressureTargetPlayerIds.contains(playerId) ||
        view.recentHostilePlayerIds.contains(playerId);
  }

  bool _isEnemyNearActiveFounder(GameView view, int col, int row) {
    final threat = HexCoordinate(col: col, row: row);
    for (final unit in view.ownUnits) {
      if (!_rules.isFounderUnit(unit) ||
          unit.isWorking ||
          unit.queuedPath != null) {
        continue;
      }
      final distance = HexDistance.between(
        HexCoordinate(col: unit.col, row: unit.row),
        threat,
      );
      if (distance <= 2) return true;
    }
    return false;
  }
}
