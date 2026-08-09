import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/lobby_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/match_activity_tracker.dart';
import 'package:aonw_server/src/multiplayer/match_broadcaster.dart';
import 'package:aonw_server/src/multiplayer/match_lifecycle_state_adapter.dart';
import 'package:aonw_server/src/multiplayer/match_mutation_outcome.dart';
import 'package:aonw_server/src/multiplayer/match_participant_connection_coordinator.dart';
import 'package:aonw_server/src/multiplayer/match_state_access.dart';
import 'package:aonw_server/src/multiplayer/match_turn_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/quickplay_lobby_policy.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/wire_player_domain_mapper.dart';

part 'match_lifecycle_service_quickplay.dart';
part 'match_lifecycle_service_presence.dart';
part 'match_lifecycle_service_presence_expiry.dart';
part 'match_lifecycle_service_resignation.dart';

const _runningMatchSnapshotCodec = RunningMatchSnapshotCodec();
const _matchLifecycleStateAdapter = MatchLifecycleStateAdapter();
const _matchActivityTracker = MatchActivityTracker();
typedef _Connections = MatchParticipantConnectionCoordinator;

final class MatchLifecycleService {
  MatchLifecycleService({
    required MatchStateAccess stateAccess,
    required MatchBroadcaster broadcaster,
    required QuickplayLobbyPolicy quickplayLobbyPolicy,
    required (LobbyPresencePolicy, MatchTurnPresencePolicy) presencePolicies,
    required PresenceGenerationGenerator presenceGenerationGenerator,
    required DateTime Function() nowUtc,
  }) : _stateAccess = stateAccess,
       _broadcaster = broadcaster,
       _quickplayLobbyPolicy = quickplayLobbyPolicy,
       _presencePolicy = presencePolicies.$1,
       _presenceGenerationGenerator = presenceGenerationGenerator,
       _connections = _Connections.bind((
         presencePolicies.$1,
         presencePolicies.$2,
         nowUtc,
       )),
       _nowUtc = nowUtc;

  final MatchStateAccess _stateAccess;
  final MatchBroadcaster _broadcaster;
  final QuickplayLobbyPolicy _quickplayLobbyPolicy;
  final LobbyPresencePolicy _presencePolicy;
  final PresenceGenerationGenerator _presenceGenerationGenerator;
  final _Connections _connections;
  final LobbyRosterPolicy _rosterPolicy = const LobbyRosterPolicy();
  final DateTime Function() _nowUtc;
  ExpiredPresenceLeaseCursor? _nextPresenceSweepCursor;

