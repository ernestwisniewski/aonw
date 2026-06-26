import 'dart:async';

import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_player_capacity.dart';
import 'package:aonw_core/protocol.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'initial_multiplayer_snapshot_factory.dart';
import 'match_connection_registry.dart';
import 'multiplayer_match_store.dart';
import 'player_seat_allocator.dart';
import 'quickplay_lobby_policy.dart';
import 'server_command_reducer.dart';

class MultiplayerEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<List<WireMatch>> listMatches(Session session) async {
    final user = _requireUser(session);
    return _hub.listMatches(
      store: _store(session),
      userIdentifier: user.userIdentifier,
    );
  }

  Future<WireMatch> createMatch(
    Session session,
    CreateMatchRequest request,
  ) async {
    final user = await _requirePlayerIdentity(session);
    return _hub.createMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      displayName: user.displayName,
      request: request,
    );
  }

  Future<WireMatch> quickplay(
    Session session,
    CreateMatchRequest request,
  ) async {
    final user = await _requirePlayerIdentity(session);
    return _hub.quickplay(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      displayName: user.displayName,
      request: request,
    );
  }

  Future<WireMatch> joinMatch(
    Session session,
    String matchId, [
    String? countryId,
  ]) async {
    final user = await _requirePlayerIdentity(session);
    return _hub.joinMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      displayName: user.displayName,
      matchId: matchId,
      countryId: countryId,
    );
  }

  Future<WireMatch> joinPrivateMatch(
    Session session,
    String inviteCode, [
    String? countryId,
  ]) async {
    final user = await _requirePlayerIdentity(session);
    return _hub.joinPrivateMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      displayName: user.displayName,
      inviteCode: inviteCode,
      countryId: countryId,
    );
  }

  Future<WireMatch> loadMatch(Session session, String matchId) async {
    final user = _requireUser(session);
    return _hub.loadMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<WireSnapshot> loadSnapshot(Session session, String matchId) async {
    final user = _requireUser(session);
    return _hub.loadSnapshot(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<List<WireEvent>> listEvents(
    Session session,
    String matchId,
    int afterOffset,
  ) async {
    final user = _requireUser(session);
    return _hub.listEvents(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
      afterOffset: afterOffset,
    );
  }

  Future<WireMatch> startMatch(Session session, String matchId) async {
    final user = _requireUser(session);
    return _hub.startMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<WireMatch> markMapLoaded(Session session, String matchId) async {
    final user = _requireUser(session);
    return _hub.loadMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<WireMatch> resignMatch(Session session, String matchId) async {
    final user = _requireUser(session);
    return _hub.resignMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<void> leaveMatch(Session session, String matchId) async {
    final user = _requireUser(session);
    await _hub.leaveMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Stream<MultiplayerServerMessage> connect(
    Session session,
    String matchId,
    int afterOffset,
    Stream<MultiplayerClientMessage> input,
  ) {
    final user = _requireUser(session);
    return _hub.connect(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
      afterOffset: afterOffset,
      input: input,
    );
  }

  AuthenticationInfo _requireUser(Session session) {
    final user = session.authenticated;
    if (user == null) {
      throw _multiplayerException(
        'auth_required',
        'Authentication is required.',
      );
    }
    return user;
  }

  Future<_PlayerIdentity> _requirePlayerIdentity(Session session) async {
    final user = _requireUser(session);
    final account = await AonwAccount.db.findFirstRow(
      session,
      where: (table) => table.authUserId.equals(
        UuidValue.withValidation(user.userIdentifier),
      ),
    );
    if (account == null) {
      throw _multiplayerException('account_not_found', 'Account is required.');
    }
    return _PlayerIdentity(
      userIdentifier: user.userIdentifier,
      displayName: account.displayName,
    );
  }

  MultiplayerMatchStore _store(Session session) {
    return ServerpodMultiplayerMatchStore(session);
  }
}

final _hub = RealtimeMatchHub();

class RealtimeMatchHub {
  RealtimeMatchHub({
    ServerCommandReducer commandReducer = const ServerCommandReducer(),
    PlayerSeatAllocator seatAllocator = const PlayerSeatAllocator(),
    QuickplayLobbyPolicy quickplayLobbyPolicy = const QuickplayLobbyPolicy(),
    DateTime Function()? nowUtc,
    MatchConnectionRegistry? connectionRegistry,
  }) : _commandReducer = commandReducer,
       _seatAllocator = seatAllocator,
       _quickplayLobbyPolicy = quickplayLobbyPolicy,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       _connectionRegistry = connectionRegistry ?? MatchConnectionRegistry();

  final ServerCommandReducer _commandReducer;
  final PlayerSeatAllocator _seatAllocator;
  final QuickplayLobbyPolicy _quickplayLobbyPolicy;
  final DateTime Function() _nowUtc;
  final MatchConnectionRegistry _connectionRegistry;

  Future<List<WireMatch>> listMatches({
    required MultiplayerMatchStore store,
    required String userIdentifier,
  }) async {
    final states = await store.listVisibleMatchStates(userIdentifier);
    return [for (final state in states) state.match];
  }

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
          return _advanceQuickplayLobby(
            store: txStore,
            state: (await txStore.findState(created.id, lock: true))!,
            snapshotFactory: snapshotFactory,
          );
        }
        if (await _abandonStaleQuickplayLobby(store: txStore, state: state)) {
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
        return _advanceQuickplayLobby(
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

  Future<bool> _abandonStaleQuickplayLobby({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
  }) async {
    final match = state.match;
    if (!match.quickplay || match.state != 'open') return false;
    final stale = _quickplayLobbyPolicy.isStaleWaitingForPlayers(
      humanPlayers: _humanPlayerCount(match),
      minPlayers: match.minPlayers,
      createdAt: match.createdAt,
      nowUtc: _nowUtc(),
      currentAutoStartAt: match.autoStartAt,
    );
    if (!stale) return false;
    final abandoned = _abandonedState(state, reason: 'quickplay_stale');
    await store.saveState(abandoned);
    _broadcastState(abandoned);
    return true;
  }

  Future<WireMatch> joinMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required String matchId,
    String? countryId,
  }) {
    return store.transaction((txStore) async {
      final state = await _requireMatch(txStore, matchId, lock: true);
      final joined = await _joinState(
        store: txStore,
        state: state,
        userIdentifier: userIdentifier,
        displayName: displayName,
        countryId: countryId,
        broadcast: !state.match.quickplay,
      );
      if (joined.quickplay && joined.state == 'open') {
        return _advanceQuickplayLobby(
          store: txStore,
          state: (await txStore.findState(joined.id, lock: true))!,
        );
      }
      return joined;
    });
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
      throw _multiplayerException('match_full', 'Match is full.');
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
    if (broadcast) _broadcastState(updated);
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
        throw _multiplayerException(
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
    if (broadcast) _broadcastState(updated);
    return updated;
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
        throw _multiplayerException(
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

  Future<WireMatch> loadMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    return store.transaction((txStore) async {
      final state = await _requireMatch(txStore, matchId, lock: true);
      _requireParticipant(state, userIdentifier);
      return _advanceQuickplayLobby(
        store: txStore,
        state: state,
        snapshotFactory: snapshotFactory,
      );
    });
  }

  Future<WireSnapshot> loadSnapshot({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) async {
    final state = await _requireMatch(store, matchId);
    _requireParticipant(state, userIdentifier);
    return state.snapshot;
  }

  Future<List<WireEvent>> listEvents({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
  }) async {
    final state = await _requireMatch(store, matchId);
    _requireParticipant(state, userIdentifier);
    return store.listEvents(matchId, afterOffset);
  }

  Future<WireMatch> startMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) {
    return store.transaction((txStore) async {
      final state = await _requireMatch(txStore, matchId, lock: true);
      if (state.match.ownerUserId != userIdentifier) {
        throw _multiplayerException(
          'not_match_owner',
          'Only the owner can start this match.',
        );
      }
      if (state.match.state != 'open') {
        throw _multiplayerException(
          'match_not_open',
          'Only open matches can be started.',
        );
      }
      if (state.match.players.length < state.match.minPlayers) {
        throw _multiplayerException(
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
      final state = await _requireMatch(txStore, matchId, lock: true);
      _requireParticipant(state, userIdentifier);
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
      _broadcastState(updated);
      return updated.match;
    });
  }

  Future<void> leaveMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) {
    return store.transaction((txStore) async {
      final state = await _requireMatch(txStore, matchId, lock: true);
      _requireParticipant(state, userIdentifier);
      final StoredMatchState updated;
      if (state.match.state == 'running') {
        updated = _runningStateAfterParticipantLeft(
          state,
          userIdentifier: userIdentifier,
        );
      } else if (state.match.ownerUserId == userIdentifier) {
        updated = _abandonedState(
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
        await _advanceQuickplayLobby(
          store: txStore,
          state: updated,
          broadcastUnchanged: true,
        );
      } else {
        _broadcastState(updated);
      }
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
    if (!_hasActiveHumanPlayer(
      players,
      excludingUserIdentifier: userIdentifier,
    )) {
      return _abandonedState(
        state,
        reason: 'player_left',
        userIdentifier: userIdentifier,
      );
    }
    return state.copyWith(match: state.match.copyWith(players: players));
  }

  Stream<MultiplayerServerMessage> connect({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
    required Stream<MultiplayerClientMessage> input,
  }) {
    return _connectionRegistry.connect(
      store: store,
      userIdentifier: userIdentifier,
      matchId: matchId,
      afterOffset: afterOffset,
      input: input,
      authorize: _authorizeConnection,
      updateConnectionState: _setParticipantConnectionState,
      handleClientMessage: _handleClientMessage,
      createMessage: _message,
    );
  }

  Future<void> _handleClientMessage({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required MultiplayerClientMessage message,
    required void Function(MultiplayerServerMessage message) emitToCaller,
  }) async {
    if (message.requestSnapshot) {
      final state = await _requireMatch(store, matchId);
      _requireParticipant(state, userIdentifier);
      emitToCaller(
        _message(
          matchId: state.match.id,
          offset: state.offset,
          match: state.match,
          snapshot: state.snapshot,
        ),
      );
    }

    final command = message.command;
    if (command == null) return;

    await store.transaction((txStore) async {
      final state = await _requireMatch(txStore, matchId, lock: true);
      final player = _requireParticipant(state, userIdentifier);
      if (command.actorPlayerId != player.id) {
        final ack = WireCommandAck(
          matchId: state.match.id,
          accepted: false,
          offset: state.offset,
          snapshot: state.snapshot,
          reason: 'Command actor does not match the authenticated player.',
        );
        emitToCaller(
          _message(matchId: state.match.id, offset: state.offset, ack: ack),
        );
        return;
      }

      final duplicate = await txStore.findEventByClientMessageId(
        state.match.id,
        actorPlayerId: player.id,
        clientMessageId: message.clientMessageId,
      );
      if (duplicate != null) {
        emitToCaller(
          _message(
            matchId: state.match.id,
            offset: duplicate.offset,
            ack: WireCommandAck(
              matchId: state.match.id,
              accepted: true,
              offset: duplicate.offset,
              snapshot: state.snapshot,
              events: duplicate.events,
            ),
          ),
        );
        return;
      }

      final reduction = await _commandReducer.reduce(
        match: state.match,
        snapshot: state.snapshot,
        wireCommand: command,
        actorPlayerId: player.id,
        now: DateTime.now().toUtc(),
      );
      if (!reduction.accepted) {
        final ack = WireCommandAck(
          matchId: state.match.id,
          accepted: false,
          offset: state.offset,
          snapshot: reduction.snapshot,
          reason: reduction.reason ?? 'Command rejected.',
        );
        emitToCaller(
          _message(matchId: state.match.id, offset: state.offset, ack: ack),
        );
        return;
      }

      final nextOffset = state.nextOffset();
      final nextSnapshot = reduction.snapshot.copyWith(offset: nextOffset);
      final nextSave = GameSave.fromJson(nextSnapshot.save);
      final event = WireEvent(
        matchId: state.match.id,
        offset: nextOffset,
        timestamp: DateTime.now().toUtc(),
        actorPlayerId: player.id,
        tick: command.tick,
        command: command.command,
        events: reduction.events.map(GameEventSerializer.toJson).toList(),
      );
      final updated = state.copyWith(
        match: state.match.copyWith(turn: nextSave.turn),
        snapshot: nextSnapshot,
      );
      await txStore.appendEvent(
        updated,
        event,
        actorPlayerId: player.id,
        clientMessageId: message.clientMessageId,
      );

      final update = _message(
        matchId: state.match.id,
        offset: event.offset,
        snapshot: updated.snapshot,
        event: event,
      );
      _connectionRegistry.broadcast(update, except: emitToCaller);

      emitToCaller(
        _message(
          matchId: state.match.id,
          offset: event.offset,
          ack: WireCommandAck(
            matchId: state.match.id,
            accepted: true,
            offset: event.offset,
            snapshot: updated.snapshot,
            events: event.events,
          ),
        ),
      );
    });
  }

  Future<StoredMatchState> _requireMatch(
    MultiplayerMatchStore store,
    String matchId, {
    bool lock = false,
  }) async {
    final state = await store.findState(matchId, lock: lock);
    if (state == null) {
      throw _multiplayerException('match_not_found', 'Match not found.');
    }
    return state;
  }

  Future<MatchConnectionAuthorization> _authorizeConnection({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
  }) async {
    final state = await _requireMatch(store, matchId);
    final player = _requireParticipant(state, userIdentifier);
    return MatchConnectionAuthorization(state: state, participant: player);
  }

  Future<StoredMatchState> _setParticipantConnectionState({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required WirePlayerConnectionState connectionState,
  }) {
    return store.transaction((txStore) async {
      final state = await _requireMatch(txStore, matchId, lock: true);
      if (state.match.state != 'open' && state.match.state != 'running') {
        return state;
      }
      final playerIndex = state.match.players.indexWhere(
        (player) => player.userId == userIdentifier,
      );
      if (playerIndex == -1) {
        throw _multiplayerException(
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
              !_hasActiveHumanPlayer(connectionUpdated.match.players)
          ? _abandonedState(
              connectionUpdated,
              reason: 'all_players_offline',
              userIdentifier: userIdentifier,
            )
          : connectionUpdated;
      await txStore.saveState(updated);
      _broadcastState(updated);
      return updated;
    });
  }

  WirePlayer _requireParticipant(
    StoredMatchState state,
    String userIdentifier,
  ) {
    for (final player in state.match.players) {
      if (player.userId == userIdentifier) return player;
    }
    throw _multiplayerException(
      'not_match_player',
      'User is not a participant in this match.',
    );
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
      throw _multiplayerException(error.code, error.message);
    }
  }

  PlayerCountry? _requestedCountry(String? countryId) {
    try {
      return _seatAllocator.countryFromId(countryId);
    } on PlayerSeatAllocationFailure catch (error) {
      throw _multiplayerException(error.code, error.message);
    }
  }

  Future<WireMatch> _advanceQuickplayLobby({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
    bool broadcastUnchanged = false,
  }) async {
    final match = state.match;
    if (!match.quickplay || match.state != 'open') {
      if (broadcastUnchanged) _broadcastState(state);
      return match;
    }

    final decision = _quickplayLobbyPolicy.evaluate(
      humanPlayers: _humanPlayerCount(match),
      minPlayers: match.minPlayers,
      maxPlayers: match.maxPlayers,
      nowUtc: _nowUtc(),
      currentAutoStartAt: match.autoStartAt,
    );

    switch (decision.action) {
      case QuickplayLobbyAction.waitForPlayers:
        if (match.autoStartAt == null) {
          if (broadcastUnchanged) _broadcastState(state);
          return match;
        }
        final updated = state.copyWith(
          match: match.copyWith(autoStartAt: null),
        );
        await store.saveState(updated);
        _broadcastState(updated);
        return updated.match;
      case QuickplayLobbyAction.waitForCountdown:
        final autoStartAt = decision.autoStartAt;
        if (autoStartAt == null ||
            _sameInstant(match.autoStartAt, autoStartAt)) {
          if (broadcastUnchanged) _broadcastState(state);
          return match;
        }
        final updated = state.copyWith(
          match: match.copyWith(autoStartAt: autoStartAt),
        );
        await store.saveState(updated);
        _broadcastState(updated);
        return updated.match;
      case QuickplayLobbyAction.start:
        return _startOpenMatch(
          store: store,
          state: state,
          snapshotFactory: snapshotFactory,
        );
    }
  }

  Future<WireMatch> _startOpenMatch({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    final now = _nowUtc();
    final playerCount = _humanPlayerCount(state.match);
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
    _broadcastState(updated);
    return updated.match;
  }

  CreateMatchRequest _quickplayRequest(CreateMatchRequest request) {
    return request.copyWith(
      name: 'Quickplay',
      maxPlayers: 4,
      minPlayers: 2,
      private: false,
    );
  }

  int _humanPlayerCount(WireMatch match) {
    return match.players
        .where((player) => player.kind == WirePlayerKind.human)
        .length;
  }

  bool _sameInstant(DateTime? a, DateTime b) {
    return a != null && a.toUtc().isAtSameMomentAs(b.toUtc());
  }

  StoredMatchState _abandonedState(
    StoredMatchState state, {
    required String reason,
    String? userIdentifier,
  }) {
    return state.copyWith(
      match: state.match.copyWith(state: 'abandoned', autoStartAt: null),
      snapshot: state.snapshot.copyWith(
        state: {
          ...state.snapshot.state,
          'phase': 'abandoned',
          'reason': reason,
          'leftUserIdentifier': ?userIdentifier,
        },
      ),
    );
  }

  bool _isActiveConnectionState(WirePlayerConnectionState state) {
    return switch (state) {
      WirePlayerConnectionState.connected ||
      WirePlayerConnectionState.connecting ||
      WirePlayerConnectionState.reconnecting => true,
      WirePlayerConnectionState.offline => false,
    };
  }

  bool _hasActiveHumanPlayer(
    Iterable<WirePlayer> players, {
    String? excludingUserIdentifier,
  }) {
    return players.any(
      (player) =>
          player.kind == WirePlayerKind.human &&
          player.userId != excludingUserIdentifier &&
          _isActiveConnectionState(player.connectionState),
    );
  }

  void _broadcastState(StoredMatchState state) {
    _connectionRegistry.broadcast(
      _message(
        matchId: state.match.id,
        offset: state.offset,
        match: state.match,
        snapshot: state.snapshot,
      ),
    );
  }
}

MultiplayerException _multiplayerException(String code, String message) {
  return MultiplayerException(code: code, message: message);
}

final class _PlayerIdentity {
  const _PlayerIdentity({
    required this.userIdentifier,
    required this.displayName,
  });

  final String userIdentifier;
  final String displayName;
}

MultiplayerServerMessage _message({
  required String matchId,
  required int offset,
  WireMatch? match,
  WireSnapshot? snapshot,
  WireEvent? event,
  WireCommandAck? ack,
}) {
  return MultiplayerServerMessage(
    serverMessageId: const Uuid().v4(),
    matchId: matchId,
    offset: offset,
    match: match,
    snapshot: snapshot,
    event: event,
    ack: ack,
  );
}

String _shortCode(String matchId) {
  return matchId.replaceAll('-', '').substring(0, 8).toUpperCase();
}
