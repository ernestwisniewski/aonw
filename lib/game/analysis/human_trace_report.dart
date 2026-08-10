class HumanTraceReport {
  const HumanTraceReport({
    required this.humanPlayerId,
    required this.firstTimestamp,
    required this.lastTimestamp,
    required this.elapsedSeconds,
    required this.offsetCount,
    required this.lastCompletedTurn,
    required this.decisions,
    required this.humanCommandCounts,
    required this.aiCommandCounts,
    required this.humanResearch,
    required this.humanProduction,
    required this.humanFoundCities,
    required this.humanWorkerImprovements,
    required this.humanAttacks,
    required this.aiSummaries,
    required this.repeatedAiCommands,
    required this.aiWorkerStalls,
  });

  final String humanPlayerId;
  final DateTime? firstTimestamp;
  final DateTime? lastTimestamp;
  final int elapsedSeconds;
  final int offsetCount;
  final int lastCompletedTurn;
  final List<HumanTraceDecision> decisions;
  final Map<String, int> humanCommandCounts;
  final Map<String, int> aiCommandCounts;
  final List<TraceResearchChoice> humanResearch;
  final List<TraceProductionChoice> humanProduction;
  final List<TraceCityFounding> humanFoundCities;
  final List<TraceWorkerImprovement> humanWorkerImprovements;
  final List<TraceAttack> humanAttacks;
  final List<AiTraceSummary> aiSummaries;
  final List<RepeatedAiCommand> repeatedAiCommands;
  final List<AiWorkerStall> aiWorkerStalls;

  Map<String, Object?> toJson() {
    return {
      'humanPlayerId': humanPlayerId,
      'firstTimestamp': firstTimestamp?.toIso8601String(),
      'lastTimestamp': lastTimestamp?.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
      'offsetCount': offsetCount,
      'lastCompletedTurn': lastCompletedTurn,
      'humanCommandCounts': humanCommandCounts,
      'aiCommandCounts': aiCommandCounts,
      'humanResearch': [for (final choice in humanResearch) choice.toJson()],
      'humanProduction': [
        for (final choice in humanProduction) choice.toJson(),
      ],
      'humanFoundCities': [for (final city in humanFoundCities) city.toJson()],
      'humanWorkerImprovements': [
        for (final improvement in humanWorkerImprovements) improvement.toJson(),
      ],
      'humanAttacks': [for (final attack in humanAttacks) attack.toJson()],
      'aiSummaries': [for (final summary in aiSummaries) summary.toJson()],
      'repeatedAiCommands': [
        for (final repeated in repeatedAiCommands.take(25)) repeated.toJson(),
      ],
      'aiWorkerStalls': [for (final stall in aiWorkerStalls) stall.toJson()],
      'decisions': [for (final decision in decisions) decision.toJson()],
    };
  }
}

class HumanTraceDecision {
  const HumanTraceDecision({
    required this.turn,
    required this.offset,
    required this.commandType,
    required this.command,
  });

  final int turn;
  final int offset;
  final String commandType;
  final Map<String, dynamic> command;

  Map<String, Object?> toJson() {
    return {
      'turn': turn,
      'offset': offset,
      'commandType': commandType,
      'command': command,
    };
  }
}

class TraceResearchChoice {
  const TraceResearchChoice({
    required this.turn,
    required this.offset,
    required this.technologyId,
  });

  final int turn;
  final int offset;
  final String technologyId;

  Map<String, Object?> toJson() {
    return {'turn': turn, 'offset': offset, 'technologyId': technologyId};
  }
}

class TraceProductionChoice {
  const TraceProductionChoice({
    required this.turn,
    required this.offset,
    required this.cityId,
    required this.kind,
    required this.target,
  });

  final int turn;
  final int offset;
  final String cityId;
  final String kind;
  final String target;

  Map<String, Object?> toJson() {
    return {
      'turn': turn,
      'offset': offset,
      'cityId': cityId,
      'kind': kind,
      'target': target,
    };
  }
}

class TraceCityFounding {
  const TraceCityFounding({
    required this.turn,
    required this.offset,
    required this.founderId,
    required this.controlledHexes,
  });

  final int turn;
  final int offset;
  final String founderId;
  final List<TraceHex> controlledHexes;

  Map<String, Object?> toJson() {
    return {
      'turn': turn,
      'offset': offset,
      'founderId': founderId,
      'controlledHexes': [for (final hex in controlledHexes) hex.toJson()],
    };
  }
}

class TraceHex {
  const TraceHex({required this.col, required this.row});

  final int col;
  final int row;

  Map<String, Object?> toJson() => {'col': col, 'row': row};
}

class TraceWorkerImprovement {
  const TraceWorkerImprovement({
    required this.turn,
    required this.offset,
    required this.unitId,
    required this.improvementType,
  });

  final int turn;
  final int offset;
  final String unitId;
  final String improvementType;

  Map<String, Object?> toJson() {
    return {
      'turn': turn,
      'offset': offset,
      'unitId': unitId,
      'improvementType': improvementType,
    };
  }
}

class TraceAttack {
  const TraceAttack({
    required this.turn,
    required this.offset,
    required this.attackerUnitId,
    required this.targetCol,
    required this.targetRow,
  });

  final int turn;
  final int offset;
  final String attackerUnitId;
  final int targetCol;
  final int targetRow;

  Map<String, Object?> toJson() {
    return {
      'turn': turn,
      'offset': offset,
      'attackerUnitId': attackerUnitId,
      'targetCol': targetCol,
      'targetRow': targetRow,
    };
  }
}

class AiTraceSummary {
  const AiTraceSummary({
    required this.playerId,
    required this.commandCounts,
    required this.cityFoundingTurns,
  });

  final String playerId;
  final Map<String, int> commandCounts;
  final List<int> cityFoundingTurns;

  Map<String, Object?> toJson() {
    return {
      'playerId': playerId,
      'commandCounts': commandCounts,
      'cityFoundingTurns': cityFoundingTurns,
    };
  }
}

class RepeatedAiCommand {
  const RepeatedAiCommand({
    required this.playerId,
    required this.commandType,
    required this.count,
    required this.firstTurn,
    required this.lastTurn,
    required this.command,
  });

  final String playerId;
  final String commandType;
  final int count;
  final int firstTurn;
  final int lastTurn;
  final Map<String, dynamic> command;

  Map<String, Object?> toJson() {
    return {
      'playerId': playerId,
      'commandType': commandType,
      'count': count,
      'firstTurn': firstTurn,
      'lastTurn': lastTurn,
      'command': command,
    };
  }
}

class AiWorkerStall {
  const AiWorkerStall({
    required this.playerId,
    required this.unitId,
    required this.improvementType,
    required this.selectionCount,
    required this.completionCount,
    required this.firstTurn,
    required this.lastTurn,
  });

  final String playerId;
  final String unitId;
  final String improvementType;
  final int selectionCount;
  final int completionCount;
  final int firstTurn;
  final int lastTurn;

  Map<String, Object?> toJson() {
    return {
      'playerId': playerId,
      'unitId': unitId,
      'improvementType': improvementType,
      'selectionCount': selectionCount,
      'completionCount': completionCount,
      'firstTurn': firstTurn,
      'lastTurn': lastTurn,
    };
  }
}
