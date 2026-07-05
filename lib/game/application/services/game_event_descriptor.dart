import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/event.dart';

enum GameEventMessageGroup {
  city,
  unit,
  combat,
  turn,
  research,
  objective,
  diplomacy,
  system,
}

enum GameEventRendererEffectKind {
  none,
  unitMoved,
  cityFounded,
  cityProducedUnit,
  cityClaimedHex,
  unitKilled,
  unitRetreated,
  combatResolved,
  workerCompletedJob,
  technologyResearched,
}

enum GameEventSoundCueKind { none, city, combat }

sealed class GameEventFocusHint {
  const GameEventFocusHint();
}

final class UnitGameEventFocusHint extends GameEventFocusHint {
  const UnitGameEventFocusHint(this.unitId);

  final String unitId;
}

final class CityGameEventFocusHint extends GameEventFocusHint {
  const CityGameEventFocusHint(this.cityId);

  final String cityId;
}

final class TileGameEventFocusHint extends GameEventFocusHint {
  const TileGameEventFocusHint({
    required this.id,
    required this.col,
    required this.row,
  });

  final String id;
  final int col;
  final int row;
}

final class PlayerAnchorGameEventFocusHint extends GameEventFocusHint {
  const PlayerAnchorGameEventFocusHint(this.playerId);

  final String playerId;
}

final class GameEventDescriptor {
  const GameEventDescriptor._(this.event);

  factory GameEventDescriptor.forEvent(GameEvent event) {
    return GameEventDescriptor._(event);
  }

  final GameEvent event;

