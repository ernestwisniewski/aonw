part of 'combat_tactics.dart';

final class _CombatRiskProfile {
  const _CombatRiskProfile({required this.aggression, required this.persona});

  factory _CombatRiskProfile.fromContext(AiContext context) {
    return _CombatRiskProfile(
      aggression:
          context.effectiveWeights.aggression *
          context.civProfile.belligerence *
          context.difficultyProfile.combatRiskMultiplier,
      persona: context.persona,
    );
  }

  final double aggression;
  final AiPersona persona;

  bool get acceptsAggressiveUnitTrade =>
      aggression >= 1.3 || persona == AiPersona.aggressive;

  bool get acceptsAggressiveCityTrade => aggression >= 1.25;
}

final class _AttackConsiderationPolicy {
  _AttackConsiderationPolicy({
    required AiContext context,
    required this.matchesWarGoal,
    required this.protectsCivilian,
    required this.defendingCity,
  }) : risk = _CombatRiskProfile.fromContext(context);

  final _CombatRiskProfile risk;
  final bool matchesWarGoal;
  final bool protectsCivilian;
  final bool defendingCity;

  bool accepts(AiAttackEvaluation evaluation) {
    if (_hasNoImpact(evaluation)) return false;
    if (evaluation.tradesAwayAttacker) return false;
    if (evaluation.isDecisive) return true;
    if (evaluation.targetIsCivilian) return true;
    if (evaluation.isFreeRangedDamage) return true;
    if (_protectsImportantGround(evaluation)) return true;
    if (_acceptsAggressiveRisk(evaluation)) return true;
    if (_advancesWarGoal(evaluation)) return true;

    return evaluation.defenderDamage >= evaluation.attackerDamage + 2;
  }

  bool _hasNoImpact(AiAttackEvaluation evaluation) {
    return evaluation.defenderDamage <= 0;
  }

  bool _protectsImportantGround(AiAttackEvaluation evaluation) {
    return (defendingCity || protectsCivilian || evaluation.threatensOwnCity) &&
        evaluation.defenderDamage >= evaluation.attackerDamage;
  }

  bool _acceptsAggressiveRisk(AiAttackEvaluation evaluation) {
    final highDamageFloor = math.max(
      2,
      (evaluation.defenderHpBefore * 0.35).ceil(),
    );
    return risk.acceptsAggressiveUnitTrade &&
        evaluation.defenderDamage >= highDamageFloor &&
        evaluation.defenderDamage + 1 >= evaluation.attackerDamage;
  }

  bool _advancesWarGoal(AiAttackEvaluation evaluation) {
    final warGoalDamageFloor = math.max(
      2,
      (evaluation.defenderHpBefore * 0.25).ceil(),
    );
    return matchesWarGoal &&
        evaluation.defenderDamage >= warGoalDamageFloor &&
        evaluation.defenderDamage >= evaluation.attackerDamage;
  }
}

final class _CityAttackConsiderationPolicy {
  _CityAttackConsiderationPolicy({
    required AiContext context,
    required this.matchesWarGoal,
  }) : risk = _CombatRiskProfile.fromContext(context);

  final _CombatRiskProfile risk;
  final bool matchesWarGoal;

  bool accepts(AiCityAttackEvaluation evaluation) {
    if (evaluation.defenderDamage <= 0) return false;
    if (evaluation.tradesAwayAttacker) return false;
    if (evaluation.cityDefeated) return true;
    if (evaluation.isFreeRangedDamage) return true;
    if (_advancesWarGoal(evaluation)) return true;
    if (_favorableDamageExchange(evaluation)) return true;

    return risk.acceptsAggressiveCityTrade &&
        evaluation.defenderDamage >= _damageFloor(evaluation) &&
        evaluation.defenderDamage + 1 >= evaluation.attackerDamage;
  }

  int _damageFloor(AiCityAttackEvaluation evaluation) {
    return math.max(
      2,
      (evaluation.defenderHpBefore * (matchesWarGoal ? 0.22 : 0.30)).ceil(),
    );
  }

  bool _advancesWarGoal(AiCityAttackEvaluation evaluation) {
    return matchesWarGoal &&
        !evaluation.attackerKilled &&
        evaluation.defenderDamage >= evaluation.attackerDamage &&
        evaluation.defenderDamage > 0;
  }

  bool _favorableDamageExchange(AiCityAttackEvaluation evaluation) {
    return evaluation.defenderDamage >= _damageFloor(evaluation) &&
        evaluation.defenderDamage >= evaluation.attackerDamage;
  }
}

