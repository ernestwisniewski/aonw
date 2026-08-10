import 'package:aonw_core/game/domain/match_rules/game_length_config.dart';

enum BalanceTelemetryFindingSeverity { info, warning, critical }

class BalanceTelemetryTuningTargets {
  const BalanceTelemetryTuningTargets({
    this.firstTechnologyMaxTurn = 10,
    this.firstBuildingMaxTurn = 18,
    this.secondCityMaxTurn = 24,
    this.firstContactMaxTurn = 28,
    this.firstCombatMaxTurn = 40,
    this.dominationThresholdMaxTurn = 0,
    this.maxDeadTurnStreak = 2,
    this.finalTechnologyMinCount = 0,
    this.finalTechnologyMaxCount = 0,
    this.finalScienceMinPerTurn = 0,
    this.finalScienceMaxPerTurn = 0,
    this.finalCityMinCount = 0,
    this.finalCityMaxCount = 0,
  });

  static const standard = BalanceTelemetryTuningTargets();
  static const standard60 = BalanceTelemetryTuningTargets(
    firstTechnologyMaxTurn: 5,
    firstBuildingMaxTurn: 20,
    secondCityMaxTurn: 16,
    firstContactMaxTurn: 24,
    firstCombatMaxTurn: 36,
    dominationThresholdMaxTurn: 0,
    finalTechnologyMinCount: 15,
    finalTechnologyMaxCount: 42,
    finalScienceMinPerTurn: 6,
    finalScienceMaxPerTurn: 70,
    finalCityMinCount: 3,
    finalCityMaxCount: 6,
  );
  static const normal90 = BalanceTelemetryTuningTargets(
    firstTechnologyMaxTurn: 6,
    firstBuildingMaxTurn: 21,
    secondCityMaxTurn: 20,
    firstContactMaxTurn: 28,
    firstCombatMaxTurn: 48,
    dominationThresholdMaxTurn: 0,
    finalTechnologyMinCount: 18,
    finalTechnologyMaxCount: 48,
    finalScienceMinPerTurn: 8,
    finalScienceMaxPerTurn: 70,
    finalCityMinCount: 3,
    finalCityMaxCount: 6,
  );
  static const long120 = BalanceTelemetryTuningTargets(
    firstTechnologyMaxTurn: 6,
    firstBuildingMaxTurn: 23,
    secondCityMaxTurn: 24,
    firstContactMaxTurn: 32,
    firstCombatMaxTurn: 60,
    dominationThresholdMaxTurn: 0,
    finalTechnologyMinCount: 22,
    finalTechnologyMaxCount: 52,
    finalScienceMinPerTurn: 10,
    finalScienceMaxPerTurn: 70,
    finalCityMinCount: 3,
    finalCityMaxCount: 5,
  );

  final int firstTechnologyMaxTurn;
  final int firstBuildingMaxTurn;
  final int secondCityMaxTurn;
  final int firstContactMaxTurn;
  final int firstCombatMaxTurn;
  final int dominationThresholdMaxTurn;
  final int maxDeadTurnStreak;
  final int finalTechnologyMinCount;
  final int finalTechnologyMaxCount;
  final int finalScienceMinPerTurn;
  final int finalScienceMaxPerTurn;
  final int finalCityMinCount;
  final int finalCityMaxCount;

  static BalanceTelemetryTuningTargets forPaceProfile(PaceProfile profile) {
    return switch (profile) {
      PaceProfile.standard60 => standard60,
      PaceProfile.normal90 => normal90,
      PaceProfile.long120 => long120,
      PaceProfile.unlimited => standard,
    };
  }
}

class BalanceTelemetryFinding {
  const BalanceTelemetryFinding({
    required this.code,
    required this.severity,
    required this.message,
    this.playerId,
    this.turn,
  });

  final String code;
  final BalanceTelemetryFindingSeverity severity;
  final String message;
  final String? playerId;
  final int? turn;

  @override
  bool operator ==(Object other) {
    return other is BalanceTelemetryFinding &&
        other.code == code &&
        other.severity == severity &&
        other.message == message &&
        other.playerId == playerId &&
        other.turn == turn;
  }

  @override
  int get hashCode => Object.hash(code, severity, message, playerId, turn);
}

class BalanceTelemetryDeadTurnRun {
  const BalanceTelemetryDeadTurnRun({
    required this.playerId,
    required this.startTurn,
    required this.endTurn,
  });

  final String playerId;
  final int startTurn;
  final int endTurn;

  int get length => endTurn - startTurn + 1;

  @override
  bool operator ==(Object other) {
    return other is BalanceTelemetryDeadTurnRun &&
        other.playerId == playerId &&
        other.startTurn == startTurn &&
        other.endTurn == endTurn;
  }

  @override
  int get hashCode => Object.hash(playerId, startTurn, endTurn);
}
