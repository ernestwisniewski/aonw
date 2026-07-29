part of 'save_ai_benchmark_report_parity_test.dart';

const _measuredDurationKeys = <String>{
  'totalPlanningMs',
  'totalExecutionMs',
  'totalComputeMs',
  'averagePlanningMs',
  'p90PlanningMs',
  'p95PlanningMs',
  'maxPlanningMs',
  'averageExecutionMs',
  'p90ExecutionMs',
  'p95ExecutionMs',
  'maxExecutionMs',
  'averageComputeMs',
  'p90ComputeMs',
  'p95ComputeMs',
  'maxComputeMs',
  'planningMs',
  'executionMs',
  'computeMs',
  'totalEstimatedInterCommandDelayMs',
  'totalEstimatedVisibleMs',
  'averageEstimatedVisibleTurnMs',
  'p90EstimatedVisibleTurnMs',
  'p95EstimatedVisibleTurnMs',
  'maxEstimatedVisibleTurnMs',
  'averageEstimatedVisibleCycleMs',
  'p90EstimatedVisibleCycleMs',
  'p95EstimatedVisibleCycleMs',
  'maxEstimatedVisibleCycleMs',
  'estimatedInterCommandDelayMs',
  'estimatedVisibleMs',
};

String _normalizedReplayJson(Map<String, dynamic> replay) {
  return const JsonEncoder.withIndent(
    '  ',
  ).convert(_normalizeMeasuredDurations(replay));
}

Object? _normalizeMeasuredDurations(Object? value) {
  if (value is List<dynamic>) {
    return [for (final item in value) _normalizeMeasuredDurations(item)];
  }
  if (value is! Map<String, dynamic>) return value;
  return {
    for (final entry in value.entries)
      entry.key: _measuredDurationKeys.contains(entry.key)
          ? '<duration>'
          : _normalizeMeasuredDurations(entry.value),
  };
}

String _multiTurnMarkdown(String markdown) {
  return markdown.substring(markdown.indexOf('## Multi-turn replay'));
}

String _normalizedReplayMarkdown(String markdown) {
  return markdown
      .replaceAllMapped(
        RegExp(r'(Planning avg |, p90 |, p95 |, max )\d+ms'),
        (match) => '${match.group(1)}<duration>',
      )
      .replaceAllMapped(
        RegExp(r'(Execution avg |compute avg )\d+ms'),
        (match) => '${match.group(1)}<duration>',
      )
      .replaceAllMapped(
        RegExp(
          r'(Estimated visible wait: )\d+ms/player-turn avg, \d+ms p95, \d+ms max; \d+ms/cycle avg',
        ),
        (match) =>
            '${match.group(1)}<duration>/player-turn avg, <duration> p95, <duration> max; <duration>/cycle avg',
      )
      .replaceAllMapped(
        RegExp(r'(, human cities 0 -> 0, )\d+ms estimated visible'),
        (match) => '${match.group(1)}<duration> estimated visible',
      )
      .replaceAllMapped(
        RegExp(r'(- [^:]+: )\d+ms plan, \d+ms replay, \d+ms estimated visible'),
        (match) =>
            '${match.group(1)}<duration> plan, <duration> replay, <duration> estimated visible',
      );
}

String _replayJsonGolden({
  required _ReplayFixture fixture,
  required String savePath,
}) {
  final isNormal = fixture.name == 'normal';
  final playerIds = isNormal ? const ['ai', 'ai_beta'] : const ['ai'];
  final cycleEvents = isNormal
      ? const [
          [_replayEventsWithoutFinalization, _replayEventsAfterFinalization],
          [_replayEventsWithoutFinalization, _replayEventsAfterFinalization],
        ]
      : const [
          [_sparseReplayEventsAfterFinalization],
          [_sparseReplayEventsAfterFinalization],
        ];
  final cycles = [
    for (var index = 0; index < 2; index++)
      _replayCycleGolden(
        index: index + 1,
        startTurn: fixture.startTurn + index,
        playerIds: playerIds,
        events: cycleEvents[index],
      ),
  ];
  return const JsonEncoder.withIndent('  ').convert({
    'savePath': savePath,
    'startTurn': fixture.startTurn,
    'endTurn': fixture.startTurn + 2,
    'startHumanCities': 0,
    'endHumanCities': 0,
    'endHumanCityStates': const <Object?>[],
    'summary': _replaySummaryGolden(playerTurns: isNormal ? 4 : 2),
    'cycles': cycles,
    'findings': const <Object?>[],
  });
}