final class _AttackCommandScorePolicy {
  _AttackCommandScorePolicy({
    required AiContext context,
    required bool matchesWarGoal,
    required bool protectsCivilian,
    required bool defendingCity,
  }) : risk = _CombatRiskProfile.fromContext(context),
       consideration = _AttackConsiderationPolicy(
         context: context,
         matchesWarGoal: matchesWarGoal,
         protectsCivilian: protectsCivilian,
         defendingCity: defendingCity,
       ),
       matchesWarGoal = matchesWarGoal,
       protectsCivilian = protectsCivilian,
       defendingCity = defendingCity;

  final _CombatRiskProfile risk;
  final _AttackConsiderationPolicy consideration;
  final bool matchesWarGoal;
  final bool protectsCivilian;
  final bool defendingCity;

  double score(AiAttackEvaluation evaluation) {
    if (!consideration.accepts(evaluation)) {
      return evaluation.heuristicScore.clamp(-0.16, 0.05).toDouble();
    }

    final score =
        0.08 +
        evaluation.heuristicScore +
        _warGoalBonus +
        _defensiveBonus(evaluation) +
        _aggressionBonus;
    return score.clamp(-0.18, 0.40).toDouble();
  }

  double get _warGoalBonus => matchesWarGoal ? 0.04 : 0.0;

  double _defensiveBonus(AiAttackEvaluation evaluation) {
    return defendingCity || protectsCivilian || evaluation.threatensOwnCity
        ? 0.03
        : 0.0;
  }

  double get _aggressionBonus =>
      (risk.aggression - 1.0).clamp(0.0, 1.0) * 0.025;
}

final class _CityAttackCommandScorePolicy {
  _CityAttackCommandScorePolicy({
    required AiContext context,
    required bool matchesWarGoal,
  }) : risk = _CombatRiskProfile.fromContext(context),
       consideration = _CityAttackConsiderationPolicy(
         context: context,
         matchesWarGoal: matchesWarGoal,
       ),
       matchesWarGoal = matchesWarGoal;

  final _CombatRiskProfile risk;
  final _CityAttackConsiderationPolicy consideration;
  final bool matchesWarGoal;

  double score(AiCityAttackEvaluation evaluation) {
    if (!consideration.accepts(evaluation)) {
      return evaluation.heuristicScore.clamp(-0.18, 0.04).toDouble();
    }

    final score =
        0.10 +
        evaluation.heuristicScore +
        _warGoalBonus +
        (risk.aggression - 1.0).clamp(0.0, 1.0) * 0.03;
    return score.clamp(-0.18, 0.48).toDouble();
  }

  double get _warGoalBonus => matchesWarGoal ? 0.07 : 0.0;
}

final class _AttackRankingBonusPolicy {
  _AttackRankingBonusPolicy({
    required AiContext context,
    required bool matchesWarGoal,
    required bool protectsCivilian,
    required bool defendingCity,
  }) : risk = _CombatRiskProfile.fromContext(context),
       consideration = _AttackConsiderationPolicy(
         context: context,
         matchesWarGoal: matchesWarGoal,
         protectsCivilian: protectsCivilian,
         defendingCity: defendingCity,
       ),
       protectsCivilian = protectsCivilian,
       defendingCity = defendingCity;

  final _CombatRiskProfile risk;
  final _AttackConsiderationPolicy consideration;
  final bool protectsCivilian;
  final bool defendingCity;

  double bonus(AiAttackEvaluation evaluation) {
    final bonus =
        evaluation.heuristicScore * 190 +
        _rejectionPenalty(evaluation) +
        _unitOutcomeBonus(evaluation) +
        _defensiveBonus(evaluation) +
        (risk.aggression - 1.0).clamp(0.0, 1.0) * 20;
    return bonus.clamp(-320.0, 320.0).toDouble();
  }

  double _rejectionPenalty(AiAttackEvaluation evaluation) {
    return consideration.accepts(evaluation) ? 0.0 : -260.0;
  }

  double _unitOutcomeBonus(AiAttackEvaluation evaluation) {
    return _bonusWhen(evaluation.defenderKilled, 90) +
        _bonusWhen(evaluation.capturesCity, 180) +
        _bonusWhen(evaluation.defenderRetreated, 35) +
        _bonusWhen(evaluation.targetIsCivilian, 70) +
        _bonusWhen(evaluation.isFreeRangedDamage, 35) -
        _bonusWhen(evaluation.attackerKilled, 180);
  }

  double _defensiveBonus(AiAttackEvaluation evaluation) {
    return defendingCity || protectsCivilian || evaluation.threatensOwnCity
        ? 35.0
        : 0.0;
  }
}

final class _CityAttackRankingBonusPolicy {
  _CityAttackRankingBonusPolicy({
    required AiContext context,
    required bool matchesWarGoal,
  }) : risk = _CombatRiskProfile.fromContext(context),
       consideration = _CityAttackConsiderationPolicy(
         context: context,
         matchesWarGoal: matchesWarGoal,
       ),
       matchesWarGoal = matchesWarGoal;

