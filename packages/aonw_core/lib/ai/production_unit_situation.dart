part of 'production_unit_scorer.dart';

final class _UnitProductionSituation {
  const _UnitProductionSituation({
    required this.unitType,
    required this.city,
    required this.view,
    required this.context,
    required this.assessment,
    required this.planState,
    required this.cache,
    required this.counterPressureScorer,
  });

  final GameUnitType unitType;
  final GameCity city;
  final GameView view;
  final AiContext context;
  final AiEmpireAssessment assessment;
  final AiProductionPlanState planState;
  final AiProductionScoringCache cache;
  final AiProductionCounterPressureScorer counterPressureScorer;

  PersonaWeights get weights => context.effectiveWeights;

  bool get isWorker => unitType == GameUnitType.worker;

  bool get isSettler => unitType == GameUnitType.settler;

  bool get isScout => unitType == GameUnitType.scout;

  bool get isMilitary => AiUnitRoles.isMilitaryType(unitType);

  bool get expansionNeed {
    return assessment.cityCount + planState.settlerCount <
        assessment.desiredCityCount;
  }

  int get expansionDeficit {
    return assessment.desiredCityCount -
        assessment.cityCount -
        planState.settlerCount;
  }

  int get militaryDeficit {
    return assessment.desiredMilitaryCount - planState.militaryCount;
  }

  int get militarySurplus {
    return planState.militaryCount - assessment.desiredMilitaryCount;
  }

  bool get enemyMilitaryPressure => assessment.enemyMilitaryPressure;

  int get oneCityReserveDefenseDeficit {
    return assessment.cityCount == 1 &&
            planState.militaryCount > 0 &&
            militaryDeficit > 0 &&
            weights.aggression > weights.expansion
        ? militaryDeficit.clamp(0, 2).toInt()
        : 0;
  }

  StrategicDefenseAssignment? get localDefense {
    return context.strategicPlan?.defenses[city.id];
  }

  bool get localDefenseNeedsProduction {
    final defense = localDefense;
    return defense != null &&
        (defense.threatLevel > 0 ||
            (!defense.hasAssignedGarrison &&
                planState.militaryCount < assessment.cityCount));
  }

  int get reserveDefenderDeficit {
    return _reserveDefenderDeficit(
      assessment: assessment,
      planState: planState,
      defense: localDefense,
      localDefenseNeedsProduction: localDefenseNeedsProduction,
    );
  }

  double get localDefensePressure {
    return _localDefenseProductionPressure(localDefense);
  }

  int get cityDefenseDeficit {
    return planState.militaryCount > 0
        ? (assessment.cityCount - planState.militaryCount).clamp(0, 3).toInt()
        : 0;
  }

  double get cityDefensePressure {
    return cityDefenseDeficit <= 1
        ? cityDefenseDeficit * 0.8
        : cityDefenseDeficit * 2.0;
  }

  int get workerDeficit {
    return assessment.desiredWorkerCount - planState.workerCount;
  }

  int get workerCoverageDeficit {
    return (assessment.cityCount - planState.workerCount).clamp(0, 3).toInt();
  }

  bool get escortedThirdCityPush {
    return assessment.cityCount == 2 &&
        planState.militaryCount >= assessment.cityCount + 1 &&
        !enemyMilitaryPressure;
  }

  int get availableSupply => cache.availableUnitSupply(planState);

  int get supplyCost => CityUnitSupplyRules.supplyCostForType(unitType);

  bool get needsCitySiteScoutProduction {
    return isScout &&
        workerDeficit <= 0 &&
        cache.needsCitySiteScoutProduction(planState);
  }

  bool get oneCitySettlerDefenseCovered {
    return assessment.cityCount > 1 || planState.militaryCount >= 2;
  }

  bool get safeSecondCityWindow {
    return expansionNeed &&
        assessment.cityCount == 1 &&
        planState.settlerCount == 0 &&
        planState.militaryCount >= 1 &&
        assessment.netGoldPerTurn >= 0 &&
        weights.expansion >= weights.aggression &&
        localDefenseCovered &&
        !localDefenseNeedsProduction &&
        !enemyMilitaryPressure;
  }

  bool get safeSecondCityPush {
    return isSettler && safeSecondCityWindow;
  }

  bool get localDefenseCovered {
    final defense = localDefense;
    return defense == null ||
        !localDefenseNeedsProduction ||
        (defense.hasAssignedGarrison && planState.militaryCount >= 2);
  }

  bool get reinforcedSecondCityPush {
    return isSettler &&
        expansionNeed &&
        assessment.cityCount == 1 &&
        planState.settlerCount == 0 &&
        planState.militaryCount >= 3 &&
        planState.workerCount >= 1 &&
        assessment.netGoldPerTurn >= -2 &&
        localDefenseCovered;
  }

