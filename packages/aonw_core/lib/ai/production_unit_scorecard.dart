part of 'production_unit_scorer.dart';

final class _UnitProductionScorecard {
  const _UnitProductionScorecard(this.situation);

  final _UnitProductionSituation situation;

  double score() {
    final policy = _UnitProductionPolicy.forSituation(situation);
    var score = policy.baseScore(situation);
    score = policy.applyCivilianSafetyAndInfrastructure(score, situation);
    score = policy.applyExpansionPlan(score, situation);
    score = policy.applyEscortAndArmyPressure(score, situation);
    score = policy.applyStrategicMode(score, situation);
    score = policy.applyScarcityPressure(score, situation);
    score = _applySupplyPressure(score);
    return score - situation.effectiveCostPenalty * 1.15;
  }

  double _applySupplyPressure(double score) {
    if (situation.availableSupply - situation.supplyCost <= 0 &&
        !situation.isUrgentNeed) {
      score -= 4.0;
    }

    return score;
  }
}
