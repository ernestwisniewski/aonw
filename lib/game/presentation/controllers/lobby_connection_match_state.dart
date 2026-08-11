import 'dart:async';

import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_controller.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_live_match_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_action_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw_core/protocol.dart';

extension LobbyConnectionMatchStateInternal on LobbyConnectionController {
  LobbyMatchActionCoordinator matchActionCoordinatorInternal() {
    return LobbyMatchActionCoordinator(
      ensureSession: () => ensureNetworkSessionInternal(),
      validateMap: () => validateMap(),
      quickplay: ({required token, required request}) =>
          sessionClient.quickplay(token: token, request: request),
      listMatches: ({required token}) =>
          sessionClient.listMatches(token: token),
      createMatch: ({required token, required request}) =>
          sessionClient.createMatch(token: token, request: request),
      joinMatch: ({required token, required matchId, country}) => sessionClient
          .joinMatch(token: token, matchId: matchId, country: country),
      createPrivateMatch: ({required token, required request}) =>
          sessionClient.createPrivateMatch(token: token, request: request),
      joinPrivateMatch: ({required token, required request}) =>
          sessionClient.joinPrivateMatch(token: token, request: request),
      startMatch: ({required token, required matchId}) =>
          sessionClient.startMatch(token: token, matchId: matchId),
      loadMatch: ({required token, required matchId}) =>
          sessionClient.loadMatch(token: token, matchId: matchId),
      leaveMatch: ({required token, required matchId}) =>
          sessionClient.leaveMatch(token: token, matchId: matchId),
      rememberMatch: ({required session, required match}) {
        return _acceptLobbyMatchUpdate(session: session, match: match);
      },
      watchMatch: ({required session, required match}) =>
          liveMatchCoordinatorInternal().watch(session: session, match: match),
      clearMatch: (session) {
        final matchId = activeMatch?.id;
        _clearNetworkActiveMatch(session);
        setActiveMatchInternal(null);
        if (matchId != null) invalidatePublishedMatch?.call(matchId);
      },
      enterMatch: ({required session, required match}) =>
          _enterMultiplayerMatch(session: session, match: match),
      scheduleAutoStartRefresh: (match) => _scheduleAutoStartRefresh(match),
      stopLobbyUpdates: () => stopLobbyUpdates(),
      canContinue: () => canContinueInternal(),
    );
  }

  LobbyMatchActionConfig matchActionConfigInternal() {
    return LobbyMatchActionConfig(
      mapName: mapName,
      country: country(),
      mapNotReadyMessage: mapNotReadyMessage(),
    );
  }

  bool _acceptLobbyMatchUpdate({
    required NetworkSession session,
    required WireMatch match,
  }) {
    if (unavailableMatchIdsInternal.contains(match.id)) return false;
    if (LobbyMatchStatusRules.isTerminal(match) ||
        !LobbyMatchStatusRules.containsUser(match, session.userId)) {
      _handleLobbyUnavailable(session: session, matchId: match.id);
      return false;
    }
    _rememberActiveMatch(session: session, match: match);
    return true;
  }

