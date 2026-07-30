/// A match phase understood by the application layer.
///
/// Persisted and player-wire strings are deliberately kept outside this
/// hierarchy. The server owns authoritative transitions.
sealed class MatchLifecycleState {
  const MatchLifecycleState();

  bool get isOpen => this is OpenMatchLifecycleState;

  bool get isRunning => this is RunningMatchLifecycleState;

  bool get isTerminal =>
      this is FinishedMatchLifecycleState ||
      this is AbandonedMatchLifecycleState;

  bool get acceptsConnectionMutation => isOpen || isRunning;
}

final class OpenMatchLifecycleState extends MatchLifecycleState {
  const OpenMatchLifecycleState();

  @override
  bool operator ==(Object other) => other is OpenMatchLifecycleState;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class RunningMatchLifecycleState extends MatchLifecycleState {
  const RunningMatchLifecycleState();

  @override
  bool operator ==(Object other) => other is RunningMatchLifecycleState;

  @override
  int get hashCode => runtimeType.hashCode;
}

enum MatchCompletionReason {
  conquest,
  domination,
  cultural,
  score,
  resignation,
  draw,
}

final class FinishedMatchLifecycleState extends MatchLifecycleState {
  const FinishedMatchLifecycleState({required this.reason});

  final MatchCompletionReason reason;

  @override
  bool operator ==(Object other) =>
      other is FinishedMatchLifecycleState && other.reason == reason;

  @override
  int get hashCode => Object.hash(FinishedMatchLifecycleState, reason);
}

enum MatchAbandonmentReason {
  playerResigned,
  ownerLeft,
  playerLeft,
  quickplayStale,
  protocolUpgrade,
  allPlayersResigned,
  noAlivePlayersAfterResignation,
}

final class AbandonedMatchLifecycleState extends MatchLifecycleState {
  const AbandonedMatchLifecycleState({required this.reason});

  final MatchAbandonmentReason reason;

  @override
  bool operator ==(Object other) =>
      other is AbandonedMatchLifecycleState && other.reason == reason;

  @override
  int get hashCode => Object.hash(AbandonedMatchLifecycleState, reason);
}
