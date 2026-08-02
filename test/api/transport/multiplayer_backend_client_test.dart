import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates one Serverpod client and closes it idempotently', () {
    var clientFactoryCalls = 0;
    final rawClient = createServerpodClient('http://localhost:8080');
    final backend = ServerpodMultiplayerBackendClient(
      serverpodHost: 'http://localhost:8080',
      token: AuthToken('jwt-token'),
      clientFactory: () {
        clientFactoryCalls += 1;
        return rawClient;
      },
    );

    expect(clientFactoryCalls, 1);
    expect(backend.isClosed, isFalse);

    backend
      ..close()
      ..close();

    expect(clientFactoryCalls, 1);
    expect(backend.isClosed, isTrue);
    expect(backend.listMatches, throwsStateError);
  });

  test('creates one refresh-aware auth provider for the shared client', () {
    var authProviderFactoryCalls = 0;
    final backend = ServerpodMultiplayerBackendClient(
      serverpodHost: 'http://localhost:8080',
      token: AuthToken('stale-jwt'),
      authKeyProviderFactory: () {
        authProviderFactoryCalls += 1;
        return ServerpodAuthTokenProvider(AuthToken('fresh-jwt'));
      },
    );
    addTearDown(backend.close);

    expect(authProviderFactoryCalls, 1);
  });
}
