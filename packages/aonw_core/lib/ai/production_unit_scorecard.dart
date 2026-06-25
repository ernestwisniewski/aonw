part of 'production_unit_scorer.dart';

final class _UnitProductionScorecard {
  const _UnitProductionScorecard(this.situation);

  final _UnitProductionSituation situation;

  double score() {
    var score = _basePolicy.baseScore(situation);
    score = _applyCivilianSafetyAndInfrastructure(score);
    score = _applySettlerExpansionPlan(score);
    score = _applyEscortAndArmyPressure(score);
    score = _applyStrategicMode(score);
    score = _applyScarcityPenalties(score);
    return score - situation.effectiveCostPenalty * 1.15;
  }

  _UnitProductionPolicy get _basePolicy {
    if (situation.isWorker) return const _WorkerProductionPolicy();
    if (situation.isSettler) return const _SettlerProductionPolicy();
    if (situation.isScout) return const _ScoutProductionPolicy();
    if (situation.isMilitary) return const _MilitaryProductionPolicy();
    return const _NoUnitProductionPolicy();
  }

  double _applyCivilianSafetyAndInfrastructure(double score) {
    final s = situation;

    if (s.isSettler &&
        !s.city.buildings.contains(CityBuildingType.granary) &&
        s.weights.expansion < 1.2) {
      score -= settlerInfrastructurePenalty(s.view.mapData);
    }
    if (s.isWorker &&
        (s.enemyMilitaryPressure || s.localDefenseNeedsProduction)) {
      score -=
          6.5 + s.localDefensePressure + (s.enemyMilitaryPressure ? 2.5 : 0.0);
    }
    if (s.isWorker && s.oneCityReserveDefenseDeficit > 0) {
      score -= 5.0 + s.oneCityReserveDefenseDeficit * 1.5;
    }
    if (s.isScout && s.localDefenseNeedsProduction) {
      score -= 6.0 + s.localDefensePressure;
    }
    if (s.isScout && s.oneCityReserveDefenseDeficit > 0) {
      score -= 8.0;
    }

    return score;
  }

  double _applySettlerExpansionPlan(double score) {
    final s = situation;

    if (s.isSettler && s.workerDeficit > 0) {
      if (s.weights.expansion >= 1.2 ||
          s.openingSecondCitySprint ||
          s.safeSecondCityPush) {
        score -= 0.0;
      } else if (s.stableSecondCityPush) {
        score -= 1.0;
      } else if (s.stableThirdCityPush && s.workerCoverageDeficit <= 1) {
        score -= 1.0;
      } else if (s.stableThirdCityPush) {
        final severeWorkerGap = (s.workerCoverageDeficit - 2)
            .clamp(0, 2)
            .toDouble();
        score -= 11.0 + severeWorkerGap * 2.0;
      } else {
        score -= 6.0;
      }
    }
    if (s.isSettler &&
        s.assessment.cityCount <= 1 &&
        !s.oneCitySettlerDefenseCovered &&
        !s.safeSecondCityPush) {
      final missingReserve = (2 - s.planState.militaryCount)
          .clamp(1, 2)
          .toInt();
      score -= 8.0 + missingReserve * 3.0;
    }
    if (s.isSettler &&
        s.safeSecondCityPush &&
        !s.stableSecondCityPush &&
        !s.openingSecondCitySprint) {
      score += 14.0 + s.expansionDeficit * 0.7 + s.weights.expansion;
    }
    if (s.isSettler && s.openingSecondCitySprint) {
      score += 8.0 + s.weights.aggression;
    }
    if (s.isSettler && s.stableSecondCityPush) {
      score += 18.0 + s.expansionDeficit * 0.7 + s.weights.expansion;
    }
    if (s.isSettler && s.reinforcedSecondCityPush) {
      score +=
          14.0 +
          s.expansionDeficit * 0.7 +
          s.weights.expansion +
          (s.enemyMilitaryPressure ? 2.0 : 0.0);
    }
    if (s.isSettler && s.stableThirdCityPush) {
      score += 10.0 + s.expansionDeficit * 1.0 + s.weights.expansion;
    }
    if (s.isSettler && s.thirdCityInfrastructureGap) {
      score -= 28.0;
    }
    if (s.isSettler && s.expansionNeed && s.weights.expansion >= 1.2) {
      score += 2.0;
    }
    if (s.isSettler &&
        s.expansionNeed &&
        s.planState.militaryCount >= s.assessment.cityCount + 1 &&
        !s.localDefenseNeedsProduction) {
      score += s.assessment.cityCount >= 2 ? 3.0 : 1.2;
    }
    if (s.isSettler && s.localDefenseNeedsProduction) {
      final threat = s.localDefense!.threatLevel.clamp(0, 10).toDouble();
      score -= s.reinforcedSecondCityPush
          ? 1.5 + threat * 0.1
          : s.stableThirdCityPush && s.escortedThirdCityPush
          ? 1.0 + threat * 0.1
          : 4.0 + threat * 0.2;
    }
    if (s.isWorker &&
        s.expansionNeed &&
        s.workerDeficit > 0 &&
        s.weights.expansion >= 1.2) {
      score -= 2.0;
    }
    if (s.isWorker && s.safeSecondCityWindow && s.workerDeficit > 0) {
      score -= 4.5;
    }
    if (s.isSettler && s.planState.settlerCount > 0) {
      final pipelinePenalty = s.assessment.cityCount < 2
          ? (s.weights.expansion >= 1.2 ? 4.5 : 10.0)
          : (s.weights.expansion >= 1.2 ? 1.5 : 6.0);
      score -=
          pipelinePenalty +
          s.workerCoverageDeficit * 2.0 +
          s.cityDefenseDeficit * 1.5;
    }

    return score;
  }

