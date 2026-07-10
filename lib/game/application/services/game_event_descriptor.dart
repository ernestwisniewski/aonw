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

typedef _GameEventPlayerIdsResolver =
    List<String> Function(
      GameState state,
      GameState? previousState,
      String? visiblePlayerId,
    );

final class GameEventDescriptor {
  GameEventDescriptor._({
    required this.activityWorthy,
    required this.messageGroup,
    this.rendererEffectKind = GameEventRendererEffectKind.none,
    this.soundCueKind = GameEventSoundCueKind.none,
    Iterable<String> unitIds = const [],
    Iterable<String> cityIds = const [],
    Iterable<GameEventFocusHint> focusHints = const [],
    Iterable<String?> playerIds = const [],
    _GameEventPlayerIdsResolver? playerIdsResolver,
  }) : unitIds = Set.unmodifiable(unitIds),
       cityIds = Set.unmodifiable(cityIds),
       focusHints = List.unmodifiable(focusHints),
       _playerIds = List.unmodifiable(playerIds),
       _playerIdsResolver = playerIdsResolver;

  factory GameEventDescriptor.forEvent(GameEvent event) {
    return switch (event) {
      CityFoundedEvent(:final cityId, :final ownerPlayerId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.city,
          rendererEffectKind: GameEventRendererEffectKind.cityFounded,
          soundCueKind: GameEventSoundCueKind.city,
          cityIds: [cityId],
          focusHints: [CityGameEventFocusHint(cityId)],
          playerIds: [ownerPlayerId],
        ),
      CityBuiltBuildingEvent(:final cityId) => GameEventDescriptor._(
        activityWorthy: true,
        messageGroup: GameEventMessageGroup.city,
        soundCueKind: GameEventSoundCueKind.city,
        cityIds: [cityId],
        focusHints: [CityGameEventFocusHint(cityId)],
        playerIdsResolver: _cityOwnerPlayerIds(cityId),
      ),
      CityBuiltWonderEvent(:final cityId, :final ownerPlayerId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.city,
          soundCueKind: GameEventSoundCueKind.city,
          cityIds: [cityId],
          focusHints: [CityGameEventFocusHint(cityId)],
          playerIds: [ownerPlayerId],
        ),
      WonderProductionRefundedEvent(:final cityId, :final ownerPlayerId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.city,
          cityIds: [cityId],
          focusHints: [CityGameEventFocusHint(cityId)],
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
          playerIdsResolver: _cityOwnerPlayerIds(cityId),
        ),
      CityClaimedHexEvent(:final cityId) => GameEventDescriptor._(
        activityWorthy: true,
        messageGroup: GameEventMessageGroup.city,
        rendererEffectKind: GameEventRendererEffectKind.cityClaimedHex,
        cityIds: [cityId],
        focusHints: [CityGameEventFocusHint(cityId)],
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
      CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId) =>
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
          playerIdsResolver: _combatPlayerIds(
            attackerUnitId: attackerUnitId,
            defenderUnitId: defenderUnitId,
          ),
        ),
      UnitKilledEvent(
        :final unitId,
        :final ownerPlayerId,
        :final attackerUnitId,
      ) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.combat,
          rendererEffectKind: GameEventRendererEffectKind.unitKilled,
          unitIds: [unitId, ?attackerUnitId],
          focusHints: [
            if (attackerUnitId != null) UnitGameEventFocusHint(attackerUnitId),
          ],
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
        playerIdsResolver: _unitOwnerPlayerIds(unitId),
      ),
      DominationThresholdReachedEvent(:final playerId) => GameEventDescriptor._(
        activityWorthy: true,
        messageGroup: GameEventMessageGroup.turn,
        focusHints: [PlayerAnchorGameEventFocusHint(playerId)],
        playerIdsResolver: _visiblePlayerAnd(playerId),
      ),
      StabilityBandChangedEvent(:final playerId) => GameEventDescriptor._(
        activityWorthy: true,
        messageGroup: GameEventMessageGroup.turn,
        playerIds: [playerId],
      ),
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
          playerIds: [playerId],
        ),
      DiplomaticProposalSentEvent(:final fromPlayerId, :final toPlayerId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.diplomacy,
          playerIds: [fromPlayerId, toPlayerId],
        ),
      DiplomaticProposalRespondedEvent(
        :final fromPlayerId,
        :final toPlayerId,
      ) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.diplomacy,
          playerIds: [fromPlayerId, toPlayerId],
        ),
      DiplomaticProposalExpiredEvent(:final fromPlayerId, :final toPlayerId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.diplomacy,
          playerIds: [fromPlayerId, toPlayerId],
        ),
      DiplomaticRelationChangedEvent(:final playerAId, :final playerBId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.diplomacy,
          playerIds: [playerAId, playerBId],
        ),
      DiplomaticMessageSentEvent(:final fromPlayerId, :final toPlayerId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.diplomacy,
          playerIds: [fromPlayerId, toPlayerId],
        ),
      DiplomaticMessageRespondedEvent(:final fromPlayerId, :final toPlayerId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.diplomacy,
          playerIds: [fromPlayerId, toPlayerId],
        ),
      DiplomaticScoreChangedEvent(:final playerAId, :final playerBId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.diplomacy,
          playerIds: [playerAId, playerBId],
        ),
      DiplomaticPromiseBrokenEvent(:final playerAId, :final playerBId) =>
        GameEventDescriptor._(
          activityWorthy: true,
          messageGroup: GameEventMessageGroup.diplomacy,
          playerIds: [playerAId, playerBId],
        ),
      CommandRejectedEvent() => GameEventDescriptor._(
        activityWorthy: true,
        messageGroup: GameEventMessageGroup.system,
      ),
      AllPlayersSubmittedEvent() => GameEventDescriptor._(
        activityWorthy: true,
        messageGroup: GameEventMessageGroup.system,
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
  }

  final bool activityWorthy;
  final GameEventMessageGroup messageGroup;
  final GameEventRendererEffectKind rendererEffectKind;
  final GameEventSoundCueKind soundCueKind;
  final Set<String> unitIds;
  final Set<String> cityIds;
  final List<GameEventFocusHint> focusHints;
  final List<String?> _playerIds;
  final _GameEventPlayerIdsResolver? _playerIdsResolver;

  List<String> playerIdsFor({
    required GameState state,
    GameState? previousState,
    String? visiblePlayerId,
  }) {
    return _playerIdsResolver?.call(state, previousState, visiblePlayerId) ??
        _orderedPlayerIds(_playerIds);
  }
}
