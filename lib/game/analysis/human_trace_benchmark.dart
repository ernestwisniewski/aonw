import 'dart:convert';

import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/ai/telemetry/balance_runner.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';

class HumanTraceBenchmark {
  const HumanTraceBenchmark({
    required this.source,
    required this.humanPlayerId,
    required this.lastCompletedTurn,
    required this.humanCityCount,
    required this.humanSecondCityTurn,
    required this.firstHumanAttackTurn,
    required this.maxRepeatedAiMoveCount,
    required this.maxAiWorkerStallSelections,
  });

  factory HumanTraceBenchmark.fromTraceJson(Map<String, dynamic> json) {
    final foundedCities =
        json['humanFoundCities'] as List<dynamic>? ?? const [];
    final attacks = json['humanAttacks'] as List<dynamic>? ?? const [];
    final repeated = json['repeatedAiCommands'] as List<dynamic>? ?? const [];
    final workerStalls = json['aiWorkerStalls'] as List<dynamic>? ?? const [];

    int? secondCityTurn;
    if (foundedCities.length >= 2) {
      secondCityTurn =
          (foundedCities[1] as Map<String, dynamic>)['turn'] as int?;
    }

    int? firstAttackTurn;
    for (final raw in attacks) {
      final turn = (raw as Map<String, dynamic>)['turn'] as int?;
      if (turn == null) continue;
      if (firstAttackTurn == null || turn < firstAttackTurn) {
        firstAttackTurn = turn;
      }
    }

    var maxMoveRepeat = 0;
    for (final raw in repeated) {
      final entry = raw as Map<String, dynamic>;
      if (entry['commandType'] != 'MoveUnit') continue;
      final count = entry['count'] as int? ?? 0;
      if (count > maxMoveRepeat) maxMoveRepeat = count;
    }

    var maxWorkerStall = 0;
    for (final raw in workerStalls) {
      final count =
          (raw as Map<String, dynamic>)['selectionCount'] as int? ?? 0;
      if (count > maxWorkerStall) maxWorkerStall = count;
    }

    return HumanTraceBenchmark(
      source: json['source'] as String? ?? 'unknown',
      humanPlayerId: json['humanPlayerId'] as String? ?? 'player_1',
      lastCompletedTurn: json['lastCompletedTurn'] as int? ?? 0,
      humanCityCount: foundedCities.length,
      humanSecondCityTurn: secondCityTurn,
      firstHumanAttackTurn: firstAttackTurn,
      maxRepeatedAiMoveCount: maxMoveRepeat,
      maxAiWorkerStallSelections: maxWorkerStall,
    );
  }

  final String source;
  final String humanPlayerId;
  final int lastCompletedTurn;
  final int humanCityCount;
  final int? humanSecondCityTurn;
  final int? firstHumanAttackTurn;
  final int maxRepeatedAiMoveCount;
  final int maxAiWorkerStallSelections;

  int get secondCityMaxTurn {
    final reference = humanSecondCityTurn ?? 36;
    return reference + 15;
  }

  int get minimumMaxCityCount {
    if (humanCityCount <= 2) return 2;
    return (humanCityCount / 2).ceil();
  }

  int get repeatedMoveLimit => 8;
  int get workerSelectionRepeatLimit => 3;

  Map<String, Object?> toJson() {
    return {
      'source': source,
      'humanPlayerId': humanPlayerId,
      'lastCompletedTurn': lastCompletedTurn,
      'humanCityCount': humanCityCount,
      'humanSecondCityTurn': humanSecondCityTurn,
      'firstHumanAttackTurn': firstHumanAttackTurn,
      'maxRepeatedAiMoveCount': maxRepeatedAiMoveCount,
      'maxAiWorkerStallSelections': maxAiWorkerStallSelections,
      'targets': {
        'secondCityMaxTurn': secondCityMaxTurn,
        'minimumMaxCityCount': minimumMaxCityCount,
        'repeatedMoveLimit': repeatedMoveLimit,
        'workerSelectionRepeatLimit': workerSelectionRepeatLimit,
      },
    };
  }
}

class HumanTraceSimulationBenchmark {
  const HumanTraceSimulationBenchmark(this.benchmark);

  final HumanTraceBenchmark benchmark;

