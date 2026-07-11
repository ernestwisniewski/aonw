import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
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
        await client.versionStatus(platform: 'macos', buildNumber: 1),
        'supported',
      );
      expect(created, hasLength(2));
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
}

NetworkSessionServerpodClientFactory _trackingFactory(
  List<_TrackingServerpodClient> created,
) {
  return (host, {token, authKeyProvider, connectionTimeout}) {
    final client = _TrackingServerpodClient(
      host,
      connectionTimeout: connectionTimeout,
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
  _TrackingServerpodClient(super.host, {super.connectionTimeout});

  var closeCalls = 0;

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
      return 'supported' as T;
    }
    throw StateError('Unexpected endpoint call: $endpoint.$method');
  }

  @override
  void close() {
    closeCalls += 1;
    super.close();
  }
}
