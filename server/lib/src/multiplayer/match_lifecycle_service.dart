import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/match_broadcaster.dart';
import 'package:aonw_server/src/multiplayer/match_mutation_outcome.dart';
import 'package:aonw_server/src/multiplayer/match_state_access.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/quickplay_lobby_policy.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/wire_player_domain_mapper.dart';

part 'match_lifecycle_service_quickplay.dart';
part 'match_lifecycle_service_resignation.dart';

const _runningMatchSnapshotCodec = RunningMatchSnapshotCodec();

final class MatchLifecycleService {
  const MatchLifecycleService({
    required MatchStateAccess stateAccess,
    required MatchBroadcaster broadcaster,
    required QuickplayLobbyPolicy quickplayLobbyPolicy,
    required DateTime Function() nowUtc,
  }) : _stateAccess = stateAccess,
       _broadcaster = broadcaster,
       _quickplayLobbyPolicy = quickplayLobbyPolicy,
       _nowUtc = nowUtc;

  final MatchStateAccess _stateAccess;
  final MatchBroadcaster _broadcaster;
  final QuickplayLobbyPolicy _quickplayLobbyPolicy;
  final DateTime Function() _nowUtc;

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
    return outcome.value;
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
      if (state.match.state != 'open') {
        throw multiplayerException(
          'match_not_open',
          'Only open matches can be started.',
        );
      }
      if (state.match.players.length < state.match.minPlayers) {
        throw multiplayerException(
          'not_enough_players',
          'Not enough players to start this match.',
        );
      }
      return _startOpenMatch(
        store: txStore,
        state: state,
        snapshotFactory: snapshotFactory,
      );
    });
    outcome.notifications.deliver(_broadcaster);
    return outcome.value;
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
      final updated = switch (state.match.state) {
        'running' => _runningStateAfterParticipantResigned(
          state,
          userIdentifier: userIdentifier,
          endedAt: now,
        ),
        'open' when state.match.ownerUserId == userIdentifier =>
          _stateAccess.abandonedState(
            state,
            reason: 'player_resigned',
            endedAt: now,
            userIdentifier: userIdentifier,
          ),
        'open' => throw multiplayerException(
          'not_match_owner',
          'Only the owner can abandon an open lobby.',
        ),
        _ => state,
      };
      await txStore.saveState(updated);
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
      final StoredMatchState updated;
      if (state.match.state == 'running') {
        updated = _runningStateAfterParticipantLeft(
          state,
          userIdentifier: userIdentifier,
        );
      } else if (state.match.state == 'open' &&
          state.match.ownerUserId == userIdentifier) {
        updated = _stateAccess.abandonedState(
          state,
          reason: 'owner_left',
          endedAt: _nowUtc(),
          userIdentifier: userIdentifier,
        );
      } else if (state.match.state == 'open') {
        final match = state.match.copyWith(
          players: [
            for (final player in state.match.players)
              if (player.userId != userIdentifier) player,
          ],
        );
        updated = state.copyWith(match: match);
      } else {
        updated = state;
      }
      await txStore.saveState(updated);
      if (updated.match.quickplay && updated.match.state == 'open') {
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

  Future<StoredMatchState> setParticipantConnectionState({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required WirePlayerConnectionState connectionState,
  }) async {
    final outcome = await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      if (state.match.state != 'open' && state.match.state != 'running') {
        return MatchMutationOutcome(state);
      }
      final playerIndex = state.match.players.indexWhere(
        (player) => player.userId == userIdentifier,
      );
      if (playerIndex == -1) {
        throw multiplayerException(
          'not_match_player',
          'User is not a participant in this match.',
        );
      }
      final player = state.match.players[playerIndex];
      if (player.connectionState == connectionState) {
        return MatchMutationOutcome(state);
      }

      final players = [...state.match.players];
      players[playerIndex] = player.copyWith(connectionState: connectionState);
      final updated = state.copyWith(
        match: state.match.copyWith(players: players),
      );
      await txStore.saveState(updated);
      return MatchMutationOutcome(
        updated,
        notifications: MatchNotificationPlan.broadcastState(updated),
      );
    });
    outcome.notifications.deliver(_broadcaster);
    return outcome.value;
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
    if (!_stateAccess.hasActiveHumanPlayer(
      players,
      excludingUserIdentifier: userIdentifier,
    )) {
      return _stateAccess.abandonedState(
        state,
        reason: 'player_left',
        endedAt: _nowUtc(),
        userIdentifier: userIdentifier,
      );
    }
    return state.copyWith(match: state.match.copyWith(players: players));
  }

  Future<MatchMutationOutcome<WireMatch>> _startOpenMatch({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    final now = _nowUtc();
    final playerCount = _stateAccess.humanPlayerCount(state.match);
    final mapName = state.match.quickplay
        ? MapPlayerCapacityRules.multiplayerStartMapName(
            requestedMapName: state.match.mapName,
            playerCount: playerCount,
            seed: StartingPositionSeed.fromParts([
              state.match.id,
              now,
              playerCount,
            ]),
          )
        : state.match.mapName;
    final runningMatch = state.match.copyWith(
      mapName: mapName,
      state: 'running',
      turn: 1,
      endedAt: null,
      outcomeCondition: null,
      winnerPlayerId: null,
      autoStartAt: null,
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
    final updated = state.copyWith(match: runningMatch, snapshot: snapshot);
    await store.saveState(updated);
    return MatchMutationOutcome(
      updated.match,
      notifications: MatchNotificationPlan.broadcastState(updated),
    );
  }

  bool _sameInstant(DateTime? a, DateTime b) {
    return a != null && a.toUtc().isAtSameMomentAs(b.toUtc());
  }
}
