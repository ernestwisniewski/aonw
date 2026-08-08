part of 'match_lifecycle_service.dart';

extension MatchLifecycleServiceQuickplay on MatchLifecycleService {
  StoredMatchState _openQuickplayStateAfterParticipantLeft(
    StoredMatchState state, {
    required String userIdentifier,
  }) {
    final players = [
      for (final player in state.match.players)
        if (player.userId != userIdentifier) player,
    ];
    if (players.isEmpty) {
      return _stateAccess.abandonedState(
        state,
        reason: MatchAbandonmentReason.ownerLeft,
        endedAt: _nowUtc(),
        userIdentifier: userIdentifier,
      );
    }
    return state.copyWith(
      match: state.match.copyWith(
        ownerUserId: state.match.ownerUserId == userIdentifier
            ? players.first.userId
            : state.match.ownerUserId,
        players: players,
      ),
    );
  }

  Future<MatchMutationOutcome<bool>> abandonStaleQuickplayLobby({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
  }) async {
    final match = state.match;
    if (!_isOpenQuickplayState(state)) {
      return const MatchMutationOutcome(false);
    }
    final now = _nowUtc();
    final stale = !state.presenceLeases.values.any(
      (lease) => !lease.isExpiredAt(now),
    );
    if (!stale) return const MatchMutationOutcome(false);
    final abandoned = _stateAccess.abandonedState(
      state,
      reason: MatchAbandonmentReason.quickplayStale,
      endedAt: _nowUtc(),
    );
    await store.saveState(abandoned);
    await store.deletePresenceLeases(match.id);
    return MatchMutationOutcome(
      true,
      notifications: MatchNotificationPlan.broadcastState(abandoned),
    );
  }

  Future<MatchMutationOutcome<StoredMatchState>> advanceQuickplayLobby({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
    bool broadcastUnchanged = false,
  }) async {
    if (!_isOpenQuickplayState(state)) {
      return _unchangedQuickplayOutcome(state, broadcast: broadcastUnchanged);
    }

    final decision = _evaluateQuickplayLobby(state);
    return switch (decision.action) {
      QuickplayLobbyAction.waitForPlayers => _waitForQuickplayPlayers(
        store: store,
        state: state,
        broadcastUnchanged: broadcastUnchanged,
      ),
      QuickplayLobbyAction.waitForCountdown => _waitForQuickplayCountdown(
        store: store,
        state: state,
        decision: decision,
        broadcastUnchanged: broadcastUnchanged,
      ),
      QuickplayLobbyAction.start => _startQuickplayLobby(
        store: store,
        state: state,
        snapshotFactory: snapshotFactory,
        broadcastUnchanged: broadcastUnchanged,
      ),
    };
  }

  QuickplayLobbyDecision _evaluateQuickplayLobby(StoredMatchState state) {
    final match = state.match;
    final memberCount = _rosterPolicy.humanMemberCount(match);
    final liveConnectedCount = match.players.where((player) {
      return player.kind == WirePlayerKind.human &&
          _presencePolicy.isLiveConnectedParticipant(
            state,
            player,
            nowUtc: _nowUtc(),
          );
    }).length;
    return _quickplayLobbyPolicy.evaluate(
      humanPlayers: liveConnectedCount == memberCount ? liveConnectedCount : 0,
      minPlayers: match.minPlayers,
      maxPlayers: match.maxPlayers,
      nowUtc: _nowUtc(),
      currentAutoStartAt: match.autoStartAt,
    );
  }

  Future<MatchMutationOutcome<StoredMatchState>> _waitForQuickplayPlayers({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required bool broadcastUnchanged,
  }) async {
    if (state.match.autoStartAt == null) {
      return _unchangedQuickplayOutcome(state, broadcast: broadcastUnchanged);
    }
    return _persistQuickplayAutoStartAt(
      store: store,
      state: state,
      autoStartAt: null,
    );
  }

  Future<MatchMutationOutcome<StoredMatchState>> _waitForQuickplayCountdown({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required QuickplayLobbyDecision decision,
    required bool broadcastUnchanged,
  }) async {
    final autoStartAt = decision.autoStartAt;
    if (autoStartAt == null ||
        _sameInstant(state.match.autoStartAt, autoStartAt)) {
      return _unchangedQuickplayOutcome(state, broadcast: broadcastUnchanged);
    }
    return _persistQuickplayAutoStartAt(
      store: store,
      state: state,
      autoStartAt: autoStartAt,
    );
  }

  Future<MatchMutationOutcome<StoredMatchState>> _startQuickplayLobby({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required InitialMultiplayerSnapshotFactory snapshotFactory,
    required bool broadcastUnchanged,
  }) {
    if (!_canStartLobby(state, nowUtc: _nowUtc())) {
      return _waitForQuickplayPlayers(
        store: store,
        state: state,
        broadcastUnchanged: broadcastUnchanged,
      );
    }
    return _startOpenMatch(
      store: store,
      state: state,
      snapshotFactory: snapshotFactory,
    );
  }

  Future<MatchMutationOutcome<StoredMatchState>> _persistQuickplayAutoStartAt({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required DateTime? autoStartAt,
  }) async {
    final updated = state.copyWith(
      match: state.match.copyWith(autoStartAt: autoStartAt),
    );
    await store.saveState(updated);
    return MatchMutationOutcome(
      updated,
      notifications: MatchNotificationPlan.broadcastState(updated),
    );
  }

  MatchMutationOutcome<StoredMatchState> _unchangedQuickplayOutcome(
    StoredMatchState state, {
    required bool broadcast,
  }) {
    return MatchMutationOutcome(
      state,
      notifications: broadcast
          ? MatchNotificationPlan.broadcastState(state)
          : const MatchNotificationPlan.empty(),
    );
  }
}

bool _isOpenQuickplayState(StoredMatchState state) =>
    state.match.quickplay &&
    _matchLifecycleStateAdapter.lifecycleOf(state).isOpen;
