import 'dart:async';

import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw_core/protocol.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

typedef LobbyCurrentSessionReader = NetworkSession? Function();
typedef LobbySessionSetter = void Function(NetworkSession? session);
typedef LobbyStoredSessionLoader = Future<StoredNetworkSession?> Function();
typedef LobbyStoredSessionSaver =
    Future<void> Function(StoredNetworkSession session);
typedef LobbyStoredSessionClearer = Future<void> Function();
typedef LobbyMatchIdSaver = Future<void> Function(String? matchId);
typedef LobbySessionTokenRefresher =
    Future<AuthToken> Function({required String refreshToken});
typedef LobbySessionClockReader = DateTime Function();

final class LobbyNetworkSessionCoordinator {
  static const tokenRefreshSkew = Duration(seconds: 30);

  final LobbyCurrentSessionReader currentSession;
  final LobbySessionSetter setSession;
  final LobbyStoredSessionLoader loadStoredSession;
  final LobbyStoredSessionSaver saveStoredSession;
  final LobbyStoredSessionClearer clearStoredSession;
  final LobbyMatchIdSaver saveMatchId;
  final LobbySessionTokenRefresher refreshToken;
  final LobbySessionClockReader now;

  const LobbyNetworkSessionCoordinator({
    required this.currentSession,
    required this.setSession,
    required this.loadStoredSession,
    required this.saveStoredSession,
    required this.clearStoredSession,
    required this.saveMatchId,
    required this.refreshToken,
    required this.now,
  });

  Future<NetworkSession> ensureSession({required String displayName}) async {
    final current = currentSession();
    final currentTime = now();
    final stored = await loadStoredSession();
    if (_canReuseCurrentSession(
      current: current,
      stored: stored,
      displayName: displayName,
      now: currentTime,
    )) {
      return current!;
    }

    if (_currentSessionDisplayNameChanged(
      current: current,
      stored: stored,
      displayName: displayName,
      now: currentTime,
    )) {
      await clearStoredSession();
      setSession(null);
    } else if (stored != null && stored.displayName != displayName) {
      await clearStoredSession();
    } else if (stored != null) {
      final refreshed = await _tryRefreshStoredSession(stored, currentTime);
      if (refreshed != null) return refreshed;
    }

    throw const NetworkSignInRequiredException();
  }

  void applyActiveMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    if (LobbyMatchStatusRules.isTerminal(match)) {
      clearActiveMatch(session);
      return;
    }
    setSession(sessionForMatch(session: session, match: match));
    unawaited(saveMatchId(match.id));
  }

  void clearActiveMatch(NetworkSession session) {
    setSession(sessionWithoutActiveMatch(session));
    unawaited(saveMatchId(null));
  }

  NetworkSession sessionForMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    return NetworkSession(
      userId: session.userId,
      playerId: LobbyMatchStatusRules.playerIdForUser(match, session.userId),
      token: session.token,
      refreshToken: session.refreshToken,
      matchId: match.id,
      connectionState: NetworkConnectionState(
        status: NetworkConnectionStatus.connected,
        changedAt: now(),
      ),
    );
  }

  NetworkSession sessionWithoutActiveMatch(NetworkSession session) {
    return NetworkSession(
      userId: session.userId,
      token: session.token,
      refreshToken: session.refreshToken,
      connectionState: session.connectionState.copyWith(changedAt: now()),
    );
  }

  bool _canReuseCurrentSession({
    required NetworkSession? current,
    required StoredNetworkSession? stored,
    required String displayName,
    required DateTime now,
  }) {
    if (current == null ||
        !current.isConnected ||
        _tokenNeedsRefresh(current, now)) {
      return false;
    }
    return stored == null ||
        stored.userId != current.userId ||
        stored.displayName == displayName;
  }

  bool _currentSessionDisplayNameChanged({
    required NetworkSession? current,
    required StoredNetworkSession? stored,
    required String displayName,
    required DateTime now,
  }) {
    if (current == null ||
        !current.isConnected ||
        _tokenNeedsRefresh(current, now) ||
        stored == null) {
      return false;
    }
    return stored.userId == current.userId && stored.displayName != displayName;
  }

  Future<NetworkSession?> _tryRefreshStoredSession(
    StoredNetworkSession stored,
    DateTime now,
  ) async {
    try {
      final token = await refreshToken(refreshToken: stored.refreshToken);
      final session = NetworkSession(
        userId: stored.userId,
        token: token,
        refreshToken: stored.refreshToken,
        matchId: stored.matchId,
        connectionState: NetworkConnectionState(
          status: NetworkConnectionStatus.connected,
          changedAt: now,
        ),
      );
      setSession(session);
      return session;
    } catch (error) {
      if (!_isRejectedRefreshToken(error)) rethrow;
      await clearStoredSession();
      return null;
    }
  }

  bool _isRejectedRefreshToken(Object error) {
    return error is sp_auth.RefreshTokenMalformedException ||
        error is sp_auth.RefreshTokenNotFoundException ||
        error is sp_auth.RefreshTokenExpiredException ||
        error is sp_auth.RefreshTokenInvalidSecretException;
  }

  bool _tokenNeedsRefresh(NetworkSession session, DateTime now) {
    return session.token.isExpiredAt(now, skew: tokenRefreshSkew);
  }
}

final class NetworkSignInRequiredException implements Exception {
  const NetworkSignInRequiredException();
}
