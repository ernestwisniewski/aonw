import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';

const defaultMultiplayerMatchInactivityTimeout = Duration(days: 7);

final class MatchActivityTracker {
  const MatchActivityTracker();

  static const _lastHumanActivityAtKey = 'lastHumanActivityAt';

  StoredMatchState record(StoredMatchState state, DateTime occurredAt) {
    return state.copyWith(snapshot: recordSnapshot(state.snapshot, occurredAt));
  }

  WireSnapshot recordSnapshot(WireSnapshot snapshot, DateTime occurredAt) {
    return snapshot.copyWith(
      state: {
        ...snapshot.state,
        _lastHumanActivityAtKey: occurredAt.toUtc().toIso8601String(),
      },
    );
  }

  WireSnapshot preserveActivity(WireSnapshot previous, WireSnapshot next) {
    final activity = previous.state[_lastHumanActivityAtKey];
    if (activity == null) return next;
    return next.copyWith(
      state: {...next.state, _lastHumanActivityAtKey: activity},
    );
  }

  bool hasExpired(
    StoredMatchState state, {
    required DateTime nowUtc,
    required Duration timeout,
  }) {
    final lastActivity = _lastActivityAt(state);
    return !lastActivity.add(timeout).isAfter(nowUtc.toUtc());
  }

  DateTime _lastActivityAt(StoredMatchState state) {
    final raw = state.snapshot.state[_lastHumanActivityAtKey];
    final parsed = raw is String ? DateTime.tryParse(raw) : null;
    return (parsed ?? state.match.createdAt).toUtc();
  }
}
