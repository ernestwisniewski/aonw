part of 'match_query_service.dart';

extension MatchQueryServiceViews on MatchQueryService {
  Future<WireSnapshot> loadSnapshot({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) async {
    final state = await _stateAccess.requireMatch(store, matchId);
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    return _projectPlayerView(
      () => _viewProjector.snapshotFor(
        state.snapshot,
        MatchRecipient(userIdentifier: userIdentifier, playerId: player.id),
      ),
    );
  }

  Future<List<WireEvent>> listEvents({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
  }) async {
    final state = await _stateAccess.requireMatch(store, matchId);
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    final events = await store.listEvents(matchId, afterOffset);
    final recipient = MatchRecipient(
      userIdentifier: userIdentifier,
      playerId: player.id,
    );
    return _projectPlayerView(() {
      return [
        for (final event in events) _viewProjector.eventFor(event, recipient),
      ];
    });
  }
}

T _projectPlayerView<T>(T Function() project) {
  try {
    return project();
  } catch (_) {
    throw multiplayerException(
      'snapshot_projection_failed',
      'Unable to project multiplayer state.',
    );
  }
}
