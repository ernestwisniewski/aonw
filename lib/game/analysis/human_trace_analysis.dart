import 'dart:convert';

import 'package:aonw/game/analysis/human_trace_report.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw_core/game/domain/command.dart';

class HumanTraceAnalyzer {
  const HumanTraceAnalyzer();

  HumanTraceReport analyze({
    required List<RecordedDomainCommand> log,
    required String humanPlayerId,
  }) {
    return _HumanTraceAccumulator(humanPlayerId).analyze(log);
  }
}

class _HumanTraceAccumulator {
  _HumanTraceAccumulator(this.humanPlayerId);

  final String humanPlayerId;
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

  var turn = 1;
  var lastCompletedTurn = 0;
  DateTime? firstTimestamp;
  DateTime? lastTimestamp;

  HumanTraceReport analyze(List<RecordedDomainCommand> log) {
    for (final entry in log) {
      _accept(entry);
    }
    return _buildReport(log.length);
  }

  void _accept(RecordedDomainCommand entry) {
    final command = entry.command;
    if (command == null) return;
    firstTimestamp ??= entry.timestamp;
    lastTimestamp = entry.timestamp;
    final owner = _commandOwner(command);
    final actorPlayerId = entry.actorPlayerId;
    final isHumanCommand = _isHumanCommand(
      actorPlayerId: actorPlayerId,
      ownerPlayerId: owner,
      command: command,
    );
    if (isHumanCommand) _recordHuman(entry, command);
    if (actorPlayerId != null) _recordAi(actorPlayerId, command);
    _recordCityFounding(
      command: command,
      actorPlayerId: actorPlayerId,
      ownerPlayerId: owner,
      isHumanCommand: isHumanCommand,
    );
    _recordEvents(entry);
  }

  bool _isHumanCommand({
    required String? actorPlayerId,
    required String? ownerPlayerId,
    required DomainCommand command,
  }) {
    return actorPlayerId == null &&
        (ownerPlayerId == null || ownerPlayerId == humanPlayerId) &&
        _isMeaningfulHumanCommand(command);
  }

  void _recordHuman(RecordedDomainCommand entry, DomainCommand command) {
    final commandType = _commandType(command);
    _increment(humanCounts, commandType);
    meaningful.add(
      HumanTraceDecision(
        turn: turn,
        offset: entry.offset,
        commandType: commandType,
        command: DomainCommandCodec.toJson(command),
      ),
    );
    _addIfPresent(humanResearch, _researchChoice(command, entry, turn));
    _addIfPresent(humanProduction, _productionChoice(command, entry, turn));
    _addIfPresent(humanFoundCities, _cityFounding(command, entry, turn));
    _addIfPresent(
      humanWorkerImprovements,
      _workerImprovement(command, entry, turn),
    );
    _addIfPresent(humanAttacks, _attack(command, entry, turn));
  }

  void _recordAi(String playerId, DomainCommand command) {
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
              command: DomainCommandCodec.toJson(command),
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

  void _recordCityFounding({
    required DomainCommand command,
    required String? actorPlayerId,
    required String? ownerPlayerId,
    required bool isHumanCommand,
  }) {
    if (command is! FoundCityCommand) return;
    final playerId =
        actorPlayerId ??
        ownerPlayerId ??
        (isHumanCommand ? humanPlayerId : null);
    if (playerId != null) {
      cityFoundingTurns.putIfAbsent(playerId, () => []).add(turn);
    }
  }

  void _recordEvents(RecordedDomainCommand entry) {
    for (final event in entry.events) {
      final descriptor = GameEventDescriptor.forEvent(event);
      final completedTurn = descriptor.completedTurn;
      if (completedTurn != null) {
        lastCompletedTurn = completedTurn;
        turn = completedTurn + 1;
      }
      final completedWorkerUnitId = descriptor.completedWorkerUnitId;
      if (completedWorkerUnitId != null) {
        _increment(workerCompletions, completedWorkerUnitId);
      }
    }
  }

  HumanTraceReport _buildReport(int offsetCount) {
    return HumanTraceReport(
      humanPlayerId: humanPlayerId,
      firstTimestamp: firstTimestamp,
      lastTimestamp: lastTimestamp,
      elapsedSeconds: firstTimestamp == null || lastTimestamp == null
          ? 0
          : lastTimestamp!.difference(firstTimestamp!).inSeconds,
      offsetCount: offsetCount,
      lastCompletedTurn: lastCompletedTurn,
      decisions: List.unmodifiable(meaningful),
      humanCommandCounts: _sortedMap(humanCounts),
      aiCommandCounts: _sortedMap(aiCounts),
      humanResearch: List.unmodifiable(humanResearch),
      humanProduction: List.unmodifiable(humanProduction),
      humanFoundCities: List.unmodifiable(humanFoundCities),
      humanWorkerImprovements: List.unmodifiable(humanWorkerImprovements),
      humanAttacks: List.unmodifiable(humanAttacks),
      aiSummaries: List.unmodifiable(_aiSummaries()),
      repeatedAiCommands: List.unmodifiable(_repeatedCommands()),
      aiWorkerStalls: List.unmodifiable(_workerStalls()),
    );
  }

  List<AiTraceSummary> _aiSummaries() {
    return [
      for (final playerId in aiPlayerCounts.keys.toList()..sort())
        AiTraceSummary(
          playerId: playerId,
          commandCounts: _sortedMap(aiPlayerCounts[playerId]!),
          cityFoundingTurns: List.unmodifiable(
            cityFoundingTurns[playerId] ?? const <int>[],
          ),
        ),
    ];
  }

  List<RepeatedAiCommand> _repeatedCommands() {
    return [
      for (final bucket in aiRepeated.values)
        if (bucket.count > 1)
          RepeatedAiCommand(
            playerId: bucket.playerId,
            commandType: bucket.commandType,
            count: bucket.count,
            firstTurn: _minimum(bucket.turns),
            lastTurn: _maximum(bucket.turns),
            command: bucket.command,
          ),
    ]..sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) return countCompare;
      return a.playerId.compareTo(b.playerId);
    });
  }

  List<AiWorkerStall> _workerStalls() {
    return [
        for (final bucket in workerSelections.values)
          AiWorkerStall(
            playerId: bucket.playerId,
            unitId: bucket.unitId,
            improvementType: bucket.improvementType,
            selectionCount: bucket.count,
            completionCount: workerCompletions[bucket.unitId] ?? 0,
            firstTurn: _minimum(bucket.turns),
            lastTurn: _maximum(bucket.turns),
          ),
      ]
      ..removeWhere((stall) => stall.selectionCount <= stall.completionCount)
      ..sort((a, b) => b.selectionCount.compareTo(a.selectionCount));
  }
}

