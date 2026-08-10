part of 'balance_telemetry.dart';

class _PlayerReportBuilder {
  int? firstTechnologyTurn;
  int? firstBuildingTurn;
  int? secondCityTurn;
  int? firstContactTurn;
  int? firstCombatTurn;
  int? firstDominationThresholdTurn;
  double maxDominationControlPercent = 0;
  int maxDominationHoldTurns = 0;
  int deadTurnCount = 0;
  int longestDeadTurnStreak = 0;
  final deadTurnRuns = <BalanceTelemetryDeadTurnRun>[];
  final objectiveActionAdviceCounts = <GameObjectiveAdvice, int>{};
  final objectiveActionTargetCounts =
      <BalanceTelemetryObjectiveActionTarget, int>{};
  int finalTechnologyCount = 0;
  int? finalSciencePerTurn;
  int finalCityCount = 0;
  int finalUnitCount = 0;
  int? finalGold;
  int? finalNetGoldPerTurn;

  void captureMilestones({
    required String playerId,
    required BalanceTelemetryTurnSample sample,
    required _EventOwnershipTransition ownership,
  }) {
    captureEndPace(playerId: playerId, sample: sample);
    final summary = _PlayerSnapshotSummary.fromState(sample.state, playerId);
    firstTechnologyTurn ??= summary.technologyCount > 0 ? sample.turn : null;
    firstBuildingTurn ??= summary.buildingCount > 0 ? sample.turn : null;
    secondCityTurn ??= summary.cityCount >= 2 ? sample.turn : null;
    firstContactTurn ??= _hasContact(sample.state, playerId)
        ? sample.turn
        : null;
    firstCombatTurn ??=
        _hasCombatEventForPlayer(
          playerId: playerId,
          ownership: ownership,
          events: sample.events,
        )
        ? sample.turn
        : null;

    final domination = sample.dominationByPlayerId[playerId];
    if (domination == null) return;
    if (domination.controlPercent > maxDominationControlPercent) {
      maxDominationControlPercent = domination.controlPercent;
    }
    if (domination.holdTurns > maxDominationHoldTurns) {
      maxDominationHoldTurns = domination.holdTurns;
    }
    firstDominationThresholdTurn ??= domination.atThreshold
        ? sample.turn
        : null;
  }

  void captureEndPace({
    required String playerId,
    required BalanceTelemetryTurnSample sample,
  }) {
    final summary = _PlayerSnapshotSummary.fromState(sample.state, playerId);
    finalTechnologyCount = summary.technologyCount;
    finalCityCount = summary.cityCount;
    finalUnitCount = summary.unitCount;
    final endPace = sample.endPaceByPlayerId[playerId];
    if (endPace != null) {
      finalTechnologyCount = endPace.completedTechnologyCount;
      finalSciencePerTurn = endPace.sciencePerTurn;
      finalCityCount = endPace.cityCount;
      finalUnitCount = endPace.unitCount;
      finalGold = endPace.gold;
      finalNetGoldPerTurn = endPace.netGoldPerTurn;
    }
  }

  void captureObjectiveAction(BalanceTelemetryObjectiveActionSample sample) {
    objectiveActionAdviceCounts.update(
      sample.advice,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    objectiveActionTargetCounts.update(
      sample.target,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  BalanceTelemetryPlayerReport build(String playerId) {
    return BalanceTelemetryPlayerReport(
      playerId: playerId,
      firstTechnologyTurn: firstTechnologyTurn,
      firstBuildingTurn: firstBuildingTurn,
      secondCityTurn: secondCityTurn,
      firstContactTurn: firstContactTurn,
      firstCombatTurn: firstCombatTurn,
      firstDominationThresholdTurn: firstDominationThresholdTurn,
      maxDominationControlPercent: maxDominationControlPercent,
      maxDominationHoldTurns: maxDominationHoldTurns,
      deadTurnCount: deadTurnCount,
      longestDeadTurnStreak: longestDeadTurnStreak,
      deadTurnRuns: List.unmodifiable(deadTurnRuns),
      objectiveActionAdviceCounts: Map.unmodifiable(
        objectiveActionAdviceCounts,
      ),
      objectiveActionTargetCounts: Map.unmodifiable(
        objectiveActionTargetCounts,
      ),
      finalTechnologyCount: finalTechnologyCount,
      finalSciencePerTurn: finalSciencePerTurn,
      finalCityCount: finalCityCount,
      finalUnitCount: finalUnitCount,
      finalGold: finalGold,
      finalNetGoldPerTurn: finalNetGoldPerTurn,
    );
  }
}
