import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reuses refresh-aware client and closes every owned client once',
    () async {
      final created = <_TrackingServerpodClient>[];
      var authProviderFactoryCalls = 0;
      final client = NetworkSessionClient(
        serverpodHost: 'http://localhost:8080',
        authKeyProviderFactory: () {
          authProviderFactoryCalls += 1;
          return ServerpodAuthTokenProvider(AuthToken('current-jwt'));
        },
        clientFactory: _trackingFactory(created),
      );

      expect(created, isEmpty, reason: 'clients are lazy');
      expect(
        await client.displayName(token: AuthToken('first-jwt')),
        'Test Player',
      );
      expect(
        await client.displayName(token: AuthToken('second-jwt')),
        'Test Player',
      );
      expect(created, hasLength(1), reason: 'one shared authenticated client');
      expect(authProviderFactoryCalls, 1);

      expect(
        await client.versionStatus(
          platform: 'macos',
          buildNumber: 1,
          multiplayerVersion: kCurrentMultiplayerVersion,
        ),
        'supported',
      );
      expect(created, hasLength(2));
      expect(created.last.appStatusRequests, [
        {
          'platform': 'macos',
          'buildNumber': 1,
          'multiplayerVersion': kCurrentMultiplayerVersion,
        },
      ]);
      expect(created.map((value) => value.closeCalls), [0, 1]);

      client
        ..close()
        ..close();

      expect(client.isClosed, isTrue);
      expect(created.map((value) => value.closeCalls), [1, 1]);
      expect(
        () => client.displayName(token: AuthToken('after-close')),
        throwsStateError,
      );
    },
  );

  test(
    'falls back to the legacy app-status shape during server rollout',
    () async {
      final created = <_TrackingServerpodClient>[];
      final client = NetworkSessionClient(
        serverpodHost: 'http://localhost:8080',
        clientFactory: _trackingFactory(
          created,
          rejectVersionedAppStatus: true,
        ),
      );
      addTearDown(client.close);

      expect(
        await client.versionStatus(
          platform: 'windows',
          buildNumber: 80,
          multiplayerVersion: kCurrentMultiplayerVersion,
        ),
        'supported',
      );
      expect(created.single.appStatusRequests, [
        {
          'platform': 'windows',
          'buildNumber': 80,
          'multiplayerVersion': kCurrentMultiplayerVersion,
        },
        {'platform': 'windows', 'buildNumber': 80},
      ]);
    },
  );

  test('closes explicit-token fallback client after every request', () async {
    final created = <_TrackingServerpodClient>[];
    final client = NetworkSessionClient(
      serverpodHost: 'http://localhost:8080',
      clientFactory: _trackingFactory(created),
    );
    addTearDown(client.close);

    await client.displayName(token: AuthToken('jwt-1'));
    await client.displayName(token: AuthToken('jwt-2'));

    expect(
      created,
      hasLength(2),
      reason: 'two explicit clients; anonymous client stays lazy',
    );
    expect(created.map((value) => value.closeCalls), [1, 1]);
  });

  test('maps only supported lobby fields to Serverpod requests', () async {
    final created = <_TrackingServerpodClient>[];
    final client = NetworkSessionClient(
      serverpodHost: 'http://localhost:8080',
      clientFactory: _trackingFactory(created),
    );
    addTearDown(client.close);
    final token = AuthToken('jwt-token');

    await client.createMatch(
      token: token,
      request: const CreateMatchRequest(
        name: 'Public table',
        mapName: 'verdantia',
        maxPlayers: 4,
        minPlayers: 2,
        country: PlayerCountry.germany,
      ),
    );
    await client.quickplay(
      token: token,
      request: const QuickplayMatchRequest(
        mapName: 'myranth',
        country: PlayerCountry.japan,
      ),
    );
    await client.createPrivateMatch(
      token: token,
      request: const CreatePrivateMatchRequest(
        mapName: 'terenos',
        country: PlayerCountry.poland,
      ),
    );
    await client.joinMatch(
      token: token,
      matchId: 'public_match',
      country: PlayerCountry.italy,
    );
    await client.joinPrivateMatch(
      token: token,
      request: const JoinPrivateMatchRequest(
        inviteCode: 'ABC123',
        country: PlayerCountry.ukraine,
      ),
    );

    final calls = [
      for (final serverpodClient in created) ...serverpodClient.matchRequests,
    ];
    expect(calls.map((call) => call.method), [
      'createMatch',
      'quickplay',
      'createMatch',
    ]);
    expect(calls[0].request.name, 'Public table');
    expect(calls[0].request.private, isFalse);
    expect(calls[1].request.name, 'Quickplay');
    expect(calls[1].request.private, isFalse);
    expect(calls[2].request.name, 'Private match');
    expect(calls[2].request.private, isTrue);
    expect(calls.map((call) => call.request.countryId), [
      'germany',
      'japan',
      'poland',
    ]);
    for (final call in calls) {
      expect(call.request.toJson().keys.toSet(), {
        '__className__',
        'name',
        'mapName',
        'maxPlayers',
        'minPlayers',
        'private',
        'countryId',
      });
    }

    final joins = [
      for (final serverpodClient in created) ...serverpodClient.joinRequests,
    ];
    expect(joins.map((call) => call.method), ['joinMatch', 'joinPrivateMatch']);
    expect(joins[0].args, {'matchId': 'public_match', 'countryId': 'italy'});
    expect(joins[1].args, {'inviteCode': 'ABC123', 'countryId': 'ukraine'});
  });
}

