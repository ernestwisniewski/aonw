import 'dart:convert';
import 'dart:io';

import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_strategy_id.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/ai/telemetry/balance_runner.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';

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

Map<String, Object?> _summaryJson({
  required _BalancePassOptions options,
  required BalanceBatchReport report,
}) {
  return {
    'generatedBy': 'dart run tool/balance_pass.dart',
    'parameters': {
      'games': options.games,
      'targetMinutes': options.gameLength.targetMinutes,
      'estimatedTurnSeconds': GameLengthConfig.estimatedMultiplayerTurnSeconds,
      'rawTurnOverride': options.rawTurnOverride,
      'turns': options.turns,
      'difficulty': options.difficulty.name,
      'mctsProfile': options.mctsProfileMode.name,
      'seed': options.seed,
      'primaryCiv': options.primaryCiv.name,
      'civs': [for (final civ in options.civs) civ.name],
    },
    'attemptedGameCount': report.attemptedGameCount,
    'completedGameCount': report.gameCount,
    'crashCount': report.crashCount,
    'totalRejectedCommands': report.totalRejectedCommands,
    'mctsRuntime': _runtimeSummaryJson(report),
    'players': [
      for (final playerId in _orderedPlayerIds(report))
        _playerJson(report, playerId),
    ],
    'countries': [
      for (final country in _orderedCountries(report))
        _countryJson(report, country),
    ],
    'games': [
      for (final game in report.games)
        {
          'index': game.index,
          'winnerPlayerId': game.winnerPlayerId,
          'victoryTurn': game.victoryTurn,
          'victoryCondition': game.victoryCondition?.name,
          'rejectedCommandCount': game.rejectedCommandCount,
          'rejectedCommands': [
            for (final rejected in game.result.rejectedCommandRecords)
              {
                'turn': rejected.turn,
                'tick': rejected.tick,
                'playerId': rejected.playerId,
                'reason': rejected.reason,
                'command': GameCommandSerializer.toJson(rejected.command),
              },
          ],
          'aiTurnRuntime': [
            for (final runtime in game.result.aiTurnRuntimes)
              {
                'turn': runtime.turn,
                'playerId': runtime.playerId,
                'strategyId': runtime.strategyId.name,
                'mctsProfileMode': runtime.profileMode.name,
                'mctsRuntimeProfile': runtime.runtimeProfile?.name,
                'adaptiveLateGame': runtime.adaptiveLateGame,
                'planningMicros': runtime.planningDuration.inMicroseconds,
                'planningMs': runtime.planningDuration.inMicroseconds / 1000.0,
                'plannedCommands': runtime.plannedCommands,
                'totalUnits': runtime.totalUnitCount,
                'totalCities': runtime.totalCityCount,
                'debugNotes': runtime.debugNotes,
                'debugMetrics': runtime.debugMetrics,
              },
          ],
        },
    ],
    'failures': [
      for (final failure in report.failures)
        {
          'index': failure.index,
          'error': failure.error.toString(),
          'stackTrace': failure.stackTrace.toString(),
        },
    ],
  };
}

