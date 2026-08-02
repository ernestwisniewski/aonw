import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

/// Owns multiplayer turn membership, timeout, and submission policy.
final class ServerTurnPolicy {
  const ServerTurnPolicy(this.turnTimeout);

  final Duration turnTimeout;

  List<String> playerIds(CanonicalGameSnapshot snapshot) {
    final kickedPlayerIds = snapshot.domain.kickedPlayerIds;
    final ids = snapshot.domain.participants
        .map((player) => player.id)
        .where((id) => id.isNotEmpty && !kickedPlayerIds.contains(id))
        .toList();
    if (ids.isNotEmpty) return ids;
    return snapshot.domain.turnStatesByPlayerId.keys
        .where((id) => id.isNotEmpty && !kickedPlayerIds.contains(id))
        .toList();
  }

  bool hasTimedOut(CanonicalGameSnapshot snapshot, DateTime now) {
    final turnStartedAt =
        snapshot.domain.turnStartedAt ?? snapshot.metadata.savedAtUtc;
    final deadline = turnStartedAt.toUtc().add(turnTimeout);
    return !now.toUtc().isBefore(deadline);
  }

  List<String> requiredSubmissionPlayerIds({
    required WireMatch match,
    required List<String> playerIds,
  }) {
    final wirePlayersById = {
      for (final player in match.players) player.id: player,
    };
    return [
      for (final playerId in playerIds)
        if (_requiresSubmission(wirePlayersById[playerId])) playerId,
    ];
  }

  bool _requiresSubmission(WirePlayer? player) {
    if (player == null) return true;
    if (player.kind == WirePlayerKind.ai) return false;
    return switch (player.connectionState) {
      WirePlayerConnectionState.connected ||
      WirePlayerConnectionState.connecting ||
      WirePlayerConnectionState.reconnecting => true,
      WirePlayerConnectionState.offline => false,
    };
  }
}
