part of 'economy_simulation.dart';

abstract final class _EconomySimulationTelemetry {
  static Map<String, BalanceTelemetryDominationSample> dominationByPlayerId(
    DominationProgressSnapshot snapshot,
  ) {
    return {
      for (final entry in snapshot.entries)
        entry.playerId: BalanceTelemetryDominationSample(
          controlPercent: entry.controlPercent,
          requiredControlPercent: entry.requiredControlPercent,
          holdTurns: entry.holdTurns,
          requiredHoldTurns: entry.requiredHoldTurns,
        ),
    };
  }

  static Map<String, BalanceTelemetryObjectiveActionSample> objectiveActions({
    required int turn,
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MatchRules matchRules,
    required GameRuleset ruleset,
  }) {
    final victory = matchRules.victory;
    final turnLimit = victory.turnLimit;
    if (!victory.scoreFallbackEnabled || turnLimit == null) return const {};

    const scorePressureWindow = 5;
    final remainingTurns = turnLimit - turn;
    if (remainingTurns < 0 || remainingTurns > scorePressureWindow) {
      return const {};
    }

    return BalanceTelemetryObjectiveActionDiagnostics.scorePressureSamplesFor(
      state: state,
      playerIds: playerIds,
      technologyRuleset: ruleset.technology,
    );
  }
}
