import 'dart:async';

import 'package:aonw_core/protocol.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'initial_multiplayer_snapshot_factory.dart';
import 'match_broadcaster.dart';
import 'match_command_service.dart';
import 'match_connection_registry.dart';
import 'match_lifecycle_service.dart';
import 'match_query_service.dart';
import 'match_state_access.dart';
import 'matchmaking_service.dart';
import 'multiplayer_errors.dart';
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
      throw multiplayerException(
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
      throw multiplayerException('account_not_found', 'Account is required.');
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
  }) : _connectionRegistry = connectionRegistry ?? MatchConnectionRegistry(),
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       _stateAccess = const MatchStateAccess() {
    _broadcaster = MatchBroadcaster(_connectionRegistry);
    _lifecycle = MatchLifecycleService(
      stateAccess: _stateAccess,
      broadcaster: _broadcaster,
      quickplayLobbyPolicy: quickplayLobbyPolicy,
      nowUtc: _nowUtc,
    );
    _matchmaking = MatchmakingService(
      seatAllocator: seatAllocator,
      stateAccess: _stateAccess,
      broadcaster: _broadcaster,
      lifecycle: _lifecycle,
      nowUtc: _nowUtc,
    );
    _queries = MatchQueryService(stateAccess: _stateAccess);
    _commands = MatchCommandService(
      commandReducer: commandReducer,
      stateAccess: _stateAccess,
      broadcaster: _broadcaster,
      nowUtc: _nowUtc,
    );
  }

  final MatchConnectionRegistry _connectionRegistry;
  final DateTime Function() _nowUtc;
  final MatchStateAccess _stateAccess;
  late final MatchBroadcaster _broadcaster;
  late final MatchLifecycleService _lifecycle;
  late final MatchmakingService _matchmaking;
  late final MatchQueryService _queries;
  late final MatchCommandService _commands;

  Future<List<WireMatch>> listMatches({
    required MultiplayerMatchStore store,
    required String userIdentifier,
  }) {
    return _queries.listMatches(store: store, userIdentifier: userIdentifier);
  }

  Future<WireMatch> quickplay({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) {
    return _matchmaking.quickplay(
      store: store,
      userIdentifier: userIdentifier,
      displayName: displayName,
      request: request,
      snapshotFactory: snapshotFactory,
    );
  }

  Future<WireMatch> createMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
  }) {
    return _matchmaking.createMatch(
      store: store,
      userIdentifier: userIdentifier,
      displayName: displayName,
      request: request,
    );
  }

  Future<WireMatch> joinMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required String matchId,
    String? countryId,
  }) {
    return _matchmaking.joinMatch(
      store: store,
      userIdentifier: userIdentifier,
      displayName: displayName,
      matchId: matchId,
      countryId: countryId,
    );
  }

  Future<WireMatch> joinPrivateMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required String inviteCode,
    String? countryId,
  }) {
    return _matchmaking.joinPrivateMatch(
      store: store,
      userIdentifier: userIdentifier,
      displayName: displayName,
      inviteCode: inviteCode,
      countryId: countryId,
    );
  }

  Future<WireMatch> loadMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) {
    return _lifecycle.loadMatch(
      store: store,
      userIdentifier: userIdentifier,
      matchId: matchId,
      snapshotFactory: snapshotFactory,
    );
  }

  Future<WireSnapshot> loadSnapshot({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) {
    return _queries.loadSnapshot(
      store: store,
      userIdentifier: userIdentifier,
      matchId: matchId,
    );
  }

  Future<List<WireEvent>> listEvents({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
  }) {
    return _queries.listEvents(
      store: store,
      userIdentifier: userIdentifier,
      matchId: matchId,
      afterOffset: afterOffset,
    );
  }

  Future<WireMatch> startMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) {
    return _lifecycle.startMatch(
      store: store,
      userIdentifier: userIdentifier,
      matchId: matchId,
      snapshotFactory: snapshotFactory,
    );
  }

  Future<WireMatch> resignMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) {
    return _lifecycle.resignMatch(
      store: store,
      userIdentifier: userIdentifier,
      matchId: matchId,
    );
  }

  Future<void> leaveMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) {
    return _lifecycle.leaveMatch(
      store: store,
      userIdentifier: userIdentifier,
      matchId: matchId,
    );
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
      authorize: _commands.authorizeConnection,
      updateConnectionState: _lifecycle.setParticipantConnectionState,
      handleClientMessage: _commands.handleClientMessage,
      createMessage: _broadcaster.message,
    );
  }
}

final class _PlayerIdentity {
  const _PlayerIdentity({
    required this.userIdentifier,
    required this.displayName,
  });

  final String userIdentifier;
  final String displayName;
}