Map<String, Object?> _playerJson(BalanceBatchReport report, String playerId) {
  return {
    'playerId': playerId,
    'country': _countryForPlayer(report, playerId)?.name,
    'winRate': report.winRate(playerId),
    'averageFinalCityCount': report.averageFinalCityCount(playerId),
    'averageCityCenterDistance': report.averageCityCenterDistance(playerId),
    'averageMinimumCityCenterDistance': report.averageMinimumCityCenterDistance(
      playerId,
    ),
    'averageFinalUnitCount': report.averageFinalUnitCount(playerId),
    'averageAttackCommands': report.averageAttackCommands(playerId),
    'averageFinalTechnologyCount': report.averageFinalTechnologyCount(playerId),
    'averageFinalSciencePerTurn': report.averageFinalSciencePerTurn(playerId),
    'averageFinalGold': report.averageFinalGold(playerId),
    'averageFinalNetGoldPerTurn': report.averageFinalNetGoldPerTurn(playerId),
    'openingSurvival': {
      'averageFirstCityTurn': report.averageFirstCityTurn(playerId),
      'settlerLostBeforeFirstCityRate': report.settlerLostBeforeFirstCityRate(
        playerId,
      ),
      'firstCityLostRate': report.firstCityLostRate(playerId),
      'lastMilitaryLostRate': report.lastMilitaryLostRate(playerId),
      'finishedWithoutCityRate': report.finishedWithoutCityRate(playerId),
    },
    'expansionRecovery': {
      'averageSecondCityTurn': report.averageSecondCityTurn(playerId),
      'secondCityCompletionRate': report.secondCityCompletionRate(playerId),
      'averageThirdCityTurn': report.averageThirdCityTurn(playerId),
      'thirdCityCompletionRate': report.thirdCityCompletionRate(playerId),
      'averageMaxCityCount': report.averageMaxCityCount(playerId),
      'finishedBelowTwoCitiesRate': report.finishedBelowTwoCitiesRate(playerId),
      'secondCityLostAfterFoundingRate': report.secondCityLostAfterFoundingRate(
        playerId,
      ),
      'averageSecondCityLossTurn': report.averageSecondCityLossTurn(playerId),
      'averageCityCountDropCount': report.averageCityCountDropCount(playerId),
      'averageFirstPostCitySettlerTurn': report.averageFirstPostCitySettlerTurn(
        playerId,
      ),
      'averageOneCityNoSettlerTurns': report.averageOneCityNoSettlerTurns(
        playerId,
      ),
      'averageOneCityWithSettlerTurns': report.averageOneCityWithSettlerTurns(
        playerId,
      ),
      'averageOneCityAttackCommands': report.averageOneCityAttackCommands(
        playerId,
      ),
      'averageFirstPostSecondCitySettlerTurn': report
          .averageFirstPostSecondCitySettlerTurn(playerId),
      'averageTwoCityNoSettlerTurns': report.averageTwoCityNoSettlerTurns(
        playerId,
      ),
      'averageTwoCityWithSettlerTurns': report.averageTwoCityWithSettlerTurns(
        playerId,
      ),
      'averageTwoCityStartUnitCommands': report.averageTwoCityStartUnitCommands(
        playerId,
      ),
      'averageTwoCityStartBuildingCommands': report
          .averageTwoCityStartBuildingCommands(playerId),
      'averageTwoCityStartProjectCommands': report
          .averageTwoCityStartProjectCommands(playerId),
      'averageTwoCityAttackCommands': report.averageTwoCityAttackCommands(
        playerId,
      ),
    },
  };
}

Map<String, Object?> _countryJson(
  BalanceBatchReport report,
  PlayerCountry country,
) {
  return {
    'country': country.name,
    'label': _label(country),
    'winRate': report.winRateForCountry(country),
    'averageFinalCityCount': report.averageFinalCityCountForCountry(country),
    'averageCityCenterDistance': report.averageCityCenterDistanceForCountry(
      country,
    ),
    'averageMinimumCityCenterDistance': report
        .averageMinimumCityCenterDistanceForCountry(country),
    'averageFinalUnitCount': report.averageFinalUnitCountForCountry(country),
    'averageAttackCommands': report.averageAttackCommandsForCountry(country),
    'averageFinalTechnologyCount': report.averageFinalTechnologyCountForCountry(
      country,
    ),
    'averageFinalSciencePerTurn': report.averageFinalSciencePerTurnForCountry(
      country,
    ),
    'averageFinalGold': report.averageFinalGoldForCountry(country),
    'averageFinalNetGoldPerTurn': report.averageFinalNetGoldPerTurnForCountry(
      country,
    ),
    'openingSurvival': {
      'averageFirstCityTurn': report.averageFirstCityTurnForCountry(country),
      'settlerLostBeforeFirstCityRate': report
          .settlerLostBeforeFirstCityRateForCountry(country),
      'firstCityLostRate': report.firstCityLostRateForCountry(country),
      'lastMilitaryLostRate': report.lastMilitaryLostRateForCountry(country),
      'finishedWithoutCityRate': report.finishedWithoutCityRateForCountry(
        country,
      ),
    },
    'expansionRecovery': {
      'averageSecondCityTurn': report.averageSecondCityTurnForCountry(country),
      'secondCityCompletionRate': report.secondCityCompletionRateForCountry(
        country,
      ),
      'averageThirdCityTurn': report.averageThirdCityTurnForCountry(country),
      'thirdCityCompletionRate': report.thirdCityCompletionRateForCountry(
        country,
      ),
      'averageMaxCityCount': report.averageMaxCityCountForCountry(country),
      'finishedBelowTwoCitiesRate': report.finishedBelowTwoCitiesRateForCountry(
        country,
      ),
      'secondCityLostAfterFoundingRate': report
          .secondCityLostAfterFoundingRateForCountry(country),
      'averageSecondCityLossTurn': report.averageSecondCityLossTurnForCountry(
        country,
      ),
      'averageCityCountDropCount': report.averageCityCountDropCountForCountry(
        country,
      ),
      'averageFirstPostCitySettlerTurn': report
          .averageFirstPostCitySettlerTurnForCountry(country),
      'averageOneCityNoSettlerTurns': report
          .averageOneCityNoSettlerTurnsForCountry(country),
      'averageOneCityWithSettlerTurns': report
          .averageOneCityWithSettlerTurnsForCountry(country),
      'averageOneCityAttackCommands': report
          .averageOneCityAttackCommandsForCountry(country),
      'averageFirstPostSecondCitySettlerTurn': report
          .averageFirstPostSecondCitySettlerTurnForCountry(country),
      'averageTwoCityNoSettlerTurns': report
          .averageTwoCityNoSettlerTurnsForCountry(country),
      'averageTwoCityWithSettlerTurns': report
          .averageTwoCityWithSettlerTurnsForCountry(country),
      'averageTwoCityStartUnitCommands': report
          .averageTwoCityStartUnitCommandsForCountry(country),
      'averageTwoCityStartBuildingCommands': report
          .averageTwoCityStartBuildingCommandsForCountry(country),
      'averageTwoCityStartProjectCommands': report
          .averageTwoCityStartProjectCommandsForCountry(country),
      'averageTwoCityAttackCommands': report
          .averageTwoCityAttackCommandsForCountry(country),
    },
  };
}

