import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/lobby_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/match_activity_tracker.dart';
import 'package:aonw_server/src/multiplayer/match_turn_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';

final class MatchParticipantConnectionTransition {
  const MatchParticipantConnectionTransition({
    required this.state,
    required this.lease,
    required this.stateChanged,
  });

  final StoredMatchState state;
  final StoredMatchPresenceLease lease;
  final bool stateChanged;
}

/// Pure aggregate mutation for one authorized participant connection.
final class MatchParticipantConnectionPolicy {
  const MatchParticipantConnectionPolicy({
    required LobbyPresencePolicy presencePolicy,
    required MatchTurnPresencePolicy turnPresencePolicy,
  }) : _presencePolicy = presencePolicy,
       _turnPresencePolicy = turnPresencePolicy;

  static const _snapshotCodec = RunningMatchSnapshotCodec();
  static const _activityTracker = MatchActivityTracker();

  final LobbyPresencePolicy _presencePolicy;
  final MatchTurnPresencePolicy _turnPresencePolicy;

  MatchParticipantConnectionTransition connect({
    required StoredMatchState state,
    required int playerIndex,
    required String userIdentifier,
    required String connectionGeneration,
    required DateTime nowUtc,
    required bool running,
  }) {
    final lease = _presencePolicy.connectedLease(
      userIdentifier: userIdentifier,
      connectionGeneration: connectionGeneration,
      nowUtc: nowUtc,
    );
    final players = [...state.match.players];
    final player = players[playerIndex];
    final restartTurnClock =
        running &&
        _turnPresencePolicy.shouldRestartClockOnConnection(
          state,
          player,
          nowUtc: nowUtc,
        );
    final visiblyChanged =
        player.connectionState != WirePlayerConnectionState.connected;
    players[playerIndex] = player.copyWith(
      connectionState: WirePlayerConnectionState.connected,
    );
    var updated = state.copyWith(
      match: state.match.copyWith(players: players),
      presenceLeases: {...state.presenceLeases, userIdentifier: lease},
    );
    if (restartTurnClock) updated = _restartTurnClock(updated, nowUtc);
    final stateChanged = visiblyChanged || restartTurnClock;
    if (running && stateChanged) {
      updated = _activityTracker.record(updated, nowUtc);
    }
    return MatchParticipantConnectionTransition(
      state: updated,
      lease: lease,
      stateChanged: stateChanged,
    );
  }

  StoredMatchState _restartTurnClock(
    StoredMatchState state,
    DateTime restartedAt,
  ) {
    final decoded = _snapshotCodec.decode(
      match: state.match,
      snapshot: state.snapshot,
    );
    final canonical = _snapshotCodec.canonicalWithValidatedRoster(
      decoded,
      match: state.match,
    );
    final snapshot = _snapshotCodec.encodeCanonical(
      decoded,
      canonical.copyWith(
        domain: canonical.domain.copyWith(turnStartedAt: restartedAt),
      ),
    );
    return state.copyWith(
      snapshot: _activityTracker.preserveActivity(state.snapshot, snapshot),
    );
  }
}
