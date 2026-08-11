import 'dart:async';

import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';
import 'package:aonw/game/application/services/network_session_state_machine.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_network_session_coordinator.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LobbyNetworkSessionCoordinator', () {
    test(
      'reuses a connected current session when stored identity is absent',
      () async {
        final current = _session(userId: 'user_1');
        final setSessions = <NetworkSession?>[];
        var refreshed = false;
        final coordinator = _coordinator(
          currentSession: () => current,
          setSession: setSessions.add,
          loadStoredSession: () async => null,
          refreshToken: ({required refreshToken}) async {
            refreshed = true;
            return NetworkSessionRefreshResult(
              token: AuthToken('fresh-token'),
              refreshToken: 'rotated-refresh-token',
            );
          },
        );

        final session = await coordinator.ensureSession(displayName: 'Alice');

        expect(session, same(current));
        expect(setSessions, isEmpty);
        expect(refreshed, isFalse);
      },
    );

    test(
      'rotates and persists a stored session while keeping its match id',
      () async {
        final setSessions = <NetworkSession?>[];
        final savedSessions = <StoredNetworkSession>[];
        final coordinator = _coordinator(
          setSession: setSessions.add,
          saveStoredSession: (session) async => savedSessions.add(session),
          loadStoredSession: () async {
            return const StoredNetworkSession(
              userId: 'user_1',
              refreshToken: 'refresh-token',
              displayName: 'Alice',
              matchId: 'match_1',
            );
          },
          refreshToken: ({required refreshToken}) async {
            expect(refreshToken, 'refresh-token');
            return NetworkSessionRefreshResult(
              token: AuthToken('fresh-token'),
              refreshToken: 'rotated-refresh-token',
            );
          },
        );

        final session = await coordinator.ensureSession(displayName: 'Alice');

        expect(session.userId, 'user_1');
        expect(session.token, AuthToken('fresh-token'));
        expect(session.refreshToken, 'rotated-refresh-token');
        expect(session.matchId, 'match_1');
        expect(setSessions.single, session);
        expect(savedSessions.single.userId, 'user_1');
        expect(savedSessions.single.refreshToken, 'rotated-refresh-token');
        expect(savedSessions.single.displayName, 'Alice');
        expect(savedSessions.single.matchId, 'match_1');
      },
    );

    test('uses each persisted rotated token for the next refresh', () async {
      StoredNetworkSession stored = const StoredNetworkSession(
        userId: 'user_1',
        refreshToken: 'initial-refresh-token',
        displayName: 'Alice',
        matchId: 'match_1',
      );
      final requestedRefreshTokens = <String>[];
      final savedSessions = <StoredNetworkSession>[];
      var refreshCount = 0;
      final coordinator = _coordinator(
        loadStoredSession: () async => stored,
        saveStoredSession: (session) async {
          stored = session;
          savedSessions.add(session);
        },
        refreshToken: ({required refreshToken}) async {
          requestedRefreshTokens.add(refreshToken);
          refreshCount += 1;
          return NetworkSessionRefreshResult(
            token: AuthToken('access-token-$refreshCount'),
            refreshToken: 'rotated-refresh-token-$refreshCount',
          );
        },
      );

      final first = await coordinator.ensureSession(displayName: 'Alice');
      final second = await coordinator.ensureSession(displayName: 'Alice');

      expect(requestedRefreshTokens, [
        'initial-refresh-token',
        'rotated-refresh-token-1',
      ]);
      expect(first.refreshToken, 'rotated-refresh-token-1');
      expect(second.token, AuthToken('access-token-2'));
      expect(second.refreshToken, 'rotated-refresh-token-2');
      expect(savedSessions.map((session) => session.refreshToken), [
        'rotated-refresh-token-1',
        'rotated-refresh-token-2',
      ]);
      expect(stored.refreshToken, 'rotated-refresh-token-2');
    });

    test('clears a rejected stored session and requires sign in', () async {
      final cleared = <String>[];
      final setSessions = <NetworkSession?>[];
      final coordinator = _coordinator(
        setSession: setSessions.add,
        clearStoredSession: () async => cleared.add('clear'),
        loadStoredSession: () async {
          return const StoredNetworkSession(
            userId: 'old_user',
            refreshToken: 'expired-refresh',
            displayName: 'Alice',
          );
        },
        refreshToken: ({required refreshToken}) async {
          throw const MultiplayerFailure.authentication(
            code: 'refresh_rejected',
          );
        },
      );

      await expectLater(
        coordinator.ensureSession(displayName: 'Alice'),
        throwsA(isA<NetworkSignInRequiredException>()),
      );

      expect(cleared, const ['clear']);
      expect(setSessions, isEmpty);
    });

    test(
      'clears current stored identity when the display name changes',
      () async {
        final current = _session(userId: 'user_1');
        final cleared = <String>[];
        final setSessions = <NetworkSession?>[];
        final coordinator = _coordinator(
          currentSession: () => current,
          setSession: setSessions.add,
          clearStoredSession: () async => cleared.add('clear'),
          loadStoredSession: () async {
            return const StoredNetworkSession(
              userId: 'user_1',
              refreshToken: 'refresh-token',
              displayName: 'Alice',
            );
          },
        );

        await expectLater(
          coordinator.ensureSession(displayName: 'Bob'),
          throwsA(isA<NetworkSignInRequiredException>()),
        );

        expect(cleared, const ['clear']);
        expect(setSessions.single, isNull);
      },
    );

    test('applies active and terminal match sessions', () async {
      final setSessions = <NetworkSession?>[];
      final savedMatchIds = <String?>[];
      final coordinator = _coordinator(
        setSession: setSessions.add,
        saveMatchId: (matchId) async => savedMatchIds.add(matchId),
      );
      final session = _session(userId: 'user_1');

      coordinator
        ..applyActiveMatch(session: session, match: _match())
        ..applyActiveMatch(
          session: session,
          match: _match(state: 'finished'),
        );
      await Future<void>.delayed(Duration.zero);

      expect(setSessions.first?.matchId, 'match_1');
      expect(setSessions.first?.playerId, 'player_1');
      expect(setSessions.last?.matchId, isNull);
      expect(setSessions.last?.playerId, isNull);
      expect(savedMatchIds, const ['match_1', null]);
    });

    test('serializes overlapping active-match persistence effects', () async {
      final firstWriteStarted = Completer<void>();
      final releaseFirstWrite = Completer<void>();
      final savedMatchIds = <String?>[];
      final coordinator = _coordinator(
        saveMatchId: (matchId) async {
          savedMatchIds.add(matchId);
          if (matchId == null) return;
          firstWriteStarted.complete();
          await releaseFirstWrite.future;
        },
      );
      final session = _session(userId: 'user_1');

      coordinator.applyActiveMatch(session: session, match: _match());
      await firstWriteStarted.future;
      coordinator.applyActiveMatch(
        session: session,
        match: _match(state: 'finished'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(savedMatchIds, const ['match_1']);

      releaseFirstWrite.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(savedMatchIds, const ['match_1', null]);
    });

    test('reports active-match persistence failures', () async {
      final reportedError = Completer<Object>();
      _coordinator(
        saveMatchId: (_) async => throw StateError('storage unavailable'),
        onEffectError: (error, _) => reportedError.complete(error),
      ).applyActiveMatch(
        session: _session(userId: 'user_1'),
        match: _match(),
      );

      expect(await reportedError.future, isA<StateError>());
    });

    test('match updates preserve credentials refreshed after stream start', () {
      final streamedSession = _session(userId: 'user_1');
      final refreshedSession = streamedSession.copyWith(
        token: AuthToken('fresh-jwt'),
        refreshToken: 'rotated-refresh',
      );
      final coordinator = _coordinator(currentSession: () => refreshedSession);

      final updated = coordinator.sessionForMatch(
        session: streamedSession,
        match: _match(),
      );

      expect(updated.token.value, 'fresh-jwt');
      expect(updated.refreshToken, 'rotated-refresh');
      expect(updated.matchId, 'match_1');
    });
  });
}

