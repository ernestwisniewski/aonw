import 'package:aonw_core/game/application/lifecycle/match_lifecycle_state.dart';

sealed class MatchLifecycleAction {
  const MatchLifecycleAction();
}

final class StartMatchLifecycle extends MatchLifecycleAction {
  const StartMatchLifecycle();
}

final class FinishMatchLifecycle extends MatchLifecycleAction {
  const FinishMatchLifecycle(this.reason);

  final MatchCompletionReason reason;
}

final class AbandonMatchLifecycle extends MatchLifecycleAction {
  const AbandonMatchLifecycle(this.reason);

  final MatchAbandonmentReason reason;
}

final class MatchLifecycleRejectionReason {
  const MatchLifecycleRejectionReason(this.code);

  static const invalidTransition = MatchLifecycleRejectionReason(
    'invalid_lifecycle_transition',
  );
  static const matchNotOpen = MatchLifecycleRejectionReason('match_not_open');
  static const matchTerminal = MatchLifecycleRejectionReason('match_terminal');
  static const invalidMetadata = MatchLifecycleRejectionReason(
    'invalid_lifecycle_metadata',
  );
  static const observedState = MatchLifecycleRejectionReason(
    'observed_lifecycle_state',
  );

  final String code;
}

sealed class MatchLifecycleTransition {
  const MatchLifecycleTransition({required this.state});

  final MatchLifecycleState state;
}

final class MatchLifecycleAccepted extends MatchLifecycleTransition {
  const MatchLifecycleAccepted({required super.state, required this.changed});

  final bool changed;
}

final class MatchLifecycleRejected extends MatchLifecycleTransition {
  const MatchLifecycleRejected({required super.state, required this.reason});

  final MatchLifecycleRejectionReason reason;
}

/// The single phase-transition policy used by authoritative server services.
final class MatchLifecycleMachine {
  const MatchLifecycleMachine();

  MatchLifecycleTransition apply(
    MatchLifecycleState state,
    MatchLifecycleAction action,
  ) {
    return switch (state) {
      OpenMatchLifecycleState() => _fromOpen(state, action),
      RunningMatchLifecycleState() => _fromRunning(state, action),
      FinishedMatchLifecycleState() => _fromFinished(state, action),
      AbandonedMatchLifecycleState() => _fromAbandoned(state, action),
    };
  }

  MatchLifecycleTransition _fromOpen(
    OpenMatchLifecycleState state,
    MatchLifecycleAction action,
  ) {
    return switch (action) {
      StartMatchLifecycle() => const MatchLifecycleAccepted(
        state: RunningMatchLifecycleState(),
        changed: true,
      ),
      FinishMatchLifecycle() => _rejected(
        state,
        MatchLifecycleRejectionReason.invalidTransition,
      ),
      AbandonMatchLifecycle(:final reason) => MatchLifecycleAccepted(
        state: AbandonedMatchLifecycleState(reason: reason),
        changed: true,
      ),
    };
  }

  MatchLifecycleTransition _fromRunning(
    RunningMatchLifecycleState state,
    MatchLifecycleAction action,
  ) {
    return switch (action) {
      StartMatchLifecycle() => _rejected(
        state,
        MatchLifecycleRejectionReason.matchNotOpen,
      ),
      FinishMatchLifecycle(:final reason) => MatchLifecycleAccepted(
        state: FinishedMatchLifecycleState(reason: reason),
        changed: true,
      ),
      AbandonMatchLifecycle(:final reason) => MatchLifecycleAccepted(
        state: AbandonedMatchLifecycleState(reason: reason),
        changed: true,
      ),
    };
  }

  MatchLifecycleTransition _fromFinished(
    FinishedMatchLifecycleState state,
    MatchLifecycleAction action,
  ) {
    return switch (action) {
      FinishMatchLifecycle(:final reason) when reason == state.reason =>
        MatchLifecycleAccepted(state: state, changed: false),
      StartMatchLifecycle() ||
      FinishMatchLifecycle() ||
      AbandonMatchLifecycle() => _rejected(
        state,
        MatchLifecycleRejectionReason.matchTerminal,
      ),
    };
  }

  MatchLifecycleTransition _fromAbandoned(
    AbandonedMatchLifecycleState state,
    MatchLifecycleAction action,
  ) {
    return switch (action) {
      AbandonMatchLifecycle(:final reason) when reason == state.reason =>
        MatchLifecycleAccepted(state: state, changed: false),
      StartMatchLifecycle() ||
      FinishMatchLifecycle() ||
      AbandonMatchLifecycle() => _rejected(
        state,
        MatchLifecycleRejectionReason.matchTerminal,
      ),
    };
  }

  MatchLifecycleRejected _rejected(
    MatchLifecycleState state,
    MatchLifecycleRejectionReason reason,
  ) => MatchLifecycleRejected(state: state, reason: reason);
}
