/// Selects the technical actor used to advance an expired simultaneous turn.
///
/// Participant order is authoritative. Submitted players take precedence over
/// the fallback pass, while empty, duplicate, and kicked identifiers are
/// ignored without mutating the supplied collections.
abstract final class TimeoutActorSelector {
  static String? select({
    required Iterable<String> orderedParticipantPlayerIds,
    required Set<String> submittedPlayerIds,
    required Set<String> kickedPlayerIds,
  }) {
    final eligiblePlayerIds = <String>[];
    final seenPlayerIds = <String>{};
    for (final playerId in orderedParticipantPlayerIds) {
      if (playerId.isEmpty ||
          !seenPlayerIds.add(playerId) ||
          kickedPlayerIds.contains(playerId)) {
        continue;
      }
      eligiblePlayerIds.add(playerId);
    }

    for (final playerId in eligiblePlayerIds) {
      if (submittedPlayerIds.contains(playerId)) return playerId;
    }
    return eligiblePlayerIds.isEmpty ? null : eligiblePlayerIds.first;
  }
}
