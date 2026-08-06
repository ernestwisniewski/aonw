part of 'matchmaking_service.dart';

extension MatchmakingServiceTransactions on MatchmakingService {
  Future<WireMatch> quickplay({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    final quickplayRequest = _requestValidator.validate(
      quickplayMatchRequest(request),
      enforceMapCapacity: false,
    );
    final outcome = await store.transaction((txStore) async {
      var notifications = const MatchNotificationPlan.empty();
      for (
        var retired = 0;
        retired < multiplayerQuickplayCandidateRetirementLimit;
        retired += 1
      ) {
        final state = await txStore.findOpenQuickplayCandidate(
          quickplayRequest,
        );
        if (state == null) break;

        if (!_stateAccess.supportsCurrentProtocol(state)) {
          await txStore.saveState(
            _stateAccess.abandonedState(
              state,
              reason: MatchAbandonmentReason.protocolUpgrade,
              endedAt: _nowUtc(),
            ),
          );
          continue;
        }

        final stale = await _lifecycle.abandonStaleQuickplayLobby(
          store: txStore,
          state: state,
        );
        notifications = notifications.followedBy(stale.notifications);
        if (stale.value) continue;

        final joined = await _joinState(
          store: txStore,
          state: state,
          userIdentifier: userIdentifier,
          displayName: displayName,
          countryId: quickplayRequest.countryId,
          broadcast: false,
        );
        final advanced = await _lifecycle.advanceQuickplayLobby(
          store: txStore,
          state: joined.value,
          snapshotFactory: snapshotFactory,
          broadcastUnchanged: true,
        );
        return MatchMutationOutcome(
          advanced.value,
          notifications: notifications.followedBy(advanced.notifications),
        );
      }

      final created = await _createMatch(
        store: txStore,
        userIdentifier: userIdentifier,
        displayName: displayName,
        request: quickplayRequest,
        quickplay: true,
      );
      final advanced = await _lifecycle.advanceQuickplayLobby(
        store: txStore,
        state: (await txStore.findState(created.id, lock: true))!,
        snapshotFactory: snapshotFactory,
      );
      return MatchMutationOutcome(
        advanced.value,
        notifications: notifications.followedBy(advanced.notifications),
      );
    });
    outcome.notifications.deliver(_broadcaster);
    return outcome.value;
  }

  Future<WireMatch> joinMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required String matchId,
    String? countryId,
  }) async {
    final outcome = await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      requirePublicOpenLobby(state);
      final joined = await _joinState(
        store: txStore,
        state: state,
        userIdentifier: userIdentifier,
        displayName: displayName,
        countryId: countryId,
        broadcast: !state.match.quickplay,
      );
      if (joined.value.match.quickplay &&
          const MatchLifecycleStateAdapter().lifecycleOf(joined.value).isOpen) {
        final advanced = await _lifecycle.advanceQuickplayLobby(
          store: txStore,
          state: joined.value,
          broadcastUnchanged: true,
        );
        return MatchMutationOutcome(
          advanced.value,
          notifications: joined.notifications.followedBy(
            advanced.notifications,
          ),
        );
      }
      return joined.withValue(joined.value.match);
    });
    outcome.notifications.deliver(_broadcaster);
    return outcome.value;
  }

  Future<WireMatch> joinPrivateMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required String inviteCode,
    String? countryId,
  }) async {
    final outcome = await store.transaction((txStore) async {
      final normalized = inviteCode.trim().toUpperCase();
      final state = await txStore.findPrivateState(normalized, lock: true);
      if (state == null) {
        throw multiplayerException(
          'private_match_not_found',
          'Private match not found.',
        );
      }
      _stateAccess.requireCurrentProtocol(state);
      requireOpenLobby(state);
      final joined = await _joinState(
        store: txStore,
        state: state,
        userIdentifier: userIdentifier,
        displayName: displayName,
        countryId: countryId,
      );
      return joined.withValue(joined.value.match);
    });
    outcome.notifications.deliver(_broadcaster);
    return outcome.value;
  }
}
