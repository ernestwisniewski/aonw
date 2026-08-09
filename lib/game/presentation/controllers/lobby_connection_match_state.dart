part of 'lobby_connection_controller.dart';

extension LobbyConnectionMatchStateInternal on LobbyConnectionController {
  LobbyMatchActionCoordinator matchActionCoordinatorInternal() {
    return LobbyMatchActionCoordinator(
      ensureSession: ensureNetworkSessionInternal,
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
      canContinue: canContinueInternal,
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
    _matchNavigationCoordinator.enter(session: session, match: match);
  }

  LobbyNetworkSessionCoordinator networkSessionCoordinatorInternal() {
    return _networkSessionCoordinator;
  }

  void _setNetworkSessionDeferred(NetworkSession? session) {
    unawaited(
      Future<void>(() {
        if (!canContinueInternal()) return;
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
    if (!canContinueInternal() || _activeMatch?.id != matchId) return;
    final reporter = reportTransportStatus;
    if (reporter == null) return;
    unawaited(
      Future<void>(() {
        if (!canContinueInternal() || _activeMatch?.id != matchId) return;
        reporter(matchId: matchId, status: status, message: message);
      }),
    );
  }

  void _applyLobbyMatchUpdateNow({
    required NetworkSession session,
    required WireMatch match,
  }) {
    if (!canContinueInternal() || _activeMatch?.id != match.id) return;
    if (!session.isConnected) return;
    if (!_acceptLobbyMatchUpdate(session: session, match: match)) return;
    if (!canContinueInternal()) return;
    _setError(null);
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

  void _handleLobbyStreamError(Object error) {
    if (error is MultiplayerFailure && error.terminatesLobbyMembership) {
      final matchId = _activeMatch?.id;
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
    final activeMatch = _activeMatch;
    if (activeMatch != null && activeMatch.id != matchId) return;
    if (!_unavailableMatchIds.add(matchId)) return;

    final previousMode = _mode;
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
