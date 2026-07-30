import 'package:aonw_core/application.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';

const _wireAdapter = MatchLifecycleWireAdapter();
const _machine = MatchLifecycleMachine();

final class StoredMatchLifecycleTransition {
  const StoredMatchLifecycleTransition({
    required this.state,
    required this.changed,
    this.rejection,
  });

  final StoredMatchState state;
  final bool changed;
  final MatchLifecycleRejectionReason? rejection;
}

/// Authoritative server application boundary for match phase transitions.
///
/// This is the only layer that couples typed lifecycle decisions to the
/// existing `WireMatch` and `WireSnapshot` string fields.
final class MatchLifecycleStateAdapter {
  const MatchLifecycleStateAdapter();

  /// Phase-only predicate for call sites that receive a generated `WireMatch`
  /// without the terminal snapshot metadata required to reconstruct reasons.
  bool isRunningWireMatch(WireMatch match) =>
      match.state ==
      _wireAdapter.encodeState(const RunningMatchLifecycleState());

  MatchLifecycleState lifecycleOf(StoredMatchState state) {
    final terminalReason = switch (state.match.state) {
      'finished' => state.match.outcomeCondition,
      'abandoned' => state.snapshot.state['reason'] as String?,
      _ => null,
    };
    final lifecycle = _wireAdapter.decodeState(
      state.match.state,
      terminalReason: terminalReason,
    );
    _validateMetadata(state, lifecycle);
    return lifecycle;
  }

  StoredMatchLifecycleTransition apply(
    StoredMatchState state,
    MatchLifecycleAction action, {
    DateTime? endedAt,
    String? winnerPlayerId,
    String? userIdentifier,
  }) {
    final MatchLifecycleState lifecycle;
    try {
      lifecycle = lifecycleOf(state);
    } on FormatException {
      return StoredMatchLifecycleTransition(
        state: state,
        changed: false,
        rejection: MatchLifecycleRejectionReason.invalidMetadata,
      );
    }
    final transition = _machine.apply(lifecycle, action);
    if (transition is MatchLifecycleRejected) {
      return StoredMatchLifecycleTransition(
        state: state,
        changed: false,
        rejection: transition.reason,
      );
    }
    final accepted = transition as MatchLifecycleAccepted;
    if (!accepted.changed) {
      return StoredMatchLifecycleTransition(state: state, changed: false);
    }

    final next = switch (accepted.state) {
      OpenMatchLifecycleState() => throw StateError(
        'The lifecycle machine cannot transition back to open.',
      ),
      RunningMatchLifecycleState() => _running(state),
      FinishedMatchLifecycleState(:final reason) => _finished(
        state,
        reason: reason,
        endedAt: _requireEndedAt(endedAt),
        winnerPlayerId: winnerPlayerId,
      ),
      AbandonedMatchLifecycleState(:final reason) => _abandoned(
        state,
        reason: reason,
        endedAt: _requireEndedAt(endedAt),
        userIdentifier: userIdentifier,
      ),
    };
    return StoredMatchLifecycleTransition(state: next, changed: true);
  }

  StoredMatchState _running(StoredMatchState state) {
    return state.copyWith(
      match: state.match.copyWith(
        state: _wireAdapter.encodeState(const RunningMatchLifecycleState()),
        endedAt: null,
        outcomeCondition: null,
        winnerPlayerId: null,
        autoStartAt: null,
      ),
      snapshot: state.snapshot.copyWith(
        state: {...state.snapshot.state, 'phase': 'running'},
      ),
    );
  }

  StoredMatchState _finished(
    StoredMatchState state, {
    required MatchCompletionReason reason,
    required DateTime endedAt,
    required String? winnerPlayerId,
  }) {
    final draw = reason == MatchCompletionReason.draw;
    if (draw && winnerPlayerId != null) {
      throw StateError('A draw cannot have a winner.');
    }
    if (!draw && winnerPlayerId == null) {
      throw StateError('A finished $reason outcome requires a winner.');
    }
    return state.copyWith(
      match: state.match.copyWith(
        state: _wireAdapter.encodeState(
          FinishedMatchLifecycleState(reason: reason),
        ),
        endedAt: endedAt.toUtc(),
        outcomeCondition: _wireAdapter.encodeFinishedReason(reason),
        winnerPlayerId: winnerPlayerId,
        autoStartAt: null,
      ),
      snapshot: state.snapshot.copyWith(
        state: {...state.snapshot.state, 'phase': 'finished'},
      ),
    );
  }