  HumanTraceSimulationBenchmarkReport evaluate(BalanceBatchReport report) {
    final observations = <PlayerBenchmarkObservation>[];
    final findings = <HumanTraceBenchmarkFinding>[];

    for (final game in report.games) {
      for (final playerId in game.playerIds) {
        final expansion = game.expansionRecovery(playerId);
        final attackCommands = game.attackCommandCount(playerId);
        final repeatSummary = _repeatSummaryFor(
          game.result.appliedCommandRecords,
          playerId: playerId,
        );
        final rejectedRecords = [
          for (final record in game.result.rejectedCommandRecords)
            if (record.playerId == playerId) record,
        ];
        final observation = PlayerBenchmarkObservation(
          gameIndex: game.index,
          playerId: playerId,
          country: game.countryForPlayer(playerId)?.name ?? 'unknown',
          secondCityTurn: expansion.secondCityTurn,
          thirdCityTurn: expansion.thirdCityTurn,
          maxCityCount: expansion.maxCityCount,
          firstPostCitySettlerTurn: expansion.firstPostCitySettlerTurn,
          firstPostCityFoundCommandTurn:
              expansion.firstPostCityFoundCommandTurn,
          oneCityNoSettlerTurns: expansion.oneCityNoSettlerTurns,
          oneCityStartUnitCommands: expansion.oneCityStartUnitCommands,
          oneCityAttackCommands: expansion.oneCityAttackCommands,
          firstPostSecondCitySettlerTurn:
              expansion.firstPostSecondCitySettlerTurn,
          firstPostSecondCityFoundCommandTurn:
              expansion.firstPostSecondCityFoundCommandTurn,
          twoCityNoSettlerTurns: expansion.twoCityNoSettlerTurns,
          twoCityStartUnitCommands: expansion.twoCityStartUnitCommands,
          twoCityStartBuildingCommands: expansion.twoCityStartBuildingCommands,
          twoCityStartProjectCommands: expansion.twoCityStartProjectCommands,
          twoCityAttackCommands: expansion.twoCityAttackCommands,
          finalSettlerCount: expansion.finalSettlerCount,
          finalCityLocations: _finalCityLocations(game, playerId),
          finalSettlerLocations: _finalSettlerLocations(game, playerId),
          settlerMoveDetails: _settlerMoveDetails(game, playerId),
          finalMilitaryCount: expansion.finalMilitaryCount,
          attackCommands: attackCommands,
          maxRepeatedMoveCount: repeatSummary.maxMoveRepeat,
          maxRepeatedMoveCommand: repeatSummary.maxMoveCommand,
          maxRepeatedWorkerSelectionCount:
              repeatSummary.maxWorkerSelectionRepeat,
          maxRepeatedWorkerSelectionCommand: repeatSummary.maxWorkerCommand,
          rejectedCommands: rejectedRecords.length,
          rejectedCommandDetails: [
            for (final record in rejectedRecords)
              _rejectedCommandDetail(record),
          ],
        );
        observations.add(observation);
        if (playerId != benchmark.humanPlayerId) {
          findings.addAll(_findingsFor(observation));
        }
      }
    }

    for (final game in report.games) {
      if (game.rejectedCommandCount > 0) {
        findings.add(
          HumanTraceBenchmarkFinding(
            severity: HumanTraceBenchmarkSeverity.fail,
            code: 'rejected_commands',
            message:
                'Game ${game.index} rejected ${game.rejectedCommandCount} command(s).',
          ),
        );
      }
    }

    return HumanTraceSimulationBenchmarkReport(
      benchmark: benchmark,
      attemptedGames: report.attemptedGameCount,
      completedGames: report.gameCount,
      crashCount: report.crashCount,
      observations: List.unmodifiable(observations),
      findings: List.unmodifiable(findings),
    );
  }

