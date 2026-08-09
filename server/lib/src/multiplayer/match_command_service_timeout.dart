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

enum _MatchTimeoutAction { unchanged, turnAdvanced, matchAbandoned }

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
      final state = await _stateAccess.requireStoredMatch(
        txStore,
        matchId,
        lock: true,
      );
      return _advanceTimedOutTurnInTransaction(store: txStore, state: state);
    });
    if (outcome.value == _MatchTimeoutAction.matchAbandoned) {
      store.operationalEvents.matchAbandoned(
        matchId: matchId,
        reasonCode: _matchLifecycleWireAdapter.encodeAbandonmentReason(
          MatchAbandonmentReason.allPlayersInactive,
        ),
      );
    }
    outcome.notifications.deliver(_broadcaster);
  }

  Future<MatchMutationOutcome<_MatchTimeoutAction>>
  _advanceTimedOutTurnInTransaction({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
  }) async {
    if (!_matchLifecycleStateAdapter.lifecycleOf(state).isRunning) {
      return const MatchMutationOutcome(_MatchTimeoutAction.unchanged);
    }
    final now = _nowUtc();
    if (await _expireInactive(store, state, now) case final outcome?) {
      return outcome;
    }
    final decodedSnapshot = _decodeRunningSnapshot(state);
    final canonicalSnapshot = decodedSnapshot.canonical;
    if (_turnPresencePolicy.areAllHumanPlayersOffline(state, nowUtc: now)) {
      return const MatchMutationOutcome(_MatchTimeoutAction.unchanged);
    }
    final timeoutReduction = await _reduceTimedOutTurnIfNeeded(
      state: state,
      snapshot: canonicalSnapshot,
      now: now,
    );
    if (timeoutReduction == null) {
      return const MatchMutationOutcome(_MatchTimeoutAction.unchanged);
    }
    return _persistTimedOutTurn(
      store: store,
      state: state,
      decodedSnapshot: decodedSnapshot,
      previousSnapshot: canonicalSnapshot,
      timeoutReduction: timeoutReduction,
      now: now,
    );
  }

  Future<MatchMutationOutcome<_MatchTimeoutAction>> _persistTimedOutTurn({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required DecodedRunningMatchSnapshot decodedSnapshot,
    required CanonicalGameSnapshot previousSnapshot,
    required ({ServerCommandReduction reduction, String actorPlayerId})
    timeoutReduction,
    required DateTime now,
  }) async {
    final (:reduction, :actorPlayerId) = timeoutReduction;
    final nextOffset = state.nextOffset();
    final updated = _stateAfterAcceptedReduction(
      state: state,
      reduction: reduction,
      snapshot: _encodeReductionSnapshot(
        decoded: decodedSnapshot,
        reduction: reduction,
        offset: nextOffset,
      ),
      now: now,
    );
    final event = _acceptedTimeoutEventForStorage(
      state: state,
      previousSnapshot: previousSnapshot,
      reduction: reduction,
      actorPlayerId: actorPlayerId,
      offset: nextOffset,
      timestamp: now,
    );
    await store._appendEventAndFinalizePresence(
      updated,
      event,
      actorPlayerId: actorPlayerId,
      clientMessageId: _timeoutClientMessageId(
        state.match.id,
        previousSnapshot.domain.turn,
      ),
    );
    return MatchMutationOutcome(
      _MatchTimeoutAction.turnAdvanced,
      notifications: MatchNotificationPlan.broadcastMessage(
        _broadcaster.message(
          matchId: state.match.id,
          offset: event.offset,
          match: updated.match.state == state.match.state
              ? null
              : updated.match,
          snapshot: updated.snapshot,
          event: event,
        ),
      ),
    );
  }

  Future<MatchMutationOutcome<_MatchTimeoutAction>?> _expireInactive(
    MultiplayerMatchStore store,
    StoredMatchState state,
    DateTime now,
  ) async {
    if (!_matchActivityTracker.hasExpired(
      state,
      nowUtc: now,
      timeout: _matchInactivityTimeout,
    )) {
      return state.snapshot.v == kProtocolVersion
          ? null
          : const MatchMutationOutcome(_MatchTimeoutAction.unchanged);
    }
    final abandoned = _stateAccess.abandonedState(
      state,
      reason: MatchAbandonmentReason.allPlayersInactive,
      endedAt: now,
    );
    await store.saveState(abandoned);
    await store.deletePresenceLeases(abandoned.match.id);
    return MatchMutationOutcome(
      _MatchTimeoutAction.matchAbandoned,
      notifications: MatchNotificationPlan.broadcastState(abandoned),
    );
  }

  Future<({ServerCommandReduction reduction, String actorPlayerId})?>
  _reduceTimedOutTurnIfNeeded({
    required StoredMatchState state,
    required CanonicalGameSnapshot snapshot,
    required DateTime now,
  }) async {
    if (!_commandReducer.hasTurnTimedOut(snapshot: snapshot, now: now)) {
      return null;
    }
    final actorPlayerId = _selectTimeoutActorPlayerId(
      match: state.match,
      snapshot: snapshot,
    );
    if (actorPlayerId == null) return null;
    final reduction = await _commandReducer.reduceTimedOutTurn(
      match: state.match,
      snapshot: snapshot,
      actorPlayerId: actorPlayerId,
      now: now,
    );
    if (!reduction.accepted ||
        reduction.nextSnapshot!.domain.turn == snapshot.domain.turn) {
      return null;
    }
    return (reduction: reduction, actorPlayerId: actorPlayerId);
  }

  String? _selectTimeoutActorPlayerId({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
  }) {
    final activePlayerIds = {
      for (final player in snapshot.domain.participants)
        if (player.id.isNotEmpty) player.id,
    };
    return TimeoutActorSelector.select(
      orderedParticipantPlayerIds: [
        for (final player in match.players)
          if (activePlayerIds.contains(player.id)) player.id,
      ],
      submittedPlayerIds: snapshot.domain.submittedPlayerIds,
      kickedPlayerIds: snapshot.domain.kickedPlayerIds,
    );
  }

  String _timeoutClientMessageId(String matchId, int turn) {
    return 'server-turn-timeout:$matchId:$turn';
  }
}
