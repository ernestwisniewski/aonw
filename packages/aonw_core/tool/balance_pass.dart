import 'dart:convert';
import 'dart:io';

import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_strategy_id.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/ai/telemetry/balance_runner.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';

part 'balance_pass_json_report.dart';
part 'balance_pass_markdown_report.dart';
part 'balance_pass_options.dart';

void main(List<String> args) {
  if (_hasFlag(args, '--help') || _hasFlag(args, '-h')) {
    stdout.writeln(_usage);
    return;
  }

  try {
    final options = _BalancePassOptions.fromArgs(args);
    final output = _OutputTargets.fromPath(options.out);
    final configs = [
      for (var index = 0; index < options.games; index++)
        BalanceRunner.fourPlayerMctsConfig(
          turns: options.turns,
          aiDifficulty: options.difficulty,
          seed: options.seed + index * 1000,
          gameLength: options.gameLength,
          primaryCountry: options.primaryCiv,
          opponentCountries: options.civs,
          mctsProfileMode: options.mctsProfileMode,
        ),
    ];
    final report = BalanceRunner.run(configs: configs);
    final summaryJson = _summaryJson(options: options, report: report);
    final markdown = _markdownReport(options: options, report: report);

    output.write(
      json: const JsonEncoder.withIndent('  ').convert(summaryJson),
      markdown: markdown,
    );
    final csvFiles = output.writeGameCsvs(report);

    stdout
      ..writeln('Wrote ${output.markdownFile.path}')
      ..writeln('Wrote ${output.jsonFile.path}')
      ..writeln('Wrote ${csvFiles.length} game CSV files')
      ..writeln(
        'Games: ${report.gameCount}/${report.attemptedGameCount}, '
        'crashes: ${report.crashCount}, '
        'rejected commands: ${report.totalRejectedCommands}',
      );

    if (report.crashCount > 0) {
      exitCode = 1;
    }
  } on _UsageException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln()
      ..writeln(_usage);
    exitCode = 64;
  }
}

