part of 'balance_telemetry.dart';

void _captureActiveSample({
  required List<String> playerIds,
  required Map<String, _PlayerReportBuilder> builders,
  required Map<String, int> activeDeadRuns,
  required BalanceTelemetryTurnSample? previousSample,
  required BalanceTelemetryTurnSample sample,
}) {
  final ownership = _eventOwnershipTransition(
    previous: previousSample?.state,
    next: sample.state,
    hasEvents: sample.events.isNotEmpty,
  );
  for (final playerId in playerIds) {
    final builder = builders[playerId]!
      ..captureMilestones(
        playerId: playerId,
        sample: sample,
        ownership: ownership,
      );
    final objectiveAction = sample.objectiveActionByPlayerId[playerId];
    if (objectiveAction != null) {
      builder.captureObjectiveAction(objectiveAction);
    }

    final previous = previousSample;
    if (previous == null) continue;
    final deadTurn = _isDeadTurn(
      playerId: playerId,
      previous: previous.state,
      current: sample.state,
      ownership: ownership,
      events: sample.events,
      commandCount: sample.meaningfulCommandsByPlayerId[playerId] ?? 0,
    );
    if (deadTurn) {
      builder.deadTurnCount += 1;
      activeDeadRuns.putIfAbsent(playerId, () => sample.turn);
    } else {
      _closeDeadRun(
        builder: builder,
        playerId: playerId,
        activeDeadRuns: activeDeadRuns,
        endTurn: sample.turn - 1,
      );
    }
  }
}

void _closeDeadRun({
  required _PlayerReportBuilder builder,
  required String playerId,
  required Map<String, int> activeDeadRuns,
  required int endTurn,
}) {
  final startTurn = activeDeadRuns.remove(playerId);
  if (startTurn == null || endTurn < startTurn) return;
  final run = BalanceTelemetryDeadTurnRun(
    playerId: playerId,
    startTurn: startTurn,
    endTurn: endTurn,
  );
  builder.deadTurnRuns.add(run);
  if (run.length > builder.longestDeadTurnStreak) {
    builder.longestDeadTurnStreak = run.length;
  }
}

class _PlayerSnapshotSummary {
  const _PlayerSnapshotSummary({
    required this.cityCount,
    required this.population,
    required this.buildingCount,
    required this.technologyCount,
    required this.unitCount,
    required this.discoveredHexCount,
    required this.controlledHexCount,
    required this.improvementCount,
    required this.unitPositions,
  });

  final int cityCount;
  final int population;
  final int buildingCount;
  final int technologyCount;
  final int unitCount;
  final int discoveredHexCount;
  final int controlledHexCount;
  final int improvementCount;
  final Map<String, HexCoordinate> unitPositions;