TraceResearchChoice? _researchChoice(
  DomainCommand command,
  RecordedDomainCommand entry,
  int turn,
) {
  if (command case SelectTechnologyCommand(:final technologyId)) {
    return TraceResearchChoice(
      turn: turn,
      offset: entry.offset,
      technologyId: technologyId.name,
    );
  }
  return null;
}

TraceProductionChoice? _productionChoice(
  DomainCommand command,
  RecordedDomainCommand entry,
  int turn,
) {
  final production = switch (command) {
    StartBuildingCommand(:final cityId, :final buildingType) => (
      cityId,
      'building',
      buildingType.name,
    ),
    StartUnitProductionCommand(:final cityId, :final unitType) => (
      cityId,
      'unit',
      unitType.name,
    ),
    StartCityProjectCommand(:final cityId, :final projectType) => (
      cityId,
      'project',
      projectType.name,
    ),
    _ => null,
  };
  if (production == null) return null;
  return TraceProductionChoice(
    turn: turn,
    offset: entry.offset,
    cityId: production.$1,
    kind: production.$2,
    target: production.$3,
  );
}

TraceCityFounding? _cityFounding(
  DomainCommand command,
  RecordedDomainCommand entry,
  int turn,
) {
  if (command case FoundCityCommand(:final founderId, :final controlledHexes)) {
    return TraceCityFounding(
      turn: turn,
      offset: entry.offset,
      founderId: founderId,
      controlledHexes: [
        for (final hex in controlledHexes) TraceHex(col: hex.col, row: hex.row),
      ],
    );
  }
  return null;
}

TraceWorkerImprovement? _workerImprovement(
  DomainCommand command,
  RecordedDomainCommand entry,
  int turn,
) {
  if (command case SelectWorkerImprovementCommand(
    :final unitId,
    :final improvementType,
  )) {
    return TraceWorkerImprovement(
      turn: turn,
      offset: entry.offset,
      unitId: unitId,
      improvementType: improvementType.name,
    );
  }
  return null;
}

TraceAttack? _attack(
  DomainCommand command,
  RecordedDomainCommand entry,
  int turn,
) {
  if (command case AttackHexCommand(
    :final attackerUnitId,
    :final defenderCol,
    :final defenderRow,
  )) {
    return TraceAttack(
      turn: turn,
      offset: entry.offset,
      attackerUnitId: attackerUnitId,
      targetCol: defenderCol,
      targetRow: defenderRow,
    );
  }
  return null;
}

void _addIfPresent<T>(List<T> target, T? value) {
  if (value != null) target.add(value);
}

void _increment(Map<String, int> counts, String key) {
  counts[key] = (counts[key] ?? 0) + 1;
}

bool _isMeaningfulHumanCommand(DomainCommand command) {
  return switch (command) {
    SubmitTurnCommand() || EndTurnCommand() => false,
    _ => true,
  };
}

bool _isRepeatedAiCandidate(DomainCommand command) {
  return switch (command) {
    MoveUnitCommand() ||
    SelectWorkerImprovementCommand() ||
    AssignWorkerToHexCommand() ||
    AttackHexCommand() ||
    FoundCityCommand() => true,
    _ => false,
  };
}

String? _commandOwner(DomainCommand command) {
  return switch (command) {
    SelectTechnologyCommand(:final playerId) => playerId,
    SubmitTurnCommand(:final playerId) => playerId,
    EndTurnCommand(:final playerId) => playerId,
    _ => null,
  };
}

String _commandType(DomainCommand command) {
  final encoded = DomainCommandCodec.toJson(command);
  return encoded['type'] as String? ?? command.runtimeType.toString();
}

String _repeatedKey({
  required String playerId,
  required DomainCommand command,
}) {
  return '$playerId|${jsonEncode(DomainCommandCodec.toJson(command))}';
}

Map<String, int> _sortedMap(Map<String, int> input) {
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

int _minimum(List<int> values) {
  return values.reduce((a, b) => a < b ? a : b);
}

int _maximum(List<int> values) {
  return values.reduce((a, b) => a > b ? a : b);
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
