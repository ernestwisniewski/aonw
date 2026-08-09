import 'dart:async';

import 'package:aonw/api/session/external_auth_browser.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

void main() {
  for (final flow in _ExternalAuthFlow.values) {
    group('${flow.label} browser auth lifecycle', () {
      test('closes once when start fails before navigation', () async {
        final scenario = _AuthScenario(flow)
          ..startError = StateError('start failed');
        final browser = _TrackingExternalAuthBrowser();
        final client = _clientFor(scenario, browser);
        addTearDown(client.close);

        await expectLater(flow.login(client), throwsA(isA<StateError>()));

        expect(browser.navigateCalls, 0);
        expect(browser.closeCalls, 1);
      });

      test('closes once when polling fails after navigation', () async {
        final scenario = _AuthScenario(flow)
          ..pollError = StateError('poll failed');
        final browser = _TrackingExternalAuthBrowser();
        final client = _clientFor(scenario, browser);
        addTearDown(client.close);

        await expectLater(flow.login(client), throwsA(isA<StateError>()));

        expect(browser.navigateCalls, 1);
        expect(scenario.pollCalls, 1);
        expect(browser.closeCalls, 1);
      });

      test('closes once on authentication timeout', () async {
        final scenario = _AuthScenario(flow)
          ..expiresAt = DateTime.now().toUtc().subtract(
            const Duration(milliseconds: 1),
          );
        final browser = _TrackingExternalAuthBrowser();
        final client = _clientFor(scenario, browser);
        addTearDown(client.close);

        await expectLater(
          flow.login(client),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('expired'),
            ),
          ),
        );

        expect(browser.navigateCalls, 1);
        expect(scenario.pollCalls, 0);
        expect(browser.closeCalls, 1);
      });

      test('client close cancels an in-flight poll and closes once', () async {
        final pendingPoll = Completer<Object>();
        final scenario = _AuthScenario(flow)..pendingPoll = pendingPoll;
        final browser = _TrackingExternalAuthBrowser();
        final client = _clientFor(scenario, browser);

        final login = flow.login(client);
        await scenario.pollStarted.future;
        expect(scenario.pollCalls, 1);

        client.close();

        await expectLater(
          login,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('closed'),
            ),
          ),
        );
        expect(browser.closeCalls, 1);

        pendingPoll.complete(scenario.pendingPollResult());
        await Future<void>.delayed(Duration.zero);
        expect(scenario.pollCalls, 1, reason: 'must not poll after close');
        expect(browser.closeCalls, 1);
      });

      test('success returns auth result and closes exactly once', () async {
        final scenario = _AuthScenario(flow)..successfulAuth = _authSuccess();
        final browser = _TrackingExternalAuthBrowser();
        final client = _clientFor(scenario, browser);

        final result = await flow.login(client);

        expect(result.userId, '018f4f7a-6b5c-7d8e-9f01-23456789abcd');
        expect(result.token.value, 'access-token');
        expect(result.refreshToken, 'refresh-token');
        expect(result.displayName, 'Browser Player');
        expect(browser.navigateCalls, 1);
        expect(scenario.pollCalls, 1);
        expect(browser.closeCalls, 1);

        client.close();
        expect(browser.closeCalls, 1);
      });
    });
  }
}

NetworkSessionClient _clientFor(
  _AuthScenario scenario,
  _TrackingExternalAuthBrowser browser,
) {
  return NetworkSessionClient(
    serverpodHost: 'http://localhost:8080',
    externalAuthBrowserFactory: () => browser,
    externalAuthPollInterval: Duration.zero,
    clientFactory: (host, {token, authKeyProvider, connectionTimeout}) =>
        _AuthServerpodClient(
          host,
          scenario: scenario,
          connectionTimeout: connectionTimeout,
        ),
  );
}

enum _ExternalAuthFlow {
  steam,
  google;

  String get label => switch (this) {
    steam => 'Steam',
    google => 'Google',
  };

  Future<NetworkAuthResult> login(NetworkSessionClient client) {
    return switch (this) {
      steam => client.loginWithSteam(),
      google => client.loginWithExternalProvider(provider: 'google'),
    };
  }
}

final class _AuthScenario {
  _AuthScenario(this.flow);

  final _ExternalAuthFlow flow;
  final Completer<void> pollStarted = Completer<void>();
  Object? startError;
  Object? pollError;
  Completer<Object>? pendingPoll;
  sp_auth.AuthSuccess? successfulAuth;
  DateTime expiresAt = DateTime.now().toUtc().add(const Duration(hours: 1));
  var pollCalls = 0;

  Future<Object> start() async {
    final error = startError;
    if (error != null) throw error;
    return switch (flow) {
      _ExternalAuthFlow.steam => sp.SteamAuthStart(
        requestId: 'steam-request',
        authUrl: 'https://auth.example/steam',
        expiresAt: expiresAt,
      ),
      _ExternalAuthFlow.google => sp.ExternalAuthStart(
        requestId: 'google-request',
        authUrl: 'https://auth.example/google',
        expiresAt: expiresAt,
      ),
    };
  }

  Future<Object> poll() async {
    pollCalls += 1;
    if (!pollStarted.isCompleted) pollStarted.complete();
    final error = pollError;
    if (error != null) throw error;
    final pending = pendingPoll;
    if (pending != null) return pending.future;
    return pendingPollResult(auth: successfulAuth);
  }

  Object pendingPollResult({sp_auth.AuthSuccess? auth}) {
    final status = auth == null ? 'pending' : 'authenticated';
    return switch (flow) {
      _ExternalAuthFlow.steam => sp.SteamAuthPollResult(
        status: status,
        auth: auth,
      ),
      _ExternalAuthFlow.google => sp.ExternalAuthPollResult(
        status: status,
        auth: auth,
      ),
    };
  }
}

final class _AuthServerpodClient extends sp.Client {
  _AuthServerpodClient(
    super.host, {
    required this.scenario,
    super.connectionTimeout,
  });

  final _AuthScenario scenario;

  @override
  Future<T> callServerEndpoint<T>(
    String endpoint,
    String method,
    Map<String, dynamic> args, {
    bool authenticated = true,
  }) async {
    if ((endpoint == 'steamAuth' || endpoint == 'externalAuth') &&
        method == 'start') {
      return await scenario.start() as T;
    }
    if ((endpoint == 'steamAuth' || endpoint == 'externalAuth') &&
        method == 'poll') {
      return await scenario.poll() as T;
    }
    if (endpoint == 'accountProfile' && method == 'ensureAccount') {
      return 'Browser Player' as T;
    }
    throw StateError('Unexpected endpoint call: $endpoint.$method');
  }
}

final class _TrackingExternalAuthBrowser implements ExternalAuthBrowser {
  var navigateCalls = 0;
  var closeCalls = 0;

  @override
  Future<bool> navigate(Uri uri) async {
    navigateCalls += 1;
    return true;
  }

  @override
  void close() {
    closeCalls += 1;
  }
}

sp_auth.AuthSuccess _authSuccess() {
  return sp_auth.AuthSuccess(
    authStrategy: 'external',
    token: 'access-token',
    tokenExpiresAt: DateTime.utc(2026, 8, 9, 15),
    refreshToken: 'refresh-token',
    authUserId: sp.UuidValue.fromString('018f4f7a-6b5c-7d8e-9f01-23456789abcd'),
    scopeNames: {'user'},
  );
}
