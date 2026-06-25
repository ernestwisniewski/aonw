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
      .where(_isCombatEvent)
      .any(
        (event) => _eventBelongsToPlayer(
          event: event,
          playerId: playerId,
          state: state,
          previousState: previousState,
        ),
      );
}

bool _isCombatEvent(GameEvent event) {
  return event is UnitAttackedEvent ||
      event is CombatResolvedEvent ||
      event is UnitKilledEvent ||
      event is CityCapturedEvent ||
      event is CityDestroyedEvent;
}

bool _eventBelongsToPlayer({
  required GameEvent event,
  required String playerId,
  required PersistentGameState state,
  required PersistentGameState? previousState,
}) {
  return switch (event) {
    CityFoundedEvent(:final ownerPlayerId) => ownerPlayerId == playerId,
    CityBuiltBuildingEvent(:final cityId) =>
      _cityOwner(state, cityId) == playerId ||
          _cityOwner(previousState, cityId) == playerId,
    CityProducedUnitEvent(:final cityId, :final producedUnitId) =>
      _cityOwner(state, cityId) == playerId ||
          _cityOwner(previousState, cityId) == playerId ||
          _unitOwner(state, producedUnitId) == playerId,
    CityClaimedHexEvent(:final cityId) =>
      _cityOwner(state, cityId) == playerId ||
          _cityOwner(previousState, cityId) == playerId,
    ResearchPointsGainedEvent() => false,
    TechnologyResearchedEvent(playerId: final eventPlayerId) =>
      eventPlayerId == playerId,
    StrategicResourceDiscoveredEvent(playerId: final eventPlayerId) =>
      eventPlayerId == playerId,
    MapObjectiveSecuredEvent(playerId: final eventPlayerId) =>
      eventPlayerId == playerId,
    UnitMovedEvent(:final unitId) =>
      _unitOwner(state, unitId) == playerId ||
          _unitOwner(previousState, unitId) == playerId,
    UnitGainedExperienceEvent(:final ownerPlayerId) =>
      ownerPlayerId == playerId,
    UnitAttackedEvent(
      :final attackerOwnerPlayerId,
      :final defenderOwnerPlayerId,
    ) =>
      attackerOwnerPlayerId == playerId || defenderOwnerPlayerId == playerId,
    CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId) =>
      _unitOwner(state, attackerUnitId) == playerId ||
          _unitOwner(previousState, attackerUnitId) == playerId ||
          _unitOwner(state, defenderUnitId) == playerId ||
          _unitOwner(previousState, defenderUnitId) == playerId ||
          _cityOwner(state, defenderUnitId) == playerId ||
          _cityOwner(previousState, defenderUnitId) == playerId,
    UnitKilledEvent(:final ownerPlayerId, :final attackerUnitId) =>
      ownerPlayerId == playerId ||
          (attackerUnitId != null &&
              (_unitOwner(state, attackerUnitId) == playerId ||
                  _unitOwner(previousState, attackerUnitId) == playerId)),
    UnitRetreatedEvent(:final ownerPlayerId) => ownerPlayerId == playerId,
    CityCapturedEvent(:final previousOwnerPlayerId, :final newOwnerPlayerId) =>
      previousOwnerPlayerId == playerId || newOwnerPlayerId == playerId,
    CityDestroyedEvent(
      :final previousOwnerPlayerId,
      :final attackerOwnerPlayerId,
    ) =>
      previousOwnerPlayerId == playerId || attackerOwnerPlayerId == playerId,
    TurnEndedEvent(playerId: final eventPlayerId) => eventPlayerId == playerId,
    WorkerCompletedJobEvent(:final unitId) =>
      _unitOwner(state, unitId) == playerId ||
          _unitOwner(previousState, unitId) == playerId,
    DominationThresholdReachedEvent(playerId: final eventPlayerId) =>
      eventPlayerId == playerId,
    CivilizationMetEvent(playerId: final eventPlayerId, :final metPlayerId) =>
      eventPlayerId == playerId || metPlayerId == playerId,
    DiplomaticProposalSentEvent(:final fromPlayerId, :final toPlayerId) =>
      fromPlayerId == playerId || toPlayerId == playerId,
    DiplomaticProposalRespondedEvent(:final fromPlayerId, :final toPlayerId) =>
      fromPlayerId == playerId || toPlayerId == playerId,
    DiplomaticProposalExpiredEvent(:final fromPlayerId, :final toPlayerId) =>
      fromPlayerId == playerId || toPlayerId == playerId,
    DiplomaticRelationChangedEvent(:final playerAId, :final playerBId) =>
      playerAId == playerId || playerBId == playerId,
    DiplomaticMessageSentEvent(:final fromPlayerId, :final toPlayerId) =>
      fromPlayerId == playerId || toPlayerId == playerId,
    DiplomaticMessageRespondedEvent(:final fromPlayerId, :final toPlayerId) =>
      fromPlayerId == playerId || toPlayerId == playerId,
    DiplomaticScoreChangedEvent(:final playerAId, :final playerBId) =>
      playerAId == playerId || playerBId == playerId,
    DiplomaticPromiseBrokenEvent(:final playerAId, :final playerBId) =>
      playerAId == playerId || playerBId == playerId,
    CommandRejectedEvent() ||
    AllPlayersSubmittedEvent() ||
    PlayerTimedOutEvent() ||
    TurnAutoResolvedEvent() ||
    PlayerKickedEvent() => false,
  };
}

String? _unitOwner(PersistentGameState? state, String unitId) {
  if (state == null) return null;
  for (final unit in state.units) {
    if (unit.id == unitId) return unit.ownerPlayerId;
  }
  return null;
}

String? _cityOwner(PersistentGameState? state, String cityId) {
  if (state == null) return null;
  for (final city in state.cities) {
    if (city.id == cityId) return city.ownerPlayerId;
  }
  return null;
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
