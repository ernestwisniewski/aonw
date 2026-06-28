import 'dart:math' as math;

import 'package:aonw_core/ai/strategic/strategic_mode.dart';

abstract final class AiGarrisonPolicy {
  // Threat levels are strategic scores, not unit counts. These thresholds mean:
  // 18 = sustained pressure worth extra cover in military mode, 24 = high local
  // danger that deserves two defenders in any mode.
  static const int militaryModeSecondDefenderThreatLevel = 18;
  static const int secondDefenderThreatLevel = 24;

  static bool needsSecondDefender(int threatLevel, StrategicMode mode) {
    return threatLevel >= secondDefenderThreatLevel ||
        (mode == StrategicMode.military &&
            threatLevel >= militaryModeSecondDefenderThreatLevel);
  }

  static int requiredGarrisonCount({
    required int ownCityCount,
    required bool hasDefenseAssignment,
    required int threatLevel,
    required int assignedUnitCount,
    required StrategicMode? mode,
  }) {
    if (ownCityCount <= 0) return 0;
    final baselineNeed = ownCityCount == 1 || hasDefenseAssignment ? 1 : 0;
    final threatNeed = mode != null && needsSecondDefender(threatLevel, mode)
        ? 2
        : threatLevel > 0
        ? 1
        : 0;
    return math.max(baselineNeed, math.max(threatNeed, assignedUnitCount));
  }
}
