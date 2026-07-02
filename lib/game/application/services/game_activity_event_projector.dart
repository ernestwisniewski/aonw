import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';

abstract final class GameActivityEventProjector {
  static List<LoggedActivityEntry> project({
    required List<GameEvent> events,
    required GameState state,
    GameState? previousState,
    String? visiblePlayerId,
  }) {
    final activityEvents = [
      ...events,
      ..._civilizationMetEvents(
        state,
        previousState,
        playerIds: _civilizationMetPlayerIds(
          state,
          previousState,
          visiblePlayerId: visiblePlayerId,
        ),
      ),
    ];
    if (activityEvents.isEmpty) return const [];

    final projected = <LoggedActivityEntry>[];
    for (var i = 0; i < activityEvents.length; i++) {
      final event = activityEvents[i];
      if (!isActivityWorthy(event)) continue;
      final playerIds = playerIdsFor(
        event,
        state,
        previousState: previousState,
        visiblePlayerId: visiblePlayerId,
      );
      if (playerIds.isEmpty) continue;
      final context = GameActivityContext.capture(
        event: event,
        state: state,
        previousState: previousState,
      );
      for (final playerId in playerIds) {
        if (visiblePlayerId != null &&
            visiblePlayerId.isNotEmpty &&
            playerId != visiblePlayerId) {
          continue;
        }
        projected.add(
          LoggedActivityEntry(
            eventIndex: i,
            playerId: playerId,
            event: event,
            context: context,
          ),
        );
      }
    }
    return List.unmodifiable(projected);
  }

  static bool isActivityWorthy(GameEvent event) {
    return switch (event) {
      CityFoundedEvent() ||
      CityBuiltBuildingEvent() ||
      CityProducedUnitEvent() ||
      CityClaimedHexEvent() ||
      CombatResolvedEvent() ||
      UnitKilledEvent() ||
      UnitRetreatedEvent() ||
      CityCapturedEvent() ||
      CityDestroyedEvent() ||
      DominationThresholdReachedEvent() ||
      StabilityBandChangedEvent() ||
      WorkerCompletedJobEvent() ||
      TechnologyResearchedEvent() ||
      StrategicResourceDiscoveredEvent() ||
      MapObjectiveSecuredEvent() ||
      CivilizationMetEvent() ||
      CommandRejectedEvent() ||
      AllPlayersSubmittedEvent() ||
      PlayerTimedOutEvent() ||
      TurnAutoResolvedEvent() ||
      PlayerKickedEvent() ||
      DiplomaticProposalSentEvent() ||
      DiplomaticProposalRespondedEvent() ||
      DiplomaticProposalExpiredEvent() ||
      DiplomaticRelationChangedEvent() ||
      DiplomaticMessageSentEvent() ||
      DiplomaticMessageRespondedEvent() ||
      DiplomaticScoreChangedEvent() ||
      DiplomaticPromiseBrokenEvent() => true,
      UnitMovedEvent() ||
      UnitGainedExperienceEvent() ||
      UnitAttackedEvent() ||
      TurnEndedEvent() ||
      ResearchPointsGainedEvent() => false,
    };
  }