LobbyNetworkSessionCoordinator _coordinator({
  LobbyCurrentSessionReader? currentSession,
  LobbySessionSetter? setSession,
  LobbyStoredSessionLoader? loadStoredSession,
  LobbyStoredSessionSaver? saveStoredSession,
  LobbyStoredSessionClearer? clearStoredSession,
  LobbyMatchIdSaver? saveMatchId,
  LobbySessionTokenRefresher? refreshToken,
  LobbySessionEffectErrorReporter? onEffectError,
}) {
  return LobbyNetworkSessionCoordinator(
    currentSession: currentSession ?? () => null,
    setSession: setSession ?? (_) {},
    loadStoredSession: loadStoredSession ?? () async => null,
    saveStoredSession: saveStoredSession ?? (_) async {},
    clearStoredSession: clearStoredSession ?? () async {},
    effectRunner: NetworkSessionEffectRunner(
      persistMatchId: saveMatchId ?? (_) async {},
      publishTransportStatus: (_) {},
      clearTransportStatus: (_) {},
      onError:
          onEffectError ??
          (error, stackTrace) {
            fail('unexpected session effect error: $error\n$stackTrace');
          },
    ),
    refreshToken:
        refreshToken ??
        ({required refreshToken}) async {
          fail('unexpected refresh token request');
        },
    now: () => DateTime.utc(2026, 6, 2, 12),
  );
}

NetworkSession _session({required String userId}) {
  return NetworkSession(
    userId: userId,
    token: AuthToken('token-$userId'),
    refreshToken: 'refresh-$userId',
    connectionState: NetworkConnectionState(
      status: NetworkConnectionStatus.connected,
      changedAt: DateTime.utc(2026, 6, 2),
    ),
  );
}

WireMatch _match({String state = 'open'}) {
  return WireMatch(
    id: 'match_1',
    ownerUserId: 'user_1',
    name: 'Duel',
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
    ],
    maxPlayers: 4,
    minPlayers: 2,
    turn: 1,
    state: state,
    createdAt: DateTime.utc(2026, 6, 2),
  );
}
