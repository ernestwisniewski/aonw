import 'package:aonw_server/src/multiplayer/lobby_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/match_lifecycle_state_adapter.dart';
import 'package:aonw_server/src/multiplayer/match_mutation_outcome.dart';
import 'package:aonw_server/src/multiplayer/match_participant_connection_policy.dart';
import 'package:aonw_server/src/multiplayer/match_turn_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';

typedef OpenQuickplayAdvancer =
    Future<MatchMutationOutcome<StoredMatchState>> Function({
      required MultiplayerMatchStore store,
      required StoredMatchState state,
      required bool broadcastUnchanged,
    });

/// Coordinates the transaction-local persistence of a participant connection.
final class MatchParticipantConnectionCoordinator {
  const MatchParticipantConnectionCoordinator({
    required MatchParticipantConnectionPolicy connectionPolicy,
    required DateTime Function() nowUtc,
  }) : _connectionPolicy = connectionPolicy,
       _nowUtc = nowUtc;

  factory MatchParticipantConnectionCoordinator.bind(
    (LobbyPresencePolicy, MatchTurnPresencePolicy, DateTime Function())
    dependencies,
  ) {
    final (presencePolicy, turnPresencePolicy, nowUtc) = dependencies;
    return MatchParticipantConnectionCoordinator(
      connectionPolicy: MatchParticipantConnectionPolicy(
        presencePolicy: presencePolicy,
        turnPresencePolicy: turnPresencePolicy,
      ),
      nowUtc: nowUtc,
    );
  }

  static const _lifecycleAdapter = MatchLifecycleStateAdapter();

  final MatchParticipantConnectionPolicy _connectionPolicy;
  final DateTime Function() _nowUtc;

  Future<MatchMutationOutcome<StoredMatchState>> connect({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required int playerIndex,
    required String connectionGeneration,
    required OpenQuickplayAdvancer advanceQuickplay,
  }) async {
    final matchId = state.match.id;
    final userIdentifier = state.match.players[playerIndex].userId;
    final lifecycle = _lifecycleAdapter.lifecycleOf(state);
    if (!lifecycle.acceptsConnectionMutation) {
      return MatchMutationOutcome(state);
    }
    final transition = _connectionPolicy.connect(
      state: state,
      playerIndex: playerIndex,
      userIdentifier: userIdentifier,
      connectionGeneration: connectionGeneration,
      nowUtc: _nowUtc(),
      running: lifecycle.isRunning,
    );
    if (transition.stateChanged) await store.saveState(transition.state);
    await store.upsertPresenceLease(matchId: matchId, lease: transition.lease);
    if (lifecycle.isOpen && transition.state.match.quickplay) {
      return advanceQuickplay(
        store: store,
        state: transition.state,
        broadcastUnchanged: transition.stateChanged,
      );
    }
    return MatchMutationOutcome(
      transition.state,
      notifications: transition.stateChanged
          ? MatchNotificationPlan.broadcastState(transition.state)
          : const MatchNotificationPlan.empty(),
    );
  }
}