String _markdownReport({
  required _BalancePassOptions options,
  required BalanceBatchReport report,
}) {
  final buffer = StringBuffer()
    ..writeln('# AI Balance Pass')
    ..writeln()
    ..writeln('Generated by `dart run tool/balance_pass.dart`.')
    ..writeln()
    ..writeln('- Games: ${options.games}')
    ..writeln('- Duration: ${_durationLabel(options)}')
    ..writeln('- Turns: ${options.turns}')
    ..writeln('- Difficulty: `${options.difficulty.name}`')
    ..writeln('- MCTS profile: `${options.mctsProfileMode.name}`')
    ..writeln('- Seed: `${options.seed}`')
    ..writeln('- Primary civ: `${options.primaryCiv.name}`')
    ..writeln('- AI civs: `${options.civs.map((civ) => civ.name).join(', ')}`')
    ..writeln()
    ..writeln('## Summary')
    ..writeln()
    ..writeln('- Attempted games: ${report.attemptedGameCount}')
    ..writeln('- Completed games: ${report.gameCount}')
    ..writeln('- Crashes: ${report.crashCount}')
    ..writeln('- Rejected commands: ${report.totalRejectedCommands}')
    ..writeln()
    ..writeln('## MCTS Runtime')
    ..writeln()
    ..writeln(_runtimeTable(report))
    ..writeln()
    ..writeln('## Players')
    ..writeln()
    ..writeln(_playerTable(report))
    ..writeln()
    ..writeln('## Opening Survival')
    ..writeln()
    ..writeln(_openingPlayerTable(report))
    ..writeln()
    ..writeln('## Second-City Recovery')
    ..writeln()
    ..writeln(_expansionPlayerTable(report))
    ..writeln()
    ..writeln('## Civilizations')
    ..writeln()
    ..writeln(_countryTable(report))
    ..writeln()
    ..writeln('## Opening Survival By Civilization')
    ..writeln()
    ..writeln(_openingCountryTable(report))
    ..writeln()
    ..writeln('## Second-City Recovery By Civilization')
    ..writeln()
    ..writeln(_expansionCountryTable(report));

  if (report.failures.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Failures')
      ..writeln()
      ..writeln('| Game | Error |')
      ..writeln('| ---: | --- |');
    for (final failure in report.failures) {
      buffer.writeln('| ${failure.index} | ${_escapeCell(failure.error)} |');
    }
  }

  return buffer.toString();
}

