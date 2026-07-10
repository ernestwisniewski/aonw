part of 'balance_telemetry.dart';

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
  required Iterable<GameEvent> events,
  required int commandCount,
}) {
  if (commandCount > 0) return false;
  if (_hasMeaningfulEventForPlayer(
    playerId: playerId,
    state: current,
    previousState: previous,
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
  required PersistentGameState state,
  required PersistentGameState? previousState,
  required Iterable<GameEvent> events,
}) {
  return events.any(
    (event) => _eventBelongsToPlayer(
      event: event,
      playerId: playerId,
      state: state,
      previousState: previousState,
    ),
  );
}

bool _hasCombatEventForPlayer({
  required String playerId,
  required PersistentGameState state,
  required PersistentGameState? previousState,
  required Iterable<GameEvent> events,
}) {
  return events
      .where((event) => GameEventDomainDescriptor.forEvent(event).combat)
      .any(
        (event) => _eventBelongsToPlayer(
          event: event,
          playerId: playerId,
          state: state,
          previousState: previousState,
        ),
      );
}

bool _eventBelongsToPlayer({
  required GameEvent event,
  required String playerId,
  required PersistentGameState state,
  required PersistentGameState? previousState,
}) {
  return GameEventDomainDescriptor.forEvent(event).belongsToPlayer(
    playerId: playerId,
    state: state,
    previousState: previousState,
  );
}

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
