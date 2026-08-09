part of 'match_lifecycle_service.dart';

final class LobbyPresenceSweepFailure {
  const LobbyPresenceSweepFailure({
    required this.matchId,
    required this.userIdentifier,
    required this.error,
    required this.stackTrace,
  });

  final String matchId;
  final String userIdentifier;
  final Object error;
  final StackTrace stackTrace;
}

extension MatchLifecycleServicePresence on MatchLifecycleService {
  Future<StoredMatchState> participantConnected({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required String connectionGeneration,
  }) async {
    final outcome = await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      final participant = _stateAccess.requireParticipant(
        state,
        userIdentifier,
      );
      return _connections.connect(
        store: txStore,
        state: state,
        playerIndex: state.match.players.indexOf(participant),
        connectionGeneration: connectionGeneration,
        advanceQuickplay: advanceQuickplayLobby,
      );
    });
    outcome.notifications.deliver(_broadcaster);
    return outcome.value;
  }

  Future<void> participantDisconnected({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required String connectionGeneration,
  }) async {
    final outcome = await store.transaction(
      (txStore) => _disconnectParticipant(
        store: txStore,
        matchId: matchId,
        userIdentifier: userIdentifier,
        connectionGeneration: connectionGeneration,
      ),
    );
    outcome.notifications.deliver(_broadcaster);
  }

  Future<MatchMutationOutcome<bool>> _disconnectParticipant({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required String connectionGeneration,
  }) async {
    final state = await _stateAccess.requireStoredMatch(
      store,
      matchId,
      lock: true,
    );
    final currentLease = state.presenceLeases[userIdentifier];
    if (currentLease?.connectionGeneration != connectionGeneration) {
      return const MatchMutationOutcome(false);
    }
    final lifecycle = _matchLifecycleStateAdapter.lifecycleOf(state);
    if (!lifecycle.acceptsConnectionMutation) {
      await store.deletePresenceLease(
        matchId: matchId,
        userIdentifier: userIdentifier,
      );
      return const MatchMutationOutcome(false);
    }
    final updated = _disconnectedParticipantState(
      state,
      userIdentifier: userIdentifier,
      reconnecting: lifecycle.isOpen,
      trackActivity: lifecycle.isRunning,
    );
    await store.saveState(updated);
    await _persistDisconnectedPresence(
      store: store,
      state: updated,
      userIdentifier: userIdentifier,
    );
    return _disconnectTransitionOutcome(store: store, state: updated);
  }

  StoredMatchState _disconnectedParticipantState(
    StoredMatchState state, {
    required String userIdentifier,
    required bool reconnecting,
    required bool trackActivity,
  }) {
    final playerIndex = _participantIndex(state, userIdentifier);
    final players = [...state.match.players];
    players[playerIndex] = players[playerIndex].copyWith(
      connectionState: reconnecting
          ? WirePlayerConnectionState.reconnecting
          : WirePlayerConnectionState.offline,
    );
    final now = _nowUtc();
    final nextLease = reconnecting
        ? _presencePolicy.reconnectLease(
            userIdentifier: userIdentifier,
            connectionGeneration: _presenceGenerationGenerator.next(),
            nowUtc: now,
          )
        : null;
    final updated = state.copyWith(
      match: state.match.copyWith(players: players),
      presenceLeases: nextLease == null
          ? _withoutPresence(state, userIdentifier)
          : {...state.presenceLeases, userIdentifier: nextLease},
    );
    return trackActivity ? _matchActivityTracker.record(updated, now) : updated;
  }

  Future<void> _persistDisconnectedPresence({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required String userIdentifier,
  }) async {
    final lease = state.presenceLeases[userIdentifier];
    if (lease != null) {
      await store.upsertPresenceLease(matchId: state.match.id, lease: lease);
      return;
    }
    await store.deletePresenceLease(
      matchId: state.match.id,
      userIdentifier: userIdentifier,
    );
  }

  Future<void> renewParticipantPresence({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required String connectionGeneration,
  }) async {
    final now = _nowUtc();
    final lease = _presencePolicy.connectedLease(
      userIdentifier: userIdentifier,
      connectionGeneration: connectionGeneration,
      nowUtc: now,
    );
    final renewed = await store.renewPresenceLease(
      matchId: matchId,
      userIdentifier: userIdentifier,
      connectionGeneration: connectionGeneration,
      expiresAt: lease.expiresAt,
      updatedAt: lease.updatedAt,
    );
    if (renewed) return;
    throw multiplayerException(
      'not_match_player',
      'Participant presence lease is no longer active.',
    );
  }

  Future<MatchMutationOutcome<bool>> _disconnectTransitionOutcome({
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

int _participantIndex(StoredMatchState state, String userIdentifier) {
  final index = state.match.players.indexWhere(
    (player) => player.userId == userIdentifier,
  );
  if (index == -1) {
    throw multiplayerException(
      'not_match_player',
      'User is not a participant in this match.',
    );
  }
  return index;
}

Map<String, StoredMatchPresenceLease> _withoutPresence(
  StoredMatchState state,
  String userIdentifier,
) {
  return {
    for (final entry in state.presenceLeases.entries)
      if (entry.key != userIdentifier) entry.key: entry.value,
  };
}