String _openingPlayerTable(BalanceBatchReport report) {
  final buffer = StringBuffer()
    ..writeln(
      '| Player | Civilization | Avg first city | Settler lost | First city lost | Last military lost | Finished no city |',
    )
    ..writeln('| --- | --- | ---: | ---: | ---: | ---: | ---: |');
  for (final playerId in _orderedPlayerIds(report)) {
    final country = _countryForPlayer(report, playerId);
    buffer.writeln(
      '| $playerId | ${country == null ? '-' : _label(country)} | '
      '${_distance(report.averageFirstCityTurn(playerId))} | '
      '${_percent(report.settlerLostBeforeFirstCityRate(playerId))} | '
      '${_percent(report.firstCityLostRate(playerId))} | '
      '${_percent(report.lastMilitaryLostRate(playerId))} | '
      '${_percent(report.finishedWithoutCityRate(playerId))} |',
    );
  }
  return buffer.toString();
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

String _playerTable(BalanceBatchReport report) {
  final buffer = StringBuffer()
    ..writeln(
      '| Player | Civilization | Win rate | Cities | City dist | Min dist | Units | Attacks | Techs | Science | Gold | Net gold |',
    )
    ..writeln(
      '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |',
    );
  for (final playerId in _orderedPlayerIds(report)) {
    final country = _countryForPlayer(report, playerId);
    buffer.writeln(
      '| $playerId | ${country == null ? '-' : _label(country)} | '
      '${_percent(report.winRate(playerId))} | '
      '${_decimal(report.averageFinalCityCount(playerId))} | '
      '${_distance(report.averageCityCenterDistance(playerId))} | '
      '${_distance(report.averageMinimumCityCenterDistance(playerId))} | '
      '${_decimal(report.averageFinalUnitCount(playerId))} | '
      '${_decimal(report.averageAttackCommands(playerId))} | '
      '${_decimal(report.averageFinalTechnologyCount(playerId))} | '
      '${_decimal(report.averageFinalSciencePerTurn(playerId))} | '
      '${_decimal(report.averageFinalGold(playerId))} | '
      '${_signedDecimal(report.averageFinalNetGoldPerTurn(playerId))} |',
    );
  }
  return buffer.toString();
}

String _expansionPlayerTable(BalanceBatchReport report) {
  final buffer = StringBuffer()
    ..writeln(
      '| Player | Civilization | Avg second city | Second-city rate | Avg third city | Third-city rate | Max cities | Finished <2 cities | Lost 2nd city | City drops | Avg 2nd settler | 1-city no-settler | 1-city settler | Avg 3rd settler | 2-city no-settler | 2-city settler | 2-city units | 2-city buildings | 2-city projects | 2-city attacks |',
    )
    ..writeln(
      '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |',
    );
  for (final playerId in _orderedPlayerIds(report)) {
    final country = _countryForPlayer(report, playerId);
    buffer.writeln(
      '| $playerId | ${country == null ? '-' : _label(country)} | '
      '${_distance(report.averageSecondCityTurn(playerId))} | '
      '${_percent(report.secondCityCompletionRate(playerId))} | '
      '${_distance(report.averageThirdCityTurn(playerId))} | '
      '${_percent(report.thirdCityCompletionRate(playerId))} | '
      '${_decimal(report.averageMaxCityCount(playerId))} | '
      '${_percent(report.finishedBelowTwoCitiesRate(playerId))} | '
      '${_percent(report.secondCityLostAfterFoundingRate(playerId))} | '
      '${_decimal(report.averageCityCountDropCount(playerId))} | '
      '${_distance(report.averageFirstPostCitySettlerTurn(playerId))} | '
      '${_decimal(report.averageOneCityNoSettlerTurns(playerId))} | '
      '${_decimal(report.averageOneCityWithSettlerTurns(playerId))} | '
      '${_distance(report.averageFirstPostSecondCitySettlerTurn(playerId))} | '
      '${_decimal(report.averageTwoCityNoSettlerTurns(playerId))} | '
      '${_decimal(report.averageTwoCityWithSettlerTurns(playerId))} | '
      '${_decimal(report.averageTwoCityStartUnitCommands(playerId))} | '
      '${_decimal(report.averageTwoCityStartBuildingCommands(playerId))} | '
      '${_decimal(report.averageTwoCityStartProjectCommands(playerId))} | '
      '${_decimal(report.averageTwoCityAttackCommands(playerId))} |',
    );
  }
  return buffer.toString();
}

String _openingCountryTable(BalanceBatchReport report) {
  final buffer = StringBuffer()
    ..writeln(
      '| Civilization | Avg first city | Settler lost | First city lost | Last military lost | Finished no city |',
    )
    ..writeln('| --- | ---: | ---: | ---: | ---: | ---: |');
  for (final country in _orderedCountries(report)) {
    buffer.writeln(
      '| ${_label(country)} | '
      '${_distance(report.averageFirstCityTurnForCountry(country))} | '
      '${_percent(report.settlerLostBeforeFirstCityRateForCountry(country))} | '
      '${_percent(report.firstCityLostRateForCountry(country))} | '
      '${_percent(report.lastMilitaryLostRateForCountry(country))} | '
      '${_percent(report.finishedWithoutCityRateForCountry(country))} |',
    );
  }
  return buffer.toString();
}

String _expansionCountryTable(BalanceBatchReport report) {
  final buffer = StringBuffer()
    ..writeln(
      '| Civilization | Avg second city | Second-city rate | Avg third city | Third-city rate | Max cities | Finished <2 cities | Lost 2nd city | City drops | Avg 2nd settler | 1-city no-settler | 1-city settler | Avg 3rd settler | 2-city no-settler | 2-city settler | 2-city units | 2-city buildings | 2-city projects | 2-city attacks |',
    )
    ..writeln(
      '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |',
    );
  for (final country in _orderedCountries(report)) {
    buffer.writeln(
      '| ${_label(country)} | '
      '${_distance(report.averageSecondCityTurnForCountry(country))} | '
      '${_percent(report.secondCityCompletionRateForCountry(country))} | '
      '${_distance(report.averageThirdCityTurnForCountry(country))} | '
      '${_percent(report.thirdCityCompletionRateForCountry(country))} | '
      '${_decimal(report.averageMaxCityCountForCountry(country))} | '
      '${_percent(report.finishedBelowTwoCitiesRateForCountry(country))} | '
      '${_percent(report.secondCityLostAfterFoundingRateForCountry(country))} | '
      '${_decimal(report.averageCityCountDropCountForCountry(country))} | '
      '${_distance(report.averageFirstPostCitySettlerTurnForCountry(country))} | '
      '${_decimal(report.averageOneCityNoSettlerTurnsForCountry(country))} | '
      '${_decimal(report.averageOneCityWithSettlerTurnsForCountry(country))} | '
      '${_distance(report.averageFirstPostSecondCitySettlerTurnForCountry(country))} | '
      '${_decimal(report.averageTwoCityNoSettlerTurnsForCountry(country))} | '
      '${_decimal(report.averageTwoCityWithSettlerTurnsForCountry(country))} | '
      '${_decimal(report.averageTwoCityStartUnitCommandsForCountry(country))} | '
      '${_decimal(report.averageTwoCityStartBuildingCommandsForCountry(country))} | '
      '${_decimal(report.averageTwoCityStartProjectCommandsForCountry(country))} | '
      '${_decimal(report.averageTwoCityAttackCommandsForCountry(country))} |',
    );
  }
  return buffer.toString();
}

String _countryTable(BalanceBatchReport report) {
  final buffer = StringBuffer()
    ..writeln(
      '| Civilization | Win rate | Cities | City dist | Min dist | Units | Attacks | Techs | Science | Gold | Net gold |',
    )
    ..writeln(
      '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |',
    );
  for (final country in _orderedCountries(report)) {
    buffer.writeln(
      '| ${_label(country)} | '
      '${_percent(report.winRateForCountry(country))} | '
      '${_decimal(report.averageFinalCityCountForCountry(country))} | '
      '${_distance(report.averageCityCenterDistanceForCountry(country))} | '
      '${_distance(report.averageMinimumCityCenterDistanceForCountry(country))} | '
      '${_decimal(report.averageFinalUnitCountForCountry(country))} | '
      '${_decimal(report.averageAttackCommandsForCountry(country))} | '
      '${_decimal(report.averageFinalTechnologyCountForCountry(country))} | '
      '${_decimal(report.averageFinalSciencePerTurnForCountry(country))} | '
      '${_decimal(report.averageFinalGoldForCountry(country))} | '
      '${_signedDecimal(report.averageFinalNetGoldPerTurnForCountry(country))} |',
    );
  }
  return buffer.toString();
}

List<String> _orderedPlayerIds(BalanceBatchReport report) {
  return report.playerIds.toList()..sort();
}

List<PlayerCountry> _orderedCountries(BalanceBatchReport report) {
  return report.countries.toList()
    ..sort((left, right) => left.name.compareTo(right.name));
}

PlayerCountry? _countryForPlayer(BalanceBatchReport report, String playerId) {
  for (final game in report.games) {
    final country = game.countryForPlayer(playerId);
    if (country != null) return country;
  }
  return null;
}

String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _decimal(double value) => value.toStringAsFixed(1);

String _durationMs(double value) => '${value.toStringAsFixed(1)}ms';

String _signedDecimal(double value) {
  final formatted = value.toStringAsFixed(1);
  return value > 0 ? '+$formatted' : formatted;
}

String _distance(double value) => value == 0 ? '-' : value.toStringAsFixed(1);

String _escapeCell(Object? value) {
  return value.toString().replaceAll('|', r'\|').replaceAll('\n', '<br>');
}

String _durationLabel(_BalancePassOptions options) {
  if (options.rawTurnOverride) return 'raw ${options.turns} turns';
  final minutes = options.gameLength.targetMinutes;
  if (minutes == null) return 'unlimited pace';
  return '$minutes min (~${options.turns} turns at '
      '${GameLengthConfig.estimatedMultiplayerTurnSeconds}s/turn)';
}

String _label(Enum value) {
  final spaced = value.name.replaceAllMapped(
    RegExp(r'(?<=[a-z])([A-Z])'),
    (match) => ' ${match.group(1)}',
  );
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

bool _hasFlag(List<String> args, String flag) {
  return args.contains(flag);
}

String? _optionValue(List<String> args, String option) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == option && i + 1 < args.length) return args[i + 1];
    if (arg.startsWith('$option=')) return arg.substring(option.length + 1);
  }
  return null;
}