  bool get activityWorthy {
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
      CityAttackedEvent() ||
      TurnEndedEvent() ||
      ResearchPointsGainedEvent() => false,
    };
  }

  GameEventMessageGroup get messageGroup {
    return switch (event) {
      CityFoundedEvent() ||
      CityBuiltBuildingEvent() ||
      CityProducedUnitEvent() ||
      CityClaimedHexEvent() => GameEventMessageGroup.city,
      UnitMovedEvent() ||
      UnitGainedExperienceEvent() ||
      WorkerCompletedJobEvent() => GameEventMessageGroup.unit,
      UnitAttackedEvent() ||
      CityAttackedEvent() ||
      CombatResolvedEvent() ||
      UnitKilledEvent() ||
      UnitRetreatedEvent() ||
      CityCapturedEvent() ||
      CityDestroyedEvent() => GameEventMessageGroup.combat,
      TurnEndedEvent() ||
      DominationThresholdReachedEvent() ||
      StabilityBandChangedEvent() => GameEventMessageGroup.turn,
      ResearchPointsGainedEvent() ||
      TechnologyResearchedEvent() ||
      StrategicResourceDiscoveredEvent() => GameEventMessageGroup.research,
      MapObjectiveSecuredEvent() => GameEventMessageGroup.objective,
      CivilizationMetEvent() ||
      DiplomaticProposalSentEvent() ||
      DiplomaticProposalRespondedEvent() ||
      DiplomaticProposalExpiredEvent() ||
      DiplomaticRelationChangedEvent() ||
      DiplomaticMessageSentEvent() ||
      DiplomaticMessageRespondedEvent() ||
      DiplomaticScoreChangedEvent() ||
      DiplomaticPromiseBrokenEvent() => GameEventMessageGroup.diplomacy,
      CommandRejectedEvent() ||
      AllPlayersSubmittedEvent() ||
      PlayerTimedOutEvent() ||
      TurnAutoResolvedEvent() ||
      PlayerKickedEvent() => GameEventMessageGroup.system,
    };
  }

  GameEventRendererEffectKind get rendererEffectKind {
    return switch (event) {
      UnitMovedEvent() => GameEventRendererEffectKind.unitMoved,
      CityFoundedEvent() => GameEventRendererEffectKind.cityFounded,
      CityProducedUnitEvent() => GameEventRendererEffectKind.cityProducedUnit,
      CityClaimedHexEvent() => GameEventRendererEffectKind.cityClaimedHex,
      UnitKilledEvent() => GameEventRendererEffectKind.unitKilled,
      UnitRetreatedEvent() => GameEventRendererEffectKind.unitRetreated,
      CombatResolvedEvent() => GameEventRendererEffectKind.combatResolved,
      WorkerCompletedJobEvent() =>
        GameEventRendererEffectKind.workerCompletedJob,
      TechnologyResearchedEvent() =>
        GameEventRendererEffectKind.technologyResearched,
      CityBuiltBuildingEvent() ||
      UnitGainedExperienceEvent() ||
      UnitAttackedEvent() ||
      CityAttackedEvent() ||
      CityCapturedEvent() ||
      CityDestroyedEvent() ||
      TurnEndedEvent() ||
      DominationThresholdReachedEvent() ||
      StabilityBandChangedEvent() ||
      ResearchPointsGainedEvent() ||
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
      DiplomaticPromiseBrokenEvent() => GameEventRendererEffectKind.none,
    };
  }

  GameEventSoundCueKind get soundCueKind {
    return switch (event) {
      CityFoundedEvent() ||
      CityBuiltBuildingEvent() ||
      CityProducedUnitEvent() ||
      CityCapturedEvent() => GameEventSoundCueKind.city,
      CombatResolvedEvent() => GameEventSoundCueKind.combat,
      CityClaimedHexEvent() ||
      UnitMovedEvent() ||
      UnitGainedExperienceEvent() ||
      UnitAttackedEvent() ||
      UnitKilledEvent() ||
      UnitRetreatedEvent() ||
      CityAttackedEvent() ||
      CityDestroyedEvent() ||
      TurnEndedEvent() ||
      WorkerCompletedJobEvent() ||
      DominationThresholdReachedEvent() ||
      StabilityBandChangedEvent() ||
      ResearchPointsGainedEvent() ||
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
      DiplomaticPromiseBrokenEvent() => GameEventSoundCueKind.none,
    };
  }

  Set<String> get unitIds {
    return switch (event) {
      CityProducedUnitEvent(:final producedUnitId) => {producedUnitId},
      UnitMovedEvent(:final unitId) => {unitId},
      UnitGainedExperienceEvent(:final unitId) => {unitId},
      UnitAttackedEvent(:final attackerUnitId, :final defenderUnitId) => {
        attackerUnitId,
        defenderUnitId,
      },
      CityAttackedEvent(:final attackerUnitId) => {attackerUnitId},
      CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId) => {
        attackerUnitId,
        defenderUnitId,
      },
      UnitKilledEvent(:final unitId, :final attackerUnitId) => {
        unitId,
        ?attackerUnitId,
      },
      UnitRetreatedEvent(:final unitId) => {unitId},
      WorkerCompletedJobEvent(:final unitId) => {unitId},
      CityFoundedEvent() ||
      CityBuiltBuildingEvent() ||
      CityClaimedHexEvent() ||
      CityCapturedEvent() ||
      CityDestroyedEvent() ||
      TurnEndedEvent() ||
      DominationThresholdReachedEvent() ||
      StabilityBandChangedEvent() ||
      ResearchPointsGainedEvent() ||
      TechnologyResearchedEvent() ||
      StrategicResourceDiscoveredEvent() ||
      MapObjectiveSecuredEvent() ||
      CivilizationMetEvent() ||
      DiplomaticProposalSentEvent() ||
      DiplomaticProposalRespondedEvent() ||
      DiplomaticProposalExpiredEvent() ||
      DiplomaticRelationChangedEvent() ||
      DiplomaticMessageSentEvent() ||
      DiplomaticMessageRespondedEvent() ||
      DiplomaticScoreChangedEvent() ||
      DiplomaticPromiseBrokenEvent() ||
      CommandRejectedEvent() ||
      AllPlayersSubmittedEvent() ||
      PlayerTimedOutEvent() ||
      TurnAutoResolvedEvent() ||
      PlayerKickedEvent() => const <String>{},
    };
  }

  Set<String> get cityIds {
    return switch (event) {
      CityFoundedEvent(:final cityId) => {cityId},
      CityBuiltBuildingEvent(:final cityId) => {cityId},
      CityProducedUnitEvent(:final cityId) => {cityId},
      CityClaimedHexEvent(:final cityId) => {cityId},
      CityAttackedEvent(:final cityId) => {cityId},
      CombatResolvedEvent(:final defenderUnitId) => {defenderUnitId},
      CityCapturedEvent(:final cityId) => {cityId},
      CityDestroyedEvent(:final cityId) => {cityId},
      UnitMovedEvent() ||
      UnitGainedExperienceEvent() ||
      UnitAttackedEvent() ||
      UnitKilledEvent() ||
      UnitRetreatedEvent() ||
      TurnEndedEvent() ||
      WorkerCompletedJobEvent() ||
      DominationThresholdReachedEvent() ||
      StabilityBandChangedEvent() ||
      ResearchPointsGainedEvent() ||
      TechnologyResearchedEvent() ||
      StrategicResourceDiscoveredEvent() ||
      MapObjectiveSecuredEvent() ||
      CivilizationMetEvent() ||
      DiplomaticProposalSentEvent() ||
      DiplomaticProposalRespondedEvent() ||
      DiplomaticProposalExpiredEvent() ||
      DiplomaticRelationChangedEvent() ||
      DiplomaticMessageSentEvent() ||
      DiplomaticMessageRespondedEvent() ||
      DiplomaticScoreChangedEvent() ||
      DiplomaticPromiseBrokenEvent() ||
      CommandRejectedEvent() ||
      AllPlayersSubmittedEvent() ||
      PlayerTimedOutEvent() ||
      TurnAutoResolvedEvent() ||
      PlayerKickedEvent() => const <String>{},
    };
  }

  List<GameEventFocusHint> get focusHints {
    return switch (event) {
      CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId) ||
      UnitAttackedEvent(:final attackerUnitId, :final defenderUnitId) => [
        CityGameEventFocusHint(defenderUnitId),
        UnitGameEventFocusHint(attackerUnitId),
        UnitGameEventFocusHint(defenderUnitId),
      ],
      CityAttackedEvent(:final attackerUnitId, :final cityId) => [
        CityGameEventFocusHint(cityId),
        UnitGameEventFocusHint(attackerUnitId),
      ],
      UnitKilledEvent(:final attackerUnitId) => [
        if (attackerUnitId != null) UnitGameEventFocusHint(attackerUnitId),
      ],
      UnitRetreatedEvent(:final unitId) => [UnitGameEventFocusHint(unitId)],
      CityCapturedEvent(:final cityId) => [CityGameEventFocusHint(cityId)],
      CityFoundedEvent(:final cityId) => [CityGameEventFocusHint(cityId)],
      CityBuiltBuildingEvent(:final cityId) => [CityGameEventFocusHint(cityId)],
      CityProducedUnitEvent(:final cityId) => [CityGameEventFocusHint(cityId)],
      CityClaimedHexEvent(:final cityId) => [CityGameEventFocusHint(cityId)],
      UnitMovedEvent(:final unitId) => [UnitGameEventFocusHint(unitId)],
      UnitGainedExperienceEvent(:final unitId) => [
        UnitGameEventFocusHint(unitId),
      ],
      WorkerCompletedJobEvent(:final unitId) => [
        UnitGameEventFocusHint(unitId),
      ],
      DominationThresholdReachedEvent(:final playerId) => [
        PlayerAnchorGameEventFocusHint(playerId),
      ],
      TechnologyResearchedEvent(:final playerId) => [
        PlayerAnchorGameEventFocusHint(playerId),
      ],
      StrategicResourceDiscoveredEvent(
        :final nearestUnclaimedCol,
        :final nearestUnclaimedRow,
      ) =>
        nearestUnclaimedCol == null || nearestUnclaimedRow == null
            ? const []
            : [
                TileGameEventFocusHint(
                  id: 'resource_${nearestUnclaimedCol}_$nearestUnclaimedRow',
                  col: nearestUnclaimedCol,
                  row: nearestUnclaimedRow,
                ),
              ],
      MapObjectiveSecuredEvent(:final objectiveId, :final col, :final row) => [
        TileGameEventFocusHint(
          id: 'objective_$objectiveId',
          col: col,
          row: row,
        ),
      ],
      CivilizationMetEvent(:final metPlayerId) => [
        PlayerAnchorGameEventFocusHint(metPlayerId),
      ],
      CityDestroyedEvent() ||
      TurnEndedEvent() ||
      StabilityBandChangedEvent() ||
      ResearchPointsGainedEvent() ||
      DiplomaticProposalSentEvent() ||
      DiplomaticProposalRespondedEvent() ||
      DiplomaticProposalExpiredEvent() ||
      DiplomaticRelationChangedEvent() ||
      DiplomaticMessageSentEvent() ||
      DiplomaticMessageRespondedEvent() ||
      DiplomaticScoreChangedEvent() ||
      DiplomaticPromiseBrokenEvent() ||
      PlayerTimedOutEvent() ||
      TurnAutoResolvedEvent() ||
      PlayerKickedEvent() ||
      CommandRejectedEvent() ||
      AllPlayersSubmittedEvent() => const [],
    };
  }

  List<String> playerIdsFor({
    required GameState state,
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
      CityAttackedEvent(
        :final attackerOwnerPlayerId,
        :final cityOwnerPlayerId,
      ) =>
        _playerIds([attackerOwnerPlayerId, cityOwnerPlayerId]),
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
      if (playerId == null || playerId.isEmpty || !seen.add(playerId)) {
        continue;
      }
      ordered.add(playerId);
    }
    return List.unmodifiable(ordered);
  }

  String? _cityOwner(GameState? state, String cityId) {
    return state?.cityById(cityId)?.ownerPlayerId;
  }

  String? _unitOwner(GameState? state, String unitId) {
    return state?.unitById(unitId)?.ownerPlayerId;
  }
}
