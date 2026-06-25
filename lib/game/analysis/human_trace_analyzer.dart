import 'dart:convert';

import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

class HumanTraceAnalyzer {
  const HumanTraceAnalyzer();

  HumanTraceReport analyze({
    required List<LoggedCommand> log,
    required String humanPlayerId,
  }) {
    var turn = 1;
    final meaningful = <HumanTraceDecision>[];
    final humanCounts = <String, int>{};
    final aiCounts = <String, int>{};
    final aiPlayerCounts = <String, Map<String, int>>{};
    final aiRepeated = <String, _RepeatedCommandBucket>{};
    final workerSelections = <String, _WorkerSelectionBucket>{};
    final workerCompletions = <String, int>{};
    final cityFoundingTurns = <String, List<int>>{};
    final humanResearch = <TraceResearchChoice>[];
    final humanProduction = <TraceProductionChoice>[];
    final humanFoundCities = <TraceCityFounding>[];
    final humanWorkerImprovements = <TraceWorkerImprovement>[];
    final humanAttacks = <TraceAttack>[];
    DateTime? firstTimestamp;
    DateTime? lastTimestamp;
    var lastCompletedTurn = 0;

    for (final entry in log) {
      firstTimestamp ??= entry.timestamp;
      lastTimestamp = entry.timestamp;
      final command = entry.command;
      final owner = _commandOwner(command);
      final actorPlayerId = entry.actorPlayerId;
      final isHumanCommand =
          actorPlayerId == null &&
          (owner == null || owner == humanPlayerId) &&
          _isMeaningfulHumanCommand(command);
      final isAiCommand = actorPlayerId != null;

      if (isHumanCommand) {
        _increment(humanCounts, _commandType(command));
        final decision = HumanTraceDecision(
          turn: turn,
          offset: entry.offset,
          commandType: _commandType(command),
          command: GameCommandSerializer.toJson(command),
        );
        meaningful.add(decision);
        switch (command) {
          case SelectTechnologyCommand(:final technologyId):
            humanResearch.add(
              TraceResearchChoice(
                turn: turn,
                offset: entry.offset,
                technologyId: technologyId.name,
              ),
            );
          case StartBuildingCommand(:final cityId, :final buildingType):
            humanProduction.add(
              TraceProductionChoice(
                turn: turn,
                offset: entry.offset,
                cityId: cityId,
                kind: 'building',
                target: buildingType.name,
              ),
            );
          case StartUnitProductionCommand(:final cityId, :final unitType):
            humanProduction.add(
              TraceProductionChoice(
                turn: turn,
                offset: entry.offset,
                cityId: cityId,
                kind: 'unit',
                target: unitType.name,
              ),
            );
          case StartCityProjectCommand(:final cityId, :final projectType):
            humanProduction.add(
              TraceProductionChoice(
                turn: turn,
                offset: entry.offset,
                cityId: cityId,
                kind: 'project',
                target: projectType.name,
              ),
            );
          case FoundCityCommand(:final founderId, :final controlledHexes):
            humanFoundCities.add(
              TraceCityFounding(
                turn: turn,
                offset: entry.offset,
                founderId: founderId,
                controlledHexes: [
                  for (final hex in controlledHexes)
                    TraceHex(col: hex.col, row: hex.row),
                ],
              ),
            );
          case SelectWorkerImprovementCommand(
            :final unitId,
            :final improvementType,
          ):
            humanWorkerImprovements.add(
              TraceWorkerImprovement(
                turn: turn,
                offset: entry.offset,
                unitId: unitId,
                improvementType: improvementType.name,
              ),
            );
          case AttackHexCommand(
            :final attackerUnitId,
            :final defenderCol,
            :final defenderRow,
          ):
            humanAttacks.add(
              TraceAttack(
                turn: turn,
                offset: entry.offset,
                attackerUnitId: attackerUnitId,
                targetCol: defenderCol,
                targetRow: defenderRow,
              ),
            );
          default:
            break;
        }
      }

      if (isAiCommand) {
        final playerId = actorPlayerId;
        final type = _commandType(command);
        _increment(aiCounts, type);
        _increment(aiPlayerCounts.putIfAbsent(playerId, () => {}), type);
        if (_isRepeatedAiCandidate(command)) {
          final key = _repeatedKey(playerId: playerId, command: command);
          aiRepeated
              .putIfAbsent(
                key,
                () => _RepeatedCommandBucket(
                  playerId: playerId,
                  commandType: type,
                  command: GameCommandSerializer.toJson(command),
                ),
              )
              .update(turn);
        }

        if (command case SelectWorkerImprovementCommand(
          :final unitId,
          :final improvementType,
        )) {
          workerSelections
              .putIfAbsent(
                '$playerId|$unitId',
                () => _WorkerSelectionBucket(
                  playerId: playerId,
                  unitId: unitId,
                  improvementType: improvementType.name,
                ),
              )
              .update(turn);
        }
      }

      if (command case FoundCityCommand()) {
        final playerId =
            actorPlayerId ?? owner ?? (isHumanCommand ? humanPlayerId : null);
        if (playerId != null) {
          cityFoundingTurns.putIfAbsent(playerId, () => []).add(turn);
        }
      }

      for (final event in entry.events) {
        switch (event) {
          case AllPlayersSubmittedEvent(turn: final completedTurn):
            lastCompletedTurn = completedTurn;
            turn = completedTurn + 1;
          case WorkerCompletedJobEvent(:final unitId):
            _increment(workerCompletions, unitId);
          default:
            break;
        }
      }
    }

    final aiSummaries = <AiTraceSummary>[
      for (final playerId in aiPlayerCounts.keys.toList()..sort())
        AiTraceSummary(
          playerId: playerId,
          commandCounts: _sortedMap(aiPlayerCounts[playerId]!),
          cityFoundingTurns: List.unmodifiable(
            cityFoundingTurns[playerId] ?? const <int>[],
          ),
        ),
    ];
    final repeatedCommands =
        aiRepeated.values
            .where((bucket) => bucket.count > 1)
            .map(
              (bucket) => RepeatedAiCommand(
                playerId: bucket.playerId,
                commandType: bucket.commandType,
                count: bucket.count,
                firstTurn: bucket.turns.reduce((a, b) => a < b ? a : b),
                lastTurn: bucket.turns.reduce((a, b) => a > b ? a : b),
                command: bucket.command,
              ),
            )
            .toList()
          ..sort((a, b) {
            final countCompare = b.count.compareTo(a.count);
            if (countCompare != 0) return countCompare;
            return a.playerId.compareTo(b.playerId);
          });
    final workerStalls =
        workerSelections.values
            .map(
              (bucket) => AiWorkerStall(
                playerId: bucket.playerId,
                unitId: bucket.unitId,
                improvementType: bucket.improvementType,
                selectionCount: bucket.count,
                completionCount: workerCompletions[bucket.unitId] ?? 0,
                firstTurn: bucket.turns.reduce((a, b) => a < b ? a : b),
                lastTurn: bucket.turns.reduce((a, b) => a > b ? a : b),
              ),
            )
            .where((stall) => stall.selectionCount > stall.completionCount)
            .toList()
          ..sort((a, b) => b.selectionCount.compareTo(a.selectionCount));

    return HumanTraceReport(
      humanPlayerId: humanPlayerId,
      firstTimestamp: firstTimestamp,
      lastTimestamp: lastTimestamp,
      elapsedSeconds: firstTimestamp == null || lastTimestamp == null
          ? 0
          : lastTimestamp.difference(firstTimestamp).inSeconds,
      offsetCount: log.length,
      lastCompletedTurn: lastCompletedTurn,
      decisions: List.unmodifiable(meaningful),
      humanCommandCounts: _sortedMap(humanCounts),
      aiCommandCounts: _sortedMap(aiCounts),
      humanResearch: List.unmodifiable(humanResearch),
      humanProduction: List.unmodifiable(humanProduction),
      humanFoundCities: List.unmodifiable(humanFoundCities),
      humanWorkerImprovements: List.unmodifiable(humanWorkerImprovements),
      humanAttacks: List.unmodifiable(humanAttacks),
      aiSummaries: List.unmodifiable(aiSummaries),
      repeatedAiCommands: List.unmodifiable(repeatedCommands),
      aiWorkerStalls: List.unmodifiable(workerStalls),
    );
  }

