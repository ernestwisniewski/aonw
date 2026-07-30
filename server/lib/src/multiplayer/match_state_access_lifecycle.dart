part of 'match_state_access.dart';

extension MatchStateAccessLifecycle on MatchStateAccess {
  StoredMatchState abandonedState(
    StoredMatchState state, {
    required MatchAbandonmentReason reason,
    required DateTime endedAt,
    String? userIdentifier,
  }) {
    final transition = const MatchLifecycleStateAdapter().apply(
      state,
      AbandonMatchLifecycle(reason),
      endedAt: endedAt,
      userIdentifier: userIdentifier,
    );
    if (transition.rejection case final rejection?) {
      throw StateError('Abandon match lifecycle rejected: ${rejection.code}.');
    }
    return transition.state;
  }
}
