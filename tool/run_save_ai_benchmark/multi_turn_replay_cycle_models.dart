part of '../run_save_ai_benchmark.dart';

class _HumanCityEndState {
  const _HumanCityEndState({
    required this.cityId,
    required this.ownerPlayerId,
    required this.centerCol,
    required this.centerRow,
    required this.hitPoints,
    required this.centerOccupant,
    required this.adjacentNonHumanUnits,
    required this.readyAttackers,
  });

  final String cityId;
  final String ownerPlayerId;
  final int centerCol;
  final int centerRow;
  final int? hitPoints;
  final String? centerOccupant;
  final List<String> adjacentNonHumanUnits;
  final List<String> readyAttackers;

  Map<String, Object?> toJson() {
    return {
      'cityId': cityId,
      'ownerPlayerId': ownerPlayerId,
      'center': {'col': centerCol, 'row': centerRow},
      'hitPoints': hitPoints,
      'centerOccupant': centerOccupant,
      'adjacentNonHumanUnits': adjacentNonHumanUnits,
      'readyAttackers': readyAttackers,
    };
  }

  String toMarkdown() {
    return '$cityId@$centerCol,$centerRow hp=${hitPoints ?? 'default'} '
        'center=${centerOccupant ?? 'empty'} '
        'adjacent=${adjacentNonHumanUnits.isEmpty ? 'none' : adjacentNonHumanUnits.join(',')} '
        'readyAttackers=${readyAttackers.isEmpty ? 'none' : readyAttackers.join(',')}';
  }
}

class _MultiTurnFindingSample {
  const _MultiTurnFindingSample({required this.cycle, required this.turn});

  final _MultiTurnCycleReport cycle;
  final _MultiTurnPlayerReport turn;

  String toMarkdown() {
    return 'cycle ${cycle.index}, turn ${cycle.startTurn}, '
        'mode ${turn.strategicMode}, military ${turn.militaryCount}, '
        'targets ${turn.targetableHumanCityCount}/${turn.targetableHumanUnitCount}';
  }
}

class _MultiTurnCycleReport {
  const _MultiTurnCycleReport({
    required this.index,
    required this.startTurn,
    required this.endTurn,
    required this.humanCitiesStart,
    required this.humanCitiesEnd,
    required this.playerTurns,
  });

  final int index;
  final int startTurn;
  final int endTurn;
  final int humanCitiesStart;
  final int humanCitiesEnd;
  final List<_MultiTurnPlayerReport> playerTurns;

  Duration get planningDuration =>
      _sumDurations(playerTurns, (turn) => turn.planningDuration);

  Duration get executionDuration =>
      _sumDurations(playerTurns, (turn) => turn.executionDuration);

  Duration get computeDuration =>
      _sumDurations(playerTurns, (turn) => turn.computeDuration);

  Duration get estimatedInterCommandDelayDuration => _sumDurations(
    playerTurns,
    (turn) => turn.estimatedInterCommandDelayDuration,
  );

  Duration get estimatedVisibleDuration =>
      _sumDurations(playerTurns, (turn) => turn.estimatedVisibleDuration);

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

  Map<String, Object?> toJson() {
    return {
      'index': index,
      'startTurn': startTurn,
      'endTurn': endTurn,
      'humanCitiesStart': humanCitiesStart,
      'humanCitiesEnd': humanCitiesEnd,
      'timing': {
        'planningMs': planningDuration.inMilliseconds,
        'executionMs': executionDuration.inMilliseconds,
        'computeMs': computeDuration.inMilliseconds,
        'estimatedInterCommandDelayMs':
            estimatedInterCommandDelayDuration.inMilliseconds,
        'estimatedVisibleMs': estimatedVisibleDuration.inMilliseconds,
      },
      'playerTurns': [for (final turn in playerTurns) turn.toJson()],
    };
  }
}
