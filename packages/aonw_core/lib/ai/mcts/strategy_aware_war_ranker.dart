import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_ranking_queries.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategic/war_front.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';

CommandRanking? rankAssignedWarFocusGuard(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  if (command is! AttackHexCommand) return null;

  final attacker = ownUnitById(view, command.attackerUnitId);
  if (attacker == null) return null;
  final assignedTargets = _offensiveWarGoalTargetPlayerIdsForUnit(
    attacker.id,
    plan,
  );
  if (assignedTargets.isEmpty) return null;

  final defender = enemyAt(view, command.defenderCol, command.defenderRow);
  final city = defender == null
      ? enemyCityAt(view, command.defenderCol, command.defenderRow)
      : null;
  final targetPlayerId = defender?.ownerPlayerId ?? city?.ownerPlayerId;
  if (targetPlayerId == null || assignedTargets.contains(targetPlayerId)) {
    return null;
  }

  if (defender != null) {
    final defenderHex = HexCoordinate(col: defender.col, row: defender.row);
    if (isOffensiveWarFrontBlocker(
      view: view,
      plan: plan,
      blockerHex: defenderHex,
      unitId: attacker.id,
    )) {
      return null;
    }

    final pendingCityAttacker = view.pendingCityAttackThreats.any(
      (threat) => threat.attackerUnitId == defender.id,
    );
    if (pendingCityAttacker) return null;

    final evaluation = AiCombatTactics.evaluateAttack(
      view: view,
      context: context,
      command: command,
    );
    if (evaluation?.threatensOwnCity ?? false) return null;
  }

  return const CommandRanking(CandidatePriority.fallback, -975);
}

CommandRanking? rankWarCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  if (plan.warGoals.isEmpty) return null;

  return switch (command) {
    AttackHexCommand() => _rankWarAttack(command, view, context, plan),
    MoveUnitCommand() => _rankWarMove(command, view, plan),
    CancelUnitActionCommand() => _rankWarWakeUp(command, view, plan),
    _ => null,
  };
}

CommandRanking rankTacticalAttack(
  AttackHexCommand command,
  GameView view,
  AiContext context,
) {
  final evaluation = AiCombatTactics.evaluateAttack(
    view: view,
    context: context,
    command: command,
  );
  if (evaluation == null) {
    final cityEvaluation = AiCombatTactics.evaluateCityAttack(
      view: view,
      context: context,
      command: command,
    );
    final cityMatchesPressure =
        cityEvaluation != null &&
        _isOffensivePressureTarget(
          cityEvaluation.city.ownerPlayerId,
          view,
          context.strategicPlan,
        );
    if (cityEvaluation == null ||
        !AiCombatTactics.shouldConsiderCityAttack(
          cityEvaluation,
          context,
          matchesWarGoal: cityMatchesPressure,
        )) {
      return const CommandRanking(CandidatePriority.fallback, -950);
    }
    final priority = context.strategicPlan?.mode == StrategicMode.military
        ? CandidatePriority.war
        : CandidatePriority.fallback;
    final base = priority == CandidatePriority.war ? 680.0 : 170.0;
    return CommandRanking(
      priority,
      base +
          AiCombatTactics.cityRankingBonus(
            cityEvaluation,
            context,
            matchesWarGoal: cityMatchesPressure,
          ),
    );
  }
  final defendingCity = evaluation.threatensOwnCity;
  final matchesPressure = _isOffensivePressureTarget(
    evaluation.defender.ownerPlayerId,
    view,
    context.strategicPlan,
  );
  final frontlineBlocker =
      !matchesPressure &&
      isOffensiveWarFrontBlocker(
        view: view,
        plan: context.strategicPlan,
        blockerHex: HexCoordinate(
          col: evaluation.defender.col,
          row: evaluation.defender.row,
        ),
        unitId: evaluation.attacker.id,
      );
  final warRelevant = matchesPressure || frontlineBlocker;
  if (!AiCombatTactics.shouldConsiderAttack(
    evaluation,
    context,
    matchesWarGoal: warRelevant,
    defendingCity: defendingCity,
  )) {
    return const CommandRanking(CandidatePriority.fallback, -950);
  }

  final mode = context.strategicPlan?.mode;
  final priority = defendingCity
      ? CandidatePriority.defense
      : mode == StrategicMode.military
      ? CandidatePriority.war
      : CandidatePriority.fallback;
  final base = switch (priority) {
    CandidatePriority.defense => 650.0,
    CandidatePriority.war => 620.0,
    _ => 120.0,
  };
  return CommandRanking(
    priority,
    base +
        AiCombatTactics.rankingBonus(
          evaluation,
          context,
          matchesWarGoal: warRelevant,
          defendingCity: defendingCity,
        ) +
        (frontlineBlocker ? 45 : 0),
  );
}

