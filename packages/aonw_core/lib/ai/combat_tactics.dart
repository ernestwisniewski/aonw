import 'dart:math' as math;

import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_persona.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

part 'combat_tactics_evaluation_builders.dart';
part 'combat_tactics_evaluations.dart';
part 'combat_tactics_policies.dart';
part 'combat_tactics_queries.dart';

abstract final class AiCombatTactics {
  static const _unitAttackBuilder = _UnitAttackEvaluationBuilder();
  static const _cityAttackBuilder = _CityAttackEvaluationBuilder();

  static AiAttackEvaluation? evaluateAttack({
    required GameView view,
    required AiContext context,
    required AttackHexCommand command,
  }) {
    return _unitAttackBuilder.evaluate(
      view: view,
      context: context,
      command: command,
    );
  }

  static bool shouldConsiderAttack(
    AiAttackEvaluation evaluation,
    AiContext context, {
    bool matchesWarGoal = false,
    bool protectsCivilian = false,
    bool defendingCity = false,
  }) {
    return _AttackConsiderationPolicy(
      context: context,
      matchesWarGoal: matchesWarGoal,
      protectsCivilian: protectsCivilian,
      defendingCity: defendingCity,
    ).accepts(evaluation);
  }

  static AiCityAttackEvaluation? evaluateCityAttack({
    required GameView view,
    required AiContext context,
    required AttackHexCommand command,
  }) {
    return _cityAttackBuilder.evaluate(
      view: view,
      context: context,
      command: command,
    );
  }

  static bool shouldConsiderCityAttack(
    AiCityAttackEvaluation evaluation,
    AiContext context, {
    bool matchesWarGoal = false,
  }) {
    return _CityAttackConsiderationPolicy(
      context: context,
      matchesWarGoal: matchesWarGoal,
    ).accepts(evaluation);
  }

  static double commandScore(
    AiAttackEvaluation evaluation,
    AiContext context, {
    bool matchesWarGoal = false,
    bool protectsCivilian = false,
    bool defendingCity = false,
  }) {
    return _AttackCommandScorePolicy(
      context: context,
      matchesWarGoal: matchesWarGoal,
      protectsCivilian: protectsCivilian,
      defendingCity: defendingCity,
    ).score(evaluation);
  }

  static double cityCommandScore(
    AiCityAttackEvaluation evaluation,
    AiContext context, {
    bool matchesWarGoal = false,
  }) {
    return _CityAttackCommandScorePolicy(
      context: context,
      matchesWarGoal: matchesWarGoal,
    ).score(evaluation);
  }

  static double rankingBonus(
    AiAttackEvaluation evaluation,
    AiContext context, {
    bool matchesWarGoal = false,
    bool protectsCivilian = false,
    bool defendingCity = false,
  }) {
    return _AttackRankingBonusPolicy(
      context: context,
      matchesWarGoal: matchesWarGoal,
      protectsCivilian: protectsCivilian,
      defendingCity: defendingCity,
    ).bonus(evaluation);
  }

  static double cityRankingBonus(
    AiCityAttackEvaluation evaluation,
    AiContext context, {
    bool matchesWarGoal = false,
  }) {
    return _CityAttackRankingBonusPolicy(
      context: context,
      matchesWarGoal: matchesWarGoal,
    ).bonus(evaluation);
  }

  static double effectiveAggression(AiContext context) {
    return _CombatRiskProfile.fromContext(context).aggression;
  }
}
