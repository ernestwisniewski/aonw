part of 'match_command_service.dart';

extension MatchCommandServiceTimeouts on MatchCommandService {
  Future<MatchConnectionAuthorization> authorizeConnection({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
  }) async {
    final state = await _stateAccess.requireMatch(store, matchId);
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    return MatchConnectionAuthorization(state: state, participant: player);
  }

  Future<void> advanceTimedOutTurns({
    required MultiplayerMatchStore store,
  }) async {
    final states = await store.listRunningStates();
    for (final state in states) {
      try {
        await advanceTimedOutTurn(store: store, matchId: state.match.id);
      } catch (_) {
        // Keep the sweep alive for other matches; the next scheduled sweep can
        // retry this match after transient store/snapshot failures.
      }
    }
  }

  Future<void> advanceTimedOutTurn({
    required MultiplayerMatchStore store,
    required String matchId,
  }) async {
    await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      if (state.match.state != 'running') return;

      final now = _nowUtc();
      if (!_commandReducer.hasTurnTimedOut(
        snapshot: state.snapshot,
        now: now,
      )) {
        return;
      }

      final save = GameSave.fromJson(state.snapshot.save);
      final persistentState = PersistentGameState.fromJson(
        state.snapshot.state,
      );
      final actorPlayerId = _timeoutActorPlayerId(
        state.match,
        save,
        persistentState,
      );
      if (actorPlayerId == null) return;

      final command = SubmitTurnCommand(actorPlayerId);
      final reduction = await _commandReducer.reduceTimedOutTurn(
        match: state.match,
        snapshot: state.snapshot,
        actorPlayerId: actorPlayerId,
        now: now,
      );
      if (!reduction.accepted) return;

      final nextSave = GameSave.fromJson(reduction.snapshot.save);
      if (nextSave.turn == save.turn) return;

      final nextOffset = state.nextOffset();
      final nextSnapshot = reduction.snapshot.copyWith(offset: nextOffset);
      final event = WireEvent(
        matchId: state.match.id,
        offset: nextOffset,
        timestamp: now,
        actorPlayerId: actorPlayerId,
        tick: state.nextOffset(),
        command: GameCommandSerializer.toJson(command),
        events: reduction.events.map(GameEventSerializer.toJson).toList(),
      );
      final updated = state.copyWith(
        match: state.match.copyWith(turn: nextSave.turn),
        snapshot: nextSnapshot,
      );
      await txStore.appendEvent(
        updated,
        event,
        actorPlayerId: actorPlayerId,
        clientMessageId: _timeoutClientMessageId(state.match.id, save.turn),
      );

      _broadcaster.broadcast(
        _broadcaster.message(
          matchId: state.match.id,
          offset: event.offset,
          snapshot: updated.snapshot,
          event: event,
        ),
      );
    });
  }

  String? _timeoutActorPlayerId(
    WireMatch match,
    GameSave save,
    PersistentGameState state,
  ) {
    final kickedPlayerIds = state.runtimeState.kickedPlayerIds;
    final matchPlayerIds = match.players.map((player) => player.id).toSet();
    final activePlayerIds = {
      for (final player in save.players)
        if (player.id.isNotEmpty) player.id,
      for (final playerId in save.playerStates.keys)
        if (playerId.isNotEmpty) playerId,
    };
    final submittedPlayerIds = state.runtimeState.submittedPlayerIds.toList()
      ..sort();
    for (final submittedPlayerId in submittedPlayerIds) {
      if (!kickedPlayerIds.contains(submittedPlayerId) &&
          matchPlayerIds.contains(submittedPlayerId) &&
          activePlayerIds.contains(submittedPlayerId)) {
        return submittedPlayerId;
      }
    }
    final fallbackPlayerIds =
        activePlayerIds
            .where(
              (playerId) =>
                  !kickedPlayerIds.contains(playerId) &&
                  matchPlayerIds.contains(playerId),
            )
            .toList()
          ..sort();
    if (fallbackPlayerIds.isNotEmpty) return fallbackPlayerIds.first;
    return null;
  }

  String _timeoutClientMessageId(String matchId, int turn) {
    return 'server-turn-timeout:$matchId:$turn';
  }
}
