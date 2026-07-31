import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/event/game_event_ownership_index.dart';
import 'package:aonw_core/game/domain/hex.dart';

part 'fortification_event_domain_descriptor.dart';

final class GameEventHostility {
  const GameEventHostility({
    required this.victimPlayerId,
    required this.hostilePlayerId,
  });

  final String victimPlayerId;
  final String hostilePlayerId;
}

/// The public endpoints of one movement event, without exposing its route.
final class GameEventCoarseMovement {
  const GameEventCoarseMovement({
    required this.origin,
    required this.destination,
  });

  final HexCoordinate origin;
  final HexCoordinate destination;

  @override
  bool operator ==(Object other) =>
      other is GameEventCoarseMovement &&
      other.origin == origin &&
      other.destination == destination;

  @override
  int get hashCode => Object.hash(origin, destination);
}

final class GameEventDomainDescriptor {
  GameEventDomainDescriptor._({
    this.combat = false,
    Iterable<String> playerIds = const [],
    Iterable<String> unitIds = const [],
    Iterable<String> cityIds = const [],
    Iterable<GameEventHostility> hostilities = const [],
    Iterable<String> attackingPlayerIds = const [],
    Iterable<String> citiesLostPlayerIds = const [],
    Iterable<String> signedPeacePlayerIds = const [],
    this.actorHostilityVictimPlayerId,
    this.coarseMovement,
    Iterable<String>? visiblePlayerIds,
    this.visibleToAllPlayers = false,
  }) : playerIds = Set.unmodifiable(playerIds),
       unitIds = Set.unmodifiable(unitIds),
       cityIds = Set.unmodifiable(cityIds),
       hostilities = List.unmodifiable(hostilities),
       attackingPlayerIds = List.unmodifiable(attackingPlayerIds),
       citiesLostPlayerIds = List.unmodifiable(citiesLostPlayerIds),
       signedPeacePlayerIds = Set.unmodifiable(signedPeacePlayerIds),
       _visiblePlayerIds = visiblePlayerIds == null
           ? null
           : Set.unmodifiable(visiblePlayerIds);

