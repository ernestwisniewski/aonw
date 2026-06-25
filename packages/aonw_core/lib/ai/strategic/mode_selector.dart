import 'dart:math' as math;

import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/strategic/economy_expectations.dart';
import 'package:aonw_core/ai/strategic/economy_health.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/threat_assessor.dart';

class ModeSelector {
  const ModeSelector();

  StrategicMode select({
    required AiEmpireAssessment assessment,
    required EconomyExpectations expectations,
    required List<PlayerThreatScore> threats,
    required AiContext context,
    EconomyHealth economyHealth = EconomyHealth.stable,
    StrategicMode? previousMode,
  }) {
    final topThreat = threats.isEmpty ? null : threats.first;
    final threatScore = topThreat?.score ?? 0.0;
    final weights = context.effectiveWeights;
    final difficultyProfile = context.difficultyProfile;
    final militaryThreshold =
        2.35 *
        difficultyProfile.militaryModeThresholdMultiplier /
        context.civProfile.belligerence;
    final lowReserveRecovery =
        context.turn > 8 &&
        assessment.netGoldPerTurn <= 0 &&
        assessment.goldReserve < expectations.goldReserveTarget ~/ 2 &&
        assessment.cityCount > 0;
    final safeSecondCityBeforeWorker =
        assessment.workerCount == 0 &&
        assessment.militaryCount >= 2 &&
        assessment.netGoldPerTurn >= 0;
    final secondCityExpansionWindow =
        assessment.cityCount == 1 &&
        assessment.settlerCount == 0 &&
        assessment.wantsExpansion &&
        (assessment.workerCount >= assessment.desiredWorkerCount ||
            safeSecondCityBeforeWorker) &&
        assessment.militaryCount > 0 &&
        assessment.netGoldPerTurn >= 0;
    final recoveryDebtIsExpansionDebt =
        secondCityExpansionWindow &&
        economyHealth.cityBehind &&
        !economyHealth.workerBehind &&
        !economyHealth.militaryBehind;
    final lowReserveIsExpansionDebt =
        secondCityExpansionWindow && lowReserveRecovery;
    final thirdCityExpansionWindow =
        assessment.cityCount == 2 &&
        assessment.settlerCount == 0 &&
        assessment.wantsExpansion &&
        assessment.militaryCount >= assessment.cityCount &&
        assessment.netGoldPerTurn >= 0;

    if (assessment.netGoldPerTurn < 0 ||
        (economyHealth.needsRecovery && !recoveryDebtIsExpansionDebt) ||
        (lowReserveRecovery && !lowReserveIsExpansionDebt)) {
      return StrategicMode.recover;
    }

    if (_hasActionableHostilePressure(threats) &&
        assessment.militaryCount >= _hostilePressureMinimumArmy(assessment)) {
      return StrategicMode.military;
    }

    if (threatScore >= militaryThreshold ||
        assessment.visibleEnemyMilitaryCount > assessment.militaryCount) {
      return StrategicMode.military;
    }

    if (secondCityExpansionWindow &&
        threatScore < 1.3 &&
        (economyHealth.cityBehind ||
            economyHealth.goldBehind ||
            lowReserveRecovery ||
            safeSecondCityBeforeWorker)) {
      return StrategicMode.expand;
    }

    if (thirdCityExpansionWindow &&
        threatScore < 1.3 &&
        !economyHealth.militaryBehind) {
      return StrategicMode.expand;
    }

    if (assessment.needsWorkers ||
        assessment.needsGoldReserve ||
        economyHealth.needsConsolidation) {
      return StrategicMode.consolidate;
    }

    if (assessment.wantsExpansion && threatScore < 1.3) {
      return StrategicMode.expand;
    }

    if (weights.science >= weights.expansion &&
        weights.science >= weights.aggression &&
        weights.science >= 1.2 &&
        threatScore < 1.5 &&
        !economyHealth.needsConsolidation) {
      return StrategicMode.techRush;
    }

    return previousMode == StrategicMode.military && threatScore >= 1.6
        ? StrategicMode.military
        : StrategicMode.consolidate;
  }

  bool _hasActionableHostilePressure(List<PlayerThreatScore> threats) {
    return threats.any(
      (threat) =>
          threat.rival.isHostile &&
          (threat.rival.rememberedCityCount > 0 ||
              threat.rival.visibleUnitCount > 0),
    );
  }

  int _hostilePressureMinimumArmy(AiEmpireAssessment assessment) {
    return math.max(2, (assessment.cityCount * 0.6).ceil());
  }
}
