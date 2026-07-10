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
      while (true) {
        final state = await txStore.findOpenQuickplayCandidate(
          quickplayRequest,
        );
        if (state == null) {
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
        notifications = notifications.followedBy(joined.notifications);
        final advanced = await _lifecycle.advanceQuickplayLobby(
          store: txStore,
          state: joined.value,
          snapshotFactory: snapshotFactory,
        );
        return MatchMutationOutcome(
          advanced.value,
          notifications: notifications.followedBy(advanced.notifications),
        );
      }
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
      if (joined.value.match.quickplay && joined.value.match.state == 'open') {
        final advanced = await _lifecycle.advanceQuickplayLobby(
          store: txStore,
          state: joined.value,
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
