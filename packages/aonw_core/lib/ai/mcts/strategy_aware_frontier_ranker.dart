import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_military_context.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_ranking_queries.dart';
import 'package:aonw_core/ai/strategic/frontier_clearing_plan.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

const _military = StrategyAwareMilitaryContext();

CommandRanking? rankFrontierClearingCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  final unitId = unitIdForCommand(command);
  if (unitId == null) return null;
  final assignment = plan.frontierClearingAssignments[unitId];
  if (assignment == null) return null;

  return switch (command) {
    AttackHexCommand() => _rankFrontierClearingAttack(
      command,
      view,
      context,
      assignment,
    ),
    MoveUnitCommand() => _rankFrontierClearingMove(command, view, assignment),
    _ => null,
  };
}

CommandRanking? rankFounderPressureClearingCommand(
  GameCommand command,
  GameView view,
  AiContext context,
) {
  if (command is! AttackHexCommand) return null;
  if (view.ownCities.isEmpty) return null;

  final defender = enemyAt(view, command.defenderCol, command.defenderRow);
  if (defender == null || !_military.isUnit(defender, context)) {
    return null;
  }

  final founderPressure = _nearestFounderPressure(
    view,
    HexCoordinate(col: defender.col, row: defender.row),
  );
  if (founderPressure == null) return null;

  final evaluation = AiCombatTactics.evaluateAttack(
    view: view,
    context: context,
    command: command,
  );
  if (evaluation == null ||
      !AiCombatTactics.shouldConsiderAttack(
        evaluation,
        context,
        protectsCivilian: true,
      )) {
    return const CommandRanking(CandidatePriority.fallback, -950);
  }

  final attacker = ownUnitById(view, command.attackerUnitId);
  if (attacker != null &&
      _military.isOnly(attacker, view, context) &&
      !_military.isSafeLastMilitaryAttack(evaluation)) {
    return const CommandRanking(CandidatePriority.fallback, -950);
  }

  final oneCityBonus = view.ownCities.length == 1 ? 42.0 : 0.0;
  return CommandRanking(
    CandidatePriority.opening,
    1215 +
        oneCityBonus +
        (3 - founderPressure.distance) * 34 +
        AiCombatTactics.rankingBonus(
          evaluation,
          context,
          protectsCivilian: true,
        ),
  );
}

({GameUnit founder, int distance})? _nearestFounderPressure(
  GameView view,
  HexCoordinate threat,
) {
  GameUnit? best;
  var bestDistance = 1 << 30;
  for (final unit in view.ownUnits) {
    if (!CityFoundingRules.canFoundCityWith(unit)) continue;
    if (unit.isWorking || unit.queuedPath != null) continue;
    final distance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      threat,
    );
    if (distance > 2) continue;
    if (distance < bestDistance ||
        (distance == bestDistance &&
            (best == null || unit.id.compareTo(best.id) < 0))) {
      best = unit;
      bestDistance = distance;
    }
  }
  return best == null ? null : (founder: best, distance: bestDistance);
}

CommandRanking? _rankFrontierClearingAttack(
  AttackHexCommand command,
  GameView view,
  AiContext context,
  StrategicFrontierClearingAssignment assignment,
) {
  if (command.defenderCol != assignment.targetHex.col ||
      command.defenderRow != assignment.targetHex.row) {
    return null;
  }
  final evaluation = AiCombatTactics.evaluateAttack(
    view: view,
    context: context,
    command: command,
  );
  if (evaluation == null ||
      evaluation.defender.ownerPlayerId != assignment.targetPlayerId ||
      !AiCombatTactics.shouldConsiderAttack(
        evaluation,
        context,
        protectsCivilian: true,
      )) {
    return const CommandRanking(CandidatePriority.fallback, -950);
  }

  return CommandRanking(
    CandidatePriority.opening,
    1234 +
        assignment.priority * 18 +
        AiCombatTactics.rankingBonus(
          evaluation,
          context,
          protectsCivilian: true,
        ),
  );
}

CommandRanking? _rankFrontierClearingMove(
  MoveUnitCommand command,
  GameView view,
  StrategicFrontierClearingAssignment assignment,
) {
  final unit = ownUnitById(view, command.unitId);
  if (unit == null) return null;
  final improvement = distanceImprovement(
    fromCol: unit.col,
    fromRow: unit.row,
    toCol: command.targetCol,
    toRow: command.targetRow,
    target: assignment.targetHex,
  );
  if (improvement <= 0) return null;
  final afterDistance = HexDistance.between(
    HexCoordinate(col: command.targetCol, row: command.targetRow),
    assignment.targetHex,
  );
  if (afterDistance > 2) return null;
  return CommandRanking(
    CandidatePriority.opening,
    1194 + assignment.priority * 12 + improvement * 22 - afterDistance * 3,
  );
}