int _positiveIntOption(List<String> args, String option, int fallback) {
  final value = _optionValue(args, option);
  if (value == null) return fallback;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) {
    throw _UsageException('$option must be a positive integer.');
  }
  return parsed;
}

int? _optionalPositiveIntOption(List<String> args, String option) {
  final value = _optionValue(args, option);
  if (value == null) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) {
    throw _UsageException('$option must be a positive integer.');
  }
  return parsed;
}

GameLengthConfig _targetGameLengthOption(int minutes) {
  try {
    return GameLengthConfig.targetDuration(minutes);
  } on ArgumentError {
    throw const _UsageException('--minutes must be 60, 90, or 120.');
  }
}

AiDifficulty _difficultyOption(List<String> args) {
  final value =
      _optionValue(args, '--difficulty') ?? _optionValue(args, '--diff');
  if (value == null) return AiDifficulty.normal;
  for (final difficulty in AiDifficulty.values) {
    if (difficulty.name == value) return difficulty;
  }
  throw _UsageException(
    '--difficulty must be one of: '
    '${AiDifficulty.values.map((difficulty) => difficulty.name).join(', ')}.',
  );
}

EconomySimulationMctsProfileMode _mctsProfileModeOption(List<String> args) {
  final value =
      _optionValue(args, '--mcts-profile') ??
      _optionValue(args, '--mcts-runtime');
  if (value == null) return EconomySimulationMctsProfileMode.simulation;
  final normalized = _normalizeEnumToken(value);
  for (final mode in EconomySimulationMctsProfileMode.values) {
    if (_normalizeEnumToken(mode.name) == normalized) return mode;
  }
  if (normalized == 'batterysaver') {
    return EconomySimulationMctsProfileMode.batterySaver;
  }
  if (normalized == 'adaptivelocal') {
    return EconomySimulationMctsProfileMode.adaptiveLocalSinglePlayer;
  }
  throw const _UsageException(
    '--mcts-profile must be one of: simulation, standard, interactive, '
    'battery-saver, adaptive-local-single-player.',
  );
}