  StoredMatchState _abandoned(
    StoredMatchState state, {
    required MatchAbandonmentReason reason,
    required DateTime endedAt,
    required String? userIdentifier,
  }) {
    final reasonCode = _wireAdapter.encodeAbandonmentReason(reason);
    return state.copyWith(
      match: state.match.copyWith(
        state: _wireAdapter.encodeState(
          AbandonedMatchLifecycleState(reason: reason),
        ),
        endedAt: endedAt.toUtc(),
        outcomeCondition: null,
        winnerPlayerId: null,
        autoStartAt: null,
      ),
      snapshot: state.snapshot.copyWith(
        state: {
          ...state.snapshot.state,
          'phase': 'abandoned',
          'reason': reasonCode,
          'leftUserIdentifier': ?userIdentifier,
        },
      ),
    );
  }

  DateTime _requireEndedAt(DateTime? endedAt) {
    if (endedAt == null) {
      throw StateError('A terminal lifecycle transition requires endedAt.');
    }
    return endedAt;
  }

  void _validateMetadata(
    StoredMatchState state,
    MatchLifecycleState lifecycle,
  ) {
    final match = state.match;
    switch (lifecycle) {
      case OpenMatchLifecycleState():
        _requireNoTerminalMetadata(
          endedAt: match.endedAt,
          outcomeCondition: match.outcomeCondition,
          winnerPlayerId: match.winnerPlayerId,
        );
      case RunningMatchLifecycleState():
        _validateRunningMetadata(match);
      case FinishedMatchLifecycleState(:final reason):
        _validateFinishedMetadata(match, reason);
      case AbandonedMatchLifecycleState():
        _validateAbandonedMetadata(match);
    }
  }

  void _validateRunningMetadata(WireMatch match) {
    _requireNoTerminalMetadata(
      endedAt: match.endedAt,
      outcomeCondition: match.outcomeCondition,
      winnerPlayerId: match.winnerPlayerId,
    );
    if (match.autoStartAt != null) {
      throw const FormatException(
        'Running match lifecycle cannot retain autoStartAt.',
      );
    }
  }

  void _validateFinishedMetadata(
    WireMatch match,
    MatchCompletionReason reason,
  ) {
    _requireTerminalTimestampAndNoAutoStart(match);
    final winner = match.winnerPlayerId;
    if (reason == MatchCompletionReason.draw) {
      if (winner != null) {
        throw const FormatException(
          'Finished draw lifecycle cannot have a winner.',
        );
      }
    } else if (winner == null || winner.isEmpty) {
      throw const FormatException(
        'Finished non-draw lifecycle requires a winner.',
      );
    }
  }

  void _validateAbandonedMetadata(WireMatch match) {
    _requireTerminalTimestampAndNoAutoStart(match);
    if (match.outcomeCondition != null || match.winnerPlayerId != null) {
      throw const FormatException(
        'Abandoned lifecycle cannot retain outcome metadata.',
      );
    }
  }

  void _requireNoTerminalMetadata({
    required DateTime? endedAt,
    required String? outcomeCondition,
    required String? winnerPlayerId,
  }) {
    if (endedAt != null || outcomeCondition != null || winnerPlayerId != null) {
      throw const FormatException(
        'Non-terminal match lifecycle cannot retain terminal metadata.',
      );
    }
  }

  void _requireTerminalTimestampAndNoAutoStart(WireMatch match) {
    if (match.endedAt == null) {
      throw const FormatException('Terminal match lifecycle requires endedAt.');
    }
    if (match.autoStartAt != null) {
      throw const FormatException(
        'Terminal match lifecycle cannot retain autoStartAt.',
      );
    }
  }
}
