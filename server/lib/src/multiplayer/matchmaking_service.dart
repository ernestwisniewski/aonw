import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'initial_multiplayer_snapshot_factory.dart';
import 'match_broadcaster.dart';
import 'match_lifecycle_service.dart';
import 'match_state_access.dart';
import 'multiplayer_errors.dart';
import 'multiplayer_match_store.dart';
import 'player_seat_allocator.dart';

final class MatchmakingService {
  const MatchmakingService({
    required PlayerSeatAllocator seatAllocator,
    required MatchStateAccess stateAccess,
    required MatchBroadcaster broadcaster,
    required MatchLifecycleService lifecycle,
    required DateTime Function() nowUtc,
  }) : _seatAllocator = seatAllocator,
       _stateAccess = stateAccess,
       _broadcaster = broadcaster,
       _lifecycle = lifecycle,
       _nowUtc = nowUtc;

  final PlayerSeatAllocator _seatAllocator;
  final MatchStateAccess _stateAccess;
  final MatchBroadcaster _broadcaster;
  final MatchLifecycleService _lifecycle;
  final DateTime Function() _nowUtc;

  Future<WireMatch> quickplay({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) {
    return store.transaction((txStore) async {
      final quickplayRequest = _quickplayRequest(request);
      while (true) {
        final state = await txStore.findOpenQuickplayCandidate(
          quickplayRequest,
        );
        if (state == null) {
          final created = await _createMatch(
            store: txStore,
            userIdentifier: userIdentifier,
            displayName: displayName,
            request: quickplayRequest,
            quickplay: true,
          );
          return _lifecycle.advanceQuickplayLobby(
            store: txStore,
            state: (await txStore.findState(created.id, lock: true))!,
            snapshotFactory: snapshotFactory,
          );
        }
        if (await _lifecycle.abandonStaleQuickplayLobby(
          store: txStore,
          state: state,
        )) {
          continue;
        }
        final joined = await _joinState(
          store: txStore,
          state: state,
          userIdentifier: userIdentifier,
          displayName: displayName,
          countryId: quickplayRequest.countryId,
          broadcast: false,
        );
        return _lifecycle.advanceQuickplayLobby(
          store: txStore,
          state: (await txStore.findState(joined.id, lock: true))!,
          snapshotFactory: snapshotFactory,
        );
      }
    });
  }

  Future<WireMatch> createMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
  }) {
    return store.transaction((txStore) {
      return _createMatch(
        store: txStore,
        userIdentifier: userIdentifier,
        displayName: displayName,
        request: request,
      );
    });
  }

  Future<WireMatch> joinMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required String matchId,
    String? countryId,
  }) {
    return store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      final joined = await _joinState(
        store: txStore,
        state: state,
        userIdentifier: userIdentifier,
        displayName: displayName,
        countryId: countryId,
        broadcast: !state.match.quickplay,
      );
      if (joined.quickplay && joined.state == 'open') {
        return _lifecycle.advanceQuickplayLobby(
          store: txStore,
          state: (await txStore.findState(joined.id, lock: true))!,
        );
      }
      return joined;
    });
  }

  Future<WireMatch> joinPrivateMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required String inviteCode,
    String? countryId,
  }) {
    return store.transaction((txStore) async {
      final normalized = inviteCode.trim().toUpperCase();
      final state = await txStore.findPrivateState(normalized, lock: true);
      if (state == null) {
        throw multiplayerException(
          'private_match_not_found',
          'Private match not found.',
        );
      }
      return _joinState(
        store: txStore,
        state: state,
        userIdentifier: userIdentifier,
        displayName: displayName,
        countryId: countryId,
      );
    });
  }

  Future<WireMatch> _createMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
    bool quickplay = false,
  }) async {
    final matchId = 'match-${const Uuid().v4()}';
    final now = _nowUtc();
    final owner = _createHumanPlayer(
      userIdentifier: userIdentifier,
      displayName: displayName,
      index: 0,
      ready: false,
      requestedCountryId: request.countryId,
      existingPlayers: const [],
    );
    final match = WireMatch(
      id: matchId,
      ownerUserId: userIdentifier,
      name: request.name,
      mapName: request.mapName,
      players: [owner],
      maxPlayers: request.maxPlayers,
      minPlayers: request.minPlayers,
      quickplay: quickplay,
      turn: 0,
      state: 'open',
      createdAt: now,
      inviteCode: request.private ? _shortCode(matchId) : null,
    );
    final snapshot = WireSnapshot(
      matchId: matchId,
      offset: 0,
      save: const {},
      state: {'phase': 'lobby', 'mapName': request.mapName},
    );
    await store.createState(StoredMatchState(match: match, snapshot: snapshot));
    return match;
  }

  Future<WireMatch> _joinState({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required String userIdentifier,
    String? displayName,
    String? countryId,
    bool broadcast = true,
  }) async {
    final existingIndex = state.match.players.indexWhere(
      (player) => player.userId == userIdentifier,
    );
    if (existingIndex != -1) {
      final updated = await _updateExistingPlayerSeat(
        store: store,
        state: state,
        playerIndex: existingIndex,
        displayName: displayName,
        countryId: countryId,
        broadcast: broadcast,
      );
      return updated.match;
    }
    if (state.match.players.length >= state.match.maxPlayers) {
      throw multiplayerException('match_full', 'Match is full.');
    }
    final player = _createHumanPlayer(
      userIdentifier: userIdentifier,
      displayName: displayName,
      index: state.match.players.length,
      ready: false,
      requestedCountryId: countryId,
      existingPlayers: state.match.players,
    );
    final updated = state.copyWith(
      match: state.match.copyWith(players: [...state.match.players, player]),
    );
    await store.saveState(updated);
    if (broadcast) _broadcaster.broadcastState(updated);
    return updated.match;
  }

  Future<StoredMatchState> _updateExistingPlayerSeat({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required int playerIndex,
    String? displayName,
    String? countryId,
    bool broadcast = true,
  }) async {
    final players = state.match.players;
    final player = players[playerIndex];
    var updatedPlayer = player;
    final normalizedName = displayName?.trim();
    if (normalizedName != null &&
        normalizedName.isNotEmpty &&
        normalizedName != player.name) {
      updatedPlayer = updatedPlayer.copyWith(name: normalizedName);
    }
    final requestedCountry = _requestedCountry(countryId);
    if (requestedCountry != null && requestedCountry != player.country) {
      final taken = players.any(
        (other) =>
            other.userId != player.userId && other.country == requestedCountry,
      );
      if (taken) {
        throw multiplayerException(
          'country_unavailable',
          'Selected civilization is already taken.',
        );
      }
      updatedPlayer = updatedPlayer.copyWith(country: requestedCountry);
    }
    if (updatedPlayer == player) return state;

    final updatedPlayers = [...players];
    updatedPlayers[playerIndex] = updatedPlayer;
    final updated = state.copyWith(
      match: state.match.copyWith(players: updatedPlayers),
    );
    await store.saveState(updated);
    if (broadcast) _broadcaster.broadcastState(updated);
    return updated;
  }

  WirePlayer _createHumanPlayer({
    required String userIdentifier,
    required int index,
    required List<WirePlayer> existingPlayers,
    String? displayName,
    String? requestedCountryId,
    bool ready = false,
  }) {
    try {
      return _seatAllocator.createHumanPlayer(
        userIdentifier: userIdentifier,
        index: index,
        existingPlayers: existingPlayers,
        displayName: displayName,
        requestedCountryId: requestedCountryId,
        ready: ready,
      );
    } on PlayerSeatAllocationFailure catch (error) {
      throw multiplayerException(error.code, error.message);
    }
  }

  PlayerCountry? _requestedCountry(String? countryId) {
    try {
      return _seatAllocator.countryFromId(countryId);
    } on PlayerSeatAllocationFailure catch (error) {
      throw multiplayerException(error.code, error.message);
    }
  }

  CreateMatchRequest _quickplayRequest(CreateMatchRequest request) {
    return request.copyWith(
      name: 'Quickplay',
      maxPlayers: 4,
      minPlayers: 2,
      private: false,
    );
  }
}

String _shortCode(String matchId) {
  return matchId.replaceAll('-', '').substring(0, 8).toUpperCase();
}
