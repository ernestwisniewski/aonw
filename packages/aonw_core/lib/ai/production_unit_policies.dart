part of 'production_unit_scorer.dart';

abstract class _UnitProductionPolicy {
  const _UnitProductionPolicy();

  static _UnitProductionPolicy forSituation(
    _UnitProductionSituation situation,
  ) {
    return switch (situation.unitType) {
      GameUnitType.worker => const _WorkerProductionPolicy(),
      GameUnitType.settler => const _SettlerProductionPolicy(),
      GameUnitType.scout => const _ScoutProductionPolicy(),
      _ when AiUnitRoles.isMilitaryType(situation.unitType) =>
        const _MilitaryProductionPolicy(),
      _ => const _NoUnitProductionPolicy(),
    };
  }

  double baseScore(_UnitProductionSituation situation);

  double applyCivilianSafetyAndInfrastructure(
    double score,
    _UnitProductionSituation situation,
  ) {
    return score;
  }

  double applyExpansionPlan(double score, _UnitProductionSituation situation) {
    return score;
  }

  double applyEscortAndArmyPressure(
    double score,
    _UnitProductionSituation situation,
  ) {
    return score + situation.counterPressureScore;
  }

  double applyStrategicMode(double score, _UnitProductionSituation situation) {
    return score;
  }

  double applyScarcityPressure(
    double score,
    _UnitProductionSituation situation,
  ) {
    return score;
  }
}

final class _WorkerProductionPolicy extends _UnitProductionPolicy {
  const _WorkerProductionPolicy();

  @override
  double baseScore(_UnitProductionSituation situation) {
    if (situation.planState.workerCount == 0 && situation.workerDeficit > 0) {
      return 11.5 + situation.workerDeficit * 1.8;
    }
    if (situation.workerDeficit > 0) {
      return 6.4 +
          situation.workerDeficit * 1.4 +
          situation.assessment.cityCount.clamp(0, 4) * 0.4;
    }
    return 0.4;
  }

  @override
  double applyCivilianSafetyAndInfrastructure(
    double score,
    _UnitProductionSituation situation,
  ) {
    if (situation.enemyMilitaryPressure ||
        situation.localDefenseNeedsProduction) {
      score -=
          6.5 +
          situation.localDefensePressure +
          (situation.enemyMilitaryPressure ? 2.5 : 0.0);
    }
    if (situation.oneCityReserveDefenseDeficit > 0) {
      score -= 5.0 + situation.oneCityReserveDefenseDeficit * 1.5;
    }
    return score;
  }

  @override
  double applyExpansionPlan(double score, _UnitProductionSituation situation) {
    if (situation.expansionNeed &&
        situation.workerDeficit > 0 &&
        situation.weights.expansion >= 1.2) {
      score -= 2.0;
    }
    if (situation.safeSecondCityWindow && situation.workerDeficit > 0) {
      score -= 4.5;
    }
    return score;
  }

  @override
  double applyStrategicMode(double score, _UnitProductionSituation situation) {
    switch (situation.context.strategicPlan?.mode) {
      case StrategicMode.recover:
        if (situation.workerDeficit > 0) score += 1.8;
      case StrategicMode.consolidate:
        if (situation.workerDeficit > 0) score += 1.0;
      case StrategicMode.military ||
          StrategicMode.expand ||
          StrategicMode.techRush ||
          null:
        break;
    }
    return score;
  }
}

final class _SettlerProductionPolicy extends _UnitProductionPolicy {
  const _SettlerProductionPolicy();

  @override
  double baseScore(_UnitProductionSituation situation) {
    if (!situation.expansionNeed) return 0.0;

    return 8.0 +
        situation.expansionDeficit * 0.9 +
        situation.weights.expansion * 1.2 +
        mapExpansionRoomScore(situation.view.mapData) +
        (situation.weights.expansion >= situation.weights.aggression
            ? 1.0
            : 0.0);
  }

  @override
  double applyCivilianSafetyAndInfrastructure(
    double score,
    _UnitProductionSituation situation,
  ) {
    if (!situation.city.buildings.contains(CityBuildingType.granary) &&
        situation.weights.expansion < 1.2) {
      score -= settlerInfrastructurePenalty(situation.view.mapData);
    }
    return score;
  }

