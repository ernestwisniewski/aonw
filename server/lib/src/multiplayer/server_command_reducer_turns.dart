part of 'server_command_reducer.dart';

extension ServerCommandReducerTurns on ServerCommandReducer {
  _CommandApplication _submitTurn({
    required CanonicalGameSnapshot snapshot,
    required WireMatch match,
    required SubmitTurnCommand command,
    required String actorPlayerId,
    required DateTime now,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    final session = snapshot.session;
    if (command.playerId != actorPlayerId) {
      return _CommandApplication.reject(
        snapshot: snapshot,
        reason: 'turn_player_not_controlled',
      );
    }
    final playerIds = _turnPlayerIds(snapshot);
    if (playerIds.isEmpty || !playerIds.contains(command.playerId)) {
      return _CommandApplication.reject(
        snapshot: snapshot,
        reason: 'turn_player_not_active',
      );
    }
    final alreadySubmitted = session.hasSubmitted(command.playerId);
    final submitted = {...session.submittedPlayerIds, command.playerId};
    final submittedSession = session.copyWith(submittedPlayerIds: submitted);
    final submittedSnapshot = snapshot.copyWith(session: submittedSession);
    final turnTimedOut = _turnTimedOut(snapshot, now);
    final waitingPlayerIds = _waitingPlayerIds(
      match: match,
      playerIds: playerIds,
      submittedPlayerIds: submitted,
      turnTimedOut: turnTimedOut,
    );
    if (waitingPlayerIds.isNotEmpty) {
      final turnStates = alreadySubmitted
          ? submittedSession.turnStatesByPlayerId
          : _finishedTurnStates(submittedSession, command.playerId);
      return _CommandApplication.accept(
        snapshot: submittedSnapshot.copyWith(
          session: identical(turnStates, submittedSession.turnStatesByPlayerId)
              ? submittedSession
              : submittedSession.copyWith(turnStatesByPlayerId: turnStates),
        ),
      );
    }
    final skippedPlayerIds = playerIds
        .where((playerId) => !submitted.contains(playerId))
        .toList();

    return _finalizeSimultaneousTurn(
      snapshot: submittedSnapshot,
      playerIds: playerIds,
      skippedPlayerIds: skippedPlayerIds,
      now: now,
      mapView: mapView,
      ruleset: ruleset,
    );
  }

  _CommandApplication _finalizeSimultaneousTurn({
    required CanonicalGameSnapshot snapshot,
    required List<String> playerIds,
    required List<String> skippedPlayerIds,
    required DateTime now,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    final result = CanonicalTurnPipeline.simultaneousFinalize(
      CanonicalTurnPipelineRequest.simultaneousFinalize(
        snapshot: snapshot,
        playerIds: playerIds,
        skippedPlayerIds: skippedPlayerIds,
        savedAt: now,
        mapView: mapView,
        ruleset: ruleset,
        preserveNonParticipantPlayerStates: true,
        trackTimeoutStreaks: true,
      ),
    );
    return _CommandApplication.accept(
      snapshot: result.snapshot,
      events: result.events,
      movementExecutions: result.movementDelta.executions,
    );
  }

  List<String> _turnPlayerIds(CanonicalGameSnapshot snapshot) {
    final kickedPlayerIds = snapshot.session.kickedPlayerIds;
    final ids = snapshot.domain.participants
        .map((player) => player.id)
        .where((id) => id.isNotEmpty && !kickedPlayerIds.contains(id))
        .toList();
    if (ids.isNotEmpty) return ids..sort();
    return snapshot.session.turnStatesByPlayerId.keys
        .where((id) => id.isNotEmpty && !kickedPlayerIds.contains(id))
        .toList()
      ..sort();
  }

  bool _turnTimedOut(CanonicalGameSnapshot snapshot, DateTime now) {
    final turnStartedAt =
        snapshot.session.turnStartedAt ?? snapshot.metadata.savedAtUtc;
    final deadline = turnStartedAt.toUtc().add(_turnTimeout);
    return !now.toUtc().isBefore(deadline);
  }

  List<String> _waitingPlayerIds({
    required WireMatch match,
    required List<String> playerIds,
    required Set<String> submittedPlayerIds,
    required bool turnTimedOut,
  }) {
    if (turnTimedOut) return const [];
    final wirePlayersById = {
      for (final player in match.players) player.id: player,
    };
    return [
      for (final playerId in playerIds)
        if (!submittedPlayerIds.contains(playerId) &&
            _requiresTurnSubmission(wirePlayersById[playerId]))
          playerId,
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

Map<String, PlayerTurnState> _finishedTurnStates(
  MatchSessionState session,
  String playerId,
) {
  if (!session.turnStatesByPlayerId.containsKey(playerId)) {
    return session.turnStatesByPlayerId;
  }
  return Map.unmodifiable({
    ...session.turnStatesByPlayerId,
    playerId: PlayerTurnState.finished,
  });
}
