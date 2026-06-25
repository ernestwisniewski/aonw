part of 'balance_telemetry.dart';

class BalanceTelemetryTurnSample {
  const BalanceTelemetryTurnSample({
    required this.turn,
    required this.state,
    this.events = const [],
    this.meaningfulCommandsByPlayerId = const {},
    this.dominationByPlayerId = const {},
    this.objectiveActionByPlayerId = const {},
    this.endPaceByPlayerId = const {},
    this.outcome = GameOutcome.ongoing,
  });

  final int turn;
  final PersistentGameState state;
  final List<GameEvent> events;
  final Map<String, int> meaningfulCommandsByPlayerId;
  final Map<String, BalanceTelemetryDominationSample> dominationByPlayerId;
  final Map<String, BalanceTelemetryObjectiveActionSample>
  objectiveActionByPlayerId;
  final Map<String, BalanceTelemetryEndPaceSample> endPaceByPlayerId;
  final GameOutcome outcome;
}

class BalanceTelemetryEndPaceSample {
  const BalanceTelemetryEndPaceSample({
    required this.completedTechnologyCount,
    required this.sciencePerTurn,
    required this.cityCount,
    required this.unitCount,
    required this.gold,
    required this.netGoldPerTurn,
  });

  final int completedTechnologyCount;
  final int sciencePerTurn;
  final int cityCount;
  final int unitCount;
  final int gold;
  final int netGoldPerTurn;

  @override
  bool operator ==(Object other) {
    return other is BalanceTelemetryEndPaceSample &&
        other.completedTechnologyCount == completedTechnologyCount &&
        other.sciencePerTurn == sciencePerTurn &&
        other.cityCount == cityCount &&
        other.unitCount == unitCount &&
        other.gold == gold &&
        other.netGoldPerTurn == netGoldPerTurn;
  }

  @override
  int get hashCode => Object.hash(
    completedTechnologyCount,
    sciencePerTurn,
    cityCount,
    unitCount,
    gold,
    netGoldPerTurn,
  );
}

enum BalanceTelemetryObjectiveActionTarget {
  unit,
  cityProduction,
  research,
  none,
}

class BalanceTelemetryObjectiveActionSample {
  const BalanceTelemetryObjectiveActionSample({
    required this.advice,
    required this.target,
  });

  final GameObjectiveAdvice advice;
  final BalanceTelemetryObjectiveActionTarget target;

  @override
  bool operator ==(Object other) {
    return other is BalanceTelemetryObjectiveActionSample &&
        other.advice == advice &&
        other.target == target;
  }

  @override
  int get hashCode => Object.hash(advice, target);
}

class BalanceTelemetryDominationSample {
  const BalanceTelemetryDominationSample({
    required this.controlPercent,
    required this.requiredControlPercent,
    required this.holdTurns,
    required this.requiredHoldTurns,
  });

  final double controlPercent;
  final double requiredControlPercent;
  final int holdTurns;
  final int requiredHoldTurns;

  bool get atThreshold => controlPercent >= requiredControlPercent;

  @override
  bool operator ==(Object other) {
    return other is BalanceTelemetryDominationSample &&
        other.controlPercent == controlPercent &&
        other.requiredControlPercent == requiredControlPercent &&
        other.holdTurns == holdTurns &&
        other.requiredHoldTurns == requiredHoldTurns;
  }

  @override
  int get hashCode => Object.hash(
    controlPercent,
    requiredControlPercent,
    holdTurns,
    requiredHoldTurns,
  );
}
