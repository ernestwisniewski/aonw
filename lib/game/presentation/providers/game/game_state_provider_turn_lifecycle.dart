part of 'game_state_provider.dart';

Duration? _doNotRetry(int retryCount, Object error) => null;

const _liveSnapshotRetryDelays = [
  Duration(milliseconds: 150),
  Duration(milliseconds: 350),
  Duration(milliseconds: 750),
];

LiveServerEvent? _presentedLiveEvent(
  LiveSnapshotPresentationDecision presentation,
  LiveServerEvent? event,
) => presentation.canPresentLiveTransition ? event : null;

String _multiplayerCacheKey(String userId, String saveId) {
  return multiplayerSnapshotCacheKey(userId: userId, matchId: saveId);
}

void _warnGameState(
  Ref ref,
  String message,
  Object? error,
  StackTrace? stackTrace,
) {
  ref
      .read(gameLoggerProvider)
      .warn('GameStateNotifier', message, error, stackTrace);
}

extension GameStateNotifierTurnLifecycle on GameStateNotifier {
  Future<GameClientState> _buildState(String saveId) async {
    _providerRef.onDispose(() => unawaited(_closeLiveEvents()));
    await _closeLiveEvents();
    _saveId = saveId;
    final session = _providerRef.watch(activeGameSessionProvider);
    if (session == null || saveId.isEmpty) {
      _dispatchCommand = null;
      return GameClientState();
    }
    final reducer = _createReducer(session);
    _reducer = reducer;
    final liveCommandDispatcher = session.gameMode == GameMode.multiplayer
        ? LiveWireCommandDispatcher(
            liveHandle: _liveCommandHandle,
            fallback: _providerRef.watch(wireCommandDispatcherProvider),
          )
        : null;
    _dispatchCommand = buildDispatchCommandUseCase(
      _providerRef,
      reducer,
      session.gameMode,
      saveId: saveId,
      commandDispatcher: liveCommandDispatcher,
    );
    final bootstrap = BootstrapGameStateUseCase(
      repository: gameRepositoryForSave(_providerRef, saveId),
      dispatchCommand: _dispatchCommand!,
    );
    final bootstrapped = await bootstrap.executeWithResult(
      saveId: saveId,
      preferredPlayerId: _providerRef.read(networkSessionProvider)?.playerId,
    );
    _eventLogOffset = bootstrapped.offset;
    var synchronized = reducer
        .syncActivePlayer(
          bootstrapped.state,
          playerId: bootstrapped.state.activePlayerId,
          canAct: bootstrapped.state.activePlayerCanAct,
        )
        .state;
    if (bootstrapped.shouldFocusTurnStart) {
      final focus = GameIntentResolver(reducer: reducer).resolve(
        synchronized.interaction,
        FocusTurnStartActionCommand(synchronized.activePlayerId),
        synchronized,
      );
      if (focus.interaction != synchronized.interaction) {
        synchronized = synchronized.copyWith(interaction: focus.interaction);
      }
    }
    if (!_isMounted) return synchronized;
    unawaited(_startLiveEvents(saveId, gameMode: session.gameMode));
    return synchronized;
  }

  GameStateReducer _createReducer(GameSession session) {
    return GameStateReducer(
      mapData: session.mapData,
      ruleset: GameRuleset.standard().copyWith(
        city: _providerRef.watch(cityRulesetProvider),
        technology: _providerRef.watch(technologyRulesetProvider),
        stability: _providerRef.watch(stabilityRulesetProvider),
      ),
    );
  }

  Future<DispatchCommandResult> _dispatchTransitionNow(
    DomainCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (!_isMounted) {
      return DispatchCommandResult(state: GameClientState());
    }
    var current = _stateValue;
    if (current == null) {
      try {
        current = await _stateFuture;
      } catch (_) {
        return DispatchCommandResult(state: GameClientState());
      }
      if (!_isMounted) return DispatchCommandResult(state: current);
    }
    final useCase = _dispatchCommand;
    if (useCase == null || _saveId.isEmpty) {
      return DispatchCommandResult(state: current);
    }
    final result = await useCase.execute(
      saveId: _saveId,
      currentState: current,
      command: command,
      context: context,
    );
    await _publishDispatchResult(result);
    return result;
  }

  Future<DispatchCommandResult> _resolveIntentTransitionNow(
    GameIntent intent, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (!_isMounted) {
      return DispatchCommandResult(state: GameClientState(), offset: -1);
    }
    var current = _stateValue;
    if (current == null) {
      try {
        current = await _stateFuture;
      } catch (_) {
        return DispatchCommandResult(state: GameClientState(), offset: -1);
      }
    }
    final reducer = _reducer;
    if (!_isMounted || reducer == null) {
      return DispatchCommandResult(state: current, offset: -1);
    }
    final resolution = GameIntentResolver(
      reducer: reducer,
      context: context,
    ).resolve(current.interaction, intent, current);
    final domainCommand = resolution.domainCommand;
    if (domainCommand != null) {
      return _dispatchResolvedDomainCommand(
        current: current,
        intent: intent,
        command: domainCommand,
        context: context,
      );
    }
    final next = resolution.interaction == current.interaction
        ? current
        : current.copyWith(interaction: resolution.interaction);
    if (_isMounted) _stateValue = next;
    return DispatchCommandResult(
      state: next,
      uiEffects: resolution.presentationFocus,
      offset: -1,
    );
  }

  Future<DispatchCommandResult> _dispatchResolvedDomainCommand({
    required GameClientState current,
    required GameIntent intent,
    required DomainCommand command,
    required GameCommandContext context,
  }) async {
    final useCase = _dispatchCommand;
    if (useCase == null || _saveId.isEmpty) {
      return DispatchCommandResult(state: current, offset: -1);
    }
    final result = await useCase.execute(
      saveId: _saveId,
      currentState: current,
      command: command,
      context: context,
      fromMovePreviewConfirmation:
          intent is TileTappedCommand && command is MoveUnitCommand,
    );
    await _publishDispatchResult(result);
    return result;
  }

  Future<void> _publishDispatchResult(DispatchCommandResult result) async {
    if (_isMounted) {
      if (result.offset >= 0) {
        _eventLogOffset = result.offset;
        _providerRef.invalidate(gameActivityHistoryProvider(_saveId));
      }
      _stateValue = result.state;
    }
    if (result.storedSnapshot && result.snapshot != null) {
      await _cacheAppliedSnapshot(
        saveId: _saveId,
        snapshot: result.snapshot!,
        offset: result.offset,
      );
    }
  }

  Future<T> _enqueueDispatch<T>(Future<T> Function() operation) {
    final next = _dispatchQueue.then((_) => operation());
    _dispatchQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<List<UiEffect>> dispatch(
    DomainCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    final result = await dispatchTransition(command, context: context);
    return result.uiEffects;
  }

  /// Use when the caller must coordinate the new state with renderer effects.
  Future<DispatchCommandResult> dispatchTransition(
    DomainCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _enqueueDispatch(
      () => _dispatchTransitionNow(command, context: context),
    );
  }

  Future<List<UiEffect>> dispatchIntent(
    GameIntent intent, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    final result = await dispatchIntentTransition(intent, context: context);
    return result.uiEffects;
  }

  Future<DispatchCommandResult> dispatchIntentTransition(
    GameIntent intent, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _enqueueDispatch(
      () => _resolveIntentTransitionNow(intent, context: context),
    );
  }

  FutureOr<LiveEventSubscriptionHandle?> _liveCommandHandle() {
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
