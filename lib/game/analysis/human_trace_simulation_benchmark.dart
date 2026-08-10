import 'dart:convert';

import 'package:aonw/game/analysis/human_trace_benchmark_model.dart';
import 'package:aonw/game/analysis/human_trace_benchmark_observation.dart';
import 'package:aonw/game/analysis/human_trace_benchmark_report.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/ai/telemetry/balance_runner.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';

class HumanTraceSimulationBenchmark {
  const HumanTraceSimulationBenchmark(this.benchmark);

  final HumanTraceBenchmark benchmark;

  HumanTraceSimulationBenchmarkReport evaluate(BalanceBatchReport report) {
    final observations = [
      for (final game in report.games)
        for (final playerId in game.playerIds) _observationFor(game, playerId),
    ];
    final findings = [
      for (final observation in observations)
        if (observation.playerId != benchmark.humanPlayerId)
          ..._findingsFor(observation),
      for (final game in report.games)
        if (game.rejectedCommandCount > 0) _rejectedCommandsFinding(game),
    ];
    return HumanTraceSimulationBenchmarkReport(
      benchmark: benchmark,
      attemptedGames: report.attemptedGameCount,
      completedGames: report.gameCount,
      crashCount: report.crashCount,
      observations: List.unmodifiable(observations),
      findings: List.unmodifiable(findings),
    );
  }

  PlayerBenchmarkObservation _observationFor(
    BalanceGameReport game,
    String playerId,
  ) {
    final expansion = game.expansionRecovery(playerId);
    final repeatSummary = _repeatSummaryFor(
      game.result.appliedCommandRecords,
      playerId: playerId,
    );
    final rejectedRecords = [
      for (final record in game.result.rejectedCommandRecords)
        if (record.playerId == playerId) record,
    ];
    return PlayerBenchmarkObservation(
      gameIndex: game.index,
      playerId: playerId,
      country: game.countryForPlayer(playerId)?.name ?? 'unknown',
      secondCityTurn: expansion.secondCityTurn,
      thirdCityTurn: expansion.thirdCityTurn,
      maxCityCount: expansion.maxCityCount,
      firstPostCitySettlerTurn: expansion.firstPostCitySettlerTurn,
      firstPostCityFoundCommandTurn: expansion.firstPostCityFoundCommandTurn,
      oneCityNoSettlerTurns: expansion.oneCityNoSettlerTurns,
      oneCityStartUnitCommands: expansion.oneCityStartUnitCommands,
      oneCityAttackCommands: expansion.oneCityAttackCommands,
      firstPostSecondCitySettlerTurn: expansion.firstPostSecondCitySettlerTurn,
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
      attackCommands: game.attackCommandCount(playerId),
      maxRepeatedMoveCount: repeatSummary.maxMoveRepeat,
      maxRepeatedMoveCommand: repeatSummary.maxMoveCommand,
      maxRepeatedWorkerSelectionCount: repeatSummary.maxWorkerSelectionRepeat,
      maxRepeatedWorkerSelectionCommand: repeatSummary.maxWorkerCommand,
      rejectedCommands: rejectedRecords.length,
      rejectedCommandDetails: [
        for (final record in rejectedRecords) _rejectedCommandDetail(record),
      ],
    );
  }

  Iterable<HumanTraceBenchmarkFinding> _findingsFor(
    PlayerBenchmarkObservation observation,
  ) sync* {
    yield* _expansionFindings(observation);
    yield* _repetitionFindings(observation);
    yield* _activityFindings(observation);
  }

  Iterable<HumanTraceBenchmarkFinding> _expansionFindings(
    PlayerBenchmarkObservation observation,
  ) sync* {
    final secondCityTurn = observation.secondCityTurn;
    if (secondCityTurn == null) {
      yield _finding(
        observation,
        HumanTraceBenchmarkSeverity.fail,
        'missing_second_city',
        'did not found a second city.',
      );
    } else if (secondCityTurn > benchmark.secondCityMaxTurn) {
      yield _finding(
        observation,
        HumanTraceBenchmarkSeverity.warn,
        'slow_second_city',
        'founded second city on turn $secondCityTurn; target is <= '
            '${benchmark.secondCityMaxTurn}.',
      );
    }
    if (observation.maxCityCount < benchmark.minimumMaxCityCount) {
      yield _finding(
        observation,
        HumanTraceBenchmarkSeverity.warn,
        'low_city_count',
        'reached only ${observation.maxCityCount} cities; target is >= '
            '${benchmark.minimumMaxCityCount}.',
      );
    }
  }

