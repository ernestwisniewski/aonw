part of 'lobby_connection_controller.dart';

extension LobbyConnectionCompositionInternal on LobbyConnectionController {
  LobbyNetworkSessionCoordinator _buildNetworkSessionCoordinator() {
    return LobbyNetworkSessionCoordinator(
      currentSession: currentSession,
      setSession: _setNetworkSessionDeferred,
      loadStoredSession: sessionStore.load,
      saveStoredSession: sessionStore.save,
      clearStoredSession: sessionStore.clear,
      saveMatchId: sessionStore.saveMatchId,
      refreshToken: sessionClient.refresh,
      now: now,
      onEffectError: reportSessionEffectError,
      ensureValidSession: ensureValidSession,
      terminateSession: terminateSession,
    );
  }

  LobbyAutoStartCoordinator _buildAutoStartCoordinator() {
    return LobbyAutoStartCoordinator(
      now: now,
      isQuickplayMode: () => _mode == LobbyMultiplayerMode.quickplay,
      activeMatch: () => _activeMatch,
      canContinue: canContinueInternal,
      refreshActiveMatch: () => unawaited(refreshActiveMatch()),
      notifyCountdownChanged: notifyStateChangedInternal,
    );
  }

  LobbyLiveMatchCoordinator _buildLiveMatchCoordinator() {
    return LobbyLiveMatchCoordinator(
      activeMatch: () => _activeMatch,
      canContinue: canContinueInternal,
      subscribe: _subscribeLobbyMatch,
      applyMatchUpdate: _applyLobbyMatchUpdateNow,
      showError: _handleLobbyStreamError,
      reportStreamError: _shouldReportLobbyStreamError,
      defer: (action) => unawaited(Future<void>(action)),
    );
  }

  LobbyMatchNavigationCoordinator _buildMatchNavigationCoordinator() {
    return LobbyMatchNavigationCoordinator(
      activeMatch: () => _activeMatch,
      canContinue: canContinueInternal,
      sessionForMatch: ({required session, required match}) {
        return networkSessionCoordinatorInternal().sessionForMatch(
          session: session,
          match: match,
        );
      },
      setSession: setSession,
      navigateTo: navigateTo,
      stopLobbyUpdates: stopLobbyUpdates,
      defer: (action) => unawaited(Future<void>(action)),
      mapSource: mapSource,
    );
  }
}