  bool get isUrgentNeed {
    return isWorker && workerDeficit > 0 ||
        needsCitySiteScoutProduction ||
        isSettler &&
            expansionNeed &&
            planState.settlerCount == 0 &&
            (oneCitySettlerDefenseCovered || reinforcedSecondCityPush) ||
        isMilitary &&
            (militaryDeficit > 0 ||
                reserveDefenderDeficit > 0 ||
                enemyMilitaryPressure ||
                localDefenseNeedsProduction);
  }

  bool get thirdCityDefenseCovered {
    final defense = localDefense;
    return localDefenseCovered ||
        ((defense?.threatLevel ?? 0) == 0 &&
            planState.militaryCount >= assessment.cityCount) ||
        escortedThirdCityPush;
  }

  bool get protectedSecondCityPush {
    return isSettler &&
        expansionNeed &&
        assessment.cityCount <= 1 &&
        oneCitySettlerDefenseCovered &&
        localDefenseCovered &&
        !localDefenseNeedsProduction &&
        !enemyMilitaryPressure;
  }

  bool get stableSecondCityPush {
    return isSettler &&
        expansionNeed &&
        assessment.cityCount == 1 &&
        planState.settlerCount == 0 &&
        planState.militaryCount >= 2 &&
        assessment.netGoldPerTurn >= -2 &&
        localDefenseCovered &&
        !localDefenseNeedsProduction &&
        !enemyMilitaryPressure;
  }

  bool get openingSecondCitySprint {
    return isSettler &&
        expansionNeed &&
        expansionDeficit >= 2 &&
        assessment.cityCount == 1 &&
        planState.settlerCount == 0 &&
        planState.workerCount == 0 &&
        oneCitySettlerDefenseCovered &&
        weights.aggression > weights.expansion &&
        assessment.netGoldPerTurn >= 0 &&
        !localDefenseNeedsProduction &&
        !enemyMilitaryPressure;
  }

  bool get stableThirdCityPush {
    return isSettler &&
        expansionNeed &&
        assessment.cityCount == 2 &&
        planState.settlerCount == 0 &&
        planState.militaryCount >= assessment.cityCount &&
        assessment.netGoldPerTurn >= 0 &&
        thirdCityDefenseCovered &&
        !enemyMilitaryPressure;
  }

  bool get thirdCityInfrastructureGap {
    return stableThirdCityPush &&
        workerCoverageDeficit == 0 &&
        weights.expansion < 1.2 &&
        view.ownCities.any((ownCity) => ownCity.buildings.isEmpty);
  }

  bool get activeSettlerNeedsEscort {
    return cache.activeSettlerNeedsEscortProduction(
      assessment: assessment,
      planState: planState,
    );
  }

  bool get hasNoOpeningScout {
    return !view.ownUnits.any((unit) => unit.type == GameUnitType.scout);
  }

  double get unitPowerScore => cache.unitPowerScore(unitType);

  double get counterPressureScore {
    return counterPressureScorer.weightedScore(
      unitType,
      view,
      enemyMilitaryPressure: enemyMilitaryPressure,
    );
  }

  double get effectiveCostPenalty {
    return isUrgentNeed ? costPenalty * 0.55 : costPenalty;
  }

  double get costPenalty {
    return productionCostPenalty(
      productionCost,
      productionPerTurnForTarget(
        city: city,
        target: UnitProductionTarget(unitType),
        cache: cache,
      ),
    );
  }

  int get productionCost {
    return CityProductionRules.unitProductionCost(
      unitType,
      ruleset: view.ruleset.city,
      paceBalance: view.ruleset.paceBalance,
    );
  }
}

double _localDefenseProductionPressure(StrategicDefenseAssignment? defense) {
  if (defense == null) return 0.0;
  if (defense.threatLevel <= 0 && defense.hasAssignedGarrison) return 0.0;
  final threat = defense.threatLevel.clamp(0, 16).toDouble();
  final missingGarrisonBonus = defense.hasAssignedGarrison ? 1.4 : 4.2;
  return missingGarrisonBonus + threat * 0.24;
}

int _reserveDefenderDeficit({
  required AiEmpireAssessment assessment,
  required AiProductionPlanState planState,
  required StrategicDefenseAssignment? defense,
  required bool localDefenseNeedsProduction,
}) {
  if (assessment.cityCount <= 0) return 0;
  final visiblePressure =
      assessment.visibleEnemyMilitaryCount > 0 ||
      assessment.enemyMilitaryPressure;
  final localPressure =
      localDefenseNeedsProduction || (defense?.threatLevel ?? 0) > 0;
  if (!visiblePressure && !localPressure) return 0;

  final target = switch (assessment.cityCount) {
    <= 1 => 2,
    2 => 3,
    _ => assessment.cityCount,
  };
  final deficit = target - planState.militaryCount;
  return deficit <= 0 ? 0 : deficit.clamp(0, 3).toInt();
}