  static void _increment(Map<String, int> counts, String key) {
    counts[key] = (counts[key] ?? 0) + 1;
  }

  static bool _isMeaningfulHumanCommand(GameCommand command) {
    return switch (command) {
      SubmitTurnCommand() ||
      EndTurnCommand() ||
      SetActivePlayerCommand() ||
      StartCityFoundingCommand() ||
      StartAttackTargetingCommand() ||
      StartWorkerActionSelectionCommand() ||
      ToggleMoveTargetingCommand() ||
      TileTappedCommand() ||
      CityTappedCommand() ||
      SelectTileCommand() ||
      SelectUnitCommand() ||
      SelectCityCommand() ||
      FocusNextPendingActionCommand() ||
      FocusTurnStartActionCommand() => false,
      _ => true,
    };
  }

  static bool _isRepeatedAiCandidate(GameCommand command) {
    return switch (command) {
      MoveUnitCommand() ||
      SelectWorkerImprovementCommand() ||
      AssignWorkerToHexCommand() ||
      AttackHexCommand() ||
      FoundCityCommand() => true,
      _ => false,
    };
  }

  static String? _commandOwner(GameCommand command) {
    return switch (command) {
      SelectTechnologyCommand(:final playerId) => playerId,
      SubmitTurnCommand(:final playerId) => playerId,
      EndTurnCommand(:final playerId) => playerId,
      SetActivePlayerCommand(:final playerId) => playerId,
      FocusNextPendingActionCommand(:final playerId) => playerId,
      FocusTurnStartActionCommand(:final playerId) => playerId,
      _ => null,
    };
  }

  static String _commandType(GameCommand command) {
    final encoded = GameCommandSerializer.toJson(command);
    return encoded['type'] as String? ?? command.runtimeType.toString();
  }

  static String _repeatedKey({
    required String playerId,
    required GameCommand command,
  }) {
    return '$playerId|${jsonEncode(GameCommandSerializer.toJson(command))}';
  }

  static Map<String, int> _sortedMap(Map<String, int> input) {
    final entries = input.entries.toList()
      ..sort((a, b) {
        final valueCompare = b.value.compareTo(a.value);
        if (valueCompare != 0) return valueCompare;
        return a.key.compareTo(b.key);
      });
    return Map.unmodifiable({
      for (final entry in entries) entry.key: entry.value,
    });
  }
}

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

class _RepeatedCommandBucket {
  _RepeatedCommandBucket({
    required this.playerId,
    required this.commandType,
    required this.command,
  });

  final String playerId;
  final String commandType;
  final Map<String, dynamic> command;
  final List<int> turns = [];
  int count = 0;

  void update(int turn) {
    count += 1;
    turns.add(turn);
  }
}

class _WorkerSelectionBucket {
  _WorkerSelectionBucket({
    required this.playerId,
    required this.unitId,
    required this.improvementType,
  });

  final String playerId;
  final String unitId;
  final String improvementType;
  final List<int> turns = [];
  int count = 0;

  void update(int turn) {
    count += 1;
    turns.add(turn);
  }
}
