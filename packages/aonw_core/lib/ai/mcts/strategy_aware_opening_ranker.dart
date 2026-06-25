import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_command_candidate_guard.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_military_context.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_ranking_queries.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

const _military = StrategyAwareMilitaryContext();

CommandRanking? rankOpeningSurvivalCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan? plan,
) {
  if (!_needsOpeningSurvival(view)) return null;

  return switch (command) {
    FoundCityCommand() => _rankOpeningFoundCity(command, view, plan),
    MoveUnitCommand() => _rankOpeningMove(command, view, context, plan),
    AttackHexCommand() => _rankOpeningAttack(command, view, context),
    _ => null,
  };
}

CommandRanking? _rankOpeningFoundCity(
  FoundCityCommand command,
  GameView view,
  StrategicPlan? plan,
) {
  final founder = ownUnitById(view, command.founderId);
  if (founder == null || !CityFoundingRules.canFoundCityWith(founder)) {
    return null;
  }
  if (!isLegalMctsCommandCandidate(command, view)) return null;

  final assignment = plan?.settlerAssignments[founder.id];
  if (assignment == null) {
    return const CommandRanking(CandidatePriority.opening, 1280);
  }

  final distance = HexDistance.between(
    HexCoordinate(col: founder.col, row: founder.row),
    HexCoordinate(col: assignment.col, row: assignment.row),
  );
  if (distance > 0) {
    return CommandRanking(CandidatePriority.opening, 1160 - distance * 8);
  }
  return CommandRanking(CandidatePriority.opening, 1320 - distance * 8);
}

CommandRanking? _rankOpeningMove(
  MoveUnitCommand command,
  GameView view,
  AiContext context,
  StrategicPlan? plan,
) {
  final unit = ownUnitById(view, command.unitId);
  if (unit == null) return null;

  if (CityFoundingRules.canFoundCityWith(unit)) {
    final assignment = plan?.settlerAssignments[unit.id];
    if (assignment != null) {
      final improvement = distanceImprovement(
        fromCol: unit.col,
        fromRow: unit.row,
        toCol: command.targetCol,
        toRow: command.targetRow,
        target: HexCoordinate(col: assignment.col, row: assignment.row),
      );
      if (improvement > 0) {
        return CommandRanking(
          CandidatePriority.opening,
          1260 + improvement * 24,
        );
      }
      return null;
    }

    return const CommandRanking(CandidatePriority.opening, 1180);
  }

  if (!_military.isType(unit.type, context)) {
    return null;
  }

  final founder = _nearestOpeningFounder(
    view,
    HexCoordinate(col: unit.col, row: unit.row),
  );
  if (founder == null) return null;

  final improvement = distanceImprovement(
    fromCol: unit.col,
    fromRow: unit.row,
    toCol: command.targetCol,
    toRow: command.targetRow,
    target: HexCoordinate(col: founder.col, row: founder.row),
  );
  if (improvement <= 0) return null;

  return CommandRanking(CandidatePriority.opening, 1140 + improvement * 18);
}

CommandRanking _rankOpeningAttack(
  AttackHexCommand command,
  GameView view,
  AiContext context,
) {
  final defender = enemyAt(view, command.defenderCol, command.defenderRow);
  if (defender != null &&
      _isNearOpeningFounder(view, defender.col, defender.row)) {
    final evaluation = AiCombatTactics.evaluateAttack(
      view: view,
      context: context,
      command: command,
    );
    if (evaluation != null &&
        AiCombatTactics.shouldConsiderAttack(
          evaluation,
          context,
          protectsCivilian: true,
        )) {
      return CommandRanking(
        CandidatePriority.opening,
        1160 +
            AiCombatTactics.rankingBonus(
              evaluation,
              context,
              protectsCivilian: true,
            ),
      );
    }
  }

  return const CommandRanking(CandidatePriority.fallback, -1000);
}

bool _needsOpeningSurvival(GameView view) {
  if (view.ownCities.isNotEmpty) return false;
  return view.ownUnits.any(CityFoundingRules.canFoundCityWith);
}

GameUnit? _nearestOpeningFounder(GameView view, HexCoordinate from) {
  GameUnit? best;
  var bestDistance = 1 << 30;
  for (final unit in view.ownUnits) {
    if (!CityFoundingRules.canFoundCityWith(unit)) continue;
    final distance = HexDistance.between(
      from,
      HexCoordinate(col: unit.col, row: unit.row),
    );
    if (distance < bestDistance ||
        (distance == bestDistance &&
            (best == null || unit.id.compareTo(best.id) < 0))) {
      best = unit;
      bestDistance = distance;
    }
  }
  return best;
}

bool _isNearOpeningFounder(GameView view, int col, int row) {
  for (final unit in view.ownUnits) {
    if (!CityFoundingRules.canFoundCityWith(unit)) continue;
    final distance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      HexCoordinate(col: col, row: row),
    );
    if (distance <= 1) return true;
  }
  return false;
}
