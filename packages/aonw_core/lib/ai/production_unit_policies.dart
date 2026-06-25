part of 'production_unit_scorer.dart';

abstract class _UnitProductionPolicy {
  const _UnitProductionPolicy();

  double baseScore(_UnitProductionSituation situation);
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
}

final class _NoUnitProductionPolicy extends _UnitProductionPolicy {
  const _NoUnitProductionPolicy();

  @override
  double baseScore(_UnitProductionSituation situation) => 0.0;
}