  Iterable<HumanTraceBenchmarkFinding> _findingsFor(
    PlayerBenchmarkObservation observation,
  ) sync* {
    final secondCityTurn = observation.secondCityTurn;
    if (secondCityTurn == null) {
      yield HumanTraceBenchmarkFinding(
        severity: HumanTraceBenchmarkSeverity.fail,
        code: 'missing_second_city',
        message:
            'Game ${observation.gameIndex} ${observation.playerId} '
            '(${observation.country}) did not found a second city.',
      );
    } else if (secondCityTurn > benchmark.secondCityMaxTurn) {
      yield HumanTraceBenchmarkFinding(
        severity: HumanTraceBenchmarkSeverity.warn,
        code: 'slow_second_city',
        message:
            'Game ${observation.gameIndex} ${observation.playerId} '
            '(${observation.country}) founded second city on turn '
            '$secondCityTurn; target is <= ${benchmark.secondCityMaxTurn}.',
      );
    }

    if (observation.maxCityCount < benchmark.minimumMaxCityCount) {
      yield HumanTraceBenchmarkFinding(
        severity: HumanTraceBenchmarkSeverity.warn,
        code: 'low_city_count',
        message:
            'Game ${observation.gameIndex} ${observation.playerId} '
            '(${observation.country}) reached only ${observation.maxCityCount} '
            'cities; target is >= ${benchmark.minimumMaxCityCount}.',
      );
    }

    if (observation.maxRepeatedMoveCount > benchmark.repeatedMoveLimit) {
      yield HumanTraceBenchmarkFinding(
        severity: HumanTraceBenchmarkSeverity.fail,
        code: 'repeated_move_loop',
        message:
            'Game ${observation.gameIndex} ${observation.playerId} '
            '(${observation.country}) repeated one MoveUnit command '
            '${observation.maxRepeatedMoveCount} times; limit is '
            '${benchmark.repeatedMoveLimit}.',
      );
    }

    if (observation.maxRepeatedWorkerSelectionCount >
        benchmark.workerSelectionRepeatLimit) {
      yield HumanTraceBenchmarkFinding(
        severity: HumanTraceBenchmarkSeverity.fail,
        code: 'repeated_worker_selection',
        message:
            'Game ${observation.gameIndex} ${observation.playerId} '
            '(${observation.country}) repeated one worker improvement command '
            '${observation.maxRepeatedWorkerSelectionCount} times; limit is '
            '${benchmark.workerSelectionRepeatLimit}.',
      );
    }

    if (benchmark.firstHumanAttackTurn != null &&
        observation.attackCommands == 0) {
      yield HumanTraceBenchmarkFinding(
        severity: HumanTraceBenchmarkSeverity.info,
        code: 'no_attack_commands',
        message:
            'Game ${observation.gameIndex} ${observation.playerId} '
            '(${observation.country}) issued no attack commands.',
      );
    }
  }

  static _RepeatSummary _repeatSummaryFor(
    Iterable<EconomySimulationAppliedCommand> records, {
    required String playerId,
  }) {
    final moves = <String, int>{};
    final workers = <String, int>{};
    for (final record in records) {
      if (record.playerId != playerId) continue;
      final command = record.command;
      switch (command) {
        case MoveUnitCommand():
          _increment(moves, jsonEncode(GameCommandSerializer.toJson(command)));
        case SelectWorkerImprovementCommand():
          _increment(
            workers,
            jsonEncode(GameCommandSerializer.toJson(command)),
          );
        default:
          break;
      }
    }
    return _RepeatSummary(
      maxMoveRepeat: _maxCount(moves),
      maxMoveCommand: _maxKey(moves),
      maxWorkerSelectionRepeat: _maxCount(workers),
      maxWorkerCommand: _maxKey(workers),
    );
  }

  static void _increment(Map<String, int> counts, String key) {
    counts[key] = (counts[key] ?? 0) + 1;
  }

  static int _maxCount(Map<String, int> counts) {
    var result = 0;
    for (final count in counts.values) {
      if (count > result) result = count;
    }
    return result;
  }

  static String? _maxKey(Map<String, int> counts) {
    String? result;
    var maxCount = 0;
    for (final entry in counts.entries) {
      if (entry.value <= maxCount) continue;
      result = entry.key;
      maxCount = entry.value;
    }
    return result;
  }

  static Map<String, Object?> _rejectedCommandDetail(
    EconomySimulationRejectedCommand record,
  ) {
    return {
      'turn': record.turn,
      'tick': record.tick,
      'command': GameCommandSerializer.toJson(record.command),
      'reason': record.reason,
    };
  }