  double _applyEscortAndArmyPressure(double score) {
    final s = situation;

    if (s.isSettler && s.activeSettlerNeedsEscort) {
      score -= 5.5;
    }
    if (s.isMilitary && s.activeSettlerNeedsEscort) {
      score += 3.0;
    }
    if (s.isMilitary && s.localDefenseNeedsProduction) {
      final threat = s.localDefense!.threatLevel.clamp(0, 12).toDouble();
      final missingGarrison = s.localDefense!.hasAssignedGarrison ? 0.0 : 1.0;
      score += 2.2 + missingGarrison + threat * 0.05;
    }
    if (s.isMilitary &&
        s.weights.aggression > s.weights.expansion &&
        s.militaryDeficit > 0) {
      score += 2.2;
    }

    score += s.counterPressureScore;

    if (s.isMilitary && s.oneCityReserveDefenseDeficit > 0) {
      score += 5.0 + s.oneCityReserveDefenseDeficit * 1.5;
    }
    if (s.isMilitary &&
        !s.needsCitySiteScoutProduction &&
        s.militarySurplus > 0) {
      final toleratedSurplus =
          s.enemyMilitaryPressure || s.localDefenseNeedsProduction ? 1 : 0;
      final surplusToDiscourage = s.militarySurplus - toleratedSurplus;
      if (surplusToDiscourage > 0) {
        final economyPressure = s.assessment.netGoldPerTurn < 0 ? 1.5 : 0.85;
        final aggressionRelief = s.weights.aggression > s.weights.expansion
            ? 0.65
            : 1.0;
        score -= surplusToDiscourage * economyPressure * aggressionRelief;
      }
    }

    return score;
  }

  double _applyStrategicMode(double score) {
    final s = situation;

    switch (s.context.strategicPlan?.mode) {
      case StrategicMode.military:
        score += s.isMilitary ? 3.0 : 0.0;
        if (s.isSettler) {
          score += s.stableSecondCityPush
              ? 3.0
              : s.reinforcedSecondCityPush
              ? 1.5
              : s.safeSecondCityPush
              ? 1.0
              : s.protectedSecondCityPush
              ? 2.5
              : -3.0;
        }
      case StrategicMode.expand:
        if (s.isSettler) score += 2.0;
        if (s.isSettler && s.cityDefenseDeficit >= 2) {
          score -= 3.0;
        }
        if (s.isMilitary && s.cityDefenseDeficit > 0) {
          score += s.cityDefenseDeficit * 1.25;
        }
        if (s.isMilitary && !s.assessment.needsMilitary) {
          score -= 1.0;
        }
      case StrategicMode.recover:
        if (s.isWorker && s.workerDeficit > 0) score += 1.8;
        if (s.isSettler) {
          score -=
              s.stableSecondCityPush ||
                  s.reinforcedSecondCityPush ||
                  s.safeSecondCityPush
              ? 0.5
              : 4.0;
        }
      case StrategicMode.consolidate:
        if (s.isWorker && s.workerDeficit > 0) score += 1.0;
        if (s.isSettler && s.assessment.cityCount >= 2) {
          score -= 1.5;
        }
      case StrategicMode.techRush:
        if (s.isSettler && s.assessment.cityCount >= 2) {
          score -= 1.0;
        }
      case null:
        break;
    }

    return score;
  }

  double _applyScarcityPenalties(double score) {
    final s = situation;

    if (s.isMilitary &&
        !s.needsCitySiteScoutProduction &&
        s.expansionNeed &&
        !s.enemyMilitaryPressure &&
        s.weights.aggression <= s.weights.expansion) {
      score -= 2.5;
    }
    if (s.availableSupply - s.supplyCost <= 0 && !s.isUrgentNeed) {
      score -= 4.0;
    }

    return score;
  }
}