CommandRanking? _rankWarAttack(
  AttackHexCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  final defender = enemyAt(view, command.defenderCol, command.defenderRow);
  final city = defender == null
      ? enemyCityAt(view, command.defenderCol, command.defenderRow)
      : null;
  if (defender == null && city == null) return null;
  final defenderHex = defender == null
      ? city!.center.toCoordinate()
      : HexCoordinate(col: defender.col, row: defender.row);
  final targetPlayerId = defender?.ownerPlayerId ?? city!.ownerPlayerId;

  for (final goal in plan.warGoals) {
    if (goal.targetPlayerId != targetPlayerId) continue;
    if (!warGoalEngagesHex(goal, defenderHex)) continue;
    final assignedBonus = goal.assignedUnitIds.contains(command.attackerUnitId)
        ? 24.0
        : 0.0;
    final targetDistance = HexDistance.between(defenderHex, goal.targetHex);
    if (defender == null) {
      final evaluation = AiCombatTactics.evaluateCityAttack(
        view: view,
        context: context,
        command: command,
      );
      if (evaluation == null ||
          !AiCombatTactics.shouldConsiderCityAttack(
            evaluation,
            context,
            matchesWarGoal: true,
          )) {
        return const CommandRanking(CandidatePriority.fallback, -950);
      }
      return CommandRanking(
        CandidatePriority.war,
        1060 +
            goal.priority * 100 +
            assignedBonus -
            targetDistance +
            AiCombatTactics.cityRankingBonus(
              evaluation,
              context,
              matchesWarGoal: true,
            ),
      );
    }
    final evaluation = AiCombatTactics.evaluateAttack(
      view: view,
      context: context,
      command: command,
    );
    if (evaluation == null ||
        !AiCombatTactics.shouldConsiderAttack(
          evaluation,
          context,
          matchesWarGoal: true,
          defendingCity: goal.kind == WarGoalKind.defend,
        )) {
      return const CommandRanking(CandidatePriority.fallback, -950);
    }
    return CommandRanking(
      CandidatePriority.war,
      1000 +
          goal.priority * 100 +
          assignedBonus -
          targetDistance +
          AiCombatTactics.rankingBonus(
            evaluation,
            context,
            matchesWarGoal: true,
            defendingCity: goal.kind == WarGoalKind.defend,
          ),
    );
  }

  return null;
}

CommandRanking? _rankWarWakeUp(
  CancelUnitActionCommand command,
  GameView view,
  StrategicPlan plan,
) {
  final unit = ownUnitById(view, command.unitId);
  if (unit == null || !unit.isFortified) return null;

  for (final goal in plan.warGoals) {
    if (goal.kind == WarGoalKind.defend) continue;
    if (!goal.assignedUnitIds.contains(unit.id)) continue;
    return CommandRanking(CandidatePriority.war, 860 + goal.priority * 100);
  }

  return null;
}

CommandRanking? _rankWarMove(
  MoveUnitCommand command,
  GameView view,
  StrategicPlan plan,
) {
  final unit = ownUnitById(view, command.unitId);
  if (unit == null) return null;

  for (final goal in plan.warGoals) {
    if (!goal.assignedUnitIds.contains(unit.id)) continue;
    final improvement = distanceImprovement(
      fromCol: unit.col,
      fromRow: unit.row,
      toCol: command.targetCol,
      toRow: command.targetRow,
      target: goal.targetHex,
    );
    if (improvement <= 0) continue;
    return CommandRanking(
      CandidatePriority.war,
      900 + goal.priority * 100 + improvement * 20,
    );
  }

  return null;
}

bool _isOffensivePressureTarget(
  String playerId,
  GameView view,
  StrategicPlan? plan,
) {
  if (view.activeHostilePlayerIds.contains(playerId)) return true;
  if (view.pressureTargetPlayerIds.contains(playerId)) return true;
  return plan?.warGoals.any(
        (goal) =>
            goal.kind != WarGoalKind.defend && goal.targetPlayerId == playerId,
      ) ??
      false;
}

Set<String> _offensiveWarGoalTargetPlayerIdsForUnit(
  String unitId,
  StrategicPlan plan,
) {
  return {
    for (final goal in plan.warGoals)
      if (goal.kind != WarGoalKind.defend &&
          goal.assignedUnitIds.contains(unitId))
        goal.targetPlayerId,
  };
}
