part of 'game_state_provider.dart';

Duration? _doNotRetry(int retryCount, Object error) => null;

extension GameStateNotifierApplicationBootstrap on GameStateNotifier {
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
}
