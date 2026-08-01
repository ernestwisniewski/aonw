part of 'server_command_reducer.dart';

extension ServerCommandReducerTurns on ServerCommandReducer {
  List<String> _turnPlayerIds(CanonicalGameSnapshot snapshot) {
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

  bool _turnTimedOut(CanonicalGameSnapshot snapshot, DateTime now) {
    final turnStartedAt =
        snapshot.domain.turnStartedAt ?? snapshot.metadata.savedAtUtc;
    final deadline = turnStartedAt.toUtc().add(_turnTimeout);
    return !now.toUtc().isBefore(deadline);
  }

  List<String> _requiredTurnSubmissionPlayerIds({
    required WireMatch match,
    required List<String> playerIds,
  }) {
    final wirePlayersById = {
      for (final player in match.players) player.id: player,
    };
    return [
      for (final playerId in playerIds)
        if (_requiresTurnSubmission(wirePlayersById[playerId])) playerId,
    ];
  }

  bool _requiresTurnSubmission(WirePlayer? player) {
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
