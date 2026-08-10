import 'dart:convert';

import 'package:aonw/game/analysis/human_trace_benchmark_model.dart';
import 'package:aonw/game/analysis/human_trace_benchmark_observation.dart';

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
    final buffer = StringBuffer();
    _writeSummary(buffer);
    _writeObservations(buffer);
    _writeExpansionDetails(buffer);
    _writeRepeatedCommandDetails(buffer);
    _writeSettlerMovementDetails(buffer);
    _writeRejectedCommandDetails(buffer);
    _writeFindings(buffer);
    return buffer.toString();
  }

  void _writeSummary(StringBuffer buffer) {
    buffer
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
      );
  }

  void _writeObservations(StringBuffer buffer) {
    buffer
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
      buffer.writeln(_observationRow(observation));
    }
  }

  void _writeExpansionDetails(StringBuffer buffer) {
    buffer
      ..writeln()
      ..writeln('### Expansion Lifecycle Details')
      ..writeln()
      ..writeln(
        '| Game | Player | Post-1 found cmd | Post-2 found cmd | Final cities | Final settlers | Final settler locations | Final military |',
      )
      ..writeln('|---:|---|---:|---:|---|---:|---|---:|');
    for (final observation in observations) {
      buffer.writeln(_expansionRow(observation));
    }
  }

  void _writeRepeatedCommandDetails(StringBuffer buffer) {
    _writeDetailHeading(buffer, 'Repeated Command Details');
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
  }

  void _writeSettlerMovementDetails(StringBuffer buffer) {
    _writeDetailHeading(buffer, 'Settler Movement Details');
    for (final observation in observations) {
      buffer.writeln(
        '- Game ${observation.gameIndex} `${observation.playerId}`: '
        '${_listOrDash(observation.settlerMoveDetails)}',
      );
    }
  }

  void _writeRejectedCommandDetails(StringBuffer buffer) {
    _writeDetailHeading(buffer, 'Rejected Command Details');
    final details = [
      for (final observation in observations)
        for (final detail in observation.rejectedCommandDetails)
          '- Game ${observation.gameIndex} `${observation.playerId}`: '
              '${jsonEncode(detail)}',
    ];
    if (details.isEmpty) {
      buffer.writeln('- none');
      return;
    }
    for (final detail in details) {
      buffer.writeln(detail);
    }
  }

  void _writeFindings(StringBuffer buffer) {
    buffer
      ..writeln()
      ..writeln('## Findings')
      ..writeln();
    if (findings.isEmpty) {
      buffer.writeln('- none');
      return;
    }
    for (final finding in findings) {
      buffer.writeln(
        '- `${finding.severity.name}` `${finding.code}`: ${finding.message}',
      );
    }
  }
}

void _writeDetailHeading(StringBuffer buffer, String heading) {
  buffer
    ..writeln()
    ..writeln('### $heading')
    ..writeln();
}

String _observationRow(PlayerBenchmarkObservation observation) {
  return '| ${observation.gameIndex} | `${observation.playerId}` | '
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
      '${observation.twoCityAttackCommands} | ${observation.attackCommands} | '
      '${observation.maxRepeatedMoveCount} | '
      '${observation.maxRepeatedWorkerSelectionCount} | '
      '${observation.rejectedCommands} |';
}

String _expansionRow(PlayerBenchmarkObservation observation) {
  return '| ${observation.gameIndex} | `${observation.playerId}` | '
      '${observation.firstPostCityFoundCommandTurn ?? '-'} | '
      '${observation.firstPostSecondCityFoundCommandTurn ?? '-'} | '
      '${_listOrDash(observation.finalCityLocations)} | '
      '${observation.finalSettlerCount} | '
      '${_listOrDash(observation.finalSettlerLocations)} | '
      '${observation.finalMilitaryCount} |';
}

String _listOrDash(List<String> values) {
  return values.isEmpty ? '-' : values.join(', ');
}