Map<String, Object?> _replaySummaryGolden({required int playerTurns}) => {
  'cycles': 2,
  'playerTurns': playerTurns,
  'totalPlanningMs': '<duration>',
  'totalExecutionMs': '<duration>',
  'totalComputeMs': '<duration>',
  'totalEstimatedInterCommandDelayMs': '<duration>',
  'totalEstimatedVisibleMs': '<duration>',
  'totalEstimatedVisibleDelayCommands': 0,
  'p95EstimatedVisibleDelayCommands': 0,
  'maxEstimatedVisibleDelayCommands': 0,
  'averagePlanningMs': '<duration>',
  'p90PlanningMs': '<duration>',
  'p95PlanningMs': '<duration>',
  'maxPlanningMs': '<duration>',
  'averageExecutionMs': '<duration>',
  'p90ExecutionMs': '<duration>',
  'p95ExecutionMs': '<duration>',
  'maxExecutionMs': '<duration>',
  'averageComputeMs': '<duration>',
  'p90ComputeMs': '<duration>',
  'p95ComputeMs': '<duration>',
  'maxComputeMs': '<duration>',
  'averageEstimatedVisibleTurnMs': '<duration>',
  'p90EstimatedVisibleTurnMs': '<duration>',
  'p95EstimatedVisibleTurnMs': '<duration>',
  'maxEstimatedVisibleTurnMs': '<duration>',
  'averageEstimatedVisibleCycleMs': '<duration>',
  'p90EstimatedVisibleCycleMs': '<duration>',
  'p95EstimatedVisibleCycleMs': '<duration>',
  'maxEstimatedVisibleCycleMs': '<duration>',
  'totalCommands': 0,
  'totalHumanAttacks': 0,
  'totalPressureTargetAttacks': 0,
  'totalNonHumanAttacks': 0,
  'totalDistractingNonHumanAttacks': 0,
  'attackTargetOwners': const {},
  'nonHumanAttackReasons': const {},
  'distractingNonHumanAttacksByPlayer': const {},
  'totalImmediateHumanAttacks': 0,
  'totalRejected': 0,
  'totalStale': 0,
  'staleMoveReasons': const {},
  'totalCityCaptures': 0,
  'totalMissingWarGoalTurns': 0,
  'missingWarGoalTurnsByPlayer': const {},
  'totalPassiveWarPressureTurns': 0,
  'passiveWarPressureTurnsByPlayer': const {},
  'longestPassiveWarPressureStreakByPlayer': const {},
  'totalPressureTargetIdleTurns': 0,
  'pressureTargetIdleTurnsByPlayer': const {},
  'longestPressureTargetIdleStreakByPlayer': const {},
  'totalPressureTargetSiegeTurns': 0,
  'pressureTargetSiegeTurnsByPlayer': const {},
};

Map<String, Object?> _replayCycleGolden({
  required int index,
  required int startTurn,
  required List<String> playerIds,
  required List<Map<String, int>> events,
}) => {
  'index': index,
  'startTurn': startTurn,
  'endTurn': startTurn + 1,
  'humanCitiesStart': 0,
  'humanCitiesEnd': 0,
  'timing': const {
    'planningMs': '<duration>',
    'executionMs': '<duration>',
    'computeMs': '<duration>',
    'estimatedInterCommandDelayMs': '<duration>',
    'estimatedVisibleMs': '<duration>',
  },
  'playerTurns': [
    for (var index = 0; index < playerIds.length; index++)
      _replayPlayerTurnGolden(
        playerId: playerIds[index],
        events: events[index],
      ),
  ],
};

