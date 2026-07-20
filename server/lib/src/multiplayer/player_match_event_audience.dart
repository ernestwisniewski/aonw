import 'package:aonw_core/game/domain/event.dart';

/// Server-owned recipient metadata embedded only in canonical event storage.
///
/// The metadata is intentionally not part of the public event codec. A
/// projected payload is always parsed and serialized again, which strips this
/// field and any other unrecognized fields before data crosses the network.
abstract final class PlayerMatchEventAudience {
  static const _audiencePlayerIdsKey = '_serverAudiencePlayerIds';

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
  }) {
    final participants =
        participantPlayerIds
            .where((playerId) => playerId.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return List.unmodifiable([
      for (final event in events)
        {
          ...GameEventSerializer.toJson(event),
          _audiencePlayerIdsKey: [
            for (final playerId in participants)
              if (_isVisibleTo(
                event,
                playerId: playerId,
                previous: previous,
                next: next,
              ))
                playerId,
          ],
        },
    ]);
  }

  /// Returns a canonical, metadata-free payload for [recipientPlayerId].
  ///
  /// Legacy rows without server-owned audience metadata are deliberately
  /// redacted. Malformed metadata fails projection instead of being treated as
  /// public data.
  static List<Map<String, dynamic>> projectForRecipient(
    Iterable<Map<String, dynamic>> canonicalEvents, {
    required String recipientPlayerId,
  }) {
    final projected = <Map<String, dynamic>>[];
    for (final canonical in canonicalEvents) {
      final rawAudience = canonical[_audiencePlayerIdsKey];
      if (rawAudience == null) continue;
      if (rawAudience is! List<Object?> ||
          rawAudience.any((playerId) => playerId is! String)) {
        throw const FormatException(
          'Invalid server-owned multiplayer event audience metadata.',
        );
      }
      if (!rawAudience.contains(recipientPlayerId)) continue;
      final domainEvent = GameEventSerializer.fromJson(canonical);
      projected.add(GameEventSerializer.toJson(domainEvent));
    }
    return List.unmodifiable(projected);
  }

  static bool _isVisibleTo(
    GameEvent event, {
    required String playerId,
    required GameEventOwnershipIndex previous,
    required GameEventOwnershipIndex next,
  }) {
    final descriptor = GameEventDomainDescriptor.forEvent(event);
    return descriptor.isVisibleToPlayer(
      playerId: playerId,
      previous: previous,
      next: next,
    );
  }
}
