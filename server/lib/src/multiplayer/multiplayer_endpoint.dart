import 'dart:async';

import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/invite_code_generator.dart';
import 'package:aonw_server/src/multiplayer/lobby_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/match_activity_tracker.dart';
import 'package:aonw_server/src/multiplayer/match_broadcaster.dart';
import 'package:aonw_server/src/multiplayer/match_command_service.dart';
import 'package:aonw_server/src/multiplayer/match_connection_registry.dart';
import 'package:aonw_server/src/multiplayer/match_lifecycle_service.dart';
import 'package:aonw_server/src/multiplayer/match_query_service.dart';
import 'package:aonw_server/src/multiplayer/match_state_access.dart';
import 'package:aonw_server/src/multiplayer/match_turn_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/matchmaking_service.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_input_validator.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_version_guard.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart';
import 'package:aonw_server/src/multiplayer/player_seat_allocator.dart';
import 'package:aonw_server/src/multiplayer/quickplay_lobby_policy.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:serverpod/serverpod.dart';

part 'realtime_match_hub_api.dart';

class MultiplayerEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<List<WireMatch>> listMatches(
    Session session, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = _requireUser(session);
    return multiplayerHub.listMatches(
      store: _store(session),
      userIdentifier: user.userIdentifier,
    );
  }

  Future<WireMatch> createMatch(
    Session session,
    CreateMatchRequest request, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = await _requirePlayerIdentity(session);
    return multiplayerHub.createMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      displayName: user.displayName,
      request: request,
    );
  }

  Future<WireMatch> quickplay(
    Session session,
    CreateMatchRequest request, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = await _requirePlayerIdentity(session);
    return multiplayerHub.quickplay(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      displayName: user.displayName,
      request: request,
    );
  }

  Future<WireMatch> joinMatch(
    Session session,
    String matchId, {
    String? countryId,
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = await _requirePlayerIdentity(session);
    return multiplayerHub.joinMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      displayName: user.displayName,
      matchId: matchId,
      countryId: countryId,
    );
  }

  Future<WireMatch> joinPrivateMatch(
    Session session,
    String inviteCode, {
    String? countryId,
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = await _requirePlayerIdentity(session);
    return multiplayerHub.joinPrivateMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      displayName: user.displayName,
      inviteCode: inviteCode,
      countryId: countryId,
    );
  }

  Future<WireMatch> loadMatch(
    Session session,
    String matchId, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = _requireUser(session);
    return multiplayerHub.loadMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<WireSnapshot> loadSnapshot(
    Session session,
    String matchId, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = _requireUser(session);
    return multiplayerHub.loadSnapshot(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<List<WireEvent>> listEvents(
    Session session,
    String matchId,
    int afterOffset, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = _requireUser(session);
    return multiplayerHub.listEvents(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
      afterOffset: afterOffset,
    );
  }

  Future<WireMatch> startMatch(
    Session session,
    String matchId, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = _requireUser(session);
    return multiplayerHub.startMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<WireMatch> markMapLoaded(
    Session session,
    String matchId, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = _requireUser(session);
    return multiplayerHub.loadMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<WireMatch> resignMatch(
    Session session,
    String matchId, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = _requireUser(session);
    return multiplayerHub.resignMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Future<void> leaveMatch(
    Session session,
    String matchId, {
    required int? multiplayerVersion,
  }) async {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = _requireUser(session);
    await multiplayerHub.leaveMatch(
      store: _store(session),
      userIdentifier: user.userIdentifier,
      matchId: matchId,
    );
  }

  Stream<MultiplayerServerMessage> connect(
    Session session,
    String matchId,
    int afterOffset,
    Stream<MultiplayerClientMessage> input, {
    required int? multiplayerVersion,
  }) {
    requireCompatibleMultiplayerClient(multiplayerVersion);
    final user = _requireUser(session);
    return multiplayerHub.connect(
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

  MultiplayerMatchStore _store(Session session) =>
      ServerpodMultiplayerMatchStore(session);
}

final multiplayerHub = RealtimeMatchHub();

class RealtimeMatchHub {
  RealtimeMatchHub({
    ServerCommandReducer? commandReducer,
    PlayerSeatAllocator seatAllocator = const PlayerSeatAllocator(),
    QuickplayLobbyPolicy quickplayLobbyPolicy = const QuickplayLobbyPolicy(),
    DateTime Function()? nowUtc,
    MatchConnectionRegistry? connectionRegistry,
    InviteCodeGenerator? inviteCodeGenerator,
    PlayerMatchViewProjector viewProjector = const PlayerMatchViewProjector(),
    Duration matchInactivityTimeout = defaultMultiplayerMatchInactivityTimeout,
    LobbyPresencePolicy presencePolicy = const LobbyPresencePolicy(),
    PresenceGenerationGenerator presenceGenerationGenerator =
        const UuidPresenceGenerationGenerator(),
  }) : _connectionRegistry =
           connectionRegistry ??
           MatchConnectionRegistry(viewProjector: viewProjector),
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       _stateAccess = const MatchStateAccess(),
       _presencePolicy = presencePolicy,
       _viewProjector = connectionRegistry?.viewProjector ?? viewProjector {
    _broadcaster = MatchBroadcaster(_connectionRegistry);
    final turnPresencePolicy = MatchTurnPresencePolicy(_presencePolicy);
    _lifecycle = MatchLifecycleService(
      stateAccess: _stateAccess,
      broadcaster: _broadcaster,
      quickplayLobbyPolicy: quickplayLobbyPolicy,
      presencePolicies: (_presencePolicy, turnPresencePolicy),
      presenceGenerationGenerator: presenceGenerationGenerator,
      nowUtc: _nowUtc,
    );
    _matchmaking = MatchmakingService(
      seatAllocator: seatAllocator,
      stateAccess: _stateAccess,
      broadcaster: _broadcaster,
      lifecycle: _lifecycle,
      presencePolicy: _presencePolicy,
      presenceGenerationGenerator: presenceGenerationGenerator,
      nowUtc: _nowUtc,
      inviteCodeGenerator: inviteCodeGenerator,
    );
    _queries = MatchQueryService(
      stateAccess: _stateAccess,
      viewProjector: _viewProjector,
      nowUtc: _nowUtc,
    );
    _commands = MatchCommandService(
      commandReducer: commandReducer ?? ServerCommandReducer(),
      stateAccess: _stateAccess,
      broadcaster: _broadcaster,
      turnPresencePolicy: turnPresencePolicy,
      nowUtc: _nowUtc,
      matchInactivityTimeout: matchInactivityTimeout,
    );
  }

  final MatchConnectionRegistry _connectionRegistry;
  final DateTime Function() _nowUtc;
  final MatchStateAccess _stateAccess;
  final LobbyPresencePolicy _presencePolicy;
  final PlayerMatchViewProjector _viewProjector;
  final MultiplayerInputValidator _inputValidator =
      const MultiplayerInputValidator();
  late final MatchBroadcaster _broadcaster;
  late final MatchLifecycleService _lifecycle;
  late final MatchmakingService _matchmaking;
  late final MatchQueryService _queries;
  late final MatchCommandService _commands;
}

final class _PlayerIdentity {
  const _PlayerIdentity({
    required this.userIdentifier,
    required this.displayName,
  });

  final String userIdentifier;
  final String displayName;
}
