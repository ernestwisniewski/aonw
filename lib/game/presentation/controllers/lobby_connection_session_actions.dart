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
        await sessionClient.signOutCurrentSession(
          token: session?.token,
          refreshToken:
              sessionRefreshToken == null || sessionRefreshToken.isEmpty
              ? stored?.refreshToken
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
      final stored = auth.toStoredSession(displayName: auth.displayName);
      if (stored == null) {
        await sessionStore.saveDisplayName(auth.displayName);
      } else {
        await sessionStore.save(stored);
      }
      setSession(session);
      setPrimaryDisplayName(auth.displayName);
      return session;
    }
  }
}
