import 'dart:async';

import 'package:aonw/game/application/services/ai_runtime_strategy_resolver.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/services/ai_turn_auto_scheduler.dart';
import 'package:aonw/game/presentation/services/ai_turn_lifecycle_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_runtime_coordinator.dart';
import 'package:aonw/game/presentation/services/isolated_ai_plan_executor.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_context.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_execution.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_process.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_rules.dart';
import 'package:aonw/shared/providers/ai_settings_provider.dart';
import 'package:flutter/widgets.dart';

extension GameAiTurnAutoPilotRuntime on GameAiTurnAutoPilotContext {
  void initialize() {
    runtimeCoordinator = createAiTurnRuntimeCoordinator();
    lifecycleCoordinator = createAiTurnLifecycleCoordinator();
  }

  AiTurnAutoScheduler aiTurnAutoScheduler() {
    return AiTurnAutoScheduler(
      logger: ref.read(gameLoggerProvider),
      runScheduler: runScheduler,
      precomputeCoordinator: precomputeCoordinator,
      precomputeCache: precomputeCache,
      throttler: runtimeThrottler,
      shouldRunLocalAi: GameAiTurnAutoPilotRules.shouldRunLocalAi,
      aiPlayerToRun: GameAiTurnAutoPilotRules.aiPlayerToRun,
      scheduleTurn: runtimeCoordinator.scheduleTurn,
      schedulePendingPrecompute: runtimeCoordinator.schedulePendingPrecompute,
      precomputeStats: runtimeCoordinator.precomputeStats,
      throttleStats: runtimeCoordinator.throttleStats,
      logThrottleChange: runtimeCoordinator.logThrottleChange,
    );
  }

  AiTurnLifecycleCoordinator createAiTurnLifecycleCoordinator() {
    return AiTurnLifecycleCoordinator(
      runScheduler: runScheduler,
      precomputeCoordinator: precomputeCoordinator,
      precomputeCache: precomputeCache,
      strategicPlanProvider: strategicPlanProvider,
      throttler: runtimeThrottler,
      cancelQueuedPrecompute: runtimeCoordinator.cancelQueuedPrecompute,
      schedulePendingPrecompute: runtimeCoordinator.schedulePendingPrecompute,
      shutdownPrecomputeExecutor: () {
        unawaited(shutdownIsolatedAiPlanExecutor());
      },
    );
  }

  AiTurnRuntimeCoordinator createAiTurnRuntimeCoordinator() {
    return AiTurnRuntimeCoordinator(
      logger: ref.read(gameLoggerProvider),
      runScheduler: runScheduler,
      precomputeCoordinator: precomputeCoordinator,
      throttler: runtimeThrottler,
      // Keep extension calls inside closures. Passing extension method tear-offs
      // across post-frame, timer, or await boundaries traps optimized dart2wasm.
      executionRunner: () => aiTurnExecutionRunner(),
      precomputeRunner: () => aiTurnPrecomputeRunner(),
      schedulePostFrame: (callback) {
        WidgetsBinding.instance.addPostFrameCallback((_) => callback());
      },
      canContinue: canContinue,
      notifyStateChanged: notifyStateChanged,
      interCommandDelay: interCommandDelayReader,
      now: () => nowUtc(),
    );
  }

  AiRuntimeStrategyResolver aiRuntimeStrategyResolver() {
    return AiRuntimeStrategyResolver(
      logger: ref.read(gameLoggerProvider),
      throttler: runtimeThrottler,
      forceBatterySaver: () => ref.read(aiSettingsProvider).batterySaver,
    );
  }

  DateTime nowUtc() => ref.read(gameClockProvider).nowUtc();
}