PlayerCountry _countryOption(
  List<String> args,
  String option,
  PlayerCountry fallback,
) {
  final value = _optionValue(args, option);
  if (value == null) return fallback;
  return _countryFromString(value, option);
}

List<PlayerCountry> _civsOption(List<String> args) {
  final value = _optionValue(args, '--civs');
  if (value == null) {
    return const [
      PlayerCountry.germany,
      PlayerCountry.netherlands,
      PlayerCountry.japan,
    ];
  }
  final civs = [
    for (final entry in value.split(','))
      if (entry.trim().isNotEmpty) _countryFromString(entry, '--civs'),
  ];
  if (civs.length != 3) {
    throw const _UsageException(
      '--civs must list exactly three AI civilizations.',
    );
  }
  if (civs.toSet().length != civs.length) {
    throw const _UsageException('--civs cannot contain duplicates.');
  }
  return List.unmodifiable(civs);
}

PlayerCountry _countryFromString(String value, String option) {
  final normalized = _normalizeEnumToken(value);
  for (final country in PlayerCountry.values) {
    if (_normalizeEnumToken(country.name) == normalized) return country;
  }
  throw _UsageException(
    '$option contains unknown civilization "$value". Valid values: '
    '${PlayerCountry.values.map((country) => country.name).join(', ')}.',
  );
}

