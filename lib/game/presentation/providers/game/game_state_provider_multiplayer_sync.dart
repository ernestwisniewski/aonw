part of 'game_state_provider.dart';

const _liveSnapshotRetryDelays = [
  Duration(milliseconds: 150),
  Duration(milliseconds: 350),
  Duration(milliseconds: 750),
];

String _multiplayerCacheKey(String userId, String saveId) {
  return multiplayerSnapshotCacheKey(userId: userId, matchId: saveId);
}

extension GameStateNotifierMultiplayerSync on GameStateNotifier {
  Future<void> _startLiveEvents(
    String saveId, {
    required GameMode gameMode,
  }) async {
    if (gameMode != GameMode.multiplayer) return;

    final session = _providerRef.read(networkSessionProvider);
    if (session == null ||
        !session.isConnected ||
        session.matchId != saveId ||
        session.token.value.isEmpty) {
      return;
    }

    final starting = Completer<LiveMultiplayerEventHandle?>();
    _liveEventsStarting = starting.future;
    try {
      final subscription = _providerRef.read(liveMultiplayerEventsProvider);
      final handle = await subscription.subscribe(
        matchId: saveId,
        token: session.token,
        tokenReader: () => _providerRef
            .read(networkSessionRefreshCoordinatorProvider)
            .currentToken(),
        fromOffset: _eventLogOffset + 1,
        nextOffset: () => _eventLogOffset + 1,
        onEvent: (event) {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.connected,
          );
          final snapshot = event.snapshot;
          if (snapshot == null) {
            unawaited(_reloadNetworkSnapshot(saveId, liveEvent: event));
          } else {
            _queueNetworkSnapshotApply(
              saveId: saveId,
              snapshot: snapshot,
              liveEvent: event,
            );
          }
        },
        onSnapshotResync: (snapshot) {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.connected,
          );
          _queueNetworkSnapshotApply(saveId: saveId, snapshot: snapshot);
        },
        onMatch: (match) {
          if (!_isMounted || _saveId != saveId) return;
          _providerRef.read(multiplayerMatchProvider.notifier).upsert(match);
        },
        onConnected: () {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.connected,
          );
        },
        onReconnecting: () {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.reconnecting,
            message: 'Live event stream reconnecting',
          );
        },
        onError: (error, stackTrace) {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.reconnecting,
            message: error.toString(),
          );
          _warn('Live event stream failed', error, stackTrace);
        },
        onDone: () {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.reconnecting,
            message: 'Live event stream closed',
          );
          _warn('Live event stream closed');
        },
      );
      if (!_isMounted || _saveId != saveId) {
        await handle.close();
        starting.complete(null);
        return;
      }
      _liveEvents = handle;
      starting.complete(handle);
    } catch (error, stackTrace) {
      starting.complete(null);
      _warn('Could not start live event stream', error, stackTrace);
    } finally {
      if (identical(_liveEventsStarting, starting.future)) {
        _liveEventsStarting = null;
      }
    }
  }

  Future<void> _reloadNetworkSnapshot(
    String saveId, {
    LiveServerEvent? liveEvent,
    int attempt = 0,
  }) async {
    if (!_isMounted || _saveId != saveId) return;
    try {
      final snapshot = await gameRepositoryForSave(
        _providerRef,
        saveId,
      ).load(saveId);
      final liveOffset = liveEvent?.wire.offset;
      if (liveOffset != null && snapshot.eventLogOffset < liveOffset) {
        if (attempt < _liveSnapshotRetryDelays.length) {
          final delay = _liveSnapshotRetryDelays[attempt];
          _warn(
            'Snapshot offset ${snapshot.eventLogOffset} is behind live '
            'event offset $liveOffset; retrying in ${delay.inMilliseconds}ms',
          );
          await Future<void>.delayed(delay);
          return _reloadNetworkSnapshot(
            saveId,
            liveEvent: liveEvent,
            attempt: attempt + 1,
          );
        }
        _warn(
          'Snapshot offset ${snapshot.eventLogOffset} stayed behind live '
          'event offset $liveOffset; keeping the current state',
        );
        return;
      }
      _queueNetworkSnapshotApply(
        saveId: saveId,
        snapshot: snapshot,
        liveEvent: liveEvent,
      );
    } catch (error, stackTrace) {
      _warn('Could not reload network snapshot', error, stackTrace);
    }
  }

  void _setNetworkConnectionStatus(
    String saveId,
    NetworkConnectionStatus status, {
    String? message,
  }) {
    if (!_isMounted) return;
    final session = _providerRef.read(networkSessionProvider);
    if (session == null || session.matchId != saveId) return;
    _providerRef
        .read(networkSessionStateProvider.notifier)
        .reportTransportStatus(
          saveId: saveId,
          status: status,
          message: message,
          changedAt: _providerRef.read(gameClockProvider).nowUtc(),
        );
  }

  Future<void> _applyNetworkSnapshot({
    required String saveId,
    required CanonicalGameSnapshot snapshot,
    LiveServerEvent? liveEvent,
  }) async {
    if (!_isMounted || _saveId != saveId) return;
    final incomingOffset = _acceptedNetworkSnapshotOffset(
      snapshot: snapshot,
      liveEvent: liveEvent,
    );
    if (incomingOffset == null) return;
    final presentation = live.resolve(_eventLogOffset, liveEvent, snapshot);
    final previousState = _stateValue;
    final viewerPlayerId = _providerRef.read(networkSessionProvider)?.playerId;
    final nextState = _reconcileNetworkSnapshotState(
      snapshot: snapshot,
      previousState: previousState,
      viewerPlayerId: viewerPlayerId,
    );
    _eventLogOffset = incomingOffset;
    _stateValue = nextState;
    await _cacheAppliedSnapshot(
      saveId: saveId,
      snapshot: snapshot,
      offset: incomingOffset,
    );
    await _presentExternalSnapshot(
      previousState: previousState,
      nextState: nextState,
      events: _presentedLiveEvents(presentation, liveEvent),
      movementExecutions: presentation.movementExecutions,
      identity: _liveBatchIdentity(saveId, incomingOffset),
      viewerPlayerId: viewerPlayerId,
      turn: snapshot.save.turn,
      renderer: _providerRef.read(activeRendererViewModelProvider),
      audioController: _providerRef.read(gameAudioControllerProvider),
      notifications: _providerRef.read(gameEventNotificationsProvider.notifier),
      isMounted: () => _isMounted,
    );
  }

  int? _acceptedNetworkSnapshotOffset({
    required CanonicalGameSnapshot snapshot,
    required LiveServerEvent? liveEvent,
  }) {
    final liveOffset = liveEvent?.wire.offset;
    if (liveOffset != null &&
        snapshot.eventLogOffset > 0 &&
        snapshot.eventLogOffset < liveOffset) {
      _warn(
        'Ignoring stale snapshot offset ${snapshot.eventLogOffset} for '
        'live event offset $liveOffset',
      );
      return null;
    }
    final incomingOffset = snapshot.eventLogOffset > 0
        ? snapshot.eventLogOffset
        : liveOffset ?? 0;
    if (incomingOffset > 0 && incomingOffset <= _eventLogOffset) return null;
    if (liveOffset != null && liveOffset > _eventLogOffset + 1) {
      _warn(
        'Detected live event offset gap: current $_eventLogOffset, '
        'incoming $liveOffset; applying authoritative snapshot',
      );
    }
    return incomingOffset;
  }

  GameClientState _reconcileNetworkSnapshotState({
    required CanonicalGameSnapshot snapshot,
    required GameClientState? previousState,
    required String? viewerPlayerId,
  }) {
    final control = PlayerControlCoordinator.initialForPlayer(
      save: snapshot.save,
      preferredPlayerId: viewerPlayerId,
    );
    final authoritativeState = snapshot.toClientState(
      activePlayerId: control.activePlayerId,
      activePlayerCanAct: control.canAct,
    );
    if (previousState == null) return authoritativeState;
    return MultiplayerInteractionReconciler.reconcile(
      authoritativeState: authoritativeState,
      interactionSource: previousState,
    );
  }

  Future<void> _cacheAppliedSnapshot({
    required String saveId,
    required CanonicalGameSnapshot snapshot,
    required int offset,
  }) async {
    if (!_isMounted || _saveId != saveId) return;
    final session = _providerRef.read(networkSessionProvider);
    if (session == null || session.matchId != saveId) return;
    try {
      await _providerRef
          .read(snapshotStoreProvider)
          .save(
            _multiplayerCacheKey(session.userId, saveId),
            Snapshot(
              state: snapshot.withEventLogOffset(offset),
              createdAt: _providerRef.read(gameClockProvider).nowUtc(),
            ),
          );
      _providerRef.invalidate(gameSaveSnapshotProvider(saveId));
    } catch (error, stackTrace) {
      _warn('Could not cache network snapshot', error, stackTrace);
    }
  }

  FutureOr<LiveMultiplayerEventHandle?> _liveCommandHandle() {
    return _liveEvents ?? _liveEventsStarting;
  }

  void _queueNetworkSnapshotApply({
    required String saveId,
    required CanonicalGameSnapshot snapshot,
    LiveServerEvent? liveEvent,
  }) {
    _networkSnapshotQueue = _networkSnapshotQueue.then(
      (_) => _applyNetworkSnapshot(
        saveId: saveId,
        snapshot: snapshot,
        liveEvent: liveEvent,
      ),
      onError: (Object error, StackTrace stackTrace) {
        _warn('Previous network snapshot apply failed', error, stackTrace);
        return _applyNetworkSnapshot(
          saveId: saveId,
          snapshot: snapshot,
          liveEvent: liveEvent,
        );
      },
    );
  }

  Future<void> _closeLiveEvents() async {
    final liveEvents = _liveEvents;
    _liveEvents = null;
    _liveEventsStarting = null;
    await liveEvents?.close();
  }
}
