import 'dart:async';

import 'package:aonw/game/presentation/controllers/lobby_connection_controller.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_match_state.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_auto_start_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_live_match_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_navigation_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_network_session_coordinator.dart';

extension LobbyConnectionCompositionInternal on LobbyConnectionController {
  LobbyNetworkSessionCoordinator buildNetworkSessionCoordinatorInternal() {
    return LobbyNetworkSessionCoordinator(
      currentSession: () => currentSession(),
      setSession: (session) => setNetworkSessionDeferredInternal(session),
      loadStoredSession: () => sessionStore.load(),
      saveStoredSession: (session) => sessionStore.save(session),
      clearStoredSession: () => sessionStore.clear(),
      refreshToken: ({required refreshToken}) =>
          sessionClient.refresh(refreshToken: refreshToken),
      now: () => now(),
      effectRunner: sessionEffectRunner,
      ensureValidSession: ensureValidSession == null
          ? null
          : () => ensureValidSession!(),
      terminateSession: terminateSession == null
          ? null
          : () => terminateSession!(),
    );
  }

  LobbyAutoStartCoordinator buildAutoStartCoordinatorInternal() {
    return LobbyAutoStartCoordinator(
      now: now,
      isQuickplayMode: () => mode == LobbyMultiplayerMode.quickplay,
      activeMatch: () => activeMatch,
      canContinue: () => canContinueInternal(),
      refreshActiveMatch: () => unawaited(refreshActiveMatch()),
      notifyCountdownChanged: () => notifyStateChangedInternal(),
    );
  }

  LobbyLiveMatchCoordinator buildLiveMatchCoordinatorInternal() {
    return LobbyLiveMatchCoordinator(
      activeMatch: () => activeMatch,
      canContinue: () => canContinueInternal(),
      subscribe:
          ({
            required session,
            required match,
            required onMatch,
            required onError,
          }) => subscribeLobbyMatchInternal(
            session: session,
            match: match,
            onMatch: onMatch,
            onError: onError,
          ),
      applyMatchUpdate: ({required session, required match}) =>
          applyLobbyMatchUpdateNowInternal(session: session, match: match),
      showError: (error) => handleLobbyStreamErrorInternal(error),
      reportStreamError: (error) => shouldReportLobbyStreamErrorInternal(error),
      defer: (action) => unawaited(Future<void>(action)),
    );
  }

  LobbyMatchNavigationCoordinator buildMatchNavigationCoordinatorInternal() {
    return LobbyMatchNavigationCoordinator(
      activeMatch: () => activeMatch,
      canContinue: () => canContinueInternal(),
      sessionForMatch: ({required session, required match}) {
        return networkSessionCoordinatorInternal().sessionForMatch(
          session: session,
          match: match,
        );
      },
      setSession: (session) => setSession(session),
      navigateTo: (location) => navigateTo(location),
      stopLobbyUpdates: () => stopLobbyUpdates(),
      defer: (action) => unawaited(Future<void>(action)),
      mapSource: mapSource,
    );
  }
}