  factory _PlayerSnapshotSummary.fromState(
    PersistentGameState state,
    String playerId,
  ) {
    final cities = [
      for (final city in state.cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final cityIds = {for (final city in cities) city.id};
    final units = [
      for (final unit in state.units)
        if (unit.ownerPlayerId == playerId) unit,
    ];
    return _PlayerSnapshotSummary(
      cityCount: cities.length,
      population: cities.fold<int>(0, (total, city) => total + city.population),
      buildingCount: cities.fold<int>(
        0,
        (total, city) => total + city.buildings.length,
      ),
      technologyCount: state.research
          .forPlayer(playerId)
          .unlockedTechnologyIds
          .length,
      unitCount: units.length,
      discoveredHexCount: state.fogOfWar
          .fogForPlayer(playerId)
          .discoveredHexes
          .length,
      controlledHexCount: cities.fold<int>(
        0,
        (total, city) => total + city.territoryHexCount,
      ),
      improvementCount: state.fieldImprovements
          .where((improvement) => cityIds.contains(improvement.builtByCityId))
          .length,
      unitPositions: {
        for (final unit in units)
          unit.id: HexCoordinate(col: unit.col, row: unit.row),
      },
    );
  }

  bool hasProgressAfter(_PlayerSnapshotSummary previous) {
    return _hasNumericProgressAfter(previous) ||
        _hasUnitMovementAfter(previous);
  }

  bool _hasNumericProgressAfter(_PlayerSnapshotSummary previous) {
    return cityCount > previous.cityCount ||
        population > previous.population ||
        buildingCount > previous.buildingCount ||
        technologyCount > previous.technologyCount ||
        unitCount > previous.unitCount ||
        discoveredHexCount > previous.discoveredHexCount ||
        controlledHexCount > previous.controlledHexCount ||
        improvementCount > previous.improvementCount;
  }

  bool _hasUnitMovementAfter(_PlayerSnapshotSummary previous) {
    return unitPositions.entries.any(
      (entry) => previous.unitPositions[entry.key] != entry.value,
    );
  }
}

bool _isDeadTurn({
  required String playerId,
  required PersistentGameState previous,
  required PersistentGameState current,
  required _EventOwnershipTransition ownership,
  required Iterable<GameEvent> events,
  required int commandCount,
}) {
  if (commandCount > 0) return false;
  if (_hasMeaningfulEventForPlayer(
    playerId: playerId,
    ownership: ownership,
    events: events,
  )) {
    return false;
  }
  final previousSummary = _PlayerSnapshotSummary.fromState(previous, playerId);
  final currentSummary = _PlayerSnapshotSummary.fromState(current, playerId);
  return !currentSummary.hasProgressAfter(previousSummary);
}

bool _hasContact(PersistentGameState state, String playerId) {
  final fog = state.fogOfWar.fogForPlayer(playerId);
  return state.units.any(
        (unit) =>
            unit.ownerPlayerId != playerId &&
            fog.isVisible(HexCoordinate(col: unit.col, row: unit.row)),
      ) ||
      state.cities.any(
        (city) =>
            city.ownerPlayerId != playerId &&
            fog.isVisible(
              HexCoordinate(col: city.center.col, row: city.center.row),
            ),
      );
}

bool _hasMeaningfulEventForPlayer({
  required String playerId,
  required _EventOwnershipTransition ownership,
  required Iterable<GameEvent> events,
}) {
  return events.any(
    (event) => _eventBelongsToPlayer(
      event: event,
      playerId: playerId,
      ownership: ownership,
    ),
  );
}

bool _hasCombatEventForPlayer({
  required String playerId,
  required _EventOwnershipTransition ownership,
  required Iterable<GameEvent> events,
}) {
  return events
      .where((event) => GameEventDomainDescriptor.forEvent(event).combat)
      .any(
        (event) => _eventBelongsToPlayer(
          event: event,
          playerId: playerId,
          ownership: ownership,
        ),
      );
}

bool _eventBelongsToPlayer({
  required GameEvent event,
  required String playerId,
  required _EventOwnershipTransition ownership,
}) {
  return GameEventDomainDescriptor.forEvent(event).belongsToPlayer(
    playerId: playerId,
    previous: ownership.previous,
    next: ownership.next,
  );
}

_EventOwnershipTransition _eventOwnershipTransition({
  required PersistentGameState? previous,
  required PersistentGameState next,
  required bool hasEvents,
}) {
  if (!hasEvents) return _emptyEventOwnershipTransition;
  return (
    previous: previous == null
        ? GameEventOwnershipIndex.empty
        : GameEventOwnershipIndex.from(previous.units, previous.cities),
    next: GameEventOwnershipIndex.from(next.units, next.cities),
  );
}

typedef _EventOwnershipTransition = ({
  GameEventOwnershipIndex previous,
  GameEventOwnershipIndex next,
});

const _emptyEventOwnershipTransition = (
  previous: GameEventOwnershipIndex.empty,
  next: GameEventOwnershipIndex.empty,
);

List<String> _orderedDistinctPlayerIds(Iterable<String> playerIds) {
  final seen = <String>{};
  final ordered = <String>[];
  for (final playerId in playerIds) {
    if (playerId.isEmpty || seen.contains(playerId)) continue;
    seen.add(playerId);
    ordered.add(playerId);
  }
  ordered.sort();
  return ordered;
}
