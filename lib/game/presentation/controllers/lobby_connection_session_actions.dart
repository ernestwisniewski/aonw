part of 'lobby_connection_controller.dart';

extension LobbyConnectionSessionActions on LobbyConnectionController {
  Future<bool> signOut() async {
    stopLobbyUpdates();
    final session = currentSession();
    Object? signOutError;
    final coordinatedSignOut = signOutSession;
    if (coordinatedSignOut == null) {
      try {
        final sessionRefreshToken = session?.refreshToken;
        final stored =
            sessionRefreshToken == null || sessionRefreshToken.isEmpty
            ? await sessionStore.load()
            : null;
        final storedRefreshToken =
            stored != null &&
                (session == null || stored.userId == session.userId)
            ? stored.refreshToken
            : null;
        await sessionClient.signOutCurrentSession(
          token: session?.token,
          refreshToken:
              sessionRefreshToken == null || sessionRefreshToken.isEmpty
              ? storedRefreshToken
              : sessionRefreshToken,
        );
      } catch (error) {
        signOutError = error;
      }
      try {
        final terminate = terminateSession;
        if (terminate == null) {
          await sessionStore.clear();
        } else {
          await terminate();
        }
      } catch (error) {
        signOutError ??= error;
      }
    } else {
      try {
        await coordinatedSignOut();
      } catch (error) {
        signOutError = error;
      }
    }
    setSession(null);
    if (!_canContinue()) return signOutError == null;
    _setState(error: null, activeMatch: null, mode: LobbyMultiplayerMode.home);
    _setPublicMatches(const [], loaded: false);
    if (signOutError != null) {
      _showNetworkError(signOutError);
      return false;
    }
    return true;
  }

  Future<NetworkSession> _ensureNetworkSession() async {
    final storedDisplayName = await sessionStore.loadDisplayName();
    try {
      return await _networkSessionCoordinator().ensureSession(
        displayName: storedDisplayName,
      );
    } on NetworkSignInRequiredException {
      final auth = await authenticate(initialDisplayName: displayName());
      if (auth == null) throw const _LobbyNetworkAuthCancelledException();
      final session = auth.toSession(changedAt: now());
      final activate = activateAuthenticatedSession;
      if (activate != null) {
        await activate(session: session, displayName: auth.displayName);
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
