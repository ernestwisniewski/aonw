part of 'match_lifecycle_service.dart';

extension MatchLifecycleServicePresenceExpiry on MatchLifecycleService {
  Future<List<LobbyPresenceSweepFailure>> expireLobbyPresence({
    required MultiplayerMatchStore store,
  }) async {
    var page = await store.listExpiredPresenceLeases(
      nowUtc: _nowUtc(),
      after: _nextPresenceSweepCursor,
    );
    if (page.candidates.isEmpty && _nextPresenceSweepCursor != null) {
      _nextPresenceSweepCursor = null;
      page = await store.listExpiredPresenceLeases(nowUtc: _nowUtc());
    }
    _nextPresenceSweepCursor = page.nextCursor;

    final failures = <LobbyPresenceSweepFailure>[];
    for (final candidate in page.candidates) {
      try {
        final outcome = await store.transaction(
          (txStore) => _expirePresenceCandidate(
            store: txStore,
            candidate: candidate,
            nowUtc: _nowUtc(),
          ),
        );
        outcome.notifications.deliver(_broadcaster);
      } catch (error, stackTrace) {
        failures.add(
          LobbyPresenceSweepFailure(
            matchId: candidate.matchId,
            userIdentifier: candidate.lease.userIdentifier,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }
    return failures;
  }

  Future<MatchMutationOutcome<bool>> _expirePresenceCandidate({
    required MultiplayerMatchStore store,
    required ExpiredPresenceLeaseCandidate candidate,
    required DateTime nowUtc,
  }) async {
    final state = await store.findState(candidate.matchId, lock: true);
    if (state == null) return const MatchMutationOutcome(false);
    final userIdentifier = candidate.lease.userIdentifier;
    if (!_isCurrentExpiredPresence(state, candidate, nowUtc: nowUtc)) {
      return const MatchMutationOutcome(false);
    }
    final lifecycle = _matchLifecycleStateAdapter.lifecycleOf(state);
    if (lifecycle.isTerminal) {
      await store.deletePresenceLease(
        matchId: candidate.matchId,
        userIdentifier: userIdentifier,
      );
      return const MatchMutationOutcome(false);
    }
    if (lifecycle.isRunning) {
      return _expireRunningPresence(
        store: store,
        state: state,
        userIdentifier: userIdentifier,
        nowUtc: nowUtc,
      );
    }
    return _expireOpenPresence(
      store: store,
      state: state,
      userIdentifier: userIdentifier,
    );
  }

  bool _isCurrentExpiredPresence(
    StoredMatchState state,
    ExpiredPresenceLeaseCandidate candidate, {
    required DateTime nowUtc,
  }) {
    final currentLease = state.presenceLeases[candidate.lease.userIdentifier];
    return currentLease != null &&
        currentLease.connectionGeneration ==
            candidate.lease.connectionGeneration &&
        currentLease.isExpiredAt(nowUtc);
  }

  Future<MatchMutationOutcome<bool>> _expireRunningPresence({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required String userIdentifier,
    required DateTime nowUtc,
  }) async {
    final playerIndex = state.match.players.indexWhere(
      (player) => player.userId == userIdentifier,
    );
    await store.deletePresenceLease(
      matchId: state.match.id,
      userIdentifier: userIdentifier,
    );
    if (playerIndex == -1) return const MatchMutationOutcome(false);
    final player = state.match.players[playerIndex];
    if (player.connectionState == WirePlayerConnectionState.offline) {
      return const MatchMutationOutcome(false);
    }
    final players = [...state.match.players];
    players[playerIndex] = player.copyWith(
      connectionState: WirePlayerConnectionState.offline,
    );
    final updated = _matchActivityTracker.record(
      state.copyWith(
        match: state.match.copyWith(players: players),
        presenceLeases: _withoutPresence(state, userIdentifier),
      ),
      nowUtc,
    );
    await store.saveState(updated);
    return MatchMutationOutcome(
      true,
      notifications: MatchNotificationPlan.broadcastState(updated),
    );
  }

  Future<MatchMutationOutcome<bool>> _expireOpenPresence({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required String userIdentifier,
  }) async {
    if (!state.match.players.any((player) => player.userId == userIdentifier)) {
      await store.deletePresenceLease(
        matchId: state.match.id,
        userIdentifier: userIdentifier,
      );
      return const MatchMutationOutcome(false);
    }
    var updated = _openStateAfterParticipantLeft(
      state,
      userIdentifier: userIdentifier,
    );
    updated = updated.copyWith(
      presenceLeases:
          _matchLifecycleStateAdapter.lifecycleOf(updated).isTerminal
          ? const {}
          : _withoutPresence(updated, userIdentifier),
    );
    await store.saveState(updated);
    await _deleteExpiredPresence(
      store: store,
      state: updated,
      userIdentifier: userIdentifier,
    );
    return _expiredTransitionOutcome(store: store, state: updated);
  }

  Future<void> _deleteExpiredPresence({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required String userIdentifier,
  }) async {
    if (_matchLifecycleStateAdapter.lifecycleOf(state).isTerminal) {
      await store.deletePresenceLeases(state.match.id);
      return;
    }
    await store.deletePresenceLease(
      matchId: state.match.id,
      userIdentifier: userIdentifier,
    );
  }

  Future<MatchMutationOutcome<bool>> _expiredTransitionOutcome({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
  }) async {
    if (_isOpenQuickplayState(state)) {
      final advanced = await advanceQuickplayLobby(
        store: store,
        state: state,
        broadcastUnchanged: true,
      );
      return advanced.withValue(true);
    }
    return MatchMutationOutcome(
      true,
      notifications: MatchNotificationPlan.broadcastState(state),
    );
  }
}
