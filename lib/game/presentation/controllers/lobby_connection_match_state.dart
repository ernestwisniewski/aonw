part of 'lobby_connection_controller.dart';

extension _LobbyConnectionMatchState on LobbyConnectionController {
  LobbyMatchActionCoordinator _matchActionCoordinator() {
    return LobbyMatchActionCoordinator(
      ensureSession: _ensureNetworkSession,
      validateMap: validateMap,
      quickplay: sessionClient.quickplay,
      listMatches: sessionClient.listMatches,
      createMatch: sessionClient.createMatch,
      joinMatch: sessionClient.joinMatch,
      createPrivateMatch: sessionClient.createPrivateMatch,
      joinPrivateMatch: sessionClient.joinPrivateMatch,
      startMatch: sessionClient.startMatch,
      loadMatch: sessionClient.loadMatch,
      leaveMatch: sessionClient.leaveMatch,
      rememberMatch: ({required session, required match}) {
        return _acceptLobbyMatchUpdate(session: session, match: match);
      },
      watchMatch: _liveMatchCoordinator.watch,
      clearMatch: (session) {
        final matchId = _activeMatch?.id;
        _clearNetworkActiveMatch(session);
        _setActiveMatch(null);
        if (matchId != null) invalidatePublishedMatch?.call(matchId);
      },
      enterMatch: _enterMultiplayerMatch,
      scheduleAutoStartRefresh: _scheduleAutoStartRefresh,
      stopLobbyUpdates: stopLobbyUpdates,
      canContinue: _canContinue,
    );
  }

  LobbyMatchActionConfig _matchActionConfig() {
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
    if (_unavailableMatchIds.contains(match.id)) return false;
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
    _setActiveMatch(match);
    publishMatch(match);
    _networkSessionCoordinator().applyActiveMatch(
      session: session,
      match: match,
    );
  }

  void _clearNetworkActiveMatch(NetworkSession session) {
    _networkSessionCoordinator().clearActiveMatch(session);
  }

  void _enterMultiplayerMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    _matchNavigationCoordinator.enter(session: session, match: match);
  }

  LobbyNetworkSessionCoordinator _networkSessionCoordinator() {
    return LobbyNetworkSessionCoordinator(
      currentSession: currentSession,
      setSession: _setNetworkSessionDeferred,
      loadStoredSession: sessionStore.load,
      saveStoredSession: sessionStore.save,
      clearStoredSession: sessionStore.clear,
      saveMatchId: sessionStore.saveMatchId,
      refreshToken: sessionClient.refresh,
      now: now,
      ensureValidSession: ensureValidSession,
      terminateSession: terminateSession,
    );
  }

  void _setNetworkSessionDeferred(NetworkSession? session) {
    unawaited(
      Future<void>(() {
        if (!_canContinue()) return;
        setSession(session);
      }),
    );
  }

  Future<LobbyLiveMatchStreamHandle> _subscribeLobbyMatch({
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
    if (!_canContinue() || _activeMatch?.id != matchId) return;
    final reporter = reportTransportStatus;
    if (reporter == null) return;
    unawaited(
      Future<void>(() {
        if (!_canContinue() || _activeMatch?.id != matchId) return;
        reporter(matchId: matchId, status: status, message: message);
      }),
    );
  }

  void _applyLobbyMatchUpdateNow({
    required NetworkSession session,
    required WireMatch match,
  }) {
    if (!_canContinue() || _activeMatch?.id != match.id) return;
    if (!session.isConnected) return;
    if (!_acceptLobbyMatchUpdate(session: session, match: match)) return;
    if (!_canContinue()) return;
    _setError(null);
    if (LobbyMatchStatusRules.canEnter(match)) {
      stopLobbyUpdates();
      _enterMultiplayerMatch(session: session, match: match);
    } else {
      _scheduleAutoStartRefresh(match);
    }
  }

  void _scheduleAutoStartRefresh(WireMatch match) {
    _autoStartCoordinator.schedule(match);
  }

  void _handleLobbyStreamError(Object error) {
    if (error is MultiplayerFailure && error.terminatesLobbyMembership) {
      final matchId = _activeMatch?.id;
      if (matchId != null) {
        _handleLobbyUnavailable(session: currentSession(), matchId: matchId);
      }
      return;
    }
    _showNetworkError(error);
  }

  void _handleLobbyUnavailable({
    required NetworkSession? session,
    required String matchId,
  }) {
    if (!_canContinue()) return;
    final activeMatch = _activeMatch;
    if (activeMatch != null && activeMatch.id != matchId) return;
    if (!_unavailableMatchIds.add(matchId)) return;

    final previousMode = _mode;
    stopLobbyUpdates();
    if (session != null) _clearNetworkActiveMatch(session);
    invalidatePublishedMatch?.call(matchId);
    _setState(
      error: null,
      activeMatch: null,
      mode: _modeAfterUnavailable(previousMode),
    );
    presentLobbyUnavailable?.call();

    if (previousMode == LobbyMultiplayerMode.publicMatch ||
        previousMode == LobbyMultiplayerMode.publicBrowse) {
      _setPublicMatches(const [], loaded: false);
      unawaited(_restorePublicBrowseAfterUnavailable());
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
