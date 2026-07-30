import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/stability.dart';

part 'game_event_descriptor_player_visibility.dart';
part 'game_event_descriptor_artifact.dart';
part 'game_event_descriptor_types.dart';

final class GameEventDescriptor {
  GameEventDescriptor._({
    required this.activityWorthy,
    required this.messageGroup,
    this.rendererEffectKind = GameEventRendererEffectKind.none,
    this.soundCueKind = GameEventSoundCueKind.none,
    Iterable<String> unitIds = const [],
    Iterable<String> cityIds = const [],
    Iterable<GameEventFocusHint> focusHints = const [],
    Iterable<GameEventActivityCategory> activityCategories = const [],
    Iterable<String?> playerIds = const [],
    _GameEventPlayerIdsResolver? playerIdsResolver,
    this.completedTurn,
    this.completedWorkerUnitId,
    this.notificationMaxDetailCount,
    this.showAsTopNotification = true,
    this.civilizationPlayerId,
    this.civilizationMetPlayerId,
    this.diplomaticMessageId,
    this.diplomaticProposalId,
    this.diplomaticPopupRecipientPlayerId,
    this.passiveDiplomaticPopup = false,
    this.diplomaticPopupTone = GameEventDiplomaticPopupTone.neutral,
    this.criticalNotification = false,
    _CriticalNotificationResolver? criticalNotificationResolver,
  }) : unitIds = Set.unmodifiable(unitIds),
       cityIds = Set.unmodifiable(cityIds),
       focusHints = List.unmodifiable(focusHints),
       activityCategories = Set.unmodifiable(activityCategories),
       _playerIds = List.unmodifiable(playerIds),
       _playerIdsResolver = playerIdsResolver,
       _criticalNotificationResolver = criticalNotificationResolver;

  factory GameEventDescriptor.forEvent(GameEvent event) {
    if (event is ArtifactLifecycleEvent) {
      return artifactGameEventDescriptor(event);
    }
    return _describeGameEvent(event);
  }

  final bool activityWorthy;
  final GameEventMessageGroup messageGroup;
  final GameEventRendererEffectKind rendererEffectKind;
  final GameEventSoundCueKind soundCueKind;
  final Set<String> unitIds;
  final Set<String> cityIds;
  final List<GameEventFocusHint> focusHints;
  final Set<GameEventActivityCategory> activityCategories;
  final int? completedTurn;
  final String? completedWorkerUnitId;
  final int? notificationMaxDetailCount;
  final bool showAsTopNotification;
  final String? civilizationPlayerId;
  final String? civilizationMetPlayerId;
  final String? diplomaticMessageId;
  final String? diplomaticProposalId;
  final String? diplomaticPopupRecipientPlayerId;
  final bool passiveDiplomaticPopup;
  final GameEventDiplomaticPopupTone diplomaticPopupTone;
  final bool criticalNotification;
  final List<String?> _playerIds;
  final _GameEventPlayerIdsResolver? _playerIdsResolver;
  final _CriticalNotificationResolver? _criticalNotificationResolver;

  List<String> playerIdsFor({
    required GameState state,
    GameState? previousState,
    String? visiblePlayerId,
  }) {
    return _playerIdsResolver?.call(state, previousState, visiblePlayerId) ??
        _orderedPlayerIds(_playerIds);
  }

  bool isCriticalNotificationFor({
    required GameState state,
    required String playerId,
  }) {
    return criticalNotification ||
        (_criticalNotificationResolver?.call(state, playerId) ?? false);
  }
}

