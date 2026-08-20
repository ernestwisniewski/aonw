part of 'game_ai_turn_auto_pilot.dart';

extension _GameAiTurnAutoPilotRuntime on _GameAiTurnAutoPilotState {
  AiStrategyRegistry _strategyRegistryFor({
    required String playerId,
    required GameSave save,
    required GameClientState gameState,
    required NetworkSession? networkSession,
  }) {
    return _aiRuntimeStrategyResolver().resolve(
      playerId: playerId,
      save: save,
      gameState: gameState,
      networkSession: networkSession,
    );
  }

  AiTurnAutoScheduler _aiTurnAutoScheduler() {
    return AiTurnAutoScheduler(
      logger: ref.read(gameLoggerProvider),
      runScheduler: _runScheduler,
      precomputeCoordinator: _precomputeCoordinator,
      precomputeCache: _precomputeCache,
      throttler: _runtimeThrottler,
      shouldRunLocalAi: GameAiTurnAutoPilotRules.shouldRunLocalAi,
      aiPlayerToRun: GameAiTurnAutoPilotRules.aiPlayerToRun,
      scheduleTurn: _runtimeCoordinator.scheduleTurn,
      schedulePendingPrecompute: _runtimeCoordinator.schedulePendingPrecompute,
      precomputeStats: _runtimeCoordinator.precomputeStats,
      throttleStats: _runtimeCoordinator.throttleStats,
      logThrottleChange: _runtimeCoordinator.logThrottleChange,
    );
  }

  AiTurnLifecycleCoordinator _createAiTurnLifecycleCoordinator() {
    return AiTurnLifecycleCoordinator(
      runScheduler: _runScheduler,
      precomputeCoordinator: _precomputeCoordinator,
      precomputeCache: _precomputeCache,
      strategicPlanProvider: _strategicPlanProvider,
      throttler: _runtimeThrottler,
      cancelQueuedPrecompute: _runtimeCoordinator.cancelQueuedPrecompute,
      schedulePendingPrecompute: _runtimeCoordinator.schedulePendingPrecompute,
      shutdownPrecomputeExecutor: () {
        unawaited(shutdownIsolatedAiPlanExecutor());
      },
    );
  }

  AiTurnRuntimeCoordinator _createAiTurnRuntimeCoordinator() {
    return AiTurnRuntimeCoordinator(
      logger: ref.read(gameLoggerProvider),
      runScheduler: _runScheduler,
      precomputeCoordinator: _precomputeCoordinator,
      throttler: _runtimeThrottler,
      executionRunner: _aiTurnExecutionRunner,
      precomputeRunner: _aiTurnPrecomputeRunner,
      schedulePostFrame: (callback) {
        WidgetsBinding.instance.addPostFrameCallback((_) => callback());
      },
      canContinue: () => mounted,
      notifyStateChanged: _notifyStateChanged,
      interCommandDelay: () => widget.interCommandDelay,
      now: _nowUtc,
    );
  }

  AiRuntimeStrategyResolver _aiRuntimeStrategyResolver() {
    return AiRuntimeStrategyResolver(
      logger: ref.read(gameLoggerProvider),
      throttler: _runtimeThrottler,
      forceBatterySaver: () => ref.read(aiSettingsProvider).batterySaver,
    );
  }

  DateTime _nowUtc() => ref.read(gameClockProvider).nowUtc();
}