Map<String, Object?> _replayPlayerTurnGolden({
  required String playerId,
  required Map<String, int> events,
}) => {
  'playerId': playerId,
  'playerName': playerId == 'ai' ? 'AI' : 'AI Beta',
  'strategicMode': 'consolidate',
  'warGoals': const [],
  'strategicAssignments': const {
    'defenseAssignedUnits': 0,
    'defenseAssignments': 0,
    'frontierClearingAssignedUnits': 0,
  },
  'empire': const {
    'cities': 0,
    'units': 0,
    'military': 0,
    'targetableHumanCities': 0,
    'targetableHumanUnits': 0,
    'nearestHumanDistance': null,
    'nearestPressureTargetMilitaryDistance': null,
    'pressureContactMilitary': 0,
    'pressureStagingMilitary': 0,
    'pressureEngagementMilitary': 0,
    'atWarWithHuman': false,
    'hasHumanPressureTarget': true,
    'missingWarGoalWhileAtWar': false,
    'passiveWarPressureTurn': false,
    'pressureTargetIdleTurn': false,
    'pressureTargetSiegeTurn': false,
    'pressureTargetPlayerIds': ['human'],
    'recentHostilePlayerIds': <String>[],
    'diplomacyVsHumans': <String, String>{'human': 'neutral'},
  },
  'planningMs': '<duration>',
  'executionMs': '<duration>',
  'computeMs': '<duration>',
  'estimatedInterCommandDelayMs': '<duration>',
  'estimatedVisibleMs': '<duration>',
  'commands': const {
    'total': 0,
    'attacks': 0,
    'attackHumans': 0,
    'attackPressureTargets': 0,
    'attackNonHumans': 0,
    'attackUnknownTargets': 0,
    'attackTargetOwners': <String, int>{},
    'nonHumanAttackReasons': <String, int>{},
    'distractingNonHumanAttacks': 0,
    'moves': 0,
    'movesTowardHumans': 0,
    'movesAwayFromHumans': 0,
    'movesTowardWarGoals': 0,
    'movesAwayFromWarGoals': 0,
    'movesTowardPressureTargets': 0,
    'movesAwayFromPressureTargets': 0,
    'production': 0,
    'workerActions': 0,
    'estimatedVisibleDelayCommands': 0,
  },
  'immediateHumanAttacks': 0,
  'immediateHumanAttackTargets': const [],
  'applied': 0,
  'rejected': 0,
  'stale': 0,
  'skippedTerminal': 0,
  'terminalChangedState': true,
  'events': events,
  'staleMoveDiagnostics': const [],
  'rejectedCommands': const [],
  'plannedCommands': const [],
  'debugMetrics': const {},
};

String _replayMarkdownGolden(_ReplayFixture fixture) {
  final isNormal = fixture.name == 'normal';
  final playerLines = isNormal
      ? '''- ai: <duration> plan, <duration> replay, <duration> estimated visible, 0 commands, 0 human attacks, 0 pressure attacks, mode consolidate, goals 0, military 0, targets 0/0, 0 applied, 0 rejected, 0 stale
- ai_beta: <duration> plan, <duration> replay, <duration> estimated visible, 0 commands, 0 human attacks, 0 pressure attacks, mode consolidate, goals 0, military 0, targets 0/0, 0 applied, 0 rejected, 0 stale'''
      : '- ai: <duration> plan, <duration> replay, <duration> estimated visible, 0 commands, 0 human attacks, 0 pressure attacks, mode consolidate, goals 0, military 0, targets 0/0, 0 applied, 0 rejected, 0 stale';
  final firstTurn = fixture.startTurn;
  final secondTurn = firstTurn + 1;
  return '''## Multi-turn replay

- Cycles: 2; turns $firstTurn -> ${firstTurn + 2}
- Planning avg <duration>, p90 <duration>, p95 <duration>, max <duration>
- Execution avg <duration>, p95 <duration>, max <duration>; compute avg <duration>, p95 <duration>
- Estimated visible wait: <duration>/player-turn avg, <duration> p95, <duration> max; <duration>/cycle avg at 40ms/visible command
- Visible command pacing: 0 delayed command(s), p95 0/turn, max 0/turn
- Commands: 0 planned, 0 human attacks, 0 pressure-target attacks, 0 rejected, 0 stale
- Attack target owners: none
- Non-human attack reasons: none
- Human cities: 0 -> 0; AI captures: 0
- Soft passivity: 0 missing war-goal turns, 0 passive pressure turns, longest streaks none
- Human pressure idle: 0 turns, 0 siege/contact turns, longest no-contact streaks none

Cycle 1: turn $firstTurn -> $secondTurn, human cities 0 -> 0, <duration> estimated visible
$playerLines

Cycle 2: turn $secondTurn -> ${secondTurn + 1}, human cities 0 -> 0, <duration> estimated visible
$playerLines

''';
}
