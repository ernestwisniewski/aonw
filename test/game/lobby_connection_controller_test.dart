import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_controller.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

import 'support/lobby_connection_controller_test_store.dart';

void main() {
  group('LobbyConnectionController', () {
    test('quickplay publishes an authenticated stored session', () async {
      final client = _FakeNetworkSessionClient(
        quickplayMatch: _match(state: 'open'),
      );
      final store = _MemoryNetworkSessionStore(displayName: 'Stored Alice');
      NetworkSession? currentSession;
      final published = <WireMatch>[];
      final presentedErrors = <String>[];
      final primaryDisplayNames = <String>[];
      final routes = <String>[];
      var authCount = 0;

      final controller = LobbyConnectionController(
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        sessionClient: client,
        sessionStore: store,
        liveEvents: _emptyLiveEvents(),
        now: () => DateTime.utc(2026, 6, 2, 12),
        canContinue: () => true,
        currentSession: () => currentSession,
        setSession: (session) => currentSession = session,
        authenticate: ({required initialDisplayName}) async {
          authCount += 1;
          expect(initialDisplayName, 'Lobby Alice');
          return NetworkAuthResult(
            userId: 'user_1',
            token: AuthToken('fresh-token'),
            refreshToken: 'refresh-token',
            displayName: 'Authenticated Alice',
          );
        },
        displayName: () => 'Lobby Alice',
        setPrimaryDisplayName: primaryDisplayNames.add,
        country: () => PlayerCountry.china,
        validateMap: () async => _validValidation(),
        mapNotReadyMessage: () => 'Map is not ready',
        inviteCodeRequiredMessage: () => 'Invite code required',
        errorTextFor: (error) => 'mapped $error',
        presentError: presentedErrors.add,
        publishMatch: published.add,
        navigateTo: routes.add,
      );
      addTearDown(controller.dispose);

      await controller.startQuickplayQueue();
      await Future<void>.delayed(Duration.zero);

      expect(authCount, 1);
      expect(controller.mode, LobbyMultiplayerMode.quickplay);
      expect(controller.busy, isFalse);
      expect(controller.error, isNull);
      expect(controller.activeMatch?.id, 'match_1');
      expect(client.quickplayRequest?.mapName, 'verdantia');
      expect(client.quickplayRequest?.country, PlayerCountry.china);
      expect(store.displayName, 'Authenticated Alice');
      expect(store.stored?.refreshToken, 'refresh-token');
      expect(store.savedMatchIds, ['match_1']);
      expect(currentSession?.userId, 'user_1');
      expect(currentSession?.matchId, 'match_1');
      expect(primaryDisplayNames, ['Authenticated Alice']);
      expect(published.map((match) => match.id), ['match_1']);
      expect(presentedErrors, isEmpty);
      expect(routes, isEmpty);
    });

    test(
      'authentication remains memory-only when credentials cannot persist',
      () async {
        final client = _FakeNetworkSessionClient(
          quickplayMatch: _match(state: 'open'),
        );
        final store = _MemoryNetworkSessionStore(
          displayName: 'Stored Alice',
          saveError: const NetworkSessionCredentialPersistenceException(),
        );
        NetworkSession? currentSession;
        final presentedErrors = <String>[];
        final primaryDisplayNames = <String>[];
        final controller = LobbyConnectionController(
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          sessionClient: client,
          sessionStore: store,
          liveEvents: _emptyLiveEvents(),
          now: () => DateTime.utc(2026, 6, 2, 12),
          canContinue: () => true,
          currentSession: () => currentSession,
          setSession: (session) => currentSession = session,
          authenticate: ({required initialDisplayName}) async {
            return NetworkAuthResult(
              userId: 'user_1',
              token: AuthToken('fresh-token'),
              refreshToken: 'refresh-token',
              displayName: 'Authenticated Alice',
            );
          },
          displayName: () => 'Lobby Alice',
          setPrimaryDisplayName: primaryDisplayNames.add,
          country: () => PlayerCountry.china,
          validateMap: () async => _validValidation(),
          mapNotReadyMessage: () => 'Map is not ready',
          inviteCodeRequiredMessage: () => 'Invite code required',
          errorTextFor: (error) => 'mapped $error',
          presentError: presentedErrors.add,
          publishMatch: (_) {},
          navigateTo: (_) {},
        );
        addTearDown(controller.dispose);

        await controller.startQuickplayQueue();

        expect(currentSession?.userId, 'user_1');
        expect(currentSession?.refreshToken, 'refresh-token');
        expect(client.quickplayRequest, isNotNull);
        expect(primaryDisplayNames, ['Authenticated Alice']);
        expect(controller.activeMatch?.id, 'match_1');
        expect(presentedErrors, isEmpty);
      },
    );

    test(
      'public lobby lists, joins and creates through active match flow',
      () async {
        final listed = _match(
          id: 'public_listed',
          state: 'open',
          quickplay: false,
          ownerUserId: 'host_player',
          players: const [
            WirePlayer(
              id: 'host_player',
              userId: 'host_player',
              name: 'Host',
              colorValue: 0xFFDC2626,
              kind: WirePlayerKind.human,
              connectionState: WirePlayerConnectionState.connected,
            ),
          ],
        );
        final joined = _match(
          id: 'public_joined',
          state: 'open',
          quickplay: false,
          ownerUserId: 'host_player',
        );
        final created = _match(
          id: 'public_created',
          state: 'open',
          quickplay: false,
        );
        final client = _FakeNetworkSessionClient(
          quickplayMatch: _match(state: 'open'),
          listedMatches: [listed],
          joinedPublicMatch: joined,
          createdPublicMatch: created,
        );
        final store = _MemoryNetworkSessionStore(displayName: 'Alice');
        NetworkSession? currentSession = NetworkSession(
          userId: 'user_1',
          token: AuthToken('token'),
          connectionState: const NetworkConnectionState(
            status: NetworkConnectionStatus.connected,
          ),
        );
        final controller = LobbyConnectionController(
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          sessionClient: client,
          sessionStore: store,
          liveEvents: _emptyLiveEvents(),
          now: () => DateTime.utc(2026, 6, 2, 12),
          canContinue: () => true,
          currentSession: () => currentSession,
          setSession: (session) => currentSession = session,
          authenticate: ({required initialDisplayName}) async => null,
          displayName: () => 'Alice',
          setPrimaryDisplayName: (_) {},
          country: () => PlayerCountry.china,
          validateMap: () async => _validValidation(),
          mapNotReadyMessage: () => 'Map is not ready',
          inviteCodeRequiredMessage: () => 'Invite code required',
          errorTextFor: (error) => 'mapped $error',
          presentError: (_) {},
          publishMatch: (_) {},
          navigateTo: (_) {},
        );
        addTearDown(controller.dispose);

        await controller.openPublicLobby();

        expect(controller.mode, LobbyMultiplayerMode.publicBrowse);
        expect(controller.publicMatchesLoaded, isTrue);
        expect(controller.publicMatches.map((match) => match.id), [
          'public_listed',
        ]);

        await controller.joinPublicMatch(matchId: listed.id);

        expect(controller.mode, LobbyMultiplayerMode.publicMatch);
        expect(controller.activeMatch?.id, 'public_joined');
        await controller.leaveLobby();
        expect(client.matchActions, ['join', 'leave']);

        await controller.openPublicLobby();
        await controller.createPublicMatch(name: 'Open table');

        expect(controller.mode, LobbyMultiplayerMode.publicMatch);
        expect(controller.activeMatch?.id, 'public_created');
        expect(client.createdPublicRequest?.name, 'Open table');
        expect(client.createdPublicRequest?.minPlayers, 2);
      },
    );

    test('token-only authentication detaches a previous account', () async {
      final client = _FakeNetworkSessionClient(
        quickplayMatch: _match(state: 'open'),
      );
      final store = _MemoryNetworkSessionStore(displayName: 'Bob')
        ..stored = const StoredNetworkSession(
          userId: 'user_a',
          refreshToken: 'refresh-a',
          displayName: 'Alice',
          matchId: 'match-a',
        );
      NetworkSession? currentSession;
      final controller = LobbyConnectionController(
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        sessionClient: client,
        sessionStore: store,
        liveEvents: _emptyLiveEvents(),
        now: () => DateTime.utc(2026, 6, 2, 12),
        canContinue: () => true,
        currentSession: () => currentSession,
        setSession: (session) => currentSession = session,
        authenticate: ({required initialDisplayName}) async {
          return NetworkAuthResult(
            userId: 'user_b',
            token: AuthToken('access-b'),
            displayName: 'Bob',
          );
        },
        displayName: () => 'Bob',
        setPrimaryDisplayName: (_) {},
        country: () => PlayerCountry.china,
        validateMap: () async => _validValidation(),
        mapNotReadyMessage: () => 'Map is not ready',
        inviteCodeRequiredMessage: () => 'Invite code required',
        errorTextFor: (error) => 'mapped $error',
        presentError: (_) {},
        publishMatch: (_) {},
        navigateTo: (_) {},
      );
      addTearDown(controller.dispose);

      await controller.startQuickplayQueue();

      expect(currentSession?.userId, 'user_b');
      expect(currentSession?.refreshToken, isNull);
      expect(store.cleared, isTrue);
      expect(
        store.clearCount,
        2,
        reason: 'fallback clears again at account bind',
      );
      expect(store.stored, isNull);
      expect(store.displayName, 'Bob');
    });

    test('token-only sign out ignores another account credentials', () async {
      final client = _FakeNetworkSessionClient(
        quickplayMatch: _match(state: 'open'),
      );
      final store = _MemoryNetworkSessionStore(displayName: 'Alice')
        ..stored = const StoredNetworkSession(
          userId: 'user_a',
          refreshToken: 'refresh-a',
          displayName: 'Alice',
        );
      NetworkSession? currentSession = NetworkSession(
        userId: 'user_b',
        token: AuthToken('access-b'),
      );
      final controller = LobbyConnectionController(
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        sessionClient: client,
        sessionStore: store,
        liveEvents: _emptyLiveEvents(),
        now: () => DateTime.utc(2026, 6, 2, 12),
        canContinue: () => true,
        currentSession: () => currentSession,
        setSession: (session) => currentSession = session,
        authenticate: ({required initialDisplayName}) async => null,
        displayName: () => 'Bob',
        setPrimaryDisplayName: (_) {},
        country: () => PlayerCountry.china,
        validateMap: () async => _validValidation(),
        mapNotReadyMessage: () => 'Map is not ready',
        inviteCodeRequiredMessage: () => 'Invite code required',
        errorTextFor: (error) => 'mapped $error',
        presentError: (_) {},
        publishMatch: (_) {},
        navigateTo: (_) {},
      );
      addTearDown(controller.dispose);

      expect(await controller.signOut(), isTrue);

      expect(client.signedOutToken?.value, 'access-b');
      expect(client.signedOutRefreshToken, isNull);
      expect(currentSession, isNull);
    });

    test('sign out revokes the session before clearing local state', () async {
      final client = _FakeNetworkSessionClient(
        quickplayMatch: _match(state: 'open'),
      );
      final store = _MemoryNetworkSessionStore(displayName: 'Alice')
        ..stored = const StoredNetworkSession(
          userId: 'user_1',
          refreshToken: 'stored-refresh-token',
          displayName: 'Alice',
        );
      NetworkSession? currentSession = NetworkSession(
        userId: 'user_1',
        token: AuthToken('access-token'),
        refreshToken: 'active-refresh-token',
      );
      final presentedErrors = <String>[];
      final controller = LobbyConnectionController(
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        sessionClient: client,
        sessionStore: store,
        liveEvents: _emptyLiveEvents(),
        now: () => DateTime.utc(2026, 6, 2, 12),
        canContinue: () => true,
        currentSession: () => currentSession,
        setSession: (session) => currentSession = session,
        authenticate: ({required initialDisplayName}) async => null,
        displayName: () => 'Alice',
        setPrimaryDisplayName: (_) {},
        country: () => PlayerCountry.china,
        validateMap: () async => _validValidation(),
        mapNotReadyMessage: () => 'Map is not ready',
        inviteCodeRequiredMessage: () => 'Invite code required',
        errorTextFor: (error) => 'mapped $error',
        presentError: presentedErrors.add,
        publishMatch: (_) {},
        navigateTo: (_) {},
      );
      addTearDown(controller.dispose);

      final revoked = await controller.signOut();

      expect(revoked, isTrue);
      expect(client.signedOutToken?.value, 'access-token');
      expect(client.signedOutRefreshToken, 'active-refresh-token');
      expect(store.cleared, isTrue);
      expect(currentSession, isNull);
      expect(presentedErrors, isEmpty);
    });

    test('sign out still clears local state when revocation fails', () async {
      final client = _FakeNetworkSessionClient(
        quickplayMatch: _match(state: 'open'),
        signOutError: StateError('offline'),
      );
      final store = _MemoryNetworkSessionStore(displayName: 'Alice')
        ..stored = const StoredNetworkSession(
          userId: 'user_1',
          refreshToken: 'stored-refresh-token',
          displayName: 'Alice',
        );
      NetworkSession? currentSession;
      final presentedErrors = <String>[];
      final controller = LobbyConnectionController(
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        sessionClient: client,
        sessionStore: store,
        liveEvents: _emptyLiveEvents(),
        now: () => DateTime.utc(2026, 6, 2, 12),
        canContinue: () => true,
        currentSession: () => currentSession,
        setSession: (session) => currentSession = session,
        authenticate: ({required initialDisplayName}) async => null,
        displayName: () => 'Alice',
        setPrimaryDisplayName: (_) {},
        country: () => PlayerCountry.china,
        validateMap: () async => _validValidation(),
        mapNotReadyMessage: () => 'Map is not ready',
        inviteCodeRequiredMessage: () => 'Invite code required',
        errorTextFor: (error) => 'mapped $error',
        presentError: presentedErrors.add,
        publishMatch: (_) {},
        navigateTo: (_) {},
      );
      addTearDown(controller.dispose);

      final revoked = await controller.signOut();

      expect(revoked, isFalse);
      expect(client.signedOutRefreshToken, 'stored-refresh-token');
      expect(store.cleared, isTrue);
      expect(currentSession, isNull);
      expect(presentedErrors.single, contains('offline'));
    });
  });
}

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
  Future<List<WireMatch>> listMatches({
    required AuthToken token,
    String? status,
  }) async {
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
    fail('unexpected match start');
  }

  @override
  Future<WireMatch> loadMatch({
    required AuthToken token,
    required String matchId,
  }) async {
    fail('unexpected match load');
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