Map<String, Object?> _runtimeSummaryJson(BalanceBatchReport report) {
  final records = _mctsRuntimeRecords(report);
  return {
    'turns': records.length,
    'averagePlanningMs': _averageRuntimeMs(records),
    'p95PlanningMs': _percentileRuntimeMs(records, 0.95),
    'maxPlanningMs': _maxRuntimeMs(records),
    'adaptiveLateGameTurns': records
        .where((record) => record.adaptiveLateGame)
        .length,
    'averageCandidateCalls': _averageMetric(records, 'mcts.candidateCalls'),
    'averageCandidateGenerationMs': _averageMetricMicros(
      records,
      'mcts.candidateElapsedMicros',
    ),
    'averageSearchMs': _averageMetricMicros(
      records,
      'mcts.searchElapsedMicros',
    ),
    'averageSearchSelectionMs': _averageMetricMicros(
      records,
      'mcts.searchSelectionElapsedMicros',
    ),
    'averageSearchExpansionMs': _averageMetricMicros(
      records,
      'mcts.searchExpansionElapsedMicros',
    ),
    'averageSearchRolloutMs': _averageMetricMicros(
      records,
      'mcts.searchRolloutElapsedMicros',
    ),
    'averageSearchEvaluationMs': _averageMetricMicros(
      records,
      'mcts.searchEvaluationElapsedMicros',
    ),
    'averageSearchBackpropagationMs': _averageMetricMicros(
      records,
      'mcts.searchBackpropagationElapsedMicros',
    ),
    'averageValidationMs': _averageMetricMicros(
      records,
      'mcts.validationElapsedMicros',
    ),
    'averageBaselinePlanMs': _averageMetricMicros(
      records,
      'mcts.baselinePlanElapsedMicros',
    ),
    'averageMergeMs': _averageMetricMicros(records, 'mcts.mergeElapsedMicros'),
    'averageStrategyMs': _averageMetricMicros(
      records,
      'mcts.strategyElapsedMicros',
    ),
    'averageSourcePlanCalls': _averageMetric(records, 'mcts.sourcePlanCalls'),
    'averageSourcePlanSkipped': _averageMetric(
      records,
      'mcts.sourcePlanSkipped',
    ),
    'averageSourcePlanMs': _averageMetricMicros(
      records,
      'mcts.sourcePlanElapsedMicros',
    ),
    'profiles': {
      for (final profile in _runtimeProfiles(records))
        profile: records
            .where((record) => _runtimeProfileLabel(record) == profile)
            .length,
    },
    'players': [
      for (final playerId in _runtimePlayerIds(records))
        {
          'playerId': playerId,
          'turns': records
              .where((record) => record.playerId == playerId)
              .length,
          'averagePlanningMs': _averageRuntimeMs(
            records.where((record) => record.playerId == playerId),
          ),
          'p95PlanningMs': _percentileRuntimeMs(
            records.where((record) => record.playerId == playerId),
            0.95,
          ),
          'maxPlanningMs': _maxRuntimeMs(
            records.where((record) => record.playerId == playerId),
          ),
          'adaptiveLateGameTurns': records
              .where(
                (record) =>
                    record.playerId == playerId && record.adaptiveLateGame,
              )
              .length,
          'averageCandidateCalls': _averageMetric(
            records.where((record) => record.playerId == playerId),
            'mcts.candidateCalls',
          ),
          'averageCandidateGenerationMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.candidateElapsedMicros',
          ),
          'averageSearchMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.searchElapsedMicros',
          ),
          'averageSearchSelectionMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.searchSelectionElapsedMicros',
          ),
          'averageSearchExpansionMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.searchExpansionElapsedMicros',
          ),
          'averageSearchRolloutMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.searchRolloutElapsedMicros',
          ),
          'averageSearchEvaluationMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.searchEvaluationElapsedMicros',
          ),
          'averageSearchBackpropagationMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.searchBackpropagationElapsedMicros',
          ),
          'averageValidationMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.validationElapsedMicros',
          ),
          'averageBaselinePlanMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.baselinePlanElapsedMicros',
          ),
          'averageMergeMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.mergeElapsedMicros',
          ),
          'averageStrategyMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.strategyElapsedMicros',
          ),
          'averageSourcePlanCalls': _averageMetric(
            records.where((record) => record.playerId == playerId),
            'mcts.sourcePlanCalls',
          ),
          'averageSourcePlanSkipped': _averageMetric(
            records.where((record) => record.playerId == playerId),
            'mcts.sourcePlanSkipped',
          ),
          'averageSourcePlanMs': _averageMetricMicros(
            records.where((record) => record.playerId == playerId),
            'mcts.sourcePlanElapsedMicros',
          ),
        },
    ],
  };
}

String _runtimeTable(BalanceBatchReport report) {
  final records = _mctsRuntimeRecords(report);
  if (records.isEmpty) return '_No MCTS runtime samples._';

  final buffer = StringBuffer()
    ..writeln(
      '| Player | Turns | Avg plan | P95 plan | Avg candidates | Avg source plans | Adaptive late-game | Profiles |',
    )
    ..writeln('| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |');
  for (final playerId in _runtimePlayerIds(records)) {
    final playerRecords = records
        .where((record) => record.playerId == playerId)
        .toList();
    buffer.writeln(
      '| $playerId | ${playerRecords.length} | '
      '${_durationMs(_averageRuntimeMs(playerRecords))} | '
      '${_durationMs(_percentileRuntimeMs(playerRecords, 0.95))} | '
      '${_decimal(_averageMetric(playerRecords, 'mcts.candidateCalls'))} | '
      '${_decimal(_averageMetric(playerRecords, 'mcts.sourcePlanCalls'))}'
      '+${_decimal(_averageMetric(playerRecords, 'mcts.sourcePlanSkipped'))} skipped | '
      '${playerRecords.where((record) => record.adaptiveLateGame).length} | '
      '${_profileCounts(playerRecords)} |',
    );
  }
  buffer
    ..writeln()
    ..writeln(
      'All MCTS turns: avg ${_durationMs(_averageRuntimeMs(records))}, '
      'p95 ${_durationMs(_percentileRuntimeMs(records, 0.95))}, '
      'max ${_durationMs(_maxRuntimeMs(records))}; '
      'candidate generation avg '
      '${_durationMs(_averageMetricMicros(records, 'mcts.candidateElapsedMicros'))}; '
      'source planning avg '
      '${_durationMs(_averageMetricMicros(records, 'mcts.sourcePlanElapsedMicros'))}.',
    )
    ..writeln(
      'MCTS phase avg: search '
      '${_durationMs(_averageMetricMicros(records, 'mcts.searchElapsedMicros'))}, '
      'validation '
      '${_durationMs(_averageMetricMicros(records, 'mcts.validationElapsedMicros'))}, '
      'baseline '
      '${_durationMs(_averageMetricMicros(records, 'mcts.baselinePlanElapsedMicros'))}, '
      'merge '
      '${_durationMs(_averageMetricMicros(records, 'mcts.mergeElapsedMicros'))}, '
      'strategy total '
      '${_durationMs(_averageMetricMicros(records, 'mcts.strategyElapsedMicros'))}.',
    )
    ..writeln(
      'MCTS search internals avg: select '
      '${_durationMs(_averageMetricMicros(records, 'mcts.searchSelectionElapsedMicros'))}, '
      'expand '
      '${_durationMs(_averageMetricMicros(records, 'mcts.searchExpansionElapsedMicros'))}, '
      'rollout '
      '${_durationMs(_averageMetricMicros(records, 'mcts.searchRolloutElapsedMicros'))}, '
      'eval '
      '${_durationMs(_averageMetricMicros(records, 'mcts.searchEvaluationElapsedMicros'))}, '
      'backprop '
      '${_durationMs(_averageMetricMicros(records, 'mcts.searchBackpropagationElapsedMicros'))}.',
    );
  return buffer.toString();
}

