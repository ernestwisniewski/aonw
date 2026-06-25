part of '../run_save_ai_benchmark.dart';

class _MultiTurnReplayReport {
  const _MultiTurnReplayReport({
    required this.savePath,
    required this.startTurn,
    required this.endTurn,
    required this.startHumanCities,
    required this.endHumanCities,
    required this.endHumanCityStates,
    required this.cycles,
  });

  final String savePath;
  final int startTurn;
  final int endTurn;
  final int startHumanCities;
  final int endHumanCities;
  final List<_HumanCityEndState> endHumanCityStates;
  final List<_MultiTurnCycleReport> cycles;

  Iterable<_MultiTurnPlayerReport> get playerTurns sync* {
    for (final cycle in cycles) {
      yield* cycle.playerTurns;
    }
  }

  int get totalCommands {
    return playerTurns.fold(0, (sum, turn) => sum + turn.commandStats.total);
  }

  int get totalHumanAttacks {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.commandStats.attackHumans,
    );
  }

  int get totalPressureTargetAttacks {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.commandStats.attackPressureTargets,
    );
  }

  int get totalNonHumanAttacks {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.commandStats.attackNonHumans,
    );
  }

  int get totalDistractingNonHumanAttacks {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.commandStats.distractingNonHumanAttacks,
    );
  }

  int get totalImmediateHumanAttacks {
    return playerTurns.fold(0, (sum, turn) => sum + turn.immediateHumanAttacks);
  }

  int get totalRejected {
    return playerTurns.fold(0, (sum, turn) => sum + turn.rejected);
  }

  int get totalStale {
    return playerTurns.fold(0, (sum, turn) => sum + turn.stale);
  }

  Map<String, int> get staleMoveReasons {
    final reasons = <String, int>{};
    for (final turn in playerTurns) {
      for (final diagnostic in turn.staleMoveDiagnostics) {
        reasons.update(
          diagnostic.reason,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return reasons;
  }

  int get totalCityCaptures {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.eventCounts.cityCaptures,
    );
  }

  Map<String, int> get attackTargetOwners {
    final owners = <String, int>{};
    for (final turn in playerTurns) {
      for (final entry in turn.commandStats.attackTargetOwners.entries) {
        owners.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    return _sortedIntMap(owners);
  }

  Map<String, int> get nonHumanAttackReasons {
    final reasons = <String, int>{};
    for (final turn in playerTurns) {
      for (final entry in turn.commandStats.nonHumanAttackReasons.entries) {
        reasons.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    return _sortedIntMap(reasons);
  }

  Map<String, int> get distractingNonHumanAttacksByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      final count = turn.commandStats.distractingNonHumanAttacks;
      if (count <= 0) continue;
      counts.update(
        turn.playerId,
        (value) => value + count,
        ifAbsent: () => count,
      );
    }
    return _sortedIntMap(counts);
  }

  int get totalMissingWarGoalTurns {
    var count = 0;
    for (final turn in playerTurns) {
      if (turn.missingWarGoalWhileAtWar) count += 1;
    }
    return count;
  }

  int get totalPassiveWarPressureTurns {
    var count = 0;
    for (final turn in playerTurns) {
      if (turn.passiveWarPressureTurn) count += 1;
    }
    return count;
  }

  int get totalPressureTargetIdleTurns {
    var count = 0;
    for (final turn in playerTurns) {
      if (turn.pressureTargetIdleTurn) count += 1;
    }
    return count;
  }

  int get totalPressureTargetSiegeTurns {
    var count = 0;
    for (final turn in playerTurns) {
      if (turn.pressureTargetSiegeTurn) count += 1;
    }
    return count;
  }

  Map<String, int> get missingWarGoalTurnsByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      if (!turn.missingWarGoalWhileAtWar) continue;
      counts.update(turn.playerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return _sortedIntMap(counts);
  }

  Map<String, int> get passiveWarPressureTurnsByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      if (!turn.passiveWarPressureTurn) continue;
      counts.update(turn.playerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return _sortedIntMap(counts);
  }

  Map<String, int> get pressureTargetIdleTurnsByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      if (!turn.pressureTargetIdleTurn) continue;
      counts.update(turn.playerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return _sortedIntMap(counts);
  }

  Map<String, int> get pressureTargetSiegeTurnsByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      if (!turn.pressureTargetSiegeTurn) continue;
      counts.update(turn.playerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return _sortedIntMap(counts);
  }

  Map<String, int> get longestPassiveWarPressureStreakByPlayer {
    final current = <String, int>{};
    final longest = <String, int>{};
    for (final cycle in cycles) {
      for (final turn in cycle.playerTurns) {
        final next = turn.passiveWarPressureTurn
            ? (current[turn.playerId] ?? 0) + 1
            : 0;
        current[turn.playerId] = next;
        if (next > (longest[turn.playerId] ?? 0)) {
          longest[turn.playerId] = next;
        }
      }
    }
    return _sortedIntMap(longest);
  }

  Map<String, int> get longestPressureTargetIdleStreakByPlayer {
    final current = <String, int>{};
    final longest = <String, int>{};
    for (final cycle in cycles) {
      for (final turn in cycle.playerTurns) {
        final next = turn.pressureTargetIdleTurn
            ? (current[turn.playerId] ?? 0) + 1
            : 0;
        current[turn.playerId] = next;
        if (next > (longest[turn.playerId] ?? 0)) {
          longest[turn.playerId] = next;
        }
      }
    }
    return _sortedIntMap(longest);
  }

  Duration get averagePlanning {
    return _averageDuration(playerTurns, (turn) => turn.planningDuration);
  }

  Duration get averageExecution =>
      _averageDuration(playerTurns, (turn) => turn.executionDuration);

  Duration get averageCompute =>
      _averageDuration(playerTurns, (turn) => turn.computeDuration);

  Duration get averageEstimatedVisibleTurn =>
      _averageDuration(playerTurns, (turn) => turn.estimatedVisibleDuration);

  Duration get averageEstimatedVisibleCycle =>
      _averageDuration(cycles, (cycle) => cycle.estimatedVisibleDuration);

  Duration get totalPlanning =>
      _sumDurations(playerTurns, (turn) => turn.planningDuration);

  Duration get totalExecution =>
      _sumDurations(playerTurns, (turn) => turn.executionDuration);

  Duration get totalCompute =>
      _sumDurations(playerTurns, (turn) => turn.computeDuration);

  Duration get totalEstimatedInterCommandDelay => _sumDurations(
    playerTurns,
    (turn) => turn.estimatedInterCommandDelayDuration,
  );

  Duration get totalEstimatedVisible =>
      _sumDurations(playerTurns, (turn) => turn.estimatedVisibleDuration);

  int get totalEstimatedVisibleDelayCommands {
    return playerTurns.fold<int>(
      0,
      (sum, turn) => sum + turn.commandStats.estimatedVisibleDelayCommands,
    );
  }

  int get maxEstimatedVisibleDelayCommands {
    if (playerTurns.isEmpty) return 0;
    return playerTurns
        .map((turn) => turn.commandStats.estimatedVisibleDelayCommands)
        .reduce((a, b) => a > b ? a : b);
  }

  int get p95EstimatedVisibleDelayCommands => _intPercentile(
    playerTurns,
    (turn) => turn.commandStats.estimatedVisibleDelayCommands,
    0.95,
  );

  Duration get maxPlanning =>
      _maxDuration(playerTurns, (turn) => turn.planningDuration);

  Duration get maxExecution =>
      _maxDuration(playerTurns, (turn) => turn.executionDuration);

  Duration get maxCompute =>
      _maxDuration(playerTurns, (turn) => turn.computeDuration);

  Duration get maxEstimatedVisibleTurn =>
      _maxDuration(playerTurns, (turn) => turn.estimatedVisibleDuration);

  Duration get maxEstimatedVisibleCycle =>
      _maxDuration(cycles, (cycle) => cycle.estimatedVisibleDuration);

  Duration get p90Planning =>
      _durationPercentile(playerTurns, (turn) => turn.planningDuration, 0.90);

  Duration get p95Planning =>
      _durationPercentile(playerTurns, (turn) => turn.planningDuration, 0.95);

  Duration get p90Execution =>
      _durationPercentile(playerTurns, (turn) => turn.executionDuration, 0.90);

  Duration get p95Execution =>
      _durationPercentile(playerTurns, (turn) => turn.executionDuration, 0.95);

  Duration get p90Compute =>
      _durationPercentile(playerTurns, (turn) => turn.computeDuration, 0.90);

  Duration get p95Compute =>
      _durationPercentile(playerTurns, (turn) => turn.computeDuration, 0.95);

  Duration get p90EstimatedVisibleTurn => _durationPercentile(
    playerTurns,
    (turn) => turn.estimatedVisibleDuration,
    0.90,
  );

  Duration get p95EstimatedVisibleTurn => _durationPercentile(
    playerTurns,
    (turn) => turn.estimatedVisibleDuration,
    0.95,
  );

  Duration get p90EstimatedVisibleCycle => _durationPercentile(
    cycles,
    (cycle) => cycle.estimatedVisibleDuration,
    0.90,
  );

  Duration get p95EstimatedVisibleCycle => _durationPercentile(
    cycles,
    (cycle) => cycle.estimatedVisibleDuration,
    0.95,
  );

  Duration _sumDurations<T>(
    Iterable<T> items,
    Duration Function(T item) select,
  ) {
    return Duration(
      microseconds: items.fold<int>(
        0,
        (sum, item) => sum + select(item).inMicroseconds,
      ),
    );
  }

  Duration _averageDuration<T>(
    Iterable<T> items,
    Duration Function(T item) select,
  ) {
    final values = items.toList();
    if (values.isEmpty) return Duration.zero;
    return Duration(
      microseconds:
          values.fold<int>(
            0,
            (sum, item) => sum + select(item).inMicroseconds,
          ) ~/
          values.length,
    );
  }

  Duration _maxDuration<T>(
    Iterable<T> items,
    Duration Function(T item) select,
  ) {
    final values = items.toList();
    if (values.isEmpty) return Duration.zero;
    return values.map(select).reduce((a, b) => a > b ? a : b);
  }

  Duration _durationPercentile<T>(
    Iterable<T> items,
    Duration Function(T item) select,
    double percentile,
  ) {
    final micros = [for (final item in items) select(item).inMicroseconds]
      ..sort();
    if (micros.isEmpty) return Duration.zero;
    final index = ((micros.length - 1) * percentile).ceil().clamp(
      0,
      micros.length - 1,
    );
    return Duration(microseconds: micros[index]);
  }

  int _intPercentile<T>(
    Iterable<T> items,
    int Function(T item) select,
    double percentile,
  ) {
    final values = [for (final item in items) select(item)]..sort();
    if (values.isEmpty) return 0;
    final index = ((values.length - 1) * percentile).ceil().clamp(
      0,
      values.length - 1,
    );
    return values[index];
  }

  List<_Finding> get findings {
    final findings = <_Finding>[];
    if (endTurn <= startTurn && cycles.isNotEmpty) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message: 'Multi-turn replay did not advance the game turn.',
        ),
      );
    }
    if (totalRejected > 0) {
      findings.add(
        _Finding(
          severity: 'fail',
          message: 'Multi-turn replay rejected $totalRejected AI command(s).',
        ),
      );
    }
    if (totalImmediateHumanAttacks > 0 && totalHumanAttacks == 0) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'AI had $totalImmediateHumanAttacks immediate human attack '
              'opportunities across replay but made no human attacks.',
        ),
      );
    }
    for (final turn in playerTurns) {
      if (turn.immediateHumanAttacks > 0 &&
          turn.commandStats.attackHumans == 0) {
        findings.add(
          _Finding(
            severity: 'fail',
            message:
                '${turn.playerId} had ${turn.immediateHumanAttacks} immediate '
                'human attack opportunity/opportunities on a replayed turn but '
                'planned no human attack.',
          ),
        );
      }
      if (!turn.terminalChangedState) {
        findings.add(
          _Finding(
            severity: 'fail',
            message: '${turn.playerId} terminal command was a no-op in replay.',
          ),
        );
      }
    }
    for (final entry in missingWarGoalTurnsByPlayer.entries) {
      final sample = _firstTurnMatching(
        entry.key,
        (turn) => turn.missingWarGoalWhileAtWar,
      );
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              '${entry.key} had ${entry.value} at-war replay turn(s) with '
              'military units and targetable human anchors but no war goal'
              '${sample == null ? '.' : ' (first: ${sample.toMarkdown()}).'}',
        ),
      );
    }
    for (final entry in longestPassiveWarPressureStreakByPlayer.entries) {
      if (entry.value < 6) continue;
      final totalTurns = passiveWarPressureTurnsByPlayer[entry.key] ?? 0;
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              '${entry.key} had a ${entry.value}-turn passive war-pressure '
              'streak and $totalTurns passive at-war turn(s) total.',
        ),
      );
    }
    for (final entry in longestPressureTargetIdleStreakByPlayer.entries) {
      if (entry.value < 8) continue;
      final totalTurns = pressureTargetIdleTurnsByPlayer[entry.key] ?? 0;
      final sample = _firstTurnMatching(
        entry.key,
        (turn) => turn.pressureTargetIdleTurn,
      );
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              '${entry.key} had a ${entry.value}-turn human pressure-target '
              'idle streak and $totalTurns idle at-war turn(s) total'
              '${sample == null ? '.' : ' (first: ${sample.toMarkdown()}).'}',
        ),
      );
    }
    if (totalDistractingNonHumanAttacks >= 5) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn replay had $totalDistractingNonHumanAttacks '
              'non-human attack(s) classified as distracting from human '
              'pressure: ${_formatIntMap(distractingNonHumanAttacksByPlayer)}.',
        ),
      );
    }
    if (averagePlanning > const Duration(milliseconds: 650)) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn average planning time ${averagePlanning.inMilliseconds}ms '
              'exceeds 650ms.',
        ),
      );
    }
    if (p95Planning > _comfortP95PlanningLimit) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn p95 planning time ${p95Planning.inMilliseconds}ms '
              'exceeds the comfort target of '
              '${_comfortP95PlanningLimit.inMilliseconds}ms.',
        ),
      );
    }
    if (maxPlanning > const Duration(milliseconds: 900)) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn max planning time ${maxPlanning.inMilliseconds}ms '
              'exceeds 900ms.',
        ),
      );
    }
    if (p95EstimatedVisibleCycle > _comfortP95EstimatedVisibleCycleLimit) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Multi-turn p95 estimated visible AI cycle time '
              '${p95EstimatedVisibleCycle.inMilliseconds}ms exceeds the '
              'comfort gate of '
              '${_comfortP95EstimatedVisibleCycleLimit.inMilliseconds}ms '
              'at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (averageEstimatedVisibleCycle > const Duration(milliseconds: 2000)) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn estimated visible AI cycle time '
              '${averageEstimatedVisibleCycle.inMilliseconds}ms exceeds '
              '2000ms at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (maxEstimatedVisibleCycle > _comfortMaxEstimatedVisibleCycleLimit) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Multi-turn max estimated visible AI cycle time '
              '${maxEstimatedVisibleCycle.inMilliseconds}ms exceeds the '
              'comfort gate of '
              '${_comfortMaxEstimatedVisibleCycleLimit.inMilliseconds}ms '
              'at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (maxEstimatedVisibleCycle > const Duration(milliseconds: 3500)) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn max estimated visible AI cycle time '
              '${maxEstimatedVisibleCycle.inMilliseconds}ms exceeds '
              '3500ms at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (p95EstimatedVisibleDelayCommands > 16) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn p95 visible command pacing '
              '$p95EstimatedVisibleDelayCommands command(s)/player-turn exceeds '
              '16 at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (maxEstimatedVisibleDelayCommands > 24) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn max visible command pacing '
              '$maxEstimatedVisibleDelayCommands command(s)/player-turn exceeds '
              '24 at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (totalStale > 0) {
      findings.add(
        _Finding(
          severity: 'warn',
          message: 'Multi-turn replay skipped $totalStale stale move(s).',
        ),
      );
    }
    return findings;
  }

  _MultiTurnFindingSample? _firstTurnMatching(
    String playerId,
    bool Function(_MultiTurnPlayerReport turn) test,
  ) {
    for (final cycle in cycles) {
      for (final turn in cycle.playerTurns) {
        if (turn.playerId != playerId || !test(turn)) continue;
        return _MultiTurnFindingSample(cycle: cycle, turn: turn);
      }
    }
    return null;
  }

  Map<String, Object?> toJson() {
    return {
      'savePath': savePath,
      'startTurn': startTurn,
      'endTurn': endTurn,
      'startHumanCities': startHumanCities,
      'endHumanCities': endHumanCities,
      'endHumanCityStates': [
        for (final cityState in endHumanCityStates) cityState.toJson(),
      ],
      'summary': {
        'cycles': cycles.length,
        'playerTurns': playerTurns.length,
        'totalPlanningMs': totalPlanning.inMilliseconds,
        'totalExecutionMs': totalExecution.inMilliseconds,
        'totalComputeMs': totalCompute.inMilliseconds,
        'totalEstimatedInterCommandDelayMs':
            totalEstimatedInterCommandDelay.inMilliseconds,
        'totalEstimatedVisibleMs': totalEstimatedVisible.inMilliseconds,
        'totalEstimatedVisibleDelayCommands':
            totalEstimatedVisibleDelayCommands,
        'p95EstimatedVisibleDelayCommands': p95EstimatedVisibleDelayCommands,
        'maxEstimatedVisibleDelayCommands': maxEstimatedVisibleDelayCommands,
        'averagePlanningMs': averagePlanning.inMilliseconds,
        'p90PlanningMs': p90Planning.inMilliseconds,
        'p95PlanningMs': p95Planning.inMilliseconds,
        'maxPlanningMs': maxPlanning.inMilliseconds,
        'averageExecutionMs': averageExecution.inMilliseconds,
        'p90ExecutionMs': p90Execution.inMilliseconds,
        'p95ExecutionMs': p95Execution.inMilliseconds,
        'maxExecutionMs': maxExecution.inMilliseconds,
        'averageComputeMs': averageCompute.inMilliseconds,
        'p90ComputeMs': p90Compute.inMilliseconds,
        'p95ComputeMs': p95Compute.inMilliseconds,
        'maxComputeMs': maxCompute.inMilliseconds,
        'averageEstimatedVisibleTurnMs':
            averageEstimatedVisibleTurn.inMilliseconds,
        'p90EstimatedVisibleTurnMs': p90EstimatedVisibleTurn.inMilliseconds,
        'p95EstimatedVisibleTurnMs': p95EstimatedVisibleTurn.inMilliseconds,
        'maxEstimatedVisibleTurnMs': maxEstimatedVisibleTurn.inMilliseconds,
        'averageEstimatedVisibleCycleMs':
            averageEstimatedVisibleCycle.inMilliseconds,
        'p90EstimatedVisibleCycleMs': p90EstimatedVisibleCycle.inMilliseconds,
        'p95EstimatedVisibleCycleMs': p95EstimatedVisibleCycle.inMilliseconds,
        'maxEstimatedVisibleCycleMs': maxEstimatedVisibleCycle.inMilliseconds,
        'totalCommands': totalCommands,
        'totalHumanAttacks': totalHumanAttacks,
        'totalPressureTargetAttacks': totalPressureTargetAttacks,
        'totalNonHumanAttacks': totalNonHumanAttacks,
        'totalDistractingNonHumanAttacks': totalDistractingNonHumanAttacks,
        'attackTargetOwners': attackTargetOwners,
        'nonHumanAttackReasons': nonHumanAttackReasons,
        'distractingNonHumanAttacksByPlayer':
            distractingNonHumanAttacksByPlayer,
        'totalImmediateHumanAttacks': totalImmediateHumanAttacks,
        'totalRejected': totalRejected,
        'totalStale': totalStale,
        'staleMoveReasons': staleMoveReasons,
        'totalCityCaptures': totalCityCaptures,
        'totalMissingWarGoalTurns': totalMissingWarGoalTurns,
        'missingWarGoalTurnsByPlayer': missingWarGoalTurnsByPlayer,
        'totalPassiveWarPressureTurns': totalPassiveWarPressureTurns,
        'passiveWarPressureTurnsByPlayer': passiveWarPressureTurnsByPlayer,
        'longestPassiveWarPressureStreakByPlayer':
            longestPassiveWarPressureStreakByPlayer,
        'totalPressureTargetIdleTurns': totalPressureTargetIdleTurns,
        'pressureTargetIdleTurnsByPlayer': pressureTargetIdleTurnsByPlayer,
        'longestPressureTargetIdleStreakByPlayer':
            longestPressureTargetIdleStreakByPlayer,
        'totalPressureTargetSiegeTurns': totalPressureTargetSiegeTurns,
        'pressureTargetSiegeTurnsByPlayer': pressureTargetSiegeTurnsByPlayer,
      },
      'cycles': [for (final cycle in cycles) cycle.toJson()],
      'findings': [for (final finding in findings) finding.toJson()],
    };
  }
}