NetworkSessionServerpodClientFactory _trackingFactory(
  List<_TrackingServerpodClient> created, {
  bool rejectVersionedAppStatus = false,
}) {
  return (host, {token, authKeyProvider, connectionTimeout}) {
    final client = _TrackingServerpodClient(
      host,
      connectionTimeout: connectionTimeout,
      rejectVersionedAppStatus: rejectVersionedAppStatus,
    );
    if (authKeyProvider != null) {
      client.authKeyProvider = authKeyProvider;
    } else if (token != null) {
      client.authKeyProvider = ServerpodAuthTokenProvider(token);
    }
    created.add(client);
    return client;
  };
}

final class _TrackingServerpodClient extends sp.Client {
  _TrackingServerpodClient(
    super.host, {
    super.connectionTimeout,
    this.rejectVersionedAppStatus = false,
  });

  final bool rejectVersionedAppStatus;

  var closeCalls = 0;
  final matchRequests = <({String method, sp.CreateMatchRequest request})>[];
  final joinRequests = <({String method, Map<String, dynamic> args})>[];
  final appStatusRequests = <Map<String, dynamic>>[];

  @override
  Future<T> callServerEndpoint<T>(
    String endpoint,
    String method,
    Map<String, dynamic> args, {
    bool authenticated = true,
  }) async {
    if (endpoint == 'emailIdp' && method == 'displayName') {
      return 'Test Player' as T;
    }
    if (endpoint == 'appStatus' && method == 'versionStatus') {
      appStatusRequests.add(Map.unmodifiable(args));
      if (rejectVersionedAppStatus && args.containsKey('multiplayerVersion')) {
        throw const sp.ServerpodClientException(
          'Unknown parameter multiplayerVersion',
          400,
        );
      }
      return 'supported' as T;
    }
    if (endpoint == 'multiplayer' &&
        (method == 'createMatch' || method == 'quickplay')) {
      final request = args['request']! as sp.CreateMatchRequest;
      matchRequests.add((method: method, request: request));
      return WireMatch(
            id: 'match_${matchRequests.length}',
            ownerUserId: 'user_1',
            name: request.name,
            mapName: request.mapName,
            players: const [],
            maxPlayers: request.maxPlayers,
            minPlayers: request.minPlayers,
            quickplay: method == 'quickplay',
            turn: 0,
            state: 'open',
            createdAt: DateTime.utc(2026, 7, 12),
          )
          as T;
    }
    if (endpoint == 'multiplayer' &&
        (method == 'joinMatch' || method == 'joinPrivateMatch')) {
      joinRequests.add((method: method, args: Map.unmodifiable(args)));
      return WireMatch(
            id: 'joined_${joinRequests.length}',
            ownerUserId: 'user_1',
            name: 'Joined match',
            mapName: 'verdantia',
            players: const [],
            maxPlayers: 4,
            minPlayers: 2,
            turn: 0,
            state: 'open',
            createdAt: DateTime.utc(2026, 7, 12),
          )
          as T;
    }
    throw StateError('Unexpected endpoint call: $endpoint.$method');
  }

  @override
  void close() {
    closeCalls += 1;
    super.close();
  }
}