List<EconomySimulationAiTurnRuntime> _mctsRuntimeRecords(
  BalanceBatchReport report,
) {
  return [
    for (final game in report.games)
      for (final record in game.result.aiTurnRuntimes)
        if (record.strategyId == AiStrategyId.mcts) record,
  ];
}

List<String> _runtimePlayerIds(Iterable<EconomySimulationAiTurnRuntime> rows) {
  return {for (final row in rows) row.playerId}.toList()..sort();
}

List<String> _runtimeProfiles(Iterable<EconomySimulationAiTurnRuntime> rows) {
  return {for (final row in rows) _runtimeProfileLabel(row)}.toList()..sort();
}

String _profileCounts(Iterable<EconomySimulationAiTurnRuntime> rows) {
  final counts = <String, int>{};
  for (final row in rows) {
    final profile = _runtimeProfileLabel(row);
    counts[profile] = (counts[profile] ?? 0) + 1;
  }
  final labels = counts.keys.toList()..sort();
  return labels.map((label) => '$label ${counts[label]}').join(', ');
}

String _runtimeProfileLabel(EconomySimulationAiTurnRuntime row) {
  return row.runtimeProfile?.name ?? row.profileMode.name;
}

double _averageRuntimeMs(Iterable<EconomySimulationAiTurnRuntime> rows) {
  final micros = [for (final row in rows) row.planningDuration.inMicroseconds];
  if (micros.isEmpty) return 0;
  return micros.reduce((left, right) => left + right) / micros.length / 1000.0;
}

double _percentileRuntimeMs(
  Iterable<EconomySimulationAiTurnRuntime> rows,
  double percentile,
) {
  final micros = [for (final row in rows) row.planningDuration.inMicroseconds]
    ..sort();
  if (micros.isEmpty) return 0;
  final index = ((micros.length - 1) * percentile).ceil();
  return micros[index] / 1000.0;
}

double _maxRuntimeMs(Iterable<EconomySimulationAiTurnRuntime> rows) {
  final micros = [for (final row in rows) row.planningDuration.inMicroseconds];
  if (micros.isEmpty) return 0;
  return micros.reduce((left, right) => left > right ? left : right) / 1000.0;
}

double _averageMetric(
  Iterable<EconomySimulationAiTurnRuntime> rows,
  String key,
) {
  final values = [
    for (final row in rows)
      if (_numMetric(row, key) != null) _numMetric(row, key)!,
  ];
  if (values.isEmpty) return 0;
  return values.reduce((left, right) => left + right) / values.length;
}

double _averageMetricMicros(
  Iterable<EconomySimulationAiTurnRuntime> rows,
  String key,
) {
  return _averageMetric(rows, key) / 1000.0;
}

num? _numMetric(EconomySimulationAiTurnRuntime row, String key) {
  final value = row.debugMetrics[key];
  return value is num ? value : null;
}