GameEventDescriptor _describeGameEvent(GameEvent event) => switch (event) {
  ArtifactLifecycleEvent() => artifactGameEventDescriptor(event),
  CityFoundedEvent(:final cityId, :final ownerPlayerId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.city,
      rendererEffectKind: GameEventRendererEffectKind.cityFounded,
      soundCueKind: GameEventSoundCueKind.city,
      cityIds: [cityId],
      focusHints: [CityGameEventFocusHint(cityId)],
      activityCategories: const [GameEventActivityCategory.city],
      playerIds: [ownerPlayerId],
    ),
  CityBuiltBuildingEvent(:final cityId) => GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.city,
    soundCueKind: GameEventSoundCueKind.city,
    cityIds: [cityId],
    focusHints: [CityGameEventFocusHint(cityId)],
    activityCategories: const [GameEventActivityCategory.city],
    playerIdsResolver: _cityOwnerPlayerIds(cityId),
  ),
  CityBuiltWonderEvent(:final cityId, :final ownerPlayerId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.city,
      soundCueKind: GameEventSoundCueKind.city,
      cityIds: [cityId],
      focusHints: [CityGameEventFocusHint(cityId)],
      activityCategories: const [GameEventActivityCategory.city],
      playerIds: [ownerPlayerId],
    ),
  WonderProductionRefundedEvent(:final cityId, :final ownerPlayerId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.city,
      cityIds: [cityId],
      focusHints: [CityGameEventFocusHint(cityId)],
      activityCategories: const [GameEventActivityCategory.city],
      playerIds: [ownerPlayerId],
    ),
  CityProducedUnitEvent(:final cityId, :final producedUnitId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.city,
      rendererEffectKind: GameEventRendererEffectKind.cityProducedUnit,
      soundCueKind: GameEventSoundCueKind.city,
      unitIds: [producedUnitId],
      cityIds: [cityId],
      focusHints: [CityGameEventFocusHint(cityId)],
      activityCategories: const [GameEventActivityCategory.city],
      playerIdsResolver: _cityOwnerPlayerIds(cityId),
    ),
  CityClaimedHexEvent(:final cityId) => GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.city,
    rendererEffectKind: GameEventRendererEffectKind.cityClaimedHex,
    cityIds: [cityId],
    focusHints: [CityGameEventFocusHint(cityId)],
    activityCategories: const [GameEventActivityCategory.city],
    playerIdsResolver: _cityOwnerPlayerIds(cityId),
  ),
  UnitMovedEvent(:final unitId) => GameEventDescriptor._(
    activityWorthy: false,
    messageGroup: GameEventMessageGroup.unit,
    rendererEffectKind: GameEventRendererEffectKind.unitMoved,
    unitIds: [unitId],
    focusHints: [UnitGameEventFocusHint(unitId)],
    playerIdsResolver: _unitOwnerPlayerIds(unitId),
  ),
  FortifiedUnitThreatenedEvent(
    :final unitId,
    :final ownerPlayerId,
    :final targets,
  ) =>
    GameEventDescriptor._(
      activityWorthy: false,
      messageGroup: GameEventMessageGroup.unit,
      rendererEffectKind: GameEventRendererEffectKind.fortifiedUnitThreatened,
      unitIds: [unitId, for (final target in targets) target.unitId],
      focusHints: [UnitGameEventFocusHint(unitId)],
      playerIds: [ownerPlayerId],
      showAsTopNotification: false,
    ),
  UnitGainedExperienceEvent(:final unitId, :final ownerPlayerId) =>
    GameEventDescriptor._(
      activityWorthy: false,
      messageGroup: GameEventMessageGroup.unit,
      unitIds: [unitId],
      focusHints: [UnitGameEventFocusHint(unitId)],
      playerIds: [ownerPlayerId],
    ),
  UnitAttackedEvent(
    :final attackerUnitId,
    :final attackerOwnerPlayerId,
    :final defenderUnitId,
    :final defenderOwnerPlayerId,
  ) =>
    GameEventDescriptor._(
      activityWorthy: false,
      messageGroup: GameEventMessageGroup.combat,
      unitIds: [attackerUnitId, defenderUnitId],
      focusHints: [
        CityGameEventFocusHint(defenderUnitId),
        UnitGameEventFocusHint(attackerUnitId),
        UnitGameEventFocusHint(defenderUnitId),
      ],
      playerIds: [attackerOwnerPlayerId, defenderOwnerPlayerId],
    ),
  CityAttackedEvent(
    :final attackerUnitId,
    :final attackerOwnerPlayerId,
    :final cityId,
    :final cityOwnerPlayerId,
  ) =>
    GameEventDescriptor._(
      activityWorthy: false,
      messageGroup: GameEventMessageGroup.combat,
      unitIds: [attackerUnitId],
      cityIds: [cityId],
      focusHints: [
        CityGameEventFocusHint(cityId),
        UnitGameEventFocusHint(attackerUnitId),
      ],
      playerIds: [attackerOwnerPlayerId, cityOwnerPlayerId],
    ),
  CombatResolvedEvent(
    :final attackerUnitId,
    :final defenderUnitId,
    :final outcome,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.combat,
      rendererEffectKind: GameEventRendererEffectKind.combatResolved,
      soundCueKind: GameEventSoundCueKind.combat,
      unitIds: [attackerUnitId, defenderUnitId],
      cityIds: [defenderUnitId],
      focusHints: [
        CityGameEventFocusHint(defenderUnitId),
        UnitGameEventFocusHint(attackerUnitId),
        UnitGameEventFocusHint(defenderUnitId),
      ],
      activityCategories: const [GameEventActivityCategory.combat],
      notificationMaxDetailCount: 2,
      criticalNotificationResolver: (state, playerId) {
        return (outcome.attackerKilled &&
                _unitBelongsTo(state, outcome.attackerUnitId, playerId)) ||
            (outcome.defenderKilled &&
                _unitBelongsTo(state, outcome.defenderUnitId, playerId));
      },
      playerIdsResolver: _combatPlayerIds(
        attackerUnitId: attackerUnitId,
        defenderUnitId: defenderUnitId,
      ),
    ),
  UnitKilledEvent(:final unitId, :final ownerPlayerId, :final attackerUnitId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.combat,
      rendererEffectKind: GameEventRendererEffectKind.unitKilled,
      unitIds: [unitId, ?attackerUnitId],
      focusHints: [
        if (attackerUnitId != null) UnitGameEventFocusHint(attackerUnitId),
      ],
      activityCategories: const [GameEventActivityCategory.combat],
      criticalNotification: true,
      playerIdsResolver: _unitKilledPlayerIds(
        ownerPlayerId: ownerPlayerId,
        attackerUnitId: attackerUnitId,
      ),
    ),
  UnitRetreatedEvent(:final unitId, :final ownerPlayerId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.combat,
      rendererEffectKind: GameEventRendererEffectKind.unitRetreated,
      unitIds: [unitId],
      focusHints: [UnitGameEventFocusHint(unitId)],
      activityCategories: const [GameEventActivityCategory.combat],
      playerIds: [ownerPlayerId],
    ),
  CityCapturedEvent(
    :final cityId,
    :final previousOwnerPlayerId,
    :final newOwnerPlayerId,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.combat,
      soundCueKind: GameEventSoundCueKind.city,
      cityIds: [cityId],
      focusHints: [CityGameEventFocusHint(cityId)],
      activityCategories: const [GameEventActivityCategory.city],
      criticalNotification: true,
      playerIds: [previousOwnerPlayerId, newOwnerPlayerId],
    ),
  CityDestroyedEvent(
    :final cityId,
    :final previousOwnerPlayerId,
    :final attackerOwnerPlayerId,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.combat,
      cityIds: [cityId],
      criticalNotification: true,
      playerIds: [previousOwnerPlayerId, attackerOwnerPlayerId],
    ),
  TurnEndedEvent(:final playerId) => GameEventDescriptor._(
    activityWorthy: false,
    messageGroup: GameEventMessageGroup.turn,
    playerIds: [playerId],
  ),
  WorkerCompletedJobEvent(:final unitId) => GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.unit,
    rendererEffectKind: GameEventRendererEffectKind.workerCompletedJob,
    unitIds: [unitId],
    focusHints: [UnitGameEventFocusHint(unitId)],
    activityCategories: const [GameEventActivityCategory.city],
    completedWorkerUnitId: unitId,
    playerIdsResolver: _unitOwnerPlayerIds(unitId),
  ),
  DominationThresholdReachedEvent(:final playerId) => GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.turn,
    focusHints: [PlayerAnchorGameEventFocusHint(playerId)],
    criticalNotification: true,
    playerIdsResolver: _visiblePlayerAnd(playerId),
  ),
  StabilityBandChangedEvent(:final playerId, :final newBand) =>
    _stabilityBandDescriptor(playerId, newBand),
  ResearchPointsGainedEvent(:final playerId) => GameEventDescriptor._(
    activityWorthy: false,
    messageGroup: GameEventMessageGroup.research,
    playerIds: [playerId],
  ),
  TechnologyResearchedEvent(:final playerId) => GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.research,
    rendererEffectKind: GameEventRendererEffectKind.technologyResearched,
    focusHints: [PlayerAnchorGameEventFocusHint(playerId)],
    activityCategories: const [GameEventActivityCategory.technology],
    criticalNotification: true,
    playerIds: [playerId],
  ),
  StrategicResourceDiscoveredEvent(
    :final playerId,
    :final nearestUnclaimedCol,
    :final nearestUnclaimedRow,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.research,
      focusHints: nearestUnclaimedCol == null || nearestUnclaimedRow == null
          ? const []
          : [
              TileGameEventFocusHint(
                id: 'resource_${nearestUnclaimedCol}_$nearestUnclaimedRow',
                col: nearestUnclaimedCol,
                row: nearestUnclaimedRow,
              ),
            ],
      playerIds: [playerId],
    ),
  MapObjectiveSecuredEvent(
    :final playerId,
    :final objectiveId,
    :final col,
    :final row,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.objective,
      focusHints: [
        TileGameEventFocusHint(
          id: 'objective_$objectiveId',
          col: col,
          row: row,
        ),
      ],
      playerIds: [playerId],
    ),
  CivilizationMetEvent(:final playerId, :final metPlayerId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.diplomacy,
      focusHints: [PlayerAnchorGameEventFocusHint(metPlayerId)],
      activityCategories: const [GameEventActivityCategory.diplomacy],
      civilizationPlayerId: playerId,
      civilizationMetPlayerId: metPlayerId,
      criticalNotification: true,
      playerIds: [playerId],
    ),
  DiplomaticProposalSentEvent(
    :final proposalId,
    :final fromPlayerId,
    :final toPlayerId,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.diplomacy,
      activityCategories: const [GameEventActivityCategory.diplomacy],
      diplomaticProposalId: proposalId,
      diplomaticPopupRecipientPlayerId: toPlayerId,
      playerIds: [fromPlayerId, toPlayerId],
    ),
  DiplomaticProposalRespondedEvent(
    :final fromPlayerId,
    :final toPlayerId,
    :final accepted,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.diplomacy,
      activityCategories: const [GameEventActivityCategory.diplomacy],
      passiveDiplomaticPopup: true,
      diplomaticPopupTone: accepted
          ? GameEventDiplomaticPopupTone.positive
          : GameEventDiplomaticPopupTone.negative,
      playerIds: [fromPlayerId, toPlayerId],
    ),
  DiplomaticProposalExpiredEvent(:final fromPlayerId, :final toPlayerId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.diplomacy,
      activityCategories: const [GameEventActivityCategory.diplomacy],
      passiveDiplomaticPopup: true,
      diplomaticPopupTone: GameEventDiplomaticPopupTone.negative,
      playerIds: [fromPlayerId, toPlayerId],
    ),
  DiplomaticRelationChangedEvent(
    :final playerAId,
    :final playerBId,
    :final newStatus,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.diplomacy,
      activityCategories: const [GameEventActivityCategory.diplomacy],
      passiveDiplomaticPopup: true,
      diplomaticPopupTone: newStatus == DiplomaticRelationStatus.war
          ? GameEventDiplomaticPopupTone.negative
          : GameEventDiplomaticPopupTone.neutral,
      playerIds: [playerAId, playerBId],
    ),
  DiplomaticMessageSentEvent(
    :final messageId,
    :final fromPlayerId,
    :final toPlayerId,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.diplomacy,
      activityCategories: const [GameEventActivityCategory.diplomacy],
      diplomaticMessageId: messageId,
      diplomaticPopupRecipientPlayerId: toPlayerId,
      playerIds: [fromPlayerId, toPlayerId],
    ),
  DiplomaticMessageRespondedEvent(
    :final fromPlayerId,
    :final toPlayerId,
    :final relationDelta,
  ) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.diplomacy,
      activityCategories: const [GameEventActivityCategory.diplomacy],
      passiveDiplomaticPopup: true,
      diplomaticPopupTone: relationDelta >= 0
          ? GameEventDiplomaticPopupTone.positive
          : GameEventDiplomaticPopupTone.negative,
      playerIds: [fromPlayerId, toPlayerId],
    ),
  DiplomaticScoreChangedEvent(:final playerAId, :final playerBId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.diplomacy,
      activityCategories: const [GameEventActivityCategory.diplomacy],
      playerIds: [playerAId, playerBId],
    ),
  DiplomaticPromiseBrokenEvent(:final playerAId, :final playerBId) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.diplomacy,
      activityCategories: const [GameEventActivityCategory.diplomacy],
      passiveDiplomaticPopup: true,
      diplomaticPopupTone: GameEventDiplomaticPopupTone.negative,
      playerIds: [playerAId, playerBId],
    ),
  CommandRejectedEvent() => GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.system,
    playerIdsResolver: _visiblePlayer(),
  ),
  AllPlayersSubmittedEvent(:final turn, :final playerIds) =>
    GameEventDescriptor._(
      activityWorthy: true,
      messageGroup: GameEventMessageGroup.system,
      completedTurn: turn,
      showAsTopNotification: false,
      playerIds: playerIds,
    ),
  PlayerTimedOutEvent(:final playerId) => GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.system,
    playerIds: [playerId],
  ),
  TurnAutoResolvedEvent(:final playerId) => GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.system,
    playerIds: [playerId],
  ),
  PlayerKickedEvent(:final playerId) => GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.system,
    playerIds: [playerId],
  ),
};
