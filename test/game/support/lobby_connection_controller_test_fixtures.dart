part of '../lobby_connection_controller_test.dart';

Stream<sp.MultiplayerServerMessage> _emptyStreamConnector({
  required String matchId,
  required AuthToken token,
  required int afterOffset,
  required Stream<sp.MultiplayerClientMessage> input,
}) {
  return const Stream<sp.MultiplayerServerMessage>.empty();
}

LiveEventSubscription _emptyLiveEvents() => LiveEventSubscription(
  serverpodHost: 'http://localhost:8080',
  connector: _emptyStreamConnector,
);

MapValidationResult _validValidation() {
  return MapValidationResult(
    mapName: 'verdantia',
    playerCount: 2,
    totalTiles: 64,
    passableTiles: 64,
    resources: const MapResourceSummary(
      resourceTiles: 0,
      foodResources: 0,
      luxuryResources: 0,
      strategicResources: 0,
    ),
    startSites: const [],
    issues: const [],
  );
}

WireMatch _match({
  required String state,
  String id = 'match_1',
  String ownerUserId = 'user_1',
  String name = 'Quickplay',
  bool quickplay = true,
  List<WirePlayer>? players,
}) {
  return WireMatch(
    id: id,
    ownerUserId: ownerUserId,
    name: name,
    mapName: 'verdantia',
    players:
        players ??
        const [
          WirePlayer(
            id: 'player_1',
            userId: 'user_1',
            name: 'Alice',
            colorValue: 0xFF2563EB,
            kind: WirePlayerKind.human,
            connectionState: WirePlayerConnectionState.connected,
          ),
          WirePlayer(
            id: 'player_2',
            userId: 'user_2',
            name: 'Bob',
            colorValue: 0xFFDC2626,
            kind: WirePlayerKind.human,
            connectionState: WirePlayerConnectionState.connected,
          ),
        ],
    maxPlayers: 4,
    minPlayers: 2,
    quickplay: quickplay,
    turn: 1,
    state: state,
    createdAt: DateTime.utc(2026, 6, 2),
  );
}

final class LobbyControllerTestClient extends NetworkSessionClient {
  final WireMatch quickplayMatch;
  List<WireMatch> listedMatches;
  final WireMatch? createdPublicMatch;
  final WireMatch? joinedPublicMatch;
  final WireMatch? startedMatch;
  final WireMatch? loadedMatch;
  final WireMatch? createdPrivateMatch;
  final WireMatch? joinedPrivateMatch;
  final Object? signOutError;
  final Object? leaveError;
  Object? listMatchesError;
  QuickplayMatchRequest? quickplayRequest;
  CreateMatchRequest? createdPublicRequest;
  final matchActions = <String>[];
  final sessionActions = <String>[];
  AuthToken? signedOutToken;
  String? signedOutRefreshToken;

  LobbyControllerTestClient({
    required this.quickplayMatch,
    this.listedMatches = const [],
    this.createdPublicMatch,
    this.joinedPublicMatch,
    this.startedMatch,
    this.loadedMatch,
    this.createdPrivateMatch,
    this.joinedPrivateMatch,
    this.signOutError,
    this.leaveError,
  }) : super(serverpodHost: 'http://localhost:8080');

  @override
  Future<void> signOutCurrentSession({
    AuthToken? token,
    String? refreshToken,
  }) async {
    sessionActions.add('signOut');
    signedOutToken = token;
    signedOutRefreshToken = refreshToken;
    final error = signOutError;
    if (error != null) throw error;
  }

  @override
  Future<WireMatch> quickplay({
    required AuthToken token,
    required QuickplayMatchRequest request,
  }) async {
    quickplayRequest = request;
    return quickplayMatch;
  }

  @override
  Future<List<WireMatch>> listMatches({required AuthToken token}) async {
    final error = listMatchesError;
    if (error != null) throw error;
    return listedMatches;
  }

  @override
  Future<WireMatch> createMatch({
    required AuthToken token,
    required CreateMatchRequest request,
  }) async {
    createdPublicRequest = request;
    return createdPublicMatch ?? fail('unexpected public match create');
  }

  @override
  Future<WireMatch> joinMatch({
    required AuthToken token,
    required String matchId,
    PlayerCountry? country,
  }) async {
    matchActions.add('join');
    return joinedPublicMatch ?? fail('unexpected public match join');
  }

  @override
  Future<WireMatch> createPrivateMatch({
    required AuthToken token,
    required CreatePrivateMatchRequest request,
  }) async {
    return createdPrivateMatch ?? fail('unexpected private match create');
  }

  @override
  Future<WireMatch> joinPrivateMatch({
    required AuthToken token,
    required JoinPrivateMatchRequest request,
  }) async {
    return joinedPrivateMatch ?? fail('unexpected private match join');
  }

  @override
  Future<WireMatch> startMatch({
    required AuthToken token,
    required String matchId,
  }) async {
    matchActions.add('start');
    return startedMatch ?? fail('unexpected match start');
  }

  @override
  Future<WireMatch> loadMatch({
    required AuthToken token,
    required String matchId,
  }) async {
    matchActions.add('load');
    return loadedMatch ?? fail('unexpected match load');
  }

  @override
  Future<void> leaveMatch({
    required AuthToken token,
    required String matchId,
  }) async {
    matchActions.add('leave');
    sessionActions.add('leave');
    final error = leaveError;
    if (error != null) throw error;
  }
}

typedef _FakeNetworkSessionClient = LobbyControllerTestClient;

const lobbyControllerTestMatch = _match;
const lobbyControllerValidValidation = _validValidation;
const emptyLobbyControllerLiveEvents = _emptyLiveEvents;

typedef _MemoryNetworkSessionStore = LobbyControllerMemorySessionStore;
