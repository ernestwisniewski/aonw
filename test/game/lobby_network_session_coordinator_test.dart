import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_network_session_coordinator.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

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
            return AuthToken('fresh-token');
          },
        );

        final session = await coordinator.ensureSession(displayName: 'Alice');

        expect(session, same(current));
        expect(setSessions, isEmpty);
        expect(refreshed, isFalse);
      },
    );

    test(
      'refreshes a stored account session and keeps the stored match id',
      () async {
        final setSessions = <NetworkSession?>[];
        final coordinator = _coordinator(
          setSession: setSessions.add,
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
            return AuthToken('fresh-token');
          },
        );

        final session = await coordinator.ensureSession(displayName: 'Alice');

        expect(session.userId, 'user_1');
        expect(session.token, AuthToken('fresh-token'));
        expect(session.refreshToken, 'refresh-token');
        expect(session.matchId, 'match_1');
        expect(setSessions.single, session);
      },
    );

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
          throw sp_auth.RefreshTokenExpiredException();
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

    test('applies active and terminal match sessions', () {
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

      expect(setSessions.first?.matchId, 'match_1');
      expect(setSessions.first?.playerId, 'player_1');
      expect(setSessions.last?.matchId, isNull);
      expect(setSessions.last?.playerId, isNull);
      expect(savedMatchIds, const ['match_1', null]);
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
}) {
  return LobbyNetworkSessionCoordinator(
    currentSession: currentSession ?? () => null,
    setSession: setSession ?? (_) {},
    loadStoredSession: loadStoredSession ?? () async => null,
    saveStoredSession: saveStoredSession ?? (_) async {},
    clearStoredSession: clearStoredSession ?? () async {},
    saveMatchId: saveMatchId ?? (_) async {},
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
