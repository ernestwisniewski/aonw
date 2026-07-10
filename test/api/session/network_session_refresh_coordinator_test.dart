import 'dart:async';

import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_refresh_coordinator.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

void main() {
  group('NetworkSessionRefreshCoordinator', () {
    test('coalesces parallel 401 recovery and persists one rotation', () async {
      final refreshStarted = Completer<void>();
      final releaseRefresh = Completer<void>();
      final store = _MemorySessionStore(_storedSession());
      NetworkSession? current = _activeSession();
      var refreshCalls = 0;
      final coordinator = _coordinator(
        store: store,
        currentSession: () => current,
        setSession: (session) => current = session,
        refreshToken: ({required refreshToken}) async {
          refreshCalls += 1;
          expect(refreshToken, 'refresh-1');
          if (!refreshStarted.isCompleted) refreshStarted.complete();
          await releaseRefresh.future;
          return NetworkSessionRefreshResult(
            token: AuthToken('jwt-2', expiresAt: DateTime.utc(2026, 7, 10, 13)),
            refreshToken: 'refresh-2',
          );
        },
      );
      final firstClient = NetworkSessionAuthKeyProvider(coordinator);
      final secondClient = NetworkSessionAuthKeyProvider(coordinator);
      final delayedClient = NetworkSessionAuthKeyProvider(coordinator);

      expect(await firstClient.authHeaderValue, 'Bearer jwt-1');
      expect(await secondClient.authHeaderValue, 'Bearer jwt-1');
      expect(await delayedClient.authHeaderValue, 'Bearer jwt-1');

      final firstRecovery = firstClient.refreshAuthKey();
      final secondRecovery = secondClient.refreshAuthKey();
      await refreshStarted.future;
      expect(refreshCalls, 1);

      releaseRefresh.complete();
      expect(
        await Future.wait([firstRecovery, secondRecovery]),
        everyElement(sp_auth.RefreshAuthKeyResult.success),
      );
      expect(current?.token.value, 'jwt-2');
      expect(current?.refreshToken, 'refresh-2');
      expect(store.savedRefreshTokens, ['refresh-2']);

      expect(
        await delayedClient.refreshAuthKey(),
        sp_auth.RefreshAuthKeyResult.success,
      );
      expect(refreshCalls, 1, reason: 'a delayed 401 used the old JWT');
    });

    test(
      'refresh failure ends the session and is not retried in a loop',
      () async {
        final store = _MemorySessionStore(_storedSession());
        NetworkSession? current = _activeSession();
        var refreshCalls = 0;
        final coordinator = _coordinator(
          store: store,
          currentSession: () => current,
          setSession: (session) => current = session,
          refreshToken: ({required refreshToken}) async {
            refreshCalls += 1;
            throw const sp_auth.ServerpodClientException(
              'Refresh service unavailable',
              503,
            );
          },
        );
        final client = NetworkSessionAuthKeyProvider(coordinator);
        expect(await client.authHeaderValue, 'Bearer jwt-1');

        expect(
          await client.refreshAuthKey(),
          sp_auth.RefreshAuthKeyResult.failedOther,
        );
        expect(current, isNull);
        expect(store.stored, isNull);
        expect(store.clearCount, 1);
        expect(refreshCalls, 1);

        expect(
          await client.refreshAuthKey(),
          sp_auth.RefreshAuthKeyResult.failedUnauthorized,
        );
        expect(refreshCalls, 1);
        expect(store.clearCount, 1);
      },
    );

    test(
      'rejected refresh is reported as unauthorized and clears credentials',
      () async {
        final store = _MemorySessionStore(_storedSession());
        NetworkSession? current = _activeSession();
        final coordinator = _coordinator(
          store: store,
          currentSession: () => current,
          setSession: (session) => current = session,
          refreshToken: ({required refreshToken}) async {
            throw sp_auth.RefreshTokenExpiredException();
          },
        );
        final client = NetworkSessionAuthKeyProvider(coordinator);
        expect(await client.authHeaderValue, 'Bearer jwt-1');

        expect(
          await client.refreshAuthKey(),
          sp_auth.RefreshAuthKeyResult.failedUnauthorized,
        );
        expect(current, isNull);
        expect(store.stored, isNull);
      },
    );

    test(
      'logout fences an in-flight refresh from restoring the session',
      () async {
        final refreshStarted = Completer<void>();
        final releaseRefresh = Completer<void>();
        final store = _MemorySessionStore(_storedSession());
        NetworkSession? current = _activeSession();
        final coordinator = _coordinator(
          store: store,
          currentSession: () => current,
          setSession: (session) => current = session,
          refreshToken: ({required refreshToken}) async {
            refreshStarted.complete();
            await releaseRefresh.future;
            return NetworkSessionRefreshResult(
              token: AuthToken('jwt-after-logout'),
              refreshToken: 'refresh-after-logout',
            );
          },
        );

        final refresh = coordinator.ensureValidSession(forceRefresh: true);
        await refreshStarted.future;
        await coordinator.terminateSession();
        releaseRefresh.complete();

        await expectLater(
          refresh,
          throwsA(isA<NetworkSessionUnavailableException>()),
        );
        expect(current, isNull);
        expect(store.stored, isNull);
        expect(store.savedRefreshTokens, isEmpty);
      },
    );

    test(
      'logout during credential persistence clears the completed stale write',
      () async {
        final saveStarted = Completer<void>();
        final releaseSave = Completer<void>();
        final store = _MemorySessionStore(
          _storedSession(),
          credentialsSaveStarted: saveStarted,
          credentialsSaveRelease: releaseSave.future,
        );
        NetworkSession? current = _activeSession();
        final coordinator = _coordinator(
          store: store,
          currentSession: () => current,
          setSession: (session) => current = session,
          refreshToken: ({required refreshToken}) async {
            return NetworkSessionRefreshResult(
              token: AuthToken('stale-jwt'),
              refreshToken: 'stale-rotated-refresh',
            );
          },
        );

        final refresh = coordinator.ensureValidSession(forceRefresh: true);
        await saveStarted.future;
        await coordinator.terminateSession();
        expect(current, isNull);
        expect(store.stored, isNull);

        releaseSave.complete();
        await expectLater(
          refresh,
          throwsA(isA<NetworkSessionUnavailableException>()),
        );
        expect(current, isNull);
        expect(store.stored, isNull);
        expect(store.clearCount, 2);
      },
    );

    test(
      'remote logout waits for rotation and revokes the newest credential',
      () async {
        final refreshStarted = Completer<void>();
        final releaseRefresh = Completer<void>();
        final store = _MemorySessionStore(_storedSession());
        NetworkSession? current = _activeSession();
        AuthToken? revokedToken;
        String? revokedRefreshToken;
        final coordinator = _coordinator(
          store: store,
          currentSession: () => current,
          setSession: (session) => current = session,
          refreshToken: ({required refreshToken}) async {
            refreshStarted.complete();
            await releaseRefresh.future;
            return NetworkSessionRefreshResult(
              token: AuthToken('jwt-2'),
              refreshToken: 'refresh-2',
            );
          },
        );

        final refresh = coordinator.ensureValidSession(forceRefresh: true);
        await refreshStarted.future;
        final signOut = coordinator.revokeAndTerminate(({
          token,
          refreshToken,
        }) async {
          revokedToken = token;
          revokedRefreshToken = refreshToken;
        });

        await expectLater(
          coordinator.currentToken(),
          throwsA(isA<NetworkSessionUnavailableException>()),
        );
        expect(revokedRefreshToken, isNull);
        releaseRefresh.complete();
        await refresh;
        await signOut;

        expect(revokedToken?.value, 'jwt-2');
        expect(revokedRefreshToken, 'refresh-2');
        expect(current, isNull);
        expect(store.stored, isNull);
      },
    );

    test('remote logout failure still clears the local session', () async {
      final store = _MemorySessionStore(_storedSession());
      NetworkSession? current = _activeSession();
      final coordinator = _coordinator(
        store: store,
        currentSession: () => current,
        setSession: (session) => current = session,
        refreshToken: ({required refreshToken}) async {
          fail('unexpected refresh');
        },
      );

      await expectLater(
        coordinator.revokeAndTerminate(({token, refreshToken}) async {
          expect(refreshToken, 'refresh-1');
          throw StateError('offline');
        }),
        throwsStateError,
      );

      expect(current, isNull);
      expect(store.stored, isNull);
    });

    test('a new login supersedes an older in-flight refresh', () async {
      final refreshStarted = Completer<void>();
      final releaseRefresh = Completer<void>();
      final store = _MemorySessionStore(_storedSession());
      NetworkSession? current = _activeSession();
      final coordinator = _coordinator(
        store: store,
        currentSession: () => current,
        setSession: (session) => current = session,
        refreshToken: ({required refreshToken}) async {
          refreshStarted.complete();
          await releaseRefresh.future;
          return NetworkSessionRefreshResult(
            token: AuthToken('stale-refresh-result'),
            refreshToken: 'stale-rotated-refresh',
          );
        },
      );

      final refresh = coordinator.ensureValidSession(forceRefresh: true);
      await refreshStarted.future;
      current = NetworkSession(
        userId: 'user-2',
        token: AuthToken('new-login-jwt'),
        refreshToken: 'new-login-refresh',
      );
      store.stored = const StoredNetworkSession(
        userId: 'user-2',
        refreshToken: 'new-login-refresh',
        displayName: 'Bob',
      );
      releaseRefresh.complete();

      await expectLater(
        refresh,
        throwsA(isA<NetworkSessionUnavailableException>()),
      );
      expect(current?.userId, 'user-2');
      expect(current?.token.value, 'new-login-jwt');
      expect(store.stored?.refreshToken, 'new-login-refresh');
      expect(store.clearCount, 0);
    });

    test(
      'new login credentials win when old refresh persistence finishes later',
      () async {
        final saveStarted = Completer<void>();
        final releaseSave = Completer<void>();
        final store = _MemorySessionStore(
          _storedSession(),
          credentialsSaveStarted: saveStarted,
          credentialsSaveRelease: releaseSave.future,
        );
        NetworkSession? current = _activeSession();
        final coordinator = _coordinator(
          store: store,
          currentSession: () => current,
          setSession: (session) => current = session,
          refreshToken: ({required refreshToken}) async {
            return NetworkSessionRefreshResult(
              token: AuthToken('stale-jwt'),
              refreshToken: 'stale-rotated-refresh',
            );
          },
        );

        final refresh = coordinator.ensureValidSession(forceRefresh: true);
        await saveStarted.future;
        current = NetworkSession(
          userId: 'user-2',
          token: AuthToken('new-login-jwt'),
          refreshToken: 'new-login-refresh',
        );
        store.stored = const StoredNetworkSession(
          userId: 'user-2',
          refreshToken: 'new-login-refresh',
          displayName: 'Bob',
        );

        releaseSave.complete();
        await expectLater(
          refresh,
          throwsA(isA<NetworkSessionUnavailableException>()),
        );
        expect(current?.token.value, 'new-login-jwt');
        expect(store.stored?.userId, 'user-2');
        expect(store.stored?.refreshToken, 'new-login-refresh');
        expect(store.savedRefreshTokens, [
          'stale-rotated-refresh',
          'new-login-refresh',
        ]);
      },
    );
  });
}

