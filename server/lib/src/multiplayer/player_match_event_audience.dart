import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';

import 'package:aonw_server/src/multiplayer/player_match_movement_audience.dart';

/// Server-owned recipient metadata embedded only in canonical event storage.
///
/// The metadata is intentionally not part of the public event codec. A
/// projected payload is always parsed and serialized again, which strips this
/// field and any other unrecognized fields before data crosses the network.
abstract final class PlayerMatchEventAudience {
  static const _audiencePlayerIdsKey = '_serverAudiencePlayerIds';
  static const _combatAnimationKey = '_serverCombatAnimation';

  /// Serializes domain events with the exact set of match participants allowed
  /// to receive each payload.
  ///
  /// Both ownership indexes are required because a transition can remove or
  /// transfer an entity (for example, a killed unit or captured city).
  /// Computing history visibility from the latest snapshot would otherwise
  /// assign an old event to the wrong owner.
  static List<Map<String, dynamic>> annotateForStorage({
    required Iterable<GameEvent> events,
    required Iterable<String> participantPlayerIds,
    required GameEventOwnershipIndex previous,
    required GameEventOwnershipIndex next,
    Iterable<CombatAnimationFact> combatAnimations = const [],
    FogOfWarState previousFog = FogOfWarState.empty,
    FogOfWarState nextFog = FogOfWarState.empty,
  }) {
    final orderedEvents = List<GameEvent>.unmodifiable(events);
    final participants =
        participantPlayerIds
            .where((playerId) => playerId.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final combat = _reviewCombat(
      events: orderedEvents,
      facts: combatAnimations,
      participants: participants,
      previous: previous,
      next: next,
      previousFog: previousFog,
      nextFog: nextFog,
    );
    return List.unmodifiable([
      for (var eventIndex = 0; eventIndex < orderedEvents.length; eventIndex++)
        {
          ...GameEventSerializer.toJson(orderedEvents[eventIndex]),
          _audiencePlayerIdsKey: [
            for (final playerId in participants)
              if (combat.audience.contains(playerId) ||
                  _isVisibleTo(
                    orderedEvents[eventIndex],
                    playerId: playerId,
                    previous: previous,
                    next: next,
                    previousFog: previousFog,
                    nextFog: nextFog,
                  ))
                playerId,
          ],
          if (combat.fact?.eventIndex == eventIndex)
            _combatAnimationKey: CombatAnimationFactCodec.toJson(combat.fact!),
        },
    ]);
  }

  /// Returns a canonical, metadata-free payload for [recipientPlayerId].
  ///
  /// Rows without server-owned audience metadata are deliberately
  /// redacted. Malformed metadata fails projection instead of being treated as
  /// public data.
  static List<Map<String, dynamic>> projectForRecipient(
    Iterable<Map<String, dynamic>> canonicalEvents, {
    required String recipientPlayerId,
  }) {
    final projected = <Map<String, dynamic>>[];
    var canonicalEventIndex = 0;
    for (final canonical in canonicalEvents) {
      final rawAudience = canonical[_audiencePlayerIdsKey];
      if (rawAudience == null) {
        canonicalEventIndex += 1;
        continue;
      }
      if (rawAudience is! List<Object?> ||
          rawAudience.any((playerId) => playerId is! String)) {
        throw const FormatException(
          'Invalid server-owned multiplayer event audience metadata.',
        );
      }
      if (!rawAudience.contains(recipientPlayerId)) {
        canonicalEventIndex += 1;
        continue;
      }
      final domainEvent = GameEventSerializer.fromJson(canonical);
      final payload = GameEventSerializer.toJson(domainEvent);
      final rawCombat = canonical[_combatAnimationKey];
      if (rawCombat != null) {
        final fact = CombatAnimationFactCodec.fromJson(
          rawCombat,
          eventIndex: canonicalEventIndex,
        );
        payload[CombatAnimationFactCodec.eventPayloadKey] =
            CombatAnimationFactCodec.toJson(fact);
      }
      projected.add(payload);
      canonicalEventIndex += 1;
    }
    return List.unmodifiable(projected);
  }

  static bool _isVisibleTo(
    GameEvent event, {
    required String playerId,
    required GameEventOwnershipIndex previous,
    required GameEventOwnershipIndex next,
    required FogOfWarState previousFog,
    required FogOfWarState nextFog,
  }) {
    final descriptor = GameEventDomainDescriptor.forEvent(event);
    if (descriptor.isVisibleToPlayer(
      playerId: playerId,
      previous: previous,
      next: next,
    )) {
      return true;
    }
    final coarseMovement = descriptor.coarseMovement;
    return coarseMovement != null &&
        PlayerMatchMovementAudience.canObserveCoarseMovement(
          playerId: playerId,
          origin: coarseMovement.origin,
          destination: coarseMovement.destination,
          previousFog: previousFog,
          nextFog: nextFog,
        );
  }
}

({CombatAnimationFact? fact, Set<String> audience}) _reviewCombat({
  required List<GameEvent> events,
  required Iterable<CombatAnimationFact> facts,
  required List<String> participants,
  required GameEventOwnershipIndex previous,
  required GameEventOwnershipIndex next,
  required FogOfWarState previousFog,
  required FogOfWarState nextFog,
}) {
  final fact = _validatedCombatFact(events, facts);
  if (fact == null) return (fact: null, audience: const {});
  final owners = {
    previous.unitOwner(fact.attackerUnitId),
    next.unitOwner(fact.attackerUnitId),
    previous.unitOwner(fact.defenderId),
    next.unitOwner(fact.defenderId),
    previous.cityOwner(fact.defenderId),
    next.cityOwner(fact.defenderId),
  }..removeWhere((playerId) => playerId == null || playerId.isEmpty);
  final origin = HexCoordinate(
    col: fact.attackerFromCol,
    row: fact.attackerFromRow,
  );
  final target = HexCoordinate(
    col: fact.attackerToCol,
    row: fact.attackerToRow,
  );
  final audience = {
    for (final playerId in participants)
      if (owners.contains(playerId) ||
          _canSeeCombat(
            playerId,
            origin: origin,
            target: target,
            previousFog: previousFog,
            nextFog: nextFog,
          ))
        playerId,
  };
  return (fact: fact, audience: Set.unmodifiable(audience));
}

CombatAnimationFact? _validatedCombatFact(
  List<GameEvent> events,
  Iterable<CombatAnimationFact> facts,
) {
  final ordered = List<CombatAnimationFact>.unmodifiable(facts);
  if (ordered.isEmpty) return null;
  if (ordered.length != 1) {
    throw const FormatException(
      'A stored command may expose exactly one combat animation fact.',
    );
  }
  final fact = ordered.single;
  if (fact.eventIndex < 0 || fact.eventIndex >= events.length) {
    throw const FormatException(
      'Combat animation fact references an invalid event index.',
    );
  }
  final event = events[fact.eventIndex];
  if (event is! CombatResolvedEvent ||
      event.attackerUnitId != fact.attackerUnitId ||
      event.defenderUnitId != fact.defenderId) {
    throw const FormatException(
      'Combat animation fact does not match its combat event.',
    );
  }
  return fact;
}

bool _canSeeCombat(
  String playerId, {
  required HexCoordinate origin,
  required HexCoordinate target,
  required FogOfWarState previousFog,
  required FogOfWarState nextFog,
}) {
  final visibleBefore =
      previousFog.isVisible(playerId, origin) &&
      previousFog.isVisible(playerId, target);
  final visibleAfter =
      nextFog.isVisible(playerId, origin) &&
      nextFog.isVisible(playerId, target);
  return visibleBefore || visibleAfter;
}
