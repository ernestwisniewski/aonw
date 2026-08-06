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
    final stale = _quickplayLobbyPolicy.isStaleWaitingForPlayers(
      humanPlayers: _stateAccess.humanPlayerCount(match),
      minPlayers: match.minPlayers,
      createdAt: match.createdAt,
      nowUtc: _nowUtc(),
      currentAutoStartAt: match.autoStartAt,
    );
    if (!stale) return const MatchMutationOutcome(false);
    final abandoned = _stateAccess.abandonedState(
      state,
      reason: MatchAbandonmentReason.quickplayStale,
      endedAt: _nowUtc(),
    );
    await store.saveState(abandoned);
    return MatchMutationOutcome(
      true,
      notifications: MatchNotificationPlan.broadcastState(abandoned),
    );
  }

  Future<MatchMutationOutcome<WireMatch>> advanceQuickplayLobby({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
    bool broadcastUnchanged = false,
  }) async {
    final match = state.match;
    if (!_isOpenQuickplayState(state)) {
      return MatchMutationOutcome(
        match,
        notifications: broadcastUnchanged
            ? MatchNotificationPlan.broadcastState(state)
            : const MatchNotificationPlan.empty(),
      );
    }

    final decision = _quickplayLobbyPolicy.evaluate(
      humanPlayers: _stateAccess.humanPlayerCount(match),
      minPlayers: match.minPlayers,
      maxPlayers: match.maxPlayers,
      nowUtc: _nowUtc(),
      currentAutoStartAt: match.autoStartAt,
    );

    switch (decision.action) {
      case QuickplayLobbyAction.waitForPlayers:
        if (match.autoStartAt == null) {
          return MatchMutationOutcome(
            match,
            notifications: broadcastUnchanged
                ? MatchNotificationPlan.broadcastState(state)
                : const MatchNotificationPlan.empty(),
          );
        }
        final updated = state.copyWith(
          match: match.copyWith(autoStartAt: null),
        );
        await store.saveState(updated);
        return MatchMutationOutcome(
          updated.match,
          notifications: MatchNotificationPlan.broadcastState(updated),
        );
      case QuickplayLobbyAction.waitForCountdown:
        final autoStartAt = decision.autoStartAt;
        if (autoStartAt == null ||
            _sameInstant(match.autoStartAt, autoStartAt)) {
          return MatchMutationOutcome(
            match,
            notifications: broadcastUnchanged
                ? MatchNotificationPlan.broadcastState(state)
                : const MatchNotificationPlan.empty(),
          );
        }
        final updated = state.copyWith(
          match: match.copyWith(autoStartAt: autoStartAt),
        );
        await store.saveState(updated);
        return MatchMutationOutcome(
          updated.match,
          notifications: MatchNotificationPlan.broadcastState(updated),
        );
      case QuickplayLobbyAction.start:
        return _startOpenMatch(
          store: store,
          state: state,
          snapshotFactory: snapshotFactory,
        );
    }
  }
}

bool _isOpenQuickplayState(StoredMatchState state) =>
    state.match.quickplay &&
    _matchLifecycleStateAdapter.lifecycleOf(state).isOpen;
