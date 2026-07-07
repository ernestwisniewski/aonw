part of 'game_event_descriptor.dart';

List<String> _eventPlayerIdsFor(
  GameEvent event, {
  required GameState state,
  GameState? previousState,
  String? visiblePlayerId,
}) {
  return switch (event) {
    CityFoundedEvent(:final ownerPlayerId) => _playerIds([ownerPlayerId]),
    CityBuiltBuildingEvent(:final cityId) => _playerIds([
      _cityOwner(state, cityId),
    ]),
    CityBuiltWonderEvent(:final ownerPlayerId) => _playerIds([ownerPlayerId]),
    WonderProductionRefundedEvent(:final ownerPlayerId) => _playerIds([
      ownerPlayerId,
    ]),
    CityProducedUnitEvent(:final cityId) => _playerIds([
      _cityOwner(state, cityId),
    ]),
    CityClaimedHexEvent(:final cityId) => _playerIds([
      _cityOwner(state, cityId),
    ]),
    UnitMovedEvent(:final unitId) => _playerIds([
      _unitOwner(state, unitId) ?? _unitOwner(previousState, unitId),
    ]),
    UnitGainedExperienceEvent(:final ownerPlayerId) => _playerIds([
      ownerPlayerId,
    ]),
    UnitAttackedEvent(
      :final attackerOwnerPlayerId,
      :final defenderOwnerPlayerId,
    ) =>
      _playerIds([attackerOwnerPlayerId, defenderOwnerPlayerId]),
    CityAttackedEvent(:final attackerOwnerPlayerId, :final cityOwnerPlayerId) =>
      _playerIds([attackerOwnerPlayerId, cityOwnerPlayerId]),
    CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId) =>
      _combatPlayerIds(
        state,
        previousState,
        attackerUnitId: attackerUnitId,
        defenderUnitId: defenderUnitId,
      ),
    UnitKilledEvent(:final ownerPlayerId, :final attackerUnitId) => _playerIds([
      ownerPlayerId,
      if (attackerUnitId != null)
        _unitOwner(state, attackerUnitId) ??
            _unitOwner(previousState, attackerUnitId) ??
            _cityOwner(state, attackerUnitId) ??
            _cityOwner(previousState, attackerUnitId),
    ]),
    UnitRetreatedEvent(:final ownerPlayerId) => _playerIds([ownerPlayerId]),
    CityCapturedEvent(:final previousOwnerPlayerId, :final newOwnerPlayerId) =>
      _playerIds([previousOwnerPlayerId, newOwnerPlayerId]),
    CityDestroyedEvent(
      :final previousOwnerPlayerId,
      :final attackerOwnerPlayerId,
    ) =>
      _playerIds([previousOwnerPlayerId, attackerOwnerPlayerId]),
    TurnEndedEvent(:final playerId) => _playerIds([playerId]),
    WorkerCompletedJobEvent(:final unitId) => _playerIds([
      _unitOwner(state, unitId) ?? _unitOwner(previousState, unitId),
    ]),
    DominationThresholdReachedEvent(:final playerId) => _playerIds([
      visiblePlayerId,
      playerId,
    ]),
    StabilityBandChangedEvent(:final playerId) => _playerIds([playerId]),
    ResearchPointsGainedEvent(:final playerId) => _playerIds([playerId]),
    TechnologyResearchedEvent(:final playerId) => _playerIds([playerId]),
    StrategicResourceDiscoveredEvent(:final playerId) => _playerIds([playerId]),
    MapObjectiveSecuredEvent(:final playerId) => _playerIds([playerId]),
    CivilizationMetEvent(:final playerId) => _playerIds([playerId]),
    PlayerTimedOutEvent(:final playerId) => _playerIds([playerId]),
    TurnAutoResolvedEvent(:final playerId) => _playerIds([playerId]),
    PlayerKickedEvent(:final playerId) => _playerIds([playerId]),
    DiplomaticProposalSentEvent(:final fromPlayerId, :final toPlayerId) =>
      _playerIds([fromPlayerId, toPlayerId]),
    DiplomaticProposalRespondedEvent(:final fromPlayerId, :final toPlayerId) =>
      _playerIds([fromPlayerId, toPlayerId]),
    DiplomaticProposalExpiredEvent(:final fromPlayerId, :final toPlayerId) =>
      _playerIds([fromPlayerId, toPlayerId]),
    DiplomaticRelationChangedEvent(:final playerAId, :final playerBId) =>
      _playerIds([playerAId, playerBId]),
    DiplomaticMessageSentEvent(:final fromPlayerId, :final toPlayerId) =>
      _playerIds([fromPlayerId, toPlayerId]),
    DiplomaticMessageRespondedEvent(:final fromPlayerId, :final toPlayerId) =>
      _playerIds([fromPlayerId, toPlayerId]),
    DiplomaticScoreChangedEvent(:final playerAId, :final playerBId) =>
      _playerIds([playerAId, playerBId]),
    DiplomaticPromiseBrokenEvent(:final playerAId, :final playerBId) =>
      _playerIds([playerAId, playerBId]),
    CommandRejectedEvent() || AllPlayersSubmittedEvent() => const <String>[],
  };
}

List<String> _combatPlayerIds(
  GameState state,
  GameState? previousState, {
  required String attackerUnitId,
  required String defenderUnitId,
}) {
  final attackerOwner =
      _unitOwner(state, attackerUnitId) ??
      _unitOwner(previousState, attackerUnitId);
  final defenderOwner =
      _unitOwner(state, defenderUnitId) ??
      _unitOwner(previousState, defenderUnitId) ??
      _cityOwner(state, defenderUnitId) ??
      _cityOwner(previousState, defenderUnitId);
  return _playerIds([attackerOwner, defenderOwner]);
}

List<String> _playerIds(Iterable<String?> playerIds) {
  final ordered = <String>[];
  final seen = <String>{};
  for (final playerId in playerIds) {
    if (playerId == null || playerId.isEmpty || !seen.add(playerId)) continue;
    ordered.add(playerId);
  }
  return List.unmodifiable(ordered);
}

String? _cityOwner(GameState? state, String cityId) =>
    state?.cityById(cityId)?.ownerPlayerId;

String? _unitOwner(GameState? state, String unitId) =>
    state?.unitById(unitId)?.ownerPlayerId;
