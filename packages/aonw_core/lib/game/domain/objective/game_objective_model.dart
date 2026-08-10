import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';

enum GameObjectiveId {
  chooseResearch,
  foundCapital,
  exploreNearby,
  queueWorker,
  improveFirstHex,
  foundSecondCity,
  buildFirstBuilding,
  improveThreeHexes,
  foundThirdCity,
  exploreRegion,
  buildCombatForce,
  raiseStability,
  holdDomination,
  breakDominationHold,
  holdScoreLead,
  overtakeScoreLeader,
  secureMapObjective,
  breakMapObjectiveHold,
}

enum GameObjectiveTone {
  research,
  expansion,
  exploration,
  economy,
  victory,
  warning,
}

enum GameObjectiveAdvice {
  foundCity,
  growPopulation,
  claimTerritory,
  constructBuilding,
  trainUnit,
  unlockTechnology,
  improveField,
  collectGold,
  protectLead,
}

enum GameObjectivePhase { foundation, expansion, pressure, endgame }

enum GameObjectiveTrack { guidance, strategic }

enum GameObjectiveTargetScaling { fixed, pace }

class GameObjectiveDefinition {
  final GameObjectiveId id;
  final GameObjectivePhase phase;
  final GameObjectiveTrack track;
  final int targetValue;
  final GameObjectiveTone tone;
  final GameObjectiveTargetScaling targetScaling;

  const GameObjectiveDefinition({
    required this.id,
    required this.phase,
    this.track = GameObjectiveTrack.guidance,
    required this.targetValue,
    required this.tone,
    this.targetScaling = GameObjectiveTargetScaling.fixed,
  });

  GameObjectiveDefinition scaledFor(PaceBalance paceBalance) {
    if (targetScaling == GameObjectiveTargetScaling.fixed) return this;
    final scaledTarget = paceBalance.objectiveTarget(targetValue);
    if (scaledTarget == targetValue) return this;
    return copyWith(targetValue: scaledTarget);
  }

  GameObjectiveDefinition copyWith({
    int? targetValue,
    GameObjectiveTone? tone,
  }) {
    return GameObjectiveDefinition(
      id: id,
      phase: phase,
      track: track,
      targetValue: targetValue ?? this.targetValue,
      tone: tone ?? this.tone,
      targetScaling: targetScaling,
    );
  }
}

class GameObjectiveProgress {
  final GameObjectiveDefinition definition;
  final int currentValue;
  final GameObjectiveAdvice? advice;

  const GameObjectiveProgress({
    required this.definition,
    required this.currentValue,
    this.advice,
  });

  int get targetValue => definition.targetValue;

  int get clampedValue => _clampInt(currentValue, 0, targetValue);

  bool get completed => currentValue >= targetValue;

  double get fraction {
    if (targetValue <= 0) return 1;
    return clampedValue / targetValue;
  }

  String get progressLabel => targetValue <= 1
      ? completed
            ? 'gotowe'
            : '0/1'
      : '$clampedValue/$targetValue';

  static int _clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
