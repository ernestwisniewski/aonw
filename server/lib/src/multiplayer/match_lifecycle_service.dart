import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_player_capacity.dart';
import 'package:aonw_core/protocol.dart';

import 'initial_multiplayer_snapshot_factory.dart';
import 'match_broadcaster.dart';
import 'match_state_access.dart';
import 'multiplayer_errors.dart';
import 'multiplayer_match_store.dart';
import 'quickplay_lobby_policy.dart';

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
  }) {
    return store.transaction((txStore) async {
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
  }

  Future<WireMatch> startMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) {
    return store.transaction((txStore) async {
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
  }

  Future<WireMatch> resignMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) {
    return store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      _stateAccess.requireParticipant(state, userIdentifier);
      final updated = state.copyWith(
        match: state.match.copyWith(state: 'finished'),
        snapshot: state.snapshot.copyWith(
          state: {
            ...state.snapshot.state,
            'phase': 'finished',
            'resignedUserIdentifier': userIdentifier,
          },
        ),
      );
      await txStore.saveState(updated);
      _broadcaster.broadcastState(updated);
      return updated.match;
    });
  }

  Future<void> leaveMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) {
    return store.transaction((txStore) async {
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
      } else if (state.match.ownerUserId == userIdentifier) {
        updated = _stateAccess.abandonedState(
          state,
          reason: 'owner_left',
          userIdentifier: userIdentifier,
        );
      } else {
        final match = state.match.copyWith(
          players: [
            for (final player in state.match.players)
              if (player.userId != userIdentifier) player,
          ],
        );
        updated = state.copyWith(match: match);
      }
      await txStore.saveState(updated);
      if (updated.match.quickplay && updated.match.state == 'open') {
        await advanceQuickplayLobby(
          store: txStore,
          state: updated,
          broadcastUnchanged: true,
        );
      } else {
        _broadcaster.broadcastState(updated);
      }
    });
  }

  Future<bool> abandonStaleQuickplayLobby({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
  }) async {
    final match = state.match;
    if (!match.quickplay || match.state != 'open') return false;
    final stale = _quickplayLobbyPolicy.isStaleWaitingForPlayers(
      humanPlayers: _stateAccess.humanPlayerCount(match),
      minPlayers: match.minPlayers,
      createdAt: match.createdAt,
      nowUtc: _nowUtc(),
      currentAutoStartAt: match.autoStartAt,
    );
    if (!stale) return false;
    final abandoned = _stateAccess.abandonedState(
      state,
      reason: 'quickplay_stale',
    );
    await store.saveState(abandoned);
    _broadcaster.broadcastState(abandoned);
    return true;
  }

  Future<WireMatch> advanceQuickplayLobby({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
    bool broadcastUnchanged = false,
  }) async {
    final match = state.match;
    if (!match.quickplay || match.state != 'open') {
      if (broadcastUnchanged) _broadcaster.broadcastState(state);
      return match;
    }

    final decision = _quickplayLobbyPolicy.evaluate(
      humanPlayers: _stateAccess.humanPlayerCount(match),
      minPlayers: match.minPlayers,
      maxPlayers: match.maxPlayers,
      nowUtc: _nowUtc(),
      currentAutoStartAt: match.autoStartAt,
    );

    switch (decision.action) {
      case QuickplayLobbyAction.waitForPlayers:
        if (match.autoStartAt == null) {
          if (broadcastUnchanged) _broadcaster.broadcastState(state);
          return match;
        }
        final updated = state.copyWith(
          match: match.copyWith(autoStartAt: null),
        );
        await store.saveState(updated);
        _broadcaster.broadcastState(updated);
        return updated.match;
      case QuickplayLobbyAction.waitForCountdown:
        final autoStartAt = decision.autoStartAt;
        if (autoStartAt == null ||
            _sameInstant(match.autoStartAt, autoStartAt)) {
          if (broadcastUnchanged) _broadcaster.broadcastState(state);
          return match;
        }
        final updated = state.copyWith(
          match: match.copyWith(autoStartAt: autoStartAt),
        );
        await store.saveState(updated);
        _broadcaster.broadcastState(updated);
        return updated.match;
      case QuickplayLobbyAction.start:
        return _startOpenMatch(
          store: store,
          state: state,
          snapshotFactory: snapshotFactory,
        );
    }
  }

  Future<StoredMatchState> setParticipantConnectionState({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required WirePlayerConnectionState connectionState,
  }) {
    return store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      if (state.match.state != 'open' && state.match.state != 'running') {
        return state;
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
      if (player.connectionState == connectionState) return state;

      final players = [...state.match.players];
      players[playerIndex] = player.copyWith(connectionState: connectionState);
      final connectionUpdated = state.copyWith(
        match: state.match.copyWith(players: players),
      );
      final updated =
          connectionState == WirePlayerConnectionState.offline &&
              connectionUpdated.match.state == 'running' &&
              !_stateAccess.hasActiveHumanPlayer(
                connectionUpdated.match.players,
              )
          ? _stateAccess.abandonedState(
              connectionUpdated,
              reason: 'all_players_offline',
              userIdentifier: userIdentifier,
            )
          : connectionUpdated;
      await txStore.saveState(updated);
      _broadcaster.broadcastState(updated);
      return updated;
    });
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
        userIdentifier: userIdentifier,
      );
    }
    return state.copyWith(match: state.match.copyWith(players: players));
  }

  Future<WireMatch> _startOpenMatch({
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
      autoStartAt: null,
    );
    final snapshot = await snapshotFactory.create(
      match: runningMatch,
      startedAt: now,
    );
    final updated = state.copyWith(match: runningMatch, snapshot: snapshot);
    await store.saveState(updated);
    _broadcaster.broadcastState(updated);
    return updated.match;
  }

  bool _sameInstant(DateTime? a, DateTime b) {
    return a != null && a.toUtc().isAtSameMomentAs(b.toUtc());
  }
}