  Iterable<HumanTraceBenchmarkFinding> _repetitionFindings(
    PlayerBenchmarkObservation observation,
  ) sync* {
    if (observation.maxRepeatedMoveCount > benchmark.repeatedMoveLimit) {
      yield _finding(
        observation,
        HumanTraceBenchmarkSeverity.fail,
        'repeated_move_loop',
        'repeated one MoveUnit command ${observation.maxRepeatedMoveCount} '
            'times; limit is ${benchmark.repeatedMoveLimit}.',
      );
    }
    if (observation.maxRepeatedWorkerSelectionCount >
        benchmark.workerSelectionRepeatLimit) {
      yield _finding(
        observation,
        HumanTraceBenchmarkSeverity.fail,
        'repeated_worker_selection',
        'repeated one worker improvement command '
            '${observation.maxRepeatedWorkerSelectionCount} times; limit is '
            '${benchmark.workerSelectionRepeatLimit}.',
      );
    }
  }

  Iterable<HumanTraceBenchmarkFinding> _activityFindings(
    PlayerBenchmarkObservation observation,
  ) sync* {
    if (benchmark.firstHumanAttackTurn != null &&
        observation.attackCommands == 0) {
      yield _finding(
        observation,
        HumanTraceBenchmarkSeverity.info,
        'no_attack_commands',
        'issued no attack commands.',
      );
    }
  }

  HumanTraceBenchmarkFinding _finding(
    PlayerBenchmarkObservation observation,
    HumanTraceBenchmarkSeverity severity,
    String code,
    String detail,
  ) {
    return HumanTraceBenchmarkFinding(
      severity: severity,
      code: code,
      message:
          'Game ${observation.gameIndex} ${observation.playerId} '
          '(${observation.country}) $detail',
    );
  }
}

HumanTraceBenchmarkFinding _rejectedCommandsFinding(BalanceGameReport game) {
  return HumanTraceBenchmarkFinding(
    severity: HumanTraceBenchmarkSeverity.fail,
    code: 'rejected_commands',
    message:
        'Game ${game.index} rejected ${game.rejectedCommandCount} command(s).',
  );
}

_RepeatSummary _repeatSummaryFor(
  Iterable<EconomySimulationAppliedCommand> records, {
  required String playerId,
}) {
  final moves = <String, int>{};
  final workers = <String, int>{};
  for (final record in records) {
    if (record.playerId != playerId) continue;
    switch (record.command) {
      case final MoveUnitCommand command:
        _increment(moves, jsonEncode(DomainCommandCodec.toJson(command)));
      case final SelectWorkerImprovementCommand command:
        _increment(workers, jsonEncode(DomainCommandCodec.toJson(command)));
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

void _increment(Map<String, int> counts, String key) {
  counts[key] = (counts[key] ?? 0) + 1;
}

int _maxCount(Map<String, int> counts) {
  return counts.values.fold(
    0,
    (result, count) => count > result ? count : result,
  );
}

String? _maxKey(Map<String, int> counts) {
  if (counts.isEmpty) return null;
  return counts.entries.reduce((best, entry) {
    return entry.value > best.value ? entry : best;
  }).key;
}

Map<String, Object?> _rejectedCommandDetail(
  EconomySimulationRejectedCommand record,
) {
  return {
    'turn': record.turn,
    'tick': record.tick,
    'command': DomainCommandCodec.toJson(record.command),
    'reason': record.reason,
  };
}

List<String> _finalSettlerLocations(BalanceGameReport game, String playerId) {
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

List<String> _finalCityLocations(BalanceGameReport game, String playerId) {
  final locations = [
    for (final city in game.result.state.cities)
      if (city.ownerPlayerId == playerId)
        '${city.id}@${city.center.col},${city.center.row}',
  ]..sort();
  return List.unmodifiable(locations);
}

String _formatNearestOwnCityDistance(
  Iterable<GameCity> cities,
  int col,
  int row,
) {
  final distance = _nearestOwnCityDistance(cities, col, row);
  return distance == null ? '' : '(d$distance)';
}

int? _nearestOwnCityDistance(Iterable<GameCity> cities, int col, int row) {
  int? result;
  final origin = HexCoordinate(col: col, row: row);
  for (final city in cities) {
    final distance = HexDistance.between(origin, city.center.toCoordinate());
    if (result == null || distance < result) result = distance;
  }
  return result;
}

List<String> _settlerMoveDetails(BalanceGameReport game, String playerId) {
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
