part of 'game_ai_turn_auto_pilot.dart';

extension _GameAiTurnAutoPilotProcess on _GameAiTurnAutoPilotState {
  AiTurnPrecomputeRunner _aiTurnPrecomputeRunner() {
    return AiTurnPrecomputeRunner(
      logger: ref.read(gameLoggerProvider),
      coordinator: _precomputeCoordinator,
      throttler: _runtimeThrottler,
      planExecutor: isolatedAiPlanPrecomputeExecutor,
      startPrecompute:
          ({required saveId, required playerId, required planExecutor}) async {
            final process = await _prepareAiTurnProcess(
              saveId: saveId,
              playerId: playerId,
            );
            return process?.precompute(planExecutor: planExecutor);
          },
      cacheSizeReader: () => _precomputeCache.length,
      precomputeStats: _runtimeCoordinator.precomputeStats,
      throttleStats: _runtimeCoordinator.throttleStats,
      logThrottleChange: _runtimeCoordinator.logThrottleChange,
    );
  }

  Future<PreparedAiTurnProcess?> _prepareAiTurnProcess({
    required String saveId,
    required String playerId,
    int? scheduledTurn,
  }) async {
    final executionToken = scheduledTurn == null
        ? null
        : _followUpIdentityGuard.beginExecution(
            saveId: saveId,
            turn: scheduledTurn,
            playerId: playerId,
          );
    if (scheduledTurn != null && executionToken == null) return null;

    final presentationDriver = _aiTurnPresentationDriver();
    final preparer = AiTurnProcessPreparer(
      repository: ref.read(gameRepositoryProvider),
      logger: ref.read(gameLoggerProvider),
      dispatch: presentationDriver.dispatchCommand,
      planExecutor: isolatedAiPlanExecutor,
      sessionReader: () => ref.read(activeGameSessionProvider),
      networkSessionReader: () => ref.read(networkSessionProvider),
      canContinue: () => mounted,
      shouldRunLocalAiForMode: GameAiTurnAutoPilotRules.shouldRunLocalAiForMode,
      canRunScheduledAiTurn: GameAiTurnAutoPilotRules.canRunScheduledAiTurn,
      strategyRegistryFor: _strategyRegistryFor,
      rulesetReader: () {
        return GameRuleset.standard().copyWith(
          city: ref.read(cityRulesetProvider),
          technology: ref.read(technologyRulesetProvider),
          stability: ref.read(stabilityRulesetProvider),
        );
      },
      eventLogReader: () => ref.read(eventLogProvider),
      precomputeCache: _precomputeCache,
      strategicPlanProvider: _strategicPlanProvider,
    );
    return preparer.prepare(
      saveId: saveId,
      playerId: playerId,
      scheduledTurn: scheduledTurn,
    );
  }

  AiTurnPresentationDriver _aiTurnPresentationDriver() {
    return AiTurnPresentationDriver(
      sessionReader: () => ref.read(activeGameSessionProvider),
      stateReader: (saveId) => ref.read(gameStateProvider(saveId)).value,
      localizationReader: () => ref.read(activeRendererViewModelProvider)?.l10n,
      applyTransition: (state, effects) async {
        final renderer = ref.read(activeRendererViewModelProvider);
        if (renderer == null) return;
        await renderer.applyTransition(state, effects);
      },
      applyProjectedTransition: (state, batch) async {
        final renderer = ref.read(activeRendererViewModelProvider);
        if (renderer == null) return;
        await renderer.applyProjectedTransition(state, batch);
      },
      hiddenDispatch: ({required saveId, required command, required context}) {
        return ref
            .read(gameStateProvider(saveId).notifier)
            .dispatchTransition(command, context: context);
      },
      canContinue: () => mounted,
    );
  }
}