  static List<String> _finalSettlerLocations(
    BalanceGameReport game,
    String playerId,
  ) {
    final cities = [
      for (final city in game.result.state.cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final locations = [
      for (final unit in game.result.state.units)
        if (unit.ownerPlayerId == playerId &&
            CityFoundingRules.canFoundCityWith(unit))
          '${unit.id}@${unit.col},${unit.row}'
              '${_formatNearestOwnCityDistance(cities, unit.col, unit.row)}',
    ]..sort();
    return List.unmodifiable(locations);
  }

  static List<String> _finalCityLocations(
    BalanceGameReport game,
    String playerId,
  ) {
    final locations = [
      for (final city in game.result.state.cities)
        if (city.ownerPlayerId == playerId)
          '${city.id}@${city.center.col},${city.center.row}',
    ]..sort();
    return List.unmodifiable(locations);
  }

  static String _formatNearestOwnCityDistance(
    Iterable<GameCity> cities,
    int col,
    int row,
  ) {
    final distance = _nearestOwnCityDistance(cities, col, row);
    return distance == null ? '' : '(d$distance)';
  }

  static int? _nearestOwnCityDistance(
    Iterable<GameCity> cities,
    int col,
    int row,
  ) {
    int? result;
    final origin = HexCoordinate(col: col, row: row);
    for (final city in cities) {
      final distance = HexDistance.between(origin, city.center.toCoordinate());
      if (result == null || distance < result) result = distance;
    }
    return result;
  }

  static List<String> _settlerMoveDetails(
    BalanceGameReport game,
    String playerId,
  ) {
    final details = <String>[];
    for (final record in game.result.appliedCommandRecords) {
      if (record.playerId != playerId) continue;
      final command = record.command;
      if (command is! MoveUnitCommand || !command.unitId.contains('settler')) {
        continue;
      }
      details.add(
        'T${record.turn}:${command.unitId}->'
        '${command.targetCol},${command.targetRow}',
      );
    }
    const maxDetails = 16;
    if (details.length <= maxDetails) return List.unmodifiable(details);
    return List.unmodifiable(details.sublist(details.length - maxDetails));
  }
}

class HumanTraceSimulationBenchmarkReport {
  const HumanTraceSimulationBenchmarkReport({
    required this.benchmark,
    required this.attemptedGames,
    required this.completedGames,
    required this.crashCount,
    required this.observations,
    required this.findings,
  });

  final HumanTraceBenchmark benchmark;
  final int attemptedGames;
  final int completedGames;
  final int crashCount;
  final List<PlayerBenchmarkObservation> observations;
  final List<HumanTraceBenchmarkFinding> findings;

  bool get passed => findings.every(
    (finding) => finding.severity != HumanTraceBenchmarkSeverity.fail,
  );

  Map<String, Object?> toJson() {
    return {
      'passed': passed,
      'attemptedGames': attemptedGames,
      'completedGames': completedGames,
      'crashCount': crashCount,
      'benchmark': benchmark.toJson(),
      'observations': [
        for (final observation in observations) observation.toJson(),
      ],
      'findings': [for (final finding in findings) finding.toJson()],
    };
  }

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Human Trace Simulation Benchmark')
      ..writeln()
      ..writeln('- Passed: ${passed ? 'yes' : 'no'}')
      ..writeln('- Attempted games: $attemptedGames')
      ..writeln('- Completed games: $completedGames')
      ..writeln('- Crashes: $crashCount')
      ..writeln('- Human trace: ${benchmark.source}')
      ..writeln(
        '- Targets: second city <= T${benchmark.secondCityMaxTurn}, '
        'max cities >= ${benchmark.minimumMaxCityCount}, repeated move <= '
        '${benchmark.repeatedMoveLimit}, repeated worker select <= '
        '${benchmark.workerSelectionRepeatLimit}',
      )
      ..writeln()
      ..writeln('## Observations')
      ..writeln()
      ..writeln(
        '| Game | Player | Country | 2nd city | 3rd city | Max cities | Post-1 settler | 1c no settler | 1c U/A | Post-2 settler | 2c no settler | 2c U/B/P | 2c attacks | Attacks | Max repeated move | Max repeated worker select | Rejected |',
      )
      ..writeln(
        '|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|',
      );
    for (final observation in observations) {
      buffer.writeln(
        '| ${observation.gameIndex} | `${observation.playerId}` | '
        '${observation.country} | ${observation.secondCityTurn ?? '-'} | '
        '${observation.thirdCityTurn ?? '-'} | ${observation.maxCityCount} | '
        '${observation.firstPostCitySettlerTurn ?? '-'} | '
        '${observation.oneCityNoSettlerTurns} | '
        '${observation.oneCityStartUnitCommands}/'
        '${observation.oneCityAttackCommands} | '
        '${observation.firstPostSecondCitySettlerTurn ?? '-'} | '
        '${observation.twoCityNoSettlerTurns} | '
        '${observation.twoCityStartUnitCommands}/'
        '${observation.twoCityStartBuildingCommands}/'
        '${observation.twoCityStartProjectCommands} | '
        '${observation.twoCityAttackCommands} | '
        '${observation.attackCommands} | '
        '${observation.maxRepeatedMoveCount} | '
        '${observation.maxRepeatedWorkerSelectionCount} | '
        '${observation.rejectedCommands} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('### Expansion Lifecycle Details')
      ..writeln()
      ..writeln(
        '| Game | Player | Post-1 found cmd | Post-2 found cmd | Final cities | Final settlers | Final settler locations | Final military |',
      )
      ..writeln('|---:|---|---:|---:|---|---:|---|---:|');
    for (final observation in observations) {
      buffer.writeln(
        '| ${observation.gameIndex} | `${observation.playerId}` | '
        '${observation.firstPostCityFoundCommandTurn ?? '-'} | '
        '${observation.firstPostSecondCityFoundCommandTurn ?? '-'} | '
        '${observation.finalCityLocations.isEmpty ? '-' : observation.finalCityLocations.join(', ')} | '
        '${observation.finalSettlerCount} | '
        '${observation.finalSettlerLocations.isEmpty ? '-' : observation.finalSettlerLocations.join(', ')} | '
        '${observation.finalMilitaryCount} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('### Repeated Command Details')
      ..writeln();
    for (final observation in observations) {
      if (observation.maxRepeatedMoveCommand == null &&
          observation.maxRepeatedWorkerSelectionCommand == null) {
        continue;
      }
      buffer.writeln(
        '- Game ${observation.gameIndex} `${observation.playerId}`: '
        'move=${observation.maxRepeatedMoveCommand ?? '-'}, '
        'worker=${observation.maxRepeatedWorkerSelectionCommand ?? '-'}',
      );
    }

    buffer
      ..writeln()
      ..writeln('### Settler Movement Details')
      ..writeln();
    for (final observation in observations) {
      buffer.writeln(
        '- Game ${observation.gameIndex} `${observation.playerId}`: '
        '${observation.settlerMoveDetails.isEmpty ? '-' : observation.settlerMoveDetails.join(', ')}',
      );
    }

    buffer
      ..writeln()
      ..writeln('### Rejected Command Details')
      ..writeln();
    var wroteRejected = false;
    for (final observation in observations) {
      for (final detail in observation.rejectedCommandDetails) {
        wroteRejected = true;
        buffer.writeln(
          '- Game ${observation.gameIndex} `${observation.playerId}`: '
          '${jsonEncode(detail)}',
        );
      }
    }
    if (!wroteRejected) {
      buffer.writeln('- none');
    }

    buffer
      ..writeln()
      ..writeln('## Findings')
      ..writeln();
    if (findings.isEmpty) {
      buffer.writeln('- none');
    } else {
      for (final finding in findings) {
        buffer.writeln(
          '- `${finding.severity.name}` `${finding.code}`: ${finding.message}',
        );
      }
    }
    return buffer.toString();
  }
}

class PlayerBenchmarkObservation {
  const PlayerBenchmarkObservation({
    required this.gameIndex,
    required this.playerId,
    required this.country,
    required this.secondCityTurn,
    required this.thirdCityTurn,
    required this.maxCityCount,
    required this.firstPostCitySettlerTurn,
    required this.firstPostCityFoundCommandTurn,
    required this.oneCityNoSettlerTurns,
    required this.oneCityStartUnitCommands,
    required this.oneCityAttackCommands,
    required this.firstPostSecondCitySettlerTurn,
    required this.firstPostSecondCityFoundCommandTurn,
    required this.twoCityNoSettlerTurns,
    required this.twoCityStartUnitCommands,
    required this.twoCityStartBuildingCommands,
    required this.twoCityStartProjectCommands,
    required this.twoCityAttackCommands,
    required this.finalSettlerCount,
    required this.finalCityLocations,
    required this.finalSettlerLocations,
    required this.settlerMoveDetails,
    required this.finalMilitaryCount,
    required this.attackCommands,
    required this.maxRepeatedMoveCount,
    required this.maxRepeatedMoveCommand,
    required this.maxRepeatedWorkerSelectionCount,
    required this.maxRepeatedWorkerSelectionCommand,
    required this.rejectedCommands,
    required this.rejectedCommandDetails,
  });

  final int gameIndex;
  final String playerId;
  final String country;
  final int? secondCityTurn;
  final int? thirdCityTurn;
  final int maxCityCount;
  final int? firstPostCitySettlerTurn;
  final int? firstPostCityFoundCommandTurn;
  final int oneCityNoSettlerTurns;
  final int oneCityStartUnitCommands;
  final int oneCityAttackCommands;
  final int? firstPostSecondCitySettlerTurn;
  final int? firstPostSecondCityFoundCommandTurn;
  final int twoCityNoSettlerTurns;
  final int twoCityStartUnitCommands;
  final int twoCityStartBuildingCommands;
  final int twoCityStartProjectCommands;
  final int twoCityAttackCommands;
  final int finalSettlerCount;
  final List<String> finalCityLocations;
  final List<String> finalSettlerLocations;
  final List<String> settlerMoveDetails;
  final int finalMilitaryCount;
  final int attackCommands;
  final int maxRepeatedMoveCount;
  final String? maxRepeatedMoveCommand;
  final int maxRepeatedWorkerSelectionCount;
  final String? maxRepeatedWorkerSelectionCommand;
  final int rejectedCommands;
  final List<Map<String, Object?>> rejectedCommandDetails;

  Map<String, Object?> toJson() {
    return {
      'gameIndex': gameIndex,
      'playerId': playerId,
      'country': country,
      'secondCityTurn': secondCityTurn,
      'thirdCityTurn': thirdCityTurn,
      'maxCityCount': maxCityCount,
      'firstPostCitySettlerTurn': firstPostCitySettlerTurn,
      'firstPostCityFoundCommandTurn': firstPostCityFoundCommandTurn,
      'oneCityNoSettlerTurns': oneCityNoSettlerTurns,
      'oneCityStartUnitCommands': oneCityStartUnitCommands,
      'oneCityAttackCommands': oneCityAttackCommands,
      'firstPostSecondCitySettlerTurn': firstPostSecondCitySettlerTurn,
      'firstPostSecondCityFoundCommandTurn':
          firstPostSecondCityFoundCommandTurn,
      'twoCityNoSettlerTurns': twoCityNoSettlerTurns,
      'twoCityStartUnitCommands': twoCityStartUnitCommands,
      'twoCityStartBuildingCommands': twoCityStartBuildingCommands,
      'twoCityStartProjectCommands': twoCityStartProjectCommands,
      'twoCityAttackCommands': twoCityAttackCommands,
      'finalSettlerCount': finalSettlerCount,
      'finalCityLocations': finalCityLocations,
      'finalSettlerLocations': finalSettlerLocations,
      'settlerMoveDetails': settlerMoveDetails,
      'finalMilitaryCount': finalMilitaryCount,
      'attackCommands': attackCommands,
      'maxRepeatedMoveCount': maxRepeatedMoveCount,
      'maxRepeatedMoveCommand': maxRepeatedMoveCommand == null
          ? null
          : jsonDecode(maxRepeatedMoveCommand!) as Map<String, dynamic>,
      'maxRepeatedWorkerSelectionCount': maxRepeatedWorkerSelectionCount,
      'maxRepeatedWorkerSelectionCommand':
          maxRepeatedWorkerSelectionCommand == null
          ? null
          : jsonDecode(maxRepeatedWorkerSelectionCommand!)
                as Map<String, dynamic>,
      'rejectedCommands': rejectedCommands,
      'rejectedCommandDetails': rejectedCommandDetails,
    };
  }
}

class HumanTraceBenchmarkFinding {
  const HumanTraceBenchmarkFinding({
    required this.severity,
    required this.code,
    required this.message,
  });

  final HumanTraceBenchmarkSeverity severity;
  final String code;
  final String message;

  Map<String, Object?> toJson() {
    return {'severity': severity.name, 'code': code, 'message': message};
  }
}

enum HumanTraceBenchmarkSeverity { info, warn, fail }

class _RepeatSummary {
  const _RepeatSummary({
    required this.maxMoveRepeat,
    required this.maxMoveCommand,
    required this.maxWorkerSelectionRepeat,
    required this.maxWorkerCommand,
  });

  final int maxMoveRepeat;
  final String? maxMoveCommand;
  final int maxWorkerSelectionRepeat;
  final String? maxWorkerCommand;
}
