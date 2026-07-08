import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/event.dart';

part 'game_event_descriptor_player_visibility.dart';

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

  bool get activityWorthy => _eventActivityWorthy(event);

  GameEventMessageGroup get messageGroup => _eventMessageGroup(event);

  GameEventRendererEffectKind get rendererEffectKind {
    return _eventRendererEffectKind(event);
  }

  GameEventSoundCueKind get soundCueKind => _eventSoundCueKind(event);

  Set<String> get unitIds => _eventUnitIds(event);

  Set<String> get cityIds => _eventCityIds(event);

  List<GameEventFocusHint> get focusHints => _eventFocusHints(event);

  List<String> playerIdsFor({
    required GameState state,
    GameState? previousState,
    String? visiblePlayerId,
  }) {
    return _eventPlayerIdsFor(
      event,
      state: state,
      previousState: previousState,
      visiblePlayerId: visiblePlayerId,
    );
  }
}

bool _eventActivityWorthy(GameEvent event) {
  return switch (event) {
    CityFoundedEvent() ||
    CityBuiltBuildingEvent() ||
    CityBuiltWonderEvent() ||
    WonderProductionRefundedEvent() ||
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

GameEventMessageGroup _eventMessageGroup(GameEvent event) {
  return switch (event) {
    CityFoundedEvent() ||
    CityBuiltBuildingEvent() ||
    CityBuiltWonderEvent() ||
    WonderProductionRefundedEvent() ||
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

GameEventRendererEffectKind _eventRendererEffectKind(GameEvent event) {
  return switch (event) {
    UnitMovedEvent() => GameEventRendererEffectKind.unitMoved,
    CityFoundedEvent() => GameEventRendererEffectKind.cityFounded,
    CityProducedUnitEvent() => GameEventRendererEffectKind.cityProducedUnit,
    CityClaimedHexEvent() => GameEventRendererEffectKind.cityClaimedHex,
    UnitKilledEvent() => GameEventRendererEffectKind.unitKilled,
    UnitRetreatedEvent() => GameEventRendererEffectKind.unitRetreated,
    CombatResolvedEvent() => GameEventRendererEffectKind.combatResolved,
    WorkerCompletedJobEvent() => GameEventRendererEffectKind.workerCompletedJob,
    TechnologyResearchedEvent() =>
      GameEventRendererEffectKind.technologyResearched,
    CityBuiltBuildingEvent() ||
    CityBuiltWonderEvent() ||
    WonderProductionRefundedEvent() ||
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

GameEventSoundCueKind _eventSoundCueKind(GameEvent event) {
  return switch (event) {
    CityFoundedEvent() ||
    CityBuiltBuildingEvent() ||
    CityBuiltWonderEvent() ||
    CityProducedUnitEvent() ||
    CityCapturedEvent() => GameEventSoundCueKind.city,
    CombatResolvedEvent() => GameEventSoundCueKind.combat,
    WonderProductionRefundedEvent() ||
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

Set<String> _eventUnitIds(GameEvent event) {
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
    CityBuiltWonderEvent() ||
    WonderProductionRefundedEvent() ||
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

Set<String> _eventCityIds(GameEvent event) {
  return switch (event) {
    CityFoundedEvent(:final cityId) => {cityId},
    CityBuiltBuildingEvent(:final cityId) => {cityId},
    CityBuiltWonderEvent(:final cityId) => {cityId},
    WonderProductionRefundedEvent(:final cityId) => {cityId},
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

List<GameEventFocusHint> _eventFocusHints(GameEvent event) {
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
    CityBuiltWonderEvent(:final cityId) => [CityGameEventFocusHint(cityId)],
    WonderProductionRefundedEvent(:final cityId) => [
      CityGameEventFocusHint(cityId),
    ],
    CityProducedUnitEvent(:final cityId) => [CityGameEventFocusHint(cityId)],
    CityClaimedHexEvent(:final cityId) => [CityGameEventFocusHint(cityId)],
    UnitMovedEvent(:final unitId) => [UnitGameEventFocusHint(unitId)],
    UnitGainedExperienceEvent(:final unitId) => [
      UnitGameEventFocusHint(unitId),
    ],
    WorkerCompletedJobEvent(:final unitId) => [UnitGameEventFocusHint(unitId)],
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
      TileGameEventFocusHint(id: 'objective_$objectiveId', col: col, row: row),
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
