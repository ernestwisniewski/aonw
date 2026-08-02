import 'dart:async';

import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/network_session_authentication.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';
import 'package:aonw/game/application/services/network_session_state_machine.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw_core/protocol.dart';

typedef LobbyCurrentSessionReader = NetworkSession? Function();
typedef LobbySessionSetter = void Function(NetworkSession? session);
typedef LobbyStoredSessionLoader = Future<StoredNetworkSession?> Function();
typedef LobbyStoredSessionSaver =
    Future<void> Function(StoredNetworkSession session);
typedef LobbyStoredSessionClearer = Future<void> Function();
typedef LobbyMatchIdSaver = Future<void> Function(String? matchId);
typedef LobbySessionTokenRefresher =
    Future<NetworkSessionRefreshResult> Function({
      required String refreshToken,
    });
typedef LobbySessionClockReader = DateTime Function();
typedef LobbyValidSessionEnsurer = Future<NetworkSession> Function();

final class LobbyNetworkSessionCoordinator {
  static const tokenRefreshSkew = Duration(seconds: 30);
  static const _sessionReducer = NetworkSessionReducer();

  final LobbyCurrentSessionReader currentSession;
  final LobbySessionSetter setSession;
  final LobbyStoredSessionLoader loadStoredSession;
  final LobbyStoredSessionSaver saveStoredSession;
  final LobbyStoredSessionClearer clearStoredSession;
  final LobbyMatchIdSaver saveMatchId;
  final LobbySessionTokenRefresher refreshToken;
  final LobbySessionClockReader now;
  final LobbyValidSessionEnsurer? ensureValidSession;
  final LobbyStoredSessionClearer? terminateSession;

  const LobbyNetworkSessionCoordinator({
    required this.currentSession,
    required this.setSession,
    required this.loadStoredSession,
    required this.saveStoredSession,
    required this.clearStoredSession,
    required this.saveMatchId,
    required this.refreshToken,
    required this.now,
    this.ensureValidSession,
    this.terminateSession,
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
      final terminate = terminateSession;
      if (terminate == null) {
        await clearStoredSession();
        setSession(null);
      } else {
        await terminate();
      }
    } else if (stored != null && stored.displayName != displayName) {
      await clearStoredSession();
    } else if (ensureValidSession != null &&
        (stored != null || current?.refreshToken?.isNotEmpty == true)) {
      try {
        return await ensureValidSession!();
      } on NetworkSessionAuthenticationException {
        // The central coordinator already ended the unusable session.
      }
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
    final transition = _activeMatchTransition(session: session, match: match);
    setSession(transition.state.session);
    unawaited(_effectRunner.runAll(transition.effects));
  }

  void clearActiveMatch(NetworkSession session) {
    final base = _latestSessionFor(session);
    final transition = _sessionReducer.reduce(
      NetworkSessionTransportState(session: base),
      ClearNetworkMatchAction(expectedUserId: base.userId, changedAt: now()),
    );
    setSession(transition.state.session);
    unawaited(_effectRunner.runAll(transition.effects));
  }

  NetworkSession sessionForMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    return _activeMatchTransition(
      session: session,
      match: match,
    ).state.session!;
  }

  NetworkSession sessionWithoutActiveMatch(NetworkSession session) {
    final base = _latestSessionFor(session);
    return _sessionReducer
        .reduce(
          NetworkSessionTransportState(session: base),
          ClearNetworkMatchAction(
            expectedUserId: base.userId,
            changedAt: now(),
          ),
        )
        .state
        .session!;
  }

  NetworkSessionTransition _activeMatchTransition({
    required NetworkSession session,
    required WireMatch match,
  }) {
    final base = _latestSessionFor(session);
    return _sessionReducer.reduce(
      NetworkSessionTransportState(session: base),
      ActivateNetworkMatchAction(
        expectedUserId: base.userId,
        playerId: LobbyMatchStatusRules.playerIdForUser(match, base.userId),
        matchId: match.id,
        changedAt: now(),
      ),
    );
  }

  NetworkSession _latestSessionFor(NetworkSession session) {
    final latest = currentSession();
    return latest?.userId == session.userId ? latest! : session;
  }

  NetworkSessionEffectRunner get _effectRunner => NetworkSessionEffectRunner(
    persistMatchId: saveMatchId,
    publishTransportStatus: (_) {},
    clearTransportStatus: (_) {},
    onError: (_, _) {},
  );

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
      final refresh = await refreshToken(refreshToken: stored.refreshToken);
      final refreshedStoredSession = StoredNetworkSession(
        userId: stored.userId,
        refreshToken: refresh.refreshToken,
        displayName: stored.displayName,
        matchId: stored.matchId,
      );
      await saveStoredSession(refreshedStoredSession);
      final session = NetworkSession(
        userId: stored.userId,
        token: refresh.token,
        refreshToken: refresh.refreshToken,
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
    return error is MultiplayerFailure &&
        error.kind == MultiplayerFailureKind.authentication &&
        error.code == 'refresh_rejected';
  }

  bool _tokenNeedsRefresh(NetworkSession session, DateTime now) {
    return session.token.isExpiredAt(now, skew: tokenRefreshSkew);
  }
}

final class NetworkSignInRequiredException implements Exception {
  const NetworkSignInRequiredException();
}