  static List<String> playerIdsFor(
    GameEvent event,
    GameState state, {
    GameState? previousState,
    String? visiblePlayerId,
  }) {
    return switch (event) {
      CityFoundedEvent(:final ownerPlayerId) => _playerIds([ownerPlayerId]),
      CityBuiltBuildingEvent(:final cityId) => _playerIds([
        _cityOwner(state, cityId),
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
      CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId) =>
        _combatPlayerIds(
          state,
          previousState,
          attackerUnitId: attackerUnitId,
          defenderUnitId: defenderUnitId,
        ),
      UnitKilledEvent(:final ownerPlayerId, :final attackerUnitId) =>
        _playerIds([
          ownerPlayerId,
          if (attackerUnitId != null)
            _unitOwner(state, attackerUnitId) ??
                _unitOwner(previousState, attackerUnitId) ??
                _cityOwner(state, attackerUnitId) ??
                _cityOwner(previousState, attackerUnitId),
        ]),
      UnitRetreatedEvent(:final ownerPlayerId) => _playerIds([ownerPlayerId]),
      CityCapturedEvent(
        :final previousOwnerPlayerId,
        :final newOwnerPlayerId,
      ) =>
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
      StrategicResourceDiscoveredEvent(:final playerId) => _playerIds([
        playerId,
      ]),
      MapObjectiveSecuredEvent(:final playerId) => _playerIds([playerId]),
      CivilizationMetEvent(:final playerId) => _playerIds([playerId]),
      PlayerTimedOutEvent(:final playerId) => _playerIds([playerId]),
      TurnAutoResolvedEvent(:final playerId) => _playerIds([playerId]),
      PlayerKickedEvent(:final playerId) => _playerIds([playerId]),
      DiplomaticProposalSentEvent(:final fromPlayerId, :final toPlayerId) =>
        _playerIds([fromPlayerId, toPlayerId]),
      DiplomaticProposalRespondedEvent(
        :final fromPlayerId,
        :final toPlayerId,
      ) =>
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

  static List<CivilizationMetEvent> _civilizationMetEvents(
    GameState state,
    GameState? previousState, {
    required List<String> playerIds,
  }) {
    if (previousState == null) return const [];
    if (playerIds.isEmpty) return const [];
    final metEvents = <CivilizationMetEvent>[];
    for (final playerId in playerIds) {
      final previouslyKnown = _knownOpponentPlayerIds(previousState, playerId);
      final currentlyKnown = _knownOpponentPlayerIds(state, playerId);
      final newlyMet = currentlyKnown.difference(previouslyKnown).toList()
        ..sort();
      for (final metPlayerId in newlyMet) {
        metEvents.add(
          CivilizationMetEvent(playerId: playerId, metPlayerId: metPlayerId),
        );
      }
    }
    return List.unmodifiable(metEvents);
  }

  static List<String> _civilizationMetPlayerIds(
    GameState state,
    GameState? previousState, {
    required String? visiblePlayerId,
  }) {
    if (visiblePlayerId != null && visiblePlayerId.isNotEmpty) {
      return [visiblePlayerId];
    }
    return _playerIds([
      state.activePlayerId,
      previousState?.activePlayerId,
      ...state.fogOfWar.players.keys,
      ...?previousState?.fogOfWar.players.keys,
      for (final unit in state.units) unit.ownerPlayerId,
      ...?previousState?.units.map((unit) => unit.ownerPlayerId),
      for (final city in state.cities) city.ownerPlayerId,
      ...?previousState?.cities.map((city) => city.ownerPlayerId),
    ]);
  }

  static Set<String> _knownOpponentPlayerIds(GameState state, String playerId) {
    final visibility = FogVisibilityQuery(
      playerId: playerId,
      state: state.fogOfWar,
    );
    final owners = <String>{};
    for (final city in state.cities) {
      if (city.ownerPlayerId == playerId || city.ownerPlayerId.isEmpty) {
        continue;
      }
      if (visibility.canRememberStaticAt(city.center.col, city.center.row)) {
        owners.add(city.ownerPlayerId);
      }
    }
    for (final unit in state.units) {
      if (unit.ownerPlayerId == playerId || unit.ownerPlayerId.isEmpty) {
        continue;
      }
      if (visibility.canSeeDynamicAt(unit.col, unit.row)) {
        owners.add(unit.ownerPlayerId);
      }
    }
    return owners;
  }

  static List<String> _combatPlayerIds(
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

  static List<String> _playerIds(Iterable<String?> playerIds) {
    final ordered = <String>[];
    final seen = <String>{};
    for (final playerId in playerIds) {
      if (playerId == null || playerId.isEmpty || !seen.add(playerId)) {
        continue;
      }
      ordered.add(playerId);
    }
    return List.unmodifiable(ordered);
  }

  static String? _cityOwner(GameState? state, String cityId) {
    return state?.cityById(cityId)?.ownerPlayerId;
  }

  static String? _unitOwner(GameState? state, String unitId) {
    return state?.unitById(unitId)?.ownerPlayerId;
  }
}