  @override
  double applyExpansionPlan(double score, _UnitProductionSituation situation) {
    if (situation.workerDeficit > 0) {
      if (situation.weights.expansion >= 1.2 ||
          situation.openingSecondCitySprint ||
          situation.safeSecondCityPush) {
        score -= 0.0;
      } else if (situation.stableSecondCityPush) {
        score -= 1.0;
      } else if (situation.stableThirdCityPush &&
          situation.workerCoverageDeficit <= 1) {
        score -= 1.0;
      } else if (situation.stableThirdCityPush) {
        final severeWorkerGap = (situation.workerCoverageDeficit - 2)
            .clamp(0, 2)
            .toDouble();
        score -= 11.0 + severeWorkerGap * 2.0;
      } else {
        score -= 6.0;
      }
    }
    if (situation.assessment.cityCount <= 1 &&
        !situation.oneCitySettlerDefenseCovered &&
        !situation.safeSecondCityPush) {
      final missingReserve = (2 - situation.planState.militaryCount)
          .clamp(1, 2)
          .toInt();
      score -= 8.0 + missingReserve * 3.0;
    }
    if (situation.safeSecondCityPush &&
        !situation.stableSecondCityPush &&
        !situation.openingSecondCitySprint) {
      score +=
          14.0 + situation.expansionDeficit * 0.7 + situation.weights.expansion;
    }
    if (situation.openingSecondCitySprint) {
      score += 8.0 + situation.weights.aggression;
    }
    if (situation.stableSecondCityPush) {
      score +=
          18.0 + situation.expansionDeficit * 0.7 + situation.weights.expansion;
    }
    if (situation.reinforcedSecondCityPush) {
      score +=
          14.0 +
          situation.expansionDeficit * 0.7 +
          situation.weights.expansion +
          (situation.enemyMilitaryPressure ? 2.0 : 0.0);
    }
    if (situation.stableThirdCityPush) {
      score +=
          10.0 + situation.expansionDeficit * 1.0 + situation.weights.expansion;
    }
    if (situation.thirdCityInfrastructureGap) {
      score -= 28.0;
    }
    if (situation.expansionNeed && situation.weights.expansion >= 1.2) {
      score += 2.0;
    }
    if (situation.expansionNeed &&
        situation.planState.militaryCount >=
            situation.assessment.cityCount + 1 &&
        !situation.localDefenseNeedsProduction) {
      score += situation.assessment.cityCount >= 2 ? 3.0 : 1.2;
    }
    if (situation.localDefenseNeedsProduction) {
      final threat = situation.localDefense!.threatLevel
          .clamp(0, 10)
          .toDouble();
      score -= situation.reinforcedSecondCityPush
          ? 1.5 + threat * 0.1
          : situation.stableThirdCityPush && situation.escortedThirdCityPush
          ? 1.0 + threat * 0.1
          : 4.0 + threat * 0.2;
    }
    if (situation.planState.settlerCount > 0) {
      final pipelinePenalty = situation.assessment.cityCount < 2
          ? (situation.weights.expansion >= 1.2 ? 4.5 : 10.0)
          : (situation.weights.expansion >= 1.2 ? 1.5 : 6.0);
      score -=
          pipelinePenalty +
          situation.workerCoverageDeficit * 2.0 +
          situation.cityDefenseDeficit * 1.5;
    }
    return score;
  }

  @override
  double applyEscortAndArmyPressure(
    double score,
    _UnitProductionSituation situation,
  ) {
    if (situation.activeSettlerNeedsEscort) {
      score -= 5.5;
    }
    return super.applyEscortAndArmyPressure(score, situation);
  }

  @override
  double applyStrategicMode(double score, _UnitProductionSituation situation) {
    switch (situation.context.strategicPlan?.mode) {
      case StrategicMode.military:
        score += situation.stableSecondCityPush
            ? 3.0
            : situation.reinforcedSecondCityPush
            ? 1.5
            : situation.safeSecondCityPush
            ? 1.0
            : situation.protectedSecondCityPush
            ? 2.5
            : -3.0;
      case StrategicMode.expand:
        score += 2.0;
        if (situation.cityDefenseDeficit >= 2) {
          score -= 3.0;
        }
      case StrategicMode.recover:
        score -=
            situation.stableSecondCityPush ||
                situation.reinforcedSecondCityPush ||
                situation.safeSecondCityPush
            ? 0.5
            : 4.0;
      case StrategicMode.consolidate:
        if (situation.assessment.cityCount >= 2) {
          score -= 1.5;
        }
      case StrategicMode.techRush:
        if (situation.assessment.cityCount >= 2) {
          score -= 1.0;
        }
      case null:
        break;
    }
    return score;
  }
}

final class _ScoutProductionPolicy extends _UnitProductionPolicy {
  const _ScoutProductionPolicy();

  @override
  double baseScore(_UnitProductionSituation situation) {
    if (!situation.localDefenseNeedsProduction &&
        situation.needsCitySiteScoutProduction) {
      return 16.0 +
          situation.expansionDeficit.clamp(0, 4) * 0.8 +
          situation.weights.expansion;
    }
    if (situation.hasNoOpeningScout && situation.view.turn <= 20) {
      return 2.2;
    }
    return 0.0;
  }

