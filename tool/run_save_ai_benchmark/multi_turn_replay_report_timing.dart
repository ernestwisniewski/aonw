part of '../run_save_ai_benchmark.dart';

extension _MultiTurnReplayReportTiming on _MultiTurnReplayReport {
  Duration get averagePlanning =>
      _averageDuration(playerTurns, (turn) => turn.planningDuration);

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

  int get totalEstimatedVisibleDelayCommands => playerTurns.fold<int>(
    0,
    (sum, turn) => sum + turn.commandStats.estimatedVisibleDelayCommands,
  );

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
}