  Future<WireMatch> loadMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    final outcome = await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      _stateAccess.requireParticipant(state, userIdentifier);
      return advanceQuickplayLobby(
        store: txStore,
        state: state,
        snapshotFactory: snapshotFactory,
      );
    });
    outcome.notifications.deliver(_broadcaster);
    return outcome.value.match;
  }

  Future<WireMatch> startMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    final outcome = await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      if (state.match.ownerUserId != userIdentifier) {
        throw multiplayerException(
          'not_match_owner',
          'Only the owner can start this match.',
        );
      }
      if (!_matchLifecycleStateAdapter.lifecycleOf(state).isOpen) {
        throw multiplayerException(
          'match_not_open',
          'Only open matches can be started.',
        );
      }
      if (!_canStartLobby(state, nowUtc: _nowUtc())) {
        throw multiplayerException(
          'not_enough_players',
          'Every reserved human seat must be connected before the match starts.',
        );
      }
      return _startOpenMatch(
        store: txStore,
        state: state,
        snapshotFactory: snapshotFactory,
      );
    });
    outcome.notifications.deliver(_broadcaster);
    return outcome.value.match;
  }

  Future<WireMatch> resignMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) async {
    final outcome = await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      _stateAccess.requireParticipant(state, userIdentifier);
      final now = _nowUtc();
      final lifecycle = _matchLifecycleStateAdapter.lifecycleOf(state);
      final updated = switch (lifecycle) {
        RunningMatchLifecycleState() => _runningStateAfterParticipantResigned(
          state,
          userIdentifier: userIdentifier,
          endedAt: now,
        ),
        OpenMatchLifecycleState()
            when state.match.ownerUserId == userIdentifier =>
          _stateAccess.abandonedState(
            state,
            reason: MatchAbandonmentReason.playerResigned,
            endedAt: now,
            userIdentifier: userIdentifier,
          ),
        OpenMatchLifecycleState() => throw multiplayerException(
          'not_match_owner',
          'Only the owner can abandon an open lobby.',
        ),
        FinishedMatchLifecycleState() ||
        AbandonedMatchLifecycleState() => state,
      };
      await txStore.saveState(updated);
      if (_matchLifecycleStateAdapter.lifecycleOf(updated).isTerminal) {
        await txStore.deletePresenceLeases(matchId);
      } else {
        await txStore.deletePresenceLease(
          matchId: matchId,
          userIdentifier: userIdentifier,
        );
      }
      return MatchMutationOutcome(
        updated.match,
        notifications: MatchNotificationPlan.broadcastState(updated),
      );
    });
    outcome.notifications.deliver(_broadcaster);
    return outcome.value;
  }

  Future<void> leaveMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) async {
    final outcome = await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      _stateAccess.requireParticipant(state, userIdentifier);
      final updated = _stateAfterParticipantLeft(
        state,
        userIdentifier: userIdentifier,
      );
      await txStore.saveState(updated);
      if (_matchLifecycleStateAdapter.lifecycleOf(updated).isTerminal) {
        await txStore.deletePresenceLeases(matchId);
      } else {
        await txStore.deletePresenceLease(
          matchId: matchId,
          userIdentifier: userIdentifier,
        );
      }
      if (updated.match.quickplay &&
          _matchLifecycleStateAdapter.lifecycleOf(updated).isOpen) {
        final advanced = await advanceQuickplayLobby(
          store: txStore,
          state: updated,
          broadcastUnchanged: true,
        );
        return advanced.withValue(true);
      }
      return MatchMutationOutcome(
        true,
        notifications: MatchNotificationPlan.broadcastState(updated),
      );
    });
    outcome.notifications.deliver(_broadcaster);
  }

  bool _canStartLobby(StoredMatchState state, {required DateTime nowUtc}) {
    return _rosterPolicy.canStart(state.match) &&
        _presencePolicy.allHumanMembersLiveConnected(state, nowUtc: nowUtc);
  }

  StoredMatchState _runningStateAfterParticipantLeft(
    StoredMatchState state, {
    required String userIdentifier,
  }) {
    final players = [
      for (final player in state.match.players)
        player.userId == userIdentifier
            ? player.copyWith(
                connectionState: WirePlayerConnectionState.offline,
              )
            : player,
    ];
    return _matchActivityTracker.record(
      state.copyWith(match: state.match.copyWith(players: players)),
      _nowUtc(),
    );
  }

  StoredMatchState _stateAfterParticipantLeft(
    StoredMatchState state, {
    required String userIdentifier,
  }) {
    return switch (_matchLifecycleStateAdapter.lifecycleOf(state)) {
      RunningMatchLifecycleState() => _runningStateAfterParticipantLeft(
        state,
        userIdentifier: userIdentifier,
      ),
      OpenMatchLifecycleState() => _openStateAfterParticipantLeft(
        state,
        userIdentifier: userIdentifier,
      ),
      FinishedMatchLifecycleState() || AbandonedMatchLifecycleState() => state,
    };
  }

  StoredMatchState _openStateAfterParticipantLeft(
    StoredMatchState state, {
    required String userIdentifier,
  }) {
    if (state.match.quickplay) {
      return _openQuickplayStateAfterParticipantLeft(
        state,
        userIdentifier: userIdentifier,
      );
    }
    if (state.match.ownerUserId == userIdentifier) {
      return _stateAccess.abandonedState(
        state,
        reason: MatchAbandonmentReason.ownerLeft,
        endedAt: _nowUtc(),
        userIdentifier: userIdentifier,
      );
    }
    return state.copyWith(
      match: state.match.copyWith(
        players: [
          for (final player in state.match.players)
            if (player.userId != userIdentifier) player,
        ],
      ),
    );
  }

  Future<MatchMutationOutcome<StoredMatchState>> _startOpenMatch({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    final now = _nowUtc();
    final playerCount = _stateAccess.humanPlayerCount(state.match);
    final mapName = state.match.quickplay
        ? MapPlayerCapacityRules.multiplayerStartMapName(
            playerCount: playerCount,
            seed: StartingPositionSeed.fromParts([
              state.match.id,
              now,
              playerCount,
            ]),
          )
        : state.match.mapName;
    final lifecycleTransition = _matchLifecycleStateAdapter.apply(
      state,
      const StartMatchLifecycle(),
    );
    if (lifecycleTransition.rejection case final rejection?) {
      throw StateError('Start match lifecycle rejected: ${rejection.code}.');
    }
    final runningMatch = lifecycleTransition.state.match.copyWith(
      mapName: mapName,
      turn: 1,
    );
    final participants = runningMatch.players
        .map(domainPlayerFromWire)
        .toList(growable: false);
    final canonicalSnapshot = await snapshotFactory.create(
      matchId: runningMatch.id,
      matchName: runningMatch.name,
      mapName: runningMatch.mapName,
      participants: participants,
      startedAt: now,
    );
    final snapshot = _runningMatchSnapshotCodec.encodeInitial(
      match: runningMatch,
      snapshot: canonicalSnapshot,
    );
    final updated = _matchActivityTracker.record(
      state.copyWith(match: runningMatch, snapshot: snapshot),
      now,
    );
    await store.saveState(updated);
    return MatchMutationOutcome(
      updated,
      notifications: MatchNotificationPlan.broadcastState(updated),
    );
  }

  bool _sameInstant(DateTime? a, DateTime b) {
    return a != null && a.toUtc().isAtSameMomentAs(b.toUtc());
  }
}
