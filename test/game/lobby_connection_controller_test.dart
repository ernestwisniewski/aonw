import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/presentation/screens/lobby_connection_controller.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LobbyConnectionController', () {
    test(
      'quickplay authenticates, stores session and publishes match',
      () async {
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
          streamConnector: _emptyStreamConnector,
          serverpodHost: 'http://localhost:8080',
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
        expect(client.quickplayRequest?.displayName, 'Lobby Alice');
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
      },
    );
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

WireMatch _match({required String state}) {
  return WireMatch(
    id: 'match_1',
    ownerUserId: 'user_1',
    name: 'Quickplay',
    mapName: 'verdantia',
    players: const [
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
    quickplay: true,
    turn: 1,
    state: state,
    createdAt: DateTime.utc(2026, 6, 2),
  );
}

final class _FakeNetworkSessionClient extends NetworkSessionClient {
  final WireMatch quickplayMatch;
  QuickplayMatchRequest? quickplayRequest;

  _FakeNetworkSessionClient({required this.quickplayMatch})
    : super(serverpodHost: 'http://localhost:8080');

  @override
  Future<WireMatch> quickplay({
    required AuthToken token,
    required QuickplayMatchRequest request,
  }) async {
    quickplayRequest = request;
    return quickplayMatch;
  }

  @override
  Future<WireMatch> createPrivateMatch({
    required AuthToken token,
    required CreatePrivateMatchRequest request,
  }) async {
    fail('unexpected private match create');
  }

  @override
  Future<WireMatch> joinPrivateMatch({
    required AuthToken token,
    required JoinPrivateMatchRequest request,
  }) async {
    fail('unexpected private match join');
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
    fail('unexpected match leave');
  }
}

final class _MemoryNetworkSessionStore extends NetworkSessionStore {
  String displayName;
  StoredNetworkSession? stored;
  final savedMatchIds = <String?>[];
  var cleared = false;

  _MemoryNetworkSessionStore({required this.displayName});

  @override
  Future<StoredNetworkSession?> load() async => stored;

  @override
  Future<String> loadDisplayName() async => displayName;

  @override
  Future<void> save(StoredNetworkSession session) async {
    stored = session;
  }

  @override
  Future<void> saveDisplayName(String displayName) async {
    this.displayName = displayName;
  }

  @override
  Future<void> saveMatchId(String? matchId) async {
    savedMatchIds.add(matchId);
    stored = stored?.copyWith(matchId: matchId);
  }

  @override
  Future<void> clear() async {
    cleared = true;
    stored = null;
  }
}
