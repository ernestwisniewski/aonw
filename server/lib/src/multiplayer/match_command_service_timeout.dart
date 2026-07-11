part of 'match_command_service.dart';

final class MatchTimeoutSweepFailure {
  const MatchTimeoutSweepFailure({
    required this.matchId,
    required this.error,
    required this.stackTrace,
  });

  final String matchId;
  final Object error;
  final StackTrace stackTrace;
}

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

  Future<List<MatchTimeoutSweepFailure>> advanceTimedOutTurns({
    required MultiplayerMatchStore store,
  }) async {
    final failures = <MatchTimeoutSweepFailure>[];
    final page = await store.listRunningStates(after: _nextTimeoutSweepCursor);
    _nextTimeoutSweepCursor = page.nextCursor;
    for (final state in page.states) {
      if (state.snapshot.v != kProtocolVersion) {
        continue;
      }
      try {
        await advanceTimedOutTurn(store: store, matchId: state.match.id);
      } catch (error, stackTrace) {
        // Keep the sweep alive for other matches; the next scheduled sweep can
        // retry this match after transient store/snapshot failures.
        failures.add(
          MatchTimeoutSweepFailure(
            matchId: state.match.id,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }
    return failures;
  }

  Future<void> advanceTimedOutTurn({
    required MultiplayerMatchStore store,
    required String matchId,
  }) async {
    final outcome = await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      if (state.match.state != 'running') {
        return const MatchMutationOutcome<bool>(false);
      }

      final now = _nowUtc();
      if (!_commandReducer.hasTurnTimedOut(
        snapshot: state.snapshot,
        now: now,
      )) {
        return const MatchMutationOutcome<bool>(false);
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
      if (actorPlayerId == null) {
        return const MatchMutationOutcome<bool>(false);
      }

      final command = SubmitTurnCommand(actorPlayerId);
      final reduction = await _commandReducer.reduceTimedOutTurn(
        match: state.match,
        snapshot: state.snapshot,
        actorPlayerId: actorPlayerId,
        now: now,
      );
      if (!reduction.accepted) {
        return const MatchMutationOutcome<bool>(false);
      }

      final nextSave = GameSave.fromJson(reduction.snapshot.save);
      if (nextSave.turn == save.turn) {
        return const MatchMutationOutcome<bool>(false);
      }

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

      return MatchMutationOutcome<bool>(
        true,
        notifications: MatchNotificationPlan.broadcastMessage(
          _broadcaster.message(
            matchId: state.match.id,
            offset: event.offset,
            snapshot: updated.snapshot,
            event: event,
          ),
        ),
      );
    });
    outcome.notifications.deliver(_broadcaster);
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
