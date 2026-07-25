part of 'server_command_reducer.dart';

const _legacyGameSnapshotAdapter = LegacyGameSnapshotAdapter();

CanonicalGameSnapshot _canonicalSnapshot({
  required GameSave save,
  required PersistentGameState state,
  required int eventLogOffset,
}) {
  return _legacyGameSnapshotAdapter.toCanonical(
    save: save,
    state: state,
    eventLogOffset: eventLogOffset,
  );
}

extension ServerCommandReducerTurns on ServerCommandReducer {
  _CommandApplication _submitTurn({
    required DecodedMatchSnapshot decodedSnapshot,
    required WireMatch match,
    required SubmitTurnCommand command,
    required String actorPlayerId,
    required DateTime now,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    final save = decodedSnapshot.save;
    final state = decodedSnapshot.state;
    if (command.playerId != actorPlayerId) {
      return _CommandApplication.reject(
        save: save,
        state: state,
        reason: 'turn_player_not_controlled',
      );
    }
    final playerIds = _turnPlayerIds(save, state);
    if (playerIds.isEmpty || !playerIds.contains(command.playerId)) {
      return _CommandApplication.reject(
        save: save,
        state: state,
        reason: 'turn_player_not_active',
      );
    }
    final alreadySubmitted = state.runtimeState.hasSubmitted(command.playerId);
    final submitted = {
      ...state.runtimeState.submittedPlayerIds,
      command.playerId,
    };
    final submittedState = state.copyWith(
      runtimeState: state.runtimeState.copyWith(submittedPlayerIds: submitted),
    );
    final turnTimedOut = _turnTimedOut(save, state, now);
    final waitingPlayerIds = _waitingPlayerIds(
      match: match,
      playerIds: playerIds,
      submittedPlayerIds: submitted,
      turnTimedOut: turnTimedOut,
    );
    if (waitingPlayerIds.isNotEmpty) {
      return _CommandApplication.accept(
        save: alreadySubmitted
            ? save.copyWith(savedAt: now.toUtc())
            : save
                  .withPlayerFinished(command.playerId)
                  .copyWith(savedAt: now.toUtc()),
        state: submittedState,
      );
    }
    final skippedPlayerIds = playerIds
        .where((playerId) => !submitted.contains(playerId))
        .toList();

    return _finalizeSimultaneousTurn(
      decodedSnapshot: decodedSnapshot.withState(submittedState),
      playerIds: playerIds,
      skippedPlayerIds: skippedPlayerIds,
      now: now,
      mapView: mapView,
      ruleset: ruleset,
    );
  }

  _CommandApplication _finalizeSimultaneousTurn({
    required DecodedMatchSnapshot decodedSnapshot,
    required List<String> playerIds,
    required List<String> skippedPlayerIds,
    required DateTime now,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    final result = CanonicalTurnPipeline.simultaneousFinalize(
      CanonicalTurnPipelineRequest.simultaneousFinalize(
        snapshot: decodedSnapshot.canonical,
        playerIds: playerIds,
        skippedPlayerIds: skippedPlayerIds,
        savedAt: now,
        mapView: mapView,
        ruleset: ruleset,
        preserveNonParticipantPlayerStates: true,
        trackTimeoutStreaks: true,
      ),
    );
    final legacyResult = _legacyGameSnapshotAdapter.toLegacy(result.snapshot);
    return _CommandApplication.accept(
      save: legacyResult.save,
      state: legacyResult.state,
      events: result.events,
      movementExecutions: result.movementDelta?.executions,
      canonicalSnapshot: result.snapshot,
    );
  }

  List<String> _turnPlayerIds(GameSave save, PersistentGameState state) {
    final kickedPlayerIds = state.runtimeState.kickedPlayerIds;
    final ids = save.players
        .map((player) => player.id)
        .where((id) => id.isNotEmpty && !kickedPlayerIds.contains(id))
        .toList();
    if (ids.isNotEmpty) return ids..sort();
    return save.playerStates.keys
        .where((id) => id.isNotEmpty && !kickedPlayerIds.contains(id))
        .toList()
      ..sort();
  }

  bool _turnTimedOut(GameSave save, PersistentGameState state, DateTime now) {
    final turnStartedAt = state.runtimeState.turnStartedAt ?? save.savedAt;
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
