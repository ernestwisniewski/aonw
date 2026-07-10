part of 'server_command_reducer.dart';

extension ServerCommandReducerTurns on ServerCommandReducer {
  _CommandApplication _submitTurn({
    required GameSave save,
    required PersistentGameState state,
    required WireMatch match,
    required SubmitTurnCommand command,
    required String actorPlayerId,
    required DateTime now,
    required MapData mapData,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
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
      save: save,
      state: submittedState,
      playerIds: playerIds,
      skippedPlayerIds: skippedPlayerIds,
      now: now,
      mapData: mapData,
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
  }

  _CommandApplication _finalizeSimultaneousTurn({
    required GameSave save,
    required PersistentGameState state,
    required List<String> playerIds,
    required List<String> skippedPlayerIds,
    required DateTime now,
    required MapData mapData,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    final result = PersistentTurnPipeline.simultaneousFinalize(
      PersistentTurnPipelineRequest.simultaneousFinalize(
        save: save,
        state: state,
        playerIds: playerIds,
        skippedPlayerIds: skippedPlayerIds,
        savedAt: now,
        mapData: mapData,
        mapDefinition: mapDefinition,
        ruleset: ruleset,
        preserveNonParticipantPlayerStates: true,
        trackTimeoutStreaks: true,
      ),
    );
    return _CommandApplication.accept(
      save: result.save,
      state: result.state,
      events: result.events,
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
