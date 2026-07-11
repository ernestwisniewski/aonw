part of 'match_state_access.dart';

extension MatchStateAccessLifecycle on MatchStateAccess {
  StoredMatchState abandonedState(
    StoredMatchState state, {
    required String reason,
    required DateTime endedAt,
    String? userIdentifier,
  }) {
    return state.copyWith(
      match: state.match.copyWith(
        state: 'abandoned',
        endedAt: endedAt.toUtc(),
        outcomeCondition: null,
        winnerPlayerId: null,
        autoStartAt: null,
      ),
      snapshot: state.snapshot.copyWith(
        state: {
          ...state.snapshot.state,
          'phase': 'abandoned',
          'reason': reason,
          'leftUserIdentifier': ?userIdentifier,
        },
      ),
    );
  }
}