  @override
  double applyCivilianSafetyAndInfrastructure(
    double score,
    _UnitProductionSituation situation,
  ) {
    if (situation.localDefenseNeedsProduction) {
      score -= 6.0 + situation.localDefensePressure;
    }
    if (situation.oneCityReserveDefenseDeficit > 0) {
      score -= 8.0;
    }
    return score;
  }
}

final class _MilitaryProductionPolicy extends _UnitProductionPolicy {
  const _MilitaryProductionPolicy();

  @override
  double baseScore(_UnitProductionSituation situation) {
    if (situation.reserveDefenderDeficit > 0) {
      return 7.0 +
          situation.reserveDefenderDeficit * 1.4 +
          situation.cityDefensePressure +
          situation.localDefensePressure +
          situation.weights.aggression * 0.6 +
          situation.unitPowerScore;
    }
    if (situation.militaryDeficit > 0) {
      return 6.2 +
          situation.militaryDeficit * 1.1 +
          situation.cityDefensePressure +
          situation.localDefensePressure +
          situation.weights.aggression * 0.7 +
          situation.unitPowerScore;
    }
    if (situation.assessment.needsMilitary) {
      return 4.0 +
          situation.localDefensePressure +
          situation.weights.aggression * 0.5 +
          situation.unitPowerScore;
    }
    if (situation.localDefenseNeedsProduction) {
      return 3.8 + situation.localDefensePressure + situation.unitPowerScore;
    }
    if (situation.activeSettlerNeedsEscort) {
      return 6.8 +
          situation.weights.aggression * 0.6 +
          situation.unitPowerScore;
    }
    return 0.6 + situation.unitPowerScore * 0.4;
  }

  @override
  double applyEscortAndArmyPressure(
    double score,
    _UnitProductionSituation situation,
  ) {
    if (situation.activeSettlerNeedsEscort) {
      score += 3.0;
    }
    if (situation.localDefenseNeedsProduction) {
      final threat = situation.localDefense!.threatLevel
          .clamp(0, 12)
          .toDouble();
      final missingGarrison = situation.localDefense!.hasAssignedGarrison
          ? 0.0
          : 1.0;
      score += 2.2 + missingGarrison + threat * 0.05;
    }
    if (situation.weights.aggression > situation.weights.expansion &&
        situation.militaryDeficit > 0) {
      score += 2.2;
    }

    score = super.applyEscortAndArmyPressure(score, situation);

    if (situation.oneCityReserveDefenseDeficit > 0) {
      score += 5.0 + situation.oneCityReserveDefenseDeficit * 1.5;
    }
    if (!situation.needsCitySiteScoutProduction &&
        situation.militarySurplus > 0) {
      final toleratedSurplus =
          situation.enemyMilitaryPressure ||
              situation.localDefenseNeedsProduction
          ? 1
          : 0;
      final surplusToDiscourage = situation.militarySurplus - toleratedSurplus;
      if (surplusToDiscourage > 0) {
        final economyPressure = situation.assessment.netGoldPerTurn < 0
            ? 1.5
            : 0.85;
        final aggressionRelief =
            situation.weights.aggression > situation.weights.expansion
            ? 0.65
            : 1.0;
        score -= surplusToDiscourage * economyPressure * aggressionRelief;
      }
    }

    return score;
  }

  @override
  double applyStrategicMode(double score, _UnitProductionSituation situation) {
    switch (situation.context.strategicPlan?.mode) {
      case StrategicMode.military:
        score += 3.0;
      case StrategicMode.expand:
        if (situation.cityDefenseDeficit > 0) {
          score += situation.cityDefenseDeficit * 1.25;
        }
        if (!situation.assessment.needsMilitary) {
          score -= 1.0;
        }
      case StrategicMode.recover ||
          StrategicMode.consolidate ||
          StrategicMode.techRush ||
          null:
        break;
    }
    return score;
  }

  @override
  double applyScarcityPressure(
    double score,
    _UnitProductionSituation situation,
  ) {
    if (!situation.needsCitySiteScoutProduction &&
        situation.expansionNeed &&
        !situation.enemyMilitaryPressure &&
        situation.weights.aggression <= situation.weights.expansion) {
      score -= 2.5;
    }
    return score;
  }
}

final class _NoUnitProductionPolicy extends _UnitProductionPolicy {
  const _NoUnitProductionPolicy();

  @override
  double baseScore(_UnitProductionSituation situation) => 0.0;
}