NetworkSessionRefreshCoordinator _coordinator({
  required _MemorySessionStore store,
  required NetworkSession? Function() currentSession,
  required void Function(NetworkSession? session) setSession,
  required NetworkSessionTokenRefresher refreshToken,
}) {
  return NetworkSessionRefreshCoordinator(
    currentSession: currentSession,
    setSession: setSession,
    sessionStore: store,
    refreshToken: refreshToken,
    now: () => DateTime.utc(2026, 7, 10, 12),
  );
}

NetworkSession _activeSession() {
  return NetworkSession(
    userId: 'user-1',
    playerId: 'player-1',
    token: AuthToken('jwt-1', expiresAt: DateTime.utc(2026, 7, 10, 13)),
    refreshToken: 'refresh-1',
    matchId: 'match-1',
    connectionState: NetworkConnectionState(
      status: NetworkConnectionStatus.connected,
      changedAt: DateTime.utc(2026, 7, 10, 11),
    ),
  );
}

StoredNetworkSession _storedSession() {
  return const StoredNetworkSession(
    userId: 'user-1',
    refreshToken: 'refresh-1',
    displayName: 'Alice',
    matchId: 'match-1',
  );
}

final class _MemorySessionStore extends NetworkSessionStore {
  StoredNetworkSession? stored;
  final savedRefreshTokens = <String>[];
  final Completer<void>? credentialsSaveStarted;
  final Future<void>? credentialsSaveRelease;
  var clearCount = 0;

  _MemorySessionStore(
    this.stored, {
    this.credentialsSaveStarted,
    this.credentialsSaveRelease,
  });

  @override
  Future<StoredNetworkSession?> load() async => stored;

  @override
  Future<void> saveCredentials({
    required String userId,
    required String refreshToken,
  }) async {
    final started = credentialsSaveStarted;
    if (started != null && !started.isCompleted) started.complete();
    final release = credentialsSaveRelease;
    if (release != null) await release;
    final current = stored;
    stored = StoredNetworkSession(
      userId: userId,
      refreshToken: refreshToken,
      displayName: current?.displayName ?? 'Player',
      matchId: current?.matchId,
    );
    savedRefreshTokens.add(refreshToken);
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    stored = null;
  }
}