String _normalizeEnumToken(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _BalancePassOptions {
  const _BalancePassOptions({
    required this.games,
    required this.gameLength,
    required this.rawTurnOverride,
    required this.turns,
    required this.difficulty,
    required this.mctsProfileMode,
    required this.seed,
    required this.primaryCiv,
    required this.civs,
    required this.out,
  });

  factory _BalancePassOptions.fromArgs(List<String> args) {
    final hasTurnOverride = _optionValue(args, '--turns') != null;
    final minutes = _optionalPositiveIntOption(args, '--minutes');
    if (hasTurnOverride && minutes != null) {
      throw const _UsageException('Use either --minutes or --turns, not both.');
    }
    final gameLength = minutes == null
        ? GameLengthConfig.standard60
        : _targetGameLengthOption(minutes);
    final primaryCiv = _countryOption(
      args,
      '--primary-civ',
      PlayerCountry.poland,
    );
    final civs = _civsOption(args);
    if (civs.contains(primaryCiv)) {
      throw const _UsageException(
        '--primary-civ cannot also appear in --civs.',
      );
    }
    return _BalancePassOptions(
      games: _positiveIntOption(args, '--games', 10),
      gameLength: hasTurnOverride ? GameLengthConfig.unlimited : gameLength,
      rawTurnOverride: hasTurnOverride,
      turns: hasTurnOverride
          ? _positiveIntOption(args, '--turns', gameLength.turnLimit!)
          : gameLength.turnLimit!,
      difficulty: _difficultyOption(args),
      mctsProfileMode: _mctsProfileModeOption(args),
      seed: _positiveIntOption(args, '--seed', 4200),
      primaryCiv: primaryCiv,
      civs: civs,
      out: _optionValue(args, '--out') ?? '../../build/reports/ai-balance',
    );
  }

  final int games;
  final GameLengthConfig gameLength;
  final bool rawTurnOverride;
  final int turns;
  final AiDifficulty difficulty;
  final EconomySimulationMctsProfileMode mctsProfileMode;
  final int seed;
  final PlayerCountry primaryCiv;
  final List<PlayerCountry> civs;
  final String out;
}

class _OutputTargets {
  const _OutputTargets({required this.jsonFile, required this.markdownFile});

  factory _OutputTargets.fromPath(String path) {
    if (path.endsWith('.json')) {
      final jsonFile = File(path);
      return _OutputTargets(
        jsonFile: jsonFile,
        markdownFile: File('${path.substring(0, path.length - 5)}.md'),
      );
    }

    final directory = Directory(path);
    return _OutputTargets(
      jsonFile: File('${directory.path}/balance-pass-summary.json'),
      markdownFile: File('${directory.path}/balance-pass-report.md'),
    );
  }

  final File jsonFile;
  final File markdownFile;

  void write({required String json, required String markdown}) {
    jsonFile.parent.createSync(recursive: true);
    markdownFile.parent.createSync(recursive: true);
    jsonFile.writeAsStringSync('$json\n');
    markdownFile.writeAsStringSync(markdown);
  }

  List<File> writeGameCsvs(BalanceBatchReport report) {
    jsonFile.parent.createSync(recursive: true);
    final files = <File>[];
    for (final game in report.games) {
      final file = File(
        '${jsonFile.parent.path}/balance-pass-game-${game.index}.csv',
      )..writeAsStringSync('${_gameCsv(game)}\n');
      files.add(file);
      final runtimeFile = File(
        '${jsonFile.parent.path}/balance-pass-game-${game.index}-runtime.csv',
      )..writeAsStringSync('${_gameRuntimeCsv(game)}\n');
      files.add(runtimeFile);
    }
    return files;
  }

  String _gameCsv(BalanceGameReport game) {
    final lines = <String>[
      ['player_id', ...EconomySimulationTurnRow.csvHeader].map(_csv).join(','),
    ];
    final entries = game.result.rowsByPlayerId.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in entries) {
      for (final row in entry.value) {
        lines.add([entry.key, ...row.toCsvFields()].map(_csv).join(','));
      }
    }
    return lines.join('\n');
  }

  String _gameRuntimeCsv(BalanceGameReport game) {
    final lines = <String>[
      [
        'turn',
        'player_id',
        'strategy_id',
        'mcts_profile_mode',
        'mcts_runtime_profile',
        'adaptive_late_game',
        'planning_us',
        'planning_ms',
        'planned_commands',
        'total_units',
        'total_cities',
        'mcts_iterations',
        'mcts_elapsed_ms',
        'mcts_search_ms',
        'mcts_search_select_ms',
        'mcts_search_expand_ms',
        'mcts_search_rollout_ms',
        'mcts_search_eval_ms',
        'mcts_search_backprop_ms',
        'mcts_validation_ms',
        'mcts_baseline_plan_ms',
        'mcts_merge_ms',
        'mcts_strategy_ms',
        'mcts_explored_nodes',
        'mcts_max_depth',
        'mcts_candidate_calls',
        'mcts_candidate_ms',
        'mcts_source_plan_calls',
        'mcts_source_plan_skipped',
        'mcts_source_plan_ms',
        'mcts_source_plan_commands',
        'mcts_raw_candidates',
        'mcts_selected_candidates',
        'debug_notes',
      ].map(_csv).join(','),
    ];
    for (final row in game.result.aiTurnRuntimes) {
      lines.add(
        [
          row.turn,
          row.playerId,
          row.strategyId.name,
          row.profileMode.name,
          row.runtimeProfile?.name ?? '',
          row.adaptiveLateGame,
          row.planningDuration.inMicroseconds,
          (row.planningDuration.inMicroseconds / 1000.0).toStringAsFixed(3),
          row.plannedCommands,
          row.totalUnitCount,
          row.totalCityCount,
          _metricValue(row, 'mcts.iterations'),
          _metricMicrosAsMs(row, 'mcts.elapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchSelectionElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchExpansionElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchRolloutElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchEvaluationElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchBackpropagationElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.validationElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.baselinePlanElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.mergeElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.strategyElapsedMicros'),
          _metricValue(row, 'mcts.exploredNodes'),
          _metricValue(row, 'mcts.maxDepth'),
          _metricValue(row, 'mcts.candidateCalls'),
          _metricMicrosAsMs(row, 'mcts.candidateElapsedMicros'),
          _metricValue(row, 'mcts.sourcePlanCalls'),
          _metricValue(row, 'mcts.sourcePlanSkipped'),
          _metricMicrosAsMs(row, 'mcts.sourcePlanElapsedMicros'),
          _metricValue(row, 'mcts.sourcePlanCommands'),
          _metricValue(row, 'mcts.rawCandidates'),
          _metricValue(row, 'mcts.selectedCandidates'),
          row.debugNotes.join('; '),
        ].map(_csv).join(','),
      );
    }
    return lines.join('\n');
  }

  Object _metricValue(EconomySimulationAiTurnRuntime row, String key) {
    return row.debugMetrics[key] ?? '';
  }

  Object _metricMicrosAsMs(EconomySimulationAiTurnRuntime row, String key) {
    final value = row.debugMetrics[key];
    if (value is! num) return '';
    return (value / 1000.0).toStringAsFixed(3);
  }

  String _csv(Object? value) {
    final text = '$value';
    if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
      return text;
    }
    return '"${text.replaceAll('"', '""')}"';
  }
}

class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}

const _usage = '''
Usage:
  dart run tool/balance_pass.dart [options]

Options:
  --games=N          Number of games to run. Default: 10
  --minutes=N        Timed preset: 60, 90, or 120 minutes.
                     Default: 60, estimated as 120 turns at 30s/turn
  --turns=N          Raw turn override for short smoke runs.
                     Cannot be combined with --minutes
  --difficulty=NAME  easy, normal, hard, or veryHard. Default: normal
  --mcts-profile=NAME
                     simulation, standard, interactive, battery-saver, or
                     adaptive-local-single-player. Default: simulation
  --seed=N           Base deterministic seed. Default: 4200
  --primary-civ=NAME Simulated-human civilization. Default: poland
  --civs=A,B,C       Three AI civilizations.
                     Default: germany,netherlands,japan
  --out=PATH         Output directory or .json file path.
                     Default: ../../build/reports/ai-balance
''';