  factory GameEventDomainDescriptor.forEvent(GameEvent event) {
    final unitPresentation = unitPresentationEventDomainDescriptor(event);
    if (unitPresentation != null) return unitPresentation;
    return switch (event) {
      CityFoundedEvent(:final ownerPlayerId) => GameEventDomainDescriptor._(
        playerIds: [ownerPlayerId],
      ),
      CityBuiltBuildingEvent(:final cityId) => GameEventDomainDescriptor._(
        cityIds: [cityId],
      ),
      CityBuiltWonderEvent(:final ownerPlayerId) => GameEventDomainDescriptor._(
        playerIds: [ownerPlayerId],
      ),
      WonderProductionRefundedEvent(:final ownerPlayerId) =>
        GameEventDomainDescriptor._(playerIds: [ownerPlayerId]),
      CityProducedUnitEvent(:final cityId, :final producedUnitId) =>
        GameEventDomainDescriptor._(
          cityIds: [cityId],
          unitIds: [producedUnitId],
        ),
      CityClaimedHexEvent() ||
      ArtifactLifecycleEvent() => _artifactLifecycleDescriptor(event),
      TechnologyResearchedEvent(:final playerId) => GameEventDomainDescriptor._(
        playerIds: [playerId],
      ),
      ResearchPointsGainedEvent(:final playerId) => GameEventDomainDescriptor._(
        playerIds: [playerId],
      ),
      StrategicResourceDiscoveredEvent(:final playerId) =>
        GameEventDomainDescriptor._(playerIds: [playerId]),
      MapObjectiveSecuredEvent(:final playerId) => GameEventDomainDescriptor._(
        playerIds: [playerId],
      ),
      UnitPresentationEvent() => throw StateError(
        'Unit presentation event was not delegated.',
      ),
      UnitAttackedEvent(
        :final attackerOwnerPlayerId,
        :final defenderOwnerPlayerId,
      ) =>
        GameEventDomainDescriptor._(
          combat: true,
          playerIds: [attackerOwnerPlayerId, defenderOwnerPlayerId],
          hostilities: [
            GameEventHostility(
              victimPlayerId: defenderOwnerPlayerId,
              hostilePlayerId: attackerOwnerPlayerId,
            ),
          ],
          attackingPlayerIds: [attackerOwnerPlayerId],
        ),
      CityAttackedEvent(
        :final attackerOwnerPlayerId,
        :final cityOwnerPlayerId,
      ) =>
        GameEventDomainDescriptor._(
          combat: true,
          playerIds: [attackerOwnerPlayerId, cityOwnerPlayerId],
          attackingPlayerIds: [attackerOwnerPlayerId],
        ),
      CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId) =>
        GameEventDomainDescriptor._(
          combat: true,
          unitIds: [attackerUnitId, defenderUnitId],
          cityIds: [defenderUnitId],
        ),
      UnitKilledEvent(:final ownerPlayerId, :final attackerUnitId) =>
        GameEventDomainDescriptor._(
          combat: true,
          playerIds: [ownerPlayerId],
          unitIds: [?attackerUnitId],
          // City bombardment reuses attackerUnitId for the attacking city.
          cityIds: [?attackerUnitId],
          actorHostilityVictimPlayerId: ownerPlayerId,
        ),
      UnitRetreatedEvent(:final ownerPlayerId) => GameEventDomainDescriptor._(
        playerIds: [ownerPlayerId],
      ),
      CityCapturedEvent(
        :final previousOwnerPlayerId,
        :final newOwnerPlayerId,
      ) =>
        GameEventDomainDescriptor._(
          combat: true,
          playerIds: [previousOwnerPlayerId, newOwnerPlayerId],
          hostilities: [
            GameEventHostility(
              victimPlayerId: previousOwnerPlayerId,
              hostilePlayerId: newOwnerPlayerId,
            ),
          ],
          citiesLostPlayerIds: [previousOwnerPlayerId],
        ),
      CityDestroyedEvent(
        :final previousOwnerPlayerId,
        :final attackerOwnerPlayerId,
      ) =>
        GameEventDomainDescriptor._(
          combat: true,
          playerIds: [previousOwnerPlayerId, attackerOwnerPlayerId],
          hostilities: [
            GameEventHostility(
              victimPlayerId: previousOwnerPlayerId,
              hostilePlayerId: attackerOwnerPlayerId,
            ),
          ],
          citiesLostPlayerIds: [previousOwnerPlayerId],
        ),
      TurnEndedEvent(:final playerId) => GameEventDomainDescriptor._(
        playerIds: [playerId],
      ),
      WorkerCompletedJobEvent(:final unitId) => GameEventDomainDescriptor._(
        unitIds: [unitId],
      ),
      DominationThresholdReachedEvent(:final playerId) =>
        GameEventDomainDescriptor._(
          playerIds: [playerId],
          visibleToAllPlayers: true,
        ),
      StabilityBandChangedEvent(:final playerId) => GameEventDomainDescriptor._(
        playerIds: [playerId],
      ),
      CivilizationMetEvent(:final playerId, :final metPlayerId) =>
        GameEventDomainDescriptor._(
          playerIds: [playerId, metPlayerId],
          // A CivilizationMet event is authored from one player's point of
          // view. The counterpart receives its own event when appropriate.
          visiblePlayerIds: [playerId],
        ),
      DiplomaticProposalSentEvent(:final fromPlayerId, :final toPlayerId) =>
        GameEventDomainDescriptor._(playerIds: [fromPlayerId, toPlayerId]),
      DiplomaticProposalRespondedEvent(
        :final fromPlayerId,
        :final toPlayerId,
        :final kind,
        :final accepted,
      ) =>
        _proposalResponseDescriptor(
          fromPlayerId: fromPlayerId,
          toPlayerId: toPlayerId,
          kind: kind,
          accepted: accepted,
        ),
      DiplomaticProposalExpiredEvent(:final fromPlayerId, :final toPlayerId) =>
        GameEventDomainDescriptor._(playerIds: [fromPlayerId, toPlayerId]),
      DiplomaticRelationChangedEvent(
        :final playerAId,
        :final playerBId,
        :final oldStatus,
        :final newStatus,
      ) =>
        GameEventDomainDescriptor._(
          playerIds: [playerAId, playerBId],
          hostilities: newStatus == DiplomaticRelationStatus.war
              ? [
                  GameEventHostility(
                    victimPlayerId: playerAId,
                    hostilePlayerId: playerBId,
                  ),
                  GameEventHostility(
                    victimPlayerId: playerBId,
                    hostilePlayerId: playerAId,
                  ),
                ]
              : const [],
          signedPeacePlayerIds:
              oldStatus == DiplomaticRelationStatus.war &&
                  newStatus != DiplomaticRelationStatus.war
              ? [playerAId, playerBId]
              : const [],
        ),
      DiplomaticMessageSentEvent(:final fromPlayerId, :final toPlayerId) =>
        GameEventDomainDescriptor._(playerIds: [fromPlayerId, toPlayerId]),
      DiplomaticMessageRespondedEvent(:final fromPlayerId, :final toPlayerId) =>
        GameEventDomainDescriptor._(playerIds: [fromPlayerId, toPlayerId]),
      DiplomaticScoreChangedEvent(:final playerAId, :final playerBId) =>
        GameEventDomainDescriptor._(playerIds: [playerAId, playerBId]),
      DiplomaticPromiseBrokenEvent(:final playerAId, :final playerBId) =>
        GameEventDomainDescriptor._(playerIds: [playerAId, playerBId]),
      PlayerTimedOutEvent(:final playerId) => GameEventDomainDescriptor._(
        playerIds: [playerId],
      ),
      TurnAutoResolvedEvent(:final playerId) => GameEventDomainDescriptor._(
        playerIds: [playerId],
      ),
      PlayerKickedEvent(:final playerId) => GameEventDomainDescriptor._(
        playerIds: [playerId],
      ),
      AllPlayersSubmittedEvent() => GameEventDomainDescriptor._(
        visibleToAllPlayers: true,
      ),
      CommandRejectedEvent() => GameEventDomainDescriptor._(
        visiblePlayerIds: const [],
      ),
    };
  }

  final bool combat;
  final Set<String> playerIds;
  final Set<String> unitIds;
  final Set<String> cityIds;
  final List<GameEventHostility> hostilities;
  final List<String> attackingPlayerIds;
  final List<String> citiesLostPlayerIds;
  final Set<String> signedPeacePlayerIds;
  final String? actorHostilityVictimPlayerId;
  final GameEventCoarseMovement? coarseMovement;
  final Set<String>? _visiblePlayerIds;
  final bool visibleToAllPlayers;

  /// Whether this domain event may cross a per-player network boundary.
  ///
  /// Explicit visibility overrides are used for asymmetric and system
  /// events. All other known events inherit their domain ownership rules.
  /// Unknown event types are fail-closed because their descriptor owns no
  /// players.
  bool isVisibleToPlayer({
    required String playerId,
    required GameEventOwnershipIndex previous,
    required GameEventOwnershipIndex next,
  }) {
    if (visibleToAllPlayers) return true;
    final visiblePlayerIds = _visiblePlayerIds;
    if (visiblePlayerIds != null) return visiblePlayerIds.contains(playerId);
    return belongsToPlayer(playerId: playerId, previous: previous, next: next);
  }

  bool belongsToPlayer({
    required String playerId,
    required GameEventOwnershipIndex previous,
    required GameEventOwnershipIndex next,
  }) {
    if (playerIds.contains(playerId)) return true;
    for (final unitId in unitIds) {
      if (next.unitOwner(unitId) == playerId ||
          previous.unitOwner(unitId) == playerId) {
        return true;
      }
    }
    for (final cityId in cityIds) {
      if (next.cityOwner(cityId) == playerId ||
          previous.cityOwner(cityId) == playerId) {
        return true;
      }
    }
    return false;
  }

  String? hostilePlayerIdFor({
    required String playerId,
    String? actorPlayerId,
  }) {
    for (final hostility in hostilities) {
      if (hostility.victimPlayerId == playerId) {
        return hostility.hostilePlayerId;
      }
    }
    if (actorHostilityVictimPlayerId == playerId &&
        actorPlayerId?.isNotEmpty == true) {
      return actorPlayerId;
    }
    return null;
  }
}

GameEventDomainDescriptor _proposalResponseDescriptor({
  required String fromPlayerId,
  required String toPlayerId,
  required DiplomaticProposalKind kind,
  required bool accepted,
}) {
  return GameEventDomainDescriptor._(
    playerIds: [fromPlayerId, toPlayerId],
    signedPeacePlayerIds: kind == DiplomaticProposalKind.truce && accepted
        ? [fromPlayerId, toPlayerId]
        : const [],
  );
}

GameEventDomainDescriptor _artifactLifecycleDescriptor(GameEvent event) {
  return switch (event) {
    CityClaimedHexEvent(:final cityId) => GameEventDomainDescriptor._(
      cityIds: [cityId],
    ),
    ArtifactLifecycleEvent() => GameEventDomainDescriptor._(
      playerIds: [event.ownerPlayerId],
      unitIds: [?event.unitId],
      cityIds: [if (event case ArtifactStoredEvent(:final cityId)) cityId],
    ),
    _ => throw StateError('Unsupported delegated event: $event'),
  };
}