  void _rememberActiveMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    setActiveMatchInternal(match);
    publishMatch(match);
    networkSessionCoordinatorInternal().applyActiveMatch(
      session: session,
      match: match,
    );
  }

  void _clearNetworkActiveMatch(NetworkSession session) {
    networkSessionCoordinatorInternal().clearActiveMatch(session);
  }

  void _enterMultiplayerMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    matchNavigationCoordinatorInternal().enter(session: session, match: match);
  }

  void setNetworkSessionDeferredInternal(NetworkSession? session) {
    unawaited(
      Future<void>(() {
        if (!canContinueInternal()) return;
        setSession(session);
      }),
    );
  }

  Future<LobbyLiveMatchStreamHandle> subscribeLobbyMatchInternal({
    required NetworkSession session,
    required WireMatch match,
    required void Function(WireMatch match) onMatch,
    required void Function(Object error, StackTrace stackTrace) onError,
  }) async {
    final handle = await liveEvents.subscribe(
      matchId: match.id,
      token: session.token,
      tokenReader: ensureValidSession == null
          ? null
          : () async => (await ensureValidSession!()).token,
      fromOffset: 0,
      onEvent: (_) {},
      onSnapshotResync: (_) {},
      onMatch: onMatch,
      onConnected: () => _reportLobbyTransportStatus(
        matchId: match.id,
        status: NetworkConnectionStatus.connected,
      ),
      onReconnecting: () => _reportLobbyTransportStatus(
        matchId: match.id,
        status: NetworkConnectionStatus.reconnecting,
        message: 'Live event stream reconnecting',
      ),
      onError: onError,
      onDone: () => _reportLobbyTransportStatus(
        matchId: match.id,
        status: NetworkConnectionStatus.reconnecting,
        message: 'Live event stream closed',
      ),
    );
    return LiveEventLobbyMatchStreamHandle(handle);
  }

  void _reportLobbyTransportStatus({
    required String matchId,
    required NetworkConnectionStatus status,
    String? message,
  }) {
    if (!canContinueInternal() || activeMatch?.id != matchId) return;
    final reporter = reportTransportStatus;
    if (reporter == null) return;
    unawaited(
      Future<void>(() {
        if (!canContinueInternal() || activeMatch?.id != matchId) return;
        reporter(matchId: matchId, status: status, message: message);
      }),
    );
  }

  void applyLobbyMatchUpdateNowInternal({
    required NetworkSession session,
    required WireMatch match,
  }) {
    if (!canContinueInternal() || activeMatch?.id != match.id) return;
    if (!session.isConnected) return;
    if (!_acceptLobbyMatchUpdate(session: session, match: match)) return;
    if (!canContinueInternal()) return;
    setErrorInternal(null);
    if (LobbyMatchStatusRules.canEnter(match)) {
      stopLobbyUpdates();
      _enterMultiplayerMatch(session: session, match: match);
    } else {
      _scheduleAutoStartRefresh(match);
    }
  }

  void _scheduleAutoStartRefresh(WireMatch match) {
    internalAutoStartCoordinator.schedule(match);
  }

  void handleLobbyStreamErrorInternal(Object error) {
    if (error is MultiplayerFailure && error.terminatesLobbyMembership) {
      final matchId = activeMatch?.id;
      if (matchId != null) {
        _handleLobbyUnavailable(session: currentSession(), matchId: matchId);
      }
      return;
    }
    showNetworkErrorInternal(error);
  }

  void _handleLobbyUnavailable({
    required NetworkSession? session,
    required String matchId,
  }) {
    if (!canContinueInternal()) return;
    final activeMatch = this.activeMatch;
    if (activeMatch != null && activeMatch.id != matchId) return;
    if (!unavailableMatchIdsInternal.add(matchId)) return;

    final previousMode = mode;
    stopLobbyUpdates();
    if (session != null) _clearNetworkActiveMatch(session);
    invalidatePublishedMatch?.call(matchId);
    setStateInternal(
      error: null,
      activeMatch: null,
      mode: _modeAfterUnavailable(previousMode),
    );
    presentLobbyUnavailable?.call();

    if (previousMode == LobbyMultiplayerMode.publicMatch ||
        previousMode == LobbyMultiplayerMode.publicBrowse) {
      setPublicMatchesInternal(const [], loaded: false);
      unawaited(restorePublicBrowseAfterUnavailableInternal());
    }
  }

  LobbyMultiplayerMode _modeAfterUnavailable(LobbyMultiplayerMode mode) {
    return switch (mode) {
      LobbyMultiplayerMode.quickplay ||
      LobbyMultiplayerMode.privateHost => LobbyMultiplayerMode.home,
      LobbyMultiplayerMode.publicMatch => LobbyMultiplayerMode.publicBrowse,
      LobbyMultiplayerMode.privateJoin => LobbyMultiplayerMode.privateJoin,
      LobbyMultiplayerMode.home || LobbyMultiplayerMode.publicBrowse => mode,
    };
  }
}
