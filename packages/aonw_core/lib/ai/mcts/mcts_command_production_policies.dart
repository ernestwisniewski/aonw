part of 'mcts_command_production_scorer.dart';

abstract class _MctsProductionPolicy {
  const _MctsProductionPolicy();

  static _MctsProductionPolicy forSituation(
    _MctsProductionSituation situation,
  ) {
    if (situation.isWorker) return const _MctsWorkerProductionPolicy();
    if (situation.isScout) return const _MctsScoutProductionPolicy();
    if (situation.isMilitary) return const _MctsMilitaryProductionPolicy();
    if (situation.isSettler) return const _MctsSettlerProductionPolicy();
    return const _MctsFallbackProductionPolicy();
  }

  double score(_MctsProductionSituation situation);
}

final class _MctsWorkerProductionPolicy extends _MctsProductionPolicy {
  const _MctsWorkerProductionPolicy();

  @override
  double score(_MctsProductionSituation situation) {
    if (situation.safeSecondCityRoom) return 0.09;
    if (situation.coreDefenseDeficit > 0) return 0.08;
    if (situation.workerRecoveryNeeded) return 0.28;
    if (situation.openingSecondCityRoom &&
        situation.assessment.workerCount == 1 &&
        situation.assessment.settlerCount == 0) {
      return 0.12;
    }
    if (situation.hasMilitaryDeficit) return 0.10;
    if (situation.assessment.cityCount > 0 &&
        situation.assessment.workerCount <= situation.assessment.cityCount) {
      return 0.18;
    }
    return 0.11;
  }
}

final class _MctsScoutProductionPolicy extends _MctsProductionPolicy {
  const _MctsScoutProductionPolicy();

  @override
  double score(_MctsProductionSituation situation) {
    return situation.needsCitySiteScoutProduction ? 0.30 : 0.11;
  }
}

final class _MctsMilitaryProductionPolicy extends _MctsProductionPolicy {
  const _MctsMilitaryProductionPolicy();

  @override
  double score(_MctsProductionSituation situation) {
    if (situation.activeSettlerNeedsEscort) return 0.27;
    if (situation.coreDefenseDeficit > 0) {
      return 0.22 + situation.coreDefenseDeficit * 0.035;
    }
    return situation.hasMilitaryDeficit ? 0.16 : 0.11;
  }
}

final class _MctsSettlerProductionPolicy extends _MctsProductionPolicy {
  const _MctsSettlerProductionPolicy();

  @override
  double score(_MctsProductionSituation situation) {
    if (situation.assessment.cityCount <= 1 &&
        situation.assessment.settlerCount > 1) {
      return 0.03;
    }
    if (situation.activeSettlerNeedsEscort) return 0.04;
    if (situation.safeSecondCityRoom) return 0.34;
    if (situation.assessment.cityCount <= 1 &&
        situation.assessment.militaryCount < 2) {
      return 0.05;
    }
    if (situation.openingSecondCityRoom &&
        situation.assessment.settlerCount == 1 &&
        situation.assessment.workerCount == 0) {
      return 0.38;
    }
    if (situation.reinforcedSecondCityRoom) {
      return switch (situation.mode) {
        StrategicMode.military || StrategicMode.recover => 0.34,
        _ => 0.32,
      };
    }
    if (situation.stableThirdCityRoom) {
      if (situation.workerRecoveryNeeded) {
        return situation.mode == StrategicMode.expand ? 0.24 : 0.22;
      }
      return situation.mode == StrategicMode.expand ? 0.36 : 0.31;
    }
    if (situation.coreDefenseDeficit > 0) return 0.05;
    if (situation.hasMilitaryDeficit) return 0.07;
    if (situation.assessment.militaryCount <= 0) return 0.04;
    if (!situation.wantsMoreCities) return 0.11;

    final modeBonus = situation.mode == StrategicMode.expand ? 0.16 : 0.08;
    final oneCityBonus = situation.assessment.cityCount <= 1 ? 0.06 : 0.0;
    return 0.13 + modeBonus + oneCityBonus;
  }
}

final class _MctsFallbackProductionPolicy extends _MctsProductionPolicy {
  const _MctsFallbackProductionPolicy();

  @override
  double score(_MctsProductionSituation situation) => 0.11;
}