  final _CombatRiskProfile risk;
  final _CityAttackConsiderationPolicy consideration;
  final bool matchesWarGoal;

  double bonus(AiCityAttackEvaluation evaluation) {
    final bonus =
        evaluation.heuristicScore * 190 +
        _rejectionPenalty(evaluation) +
        _cityOutcomeBonus(evaluation) +
        (risk.aggression - 1.0).clamp(0.0, 1.0) * 24;
    return bonus.clamp(-340.0, 360.0).toDouble();
  }

  double _rejectionPenalty(AiCityAttackEvaluation evaluation) {
    return consideration.accepts(evaluation) ? 0.0 : -280.0;
  }

  double _cityOutcomeBonus(AiCityAttackEvaluation evaluation) {
    return _bonusWhen(evaluation.capturesCity, 230) +
        _bonusWhen(evaluation.destroysCity, 140) +
        _bonusWhen(evaluation.isFreeRangedDamage, 30) -
        _bonusWhen(evaluation.attackerKilled, 200) +
        _bonusWhen(matchesWarGoal, 45);
  }
}

abstract final class _CombatHeuristicScorer {
  static double unit(AiAttackEvaluation evaluation) {
    final score =
        _unitExchangeScore(evaluation) +
        _unitOutcomeBonus(evaluation) +
        _unitLowImpactPenalty(evaluation);
    return score.clamp(-0.30, 0.60).toDouble();
  }

  static double city(AiCityAttackEvaluation evaluation) {
    final score =
        _cityExchangeScore(evaluation) +
        _cityOutcomeBonus(evaluation) +
        _cityLowImpactPenalty(evaluation);
    return score.clamp(-0.35, 0.70).toDouble();
  }

  static double _unitExchangeScore(AiAttackEvaluation evaluation) {
    final defenderRatio =
        evaluation.defenderDamage / math.max(1, evaluation.defenderHpBefore);
    final attackerRatio =
        evaluation.attackerDamage / math.max(1, evaluation.attackerHpBefore);
    return 0.02 + defenderRatio * 0.20 - attackerRatio * 0.24;
  }

  static double _unitOutcomeBonus(AiAttackEvaluation evaluation) {
    return _defenderKillBonus(evaluation) +
        _bonusWhen(evaluation.capturesCity, 0.36) +
        _bonusWhen(evaluation.defenderRetreated, 0.08) +
        _bonusWhen(
          evaluation.targetIsCivilian && evaluation.defenderDamage > 0,
          0.10,
        ) +
        _bonusWhen(evaluation.isFreeRangedDamage, 0.06) +
        _bonusWhen(evaluation.threatensOwnCity, 0.06) -
        _bonusWhen(evaluation.attackerKilled, 0.45);
  }

  static double _defenderKillBonus(AiAttackEvaluation evaluation) {
    if (!evaluation.defenderKilled) return 0;
    return evaluation.targetIsCivilian ? 0.24 : 0.28;
  }

  static double _unitLowImpactPenalty(AiAttackEvaluation evaluation) {
    final lowImpactFloor = math.max(
      2,
      (evaluation.defenderHpBefore * 0.25).ceil(),
    );
    final lowImpactAttack =
        !evaluation.defenderKilled &&
        !evaluation.targetIsCivilian &&
        evaluation.defenderDamage < lowImpactFloor;
    return lowImpactAttack ? -0.05 : 0.0;
  }

  static double _cityExchangeScore(AiCityAttackEvaluation evaluation) {
    final defenderRatio =
        evaluation.defenderDamage / math.max(1, evaluation.defenderHpBefore);
    final attackerRatio =
        evaluation.attackerDamage / math.max(1, evaluation.attackerHpBefore);
    return 0.03 + defenderRatio * 0.23 - attackerRatio * 0.25;
  }

  static double _cityOutcomeBonus(AiCityAttackEvaluation evaluation) {
    return _bonusWhen(evaluation.capturesCity, 0.48) +
        _bonusWhen(evaluation.destroysCity, 0.28) +
        _bonusWhen(evaluation.isFreeRangedDamage, 0.06) -
        _bonusWhen(evaluation.attackerKilled, 0.50);
  }

  static double _cityLowImpactPenalty(AiCityAttackEvaluation evaluation) {
    final lowImpactAttack =
        !evaluation.cityDefeated &&
        evaluation.defenderDamage <
            math.max(2, (evaluation.defenderHpBefore * 0.25).ceil());
    return lowImpactAttack ? -0.06 : 0.0;
  }
}

double _bonusWhen(bool condition, num bonus) {
  return condition ? bonus.toDouble() : 0.0;
}
