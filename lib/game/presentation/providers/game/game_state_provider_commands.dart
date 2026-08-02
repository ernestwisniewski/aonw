part of 'game_state_provider.dart';

extension GameStateNotifierCommands on GameStateNotifier {
  Future<void> syncActivePlayer({
    required String playerId,
    required bool canAct,
  }) => _enqueueDispatch(() async {
    final current = _stateValue;
    final reducer = _reducer;
    if (!_isMounted || current == null || reducer == null) return;
    _stateValue = reducer
        .syncActivePlayer(current, playerId: playerId, canAct: canAct)
        .state;
  });

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
}
