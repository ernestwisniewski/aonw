import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_controller.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_network_session_coordinator.dart';
import 'package:aonw_core/protocol.dart';

extension LobbyConnectionSessionActions on LobbyConnectionController {
  Future<bool> signOut() async {
    final session = currentSession();
    final activeMatch = this.activeMatch;
    await _leaveOpenLobbyBeforeSignOut(session: session, match: activeMatch);
    await stopLobbyUpdatesAndWaitInternal();
    final signOutError = await _revokeAndTerminateSession(session);
    setSession(null);
    return _completeSignOut(activeMatch: activeMatch, error: signOutError);
  }

  Future<Object?> _revokeAndTerminateSession(NetworkSession? session) async {
    final coordinatedSignOut = signOutSession;
    if (coordinatedSignOut != null) {
      return _captureSignOutError(coordinatedSignOut);
    }
    final revokeError = await _captureSignOutError(
      () => _revokeDirectSession(session),
    );
    final terminateError = await _captureSignOutError(_terminateLocalSession);
    return revokeError ?? terminateError;
  }

  Future<void> _revokeDirectSession(NetworkSession? session) async {
    await sessionClient.signOutCurrentSession(
      token: session?.token,
      refreshToken: await _refreshTokenForSignOut(session),
    );
  }

  Future<String?> _refreshTokenForSignOut(NetworkSession? session) async {
    final currentRefreshToken = session?.refreshToken;
    if (currentRefreshToken != null && currentRefreshToken.isNotEmpty) {
      return currentRefreshToken;
    }
    final stored = await sessionStore.load();
    if (stored == null ||
        (session != null && stored.userId != session.userId)) {
      return null;
    }
    return stored.refreshToken;
  }

  Future<void> _terminateLocalSession() async {
    final terminate = terminateSession;
    if (terminate == null) {
      await sessionStore.clear();
      return;
    }
    await terminate();
  }

  Future<Object?> _captureSignOutError(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (error) {
      return error;
    }
  }

  bool _completeSignOut({
    required WireMatch? activeMatch,
    required Object? error,
  }) {
    if (!canContinueInternal()) return error == null;
    if (activeMatch != null) {
      invalidatePublishedMatch?.call(activeMatch.id);
    }
    setStateInternal(
      error: null,
      activeMatch: null,
      mode: LobbyMultiplayerMode.home,
    );
    setPublicMatchesInternal(const [], loaded: false);
    if (error != null) {
      showNetworkErrorInternal(error);
      return false;
    }
    return true;
  }

  Future<void> _leaveOpenLobbyBeforeSignOut({
    required NetworkSession? session,
    required WireMatch? match,
  }) async {
    if (session == null ||
        match == null ||
        !LobbyMatchStatusRules.isOpen(match)) {
      return;
    }
    try {
      await sessionClient.leaveMatch(token: session.token, matchId: match.id);
    } catch (_) {
      // Session revocation must continue; server-side presence expiry is the
      // authoritative fallback when this best-effort leave cannot be delivered.
    }
  }

  Future<NetworkSession> ensureNetworkSessionInternal() async {
    final storedDisplayName = await sessionStore.loadDisplayName();
    try {
      return await networkSessionCoordinatorInternal().ensureSession(
        displayName: storedDisplayName,
      );
    } on NetworkSignInRequiredException {
      final auth = await authenticate(initialDisplayName: displayName());
      if (auth == null) throw const LobbyNetworkAuthCancelledException();
      final session = auth.toSession(changedAt: now());
      final activate = activateAuthenticatedSession;
      if (activate != null) {
        await activate.activate(
          session: session,
          displayName: auth.displayName,
        );
      } else {
        setSession(session);
        await _persistFallbackAuthenticatedSession(auth);
      }
      setPrimaryDisplayName(auth.displayName);
      return session;
    }
  }

  Future<void> _persistFallbackAuthenticatedSession(
    NetworkAuthResult auth,
  ) async {
    final stored = auth.toStoredSession(displayName: auth.displayName);
    if (stored == null) {
      try {
        // A token-only login must not inherit a previous account's refresh
        // credential or match metadata.
        await sessionStore.clear();
        await sessionStore.saveDisplayName(auth.displayName);
      } catch (_) {
        // The authenticated session remains usable in memory. The owner check
        // in signOut prevents any stale stored credential from being revoked.
      }
      return;
    }

    try {
      await sessionStore.save(stored);
    } on NetworkSessionCredentialPersistenceException {
      try {
        // Detach any previous account after a failed secure write. Production
        // uses the refresh coordinator and retries the new credential.
        await sessionStore.clear();
        await sessionStore.saveDisplayName(auth.displayName);
      } catch (_) {
        // Keep the authenticated session memory-only when storage is broken.
      }
    }
  }
}
