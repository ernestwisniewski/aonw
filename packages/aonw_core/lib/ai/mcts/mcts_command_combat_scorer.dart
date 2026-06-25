import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/mcts/mcts_evaluation_queries.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/war_front.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsCommandCombatScorer {
  const MctsCommandCombatScorer();

  double scoreFortify(
    FortifyUnitCommand command, {
    required SimulatedState state,
    AiContext? context,
  }) {
    final unit = mctsOwnUnitById(state.ownUnits, command.unitId);
    if (unit == null) return -0.005;

    final stats = UnitCombatStats.derive(
      unit,
      ruleset: context?.ruleset.combat ?? state.view.ruleset.combat,
    );
    final hp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
    final hpDeficit = (stats.hp - hp).clamp(0, stats.hp).toDouble();
    if (hpDeficit <= 0) return -0.005;
    if (context == null) return hpDeficit > 0 ? 0.04 : -0.005;

    final defenses = context.strategicPlan?.defenses.values;
    if (defenses == null) {
      return hpDeficit > 0 && mctsIsNearOwnCity(state, unit.col, unit.row, 1)
          ? 0.04
          : -0.005;
    }

    for (final defense in defenses) {
      if (!defense.assignedUnitIds.contains(unit.id)) continue;
      final distance = HexDistance.between(
        HexCoordinate(col: unit.col, row: unit.row),
        defense.cityCenter.toCoordinate(),
      );
      if (distance > 1) continue;
      final threatened =
          defense.threatLevel > 0 ||
          state.visibleTargetableEnemyUnits.any(
            (enemy) =>
                mctsCanServeAsMilitaryUnit(enemy, context) &&
                HexDistance.between(
                      HexCoordinate(col: enemy.col, row: enemy.row),
                      defense.cityCenter.toCoordinate(),
                    ) <=
                    3,
          );
      if (!threatened && hpDeficit <= 0) return 0.02;
      return (0.09 + hpDeficit * 0.015 + defense.threatLevel * 0.004)
          .clamp(0.04, 0.22)
          .toDouble();
    }

    return hpDeficit > 0 && mctsIsNearOwnCity(state, unit.col, unit.row, 1)
        ? 0.04
        : -0.005;
  }

  double scoreAttack(
    AttackHexCommand command, {
    required SimulatedState state,
    AiContext? context,
  }) {
    if (context == null) return 0.08;
    final evaluation = AiCombatTactics.evaluateAttack(
      view: state.view,
      context: context,
      command: command,
    );
    if (evaluation == null) {
      final cityEvaluation = AiCombatTactics.evaluateCityAttack(
        view: state.view,
        context: context,
        command: command,
      );
      if (cityEvaluation != null) {
        final cityHex = cityEvaluation.city.center.toCoordinate();
        final matchesWarGoal =
            context.strategicPlan?.warGoals.any(
              (goal) =>
                  goal.targetPlayerId == cityEvaluation.city.ownerPlayerId &&
                  warGoalEngagesHex(goal, cityHex),
            ) ??
            false;
        return AiCombatTactics.cityCommandScore(
          cityEvaluation,
          context,
          matchesWarGoal: matchesWarGoal,
        );
      }
      final clearingBonus = _frontierClearingAttackBonus(
        command,
        context: context,
      );
      return (_postAttackScore(command, state: state, context: context) +
              clearingBonus)
          .clamp(-0.18, 0.40)
          .toDouble();
    }

    final defenderHex = HexCoordinate(
      col: evaluation.defender.col,
      row: evaluation.defender.row,
    );
    final matchesWarGoal =
        context.strategicPlan?.warGoals.any(
          (goal) =>
              goal.targetPlayerId == evaluation.defender.ownerPlayerId &&
              warGoalEngagesHex(goal, defenderHex),
        ) ??
        false;
    final frontlineBlocker =
        !matchesWarGoal &&
        isOffensiveWarFrontBlocker(
          view: state.view,
          plan: context.strategicPlan,
          blockerHex: defenderHex,
          unitId: evaluation.attacker.id,
        );
    final assignedFounderClear = _matchesFrontierClearingTarget(
      command,
      targetPlayerId: evaluation.defender.ownerPlayerId,
      defenderHex: defenderHex,
      context: context,
    );
    final protectsFounder =
        assignedFounderClear ||
        _defenderPressuresActiveFounder(
          state: state,
          context: context,
          defender: evaluation.defender,
          defenderHex: defenderHex,
        );
    final clearingBonus = assignedFounderClear
        ? _frontierClearingAttackBonus(command, context: context)
        : 0.0;
    final pressureBonus = protectsFounder
        ? _activeFounderPressureAttackBonus(
            state: state,
            context: context,
            defenderHex: defenderHex,
          )
        : 0.0;
    return (AiCombatTactics.commandScore(
              evaluation,
              context,
              matchesWarGoal: matchesWarGoal || frontlineBlocker,
              protectsCivilian: protectsFounder,
            ) +
            clearingBonus +
            pressureBonus +
            (frontlineBlocker ? 0.035 : 0.0))
        .clamp(-0.18, 0.40)
        .toDouble();
  }

  bool _matchesFrontierClearingTarget(
    AttackHexCommand command, {
    required String targetPlayerId,
    required HexCoordinate defenderHex,
    required AiContext context,
  }) {
    final assignment = context
        .strategicPlan
        ?.frontierClearingAssignments[command.attackerUnitId];
    return assignment != null &&
        assignment.targetPlayerId == targetPlayerId &&
        assignment.targetHex == defenderHex;
  }

  double _frontierClearingAttackBonus(
    AttackHexCommand command, {
    required AiContext context,
  }) {
    final assignment = context
        .strategicPlan
        ?.frontierClearingAssignments[command.attackerUnitId];
    if (assignment == null ||
        assignment.targetHex.col != command.defenderCol ||
        assignment.targetHex.row != command.defenderRow) {
      return 0;
    }
    return (0.045 + assignment.priority * 0.012).clamp(0.0, 0.095).toDouble();
  }

  bool _defenderPressuresActiveFounder({
    required SimulatedState state,
    required AiContext context,
    required GameUnit defender,
    required HexCoordinate defenderHex,
  }) {
    if (state.ownCities.isEmpty ||
        !mctsCanServeAsMilitaryUnit(defender, context)) {
      return false;
    }
    return _activeFounderPressureDistance(state, defenderHex) != null;
  }

  double _activeFounderPressureAttackBonus({
    required SimulatedState state,
    required AiContext context,
    required HexCoordinate defenderHex,
  }) {
    if (state.ownCities.isEmpty) return 0;
    final distance = _activeFounderPressureDistance(state, defenderHex);
    if (distance == null) return 0;
    final oneCityBonus = state.ownCities.length == 1 ? 0.025 : 0.0;
    final modeBonus = context.strategicPlan?.mode == StrategicMode.recover
        ? 0.015
        : 0.0;
    return (0.04 + (3 - distance) * 0.018 + oneCityBonus + modeBonus)
        .clamp(0.0, 0.105)
        .toDouble();
  }

  int? _activeFounderPressureDistance(
    SimulatedState state,
    HexCoordinate defenderHex,
  ) {
    int? best;
    for (final founder in state.ownUnits) {
      if (!CityFoundingRules.canFoundCityWith(founder)) continue;
      if (founder.isWorking || founder.queuedPath != null) continue;
      final distance = HexDistance.between(
        HexCoordinate(col: founder.col, row: founder.row),
        defenderHex,
      );
      if (distance > 2) continue;
      if (best == null || distance < best) best = distance;
    }
    return best;
  }

  double _postAttackScore(
    AttackHexCommand command, {
    required SimulatedState state,
    required AiContext context,
  }) {
    final attacker = mctsOwnUnitById(state.ownUnits, command.attackerUnitId);
    final defender = mctsEnemyAt(
      state.visibleTargetableEnemyUnits,
      command.defenderCol,
      command.defenderRow,
    );
    if (defender == null && attacker != null) return 0.34;
    if (attacker == null && defender != null) return -0.14;
    if (attacker == null || defender == null) return -0.06;

    final attackerStats = UnitCombatStats.derive(
      attacker,
      ruleset: context.ruleset.combat,
    );
    final defenderStats = UnitCombatStats.derive(
      defender,
      ruleset: context.ruleset.combat,
    );
    final attackerHp = UnitCombatHealth.currentHp(
      attacker,
      effectiveStats: attackerStats,
    );
    final defenderHp = UnitCombatHealth.currentHp(
      defender,
      effectiveStats: defenderStats,
    );
    final defenderDamageRatio =
        1.0 - defenderHp / defenderStats.hp.clamp(1, 1 << 30);
    final attackerDamageRatio =
        1.0 - attackerHp / attackerStats.hp.clamp(1, 1 << 30);
    var score = 0.02 + defenderDamageRatio * 0.16 - attackerDamageRatio * 0.18;
    if (defenderHp * 100 <= defenderStats.hp * 35) score += 0.08;
    return score.clamp(-0.14, 0.14).toDouble();
  }
}
