import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';

typedef AiTurnCancelQueuedPrecompute = void Function();
typedef AiTurnSchedulePendingPrecompute = void Function();
typedef AiTurnShutdownPrecomputeExecutor = void Function();

final class AiTurnLifecycleCoordinator {
  final AiTurnRunScheduler runScheduler;
  final AiTurnPrecomputeCoordinator precomputeCoordinator;
  final AiTurnPlanPrecomputeCache precomputeCache;
  final AiStrategicPlanProvider strategicPlanProvider;
  final AiRuntimeThrottler throttler;
  final AiTurnCancelQueuedPrecompute cancelQueuedPrecompute;
  final AiTurnSchedulePendingPrecompute schedulePendingPrecompute;
  final AiTurnShutdownPrecomputeExecutor shutdownPrecomputeExecutor;

  const AiTurnLifecycleCoordinator({
    required this.runScheduler,
    required this.precomputeCoordinator,
    required this.precomputeCache,
    required this.strategicPlanProvider,
    required this.throttler,
    required this.cancelQueuedPrecompute,
    required this.schedulePendingPrecompute,
    required this.shutdownPrecomputeExecutor,
  });

  void handleSaveChange({
    required GameSave? previousSave,
    required GameSave? currentSave,
  }) {
    if (previousSave?.id != currentSave?.id) {
      _resetForSave();
      return;
    }
    if (previousSave?.turn != currentSave?.turn) {
      _resetForTurn(currentSave);
    }
  }

  void handleLifecyclePaused(bool paused) {
    if (!precomputeCoordinator.setLifecyclePaused(paused)) return;
    if (paused) {
      precomputeCoordinator.clearScheduledKeys();
      cancelQueuedPrecompute();
      precomputeCache.clear();
      shutdownPrecomputeExecutor();
    } else {
      schedulePendingPrecompute();
    }
  }

  void dispose() {
    cancelQueuedPrecompute();
    precomputeCache.clear();
    strategicPlanProvider.clear();
  }

  void _resetForSave() {
    runScheduler.resetForSave();
    precomputeCoordinator.clearScheduledKeys();
    cancelQueuedPrecompute();
    precomputeCache.clear();
    strategicPlanProvider.clear();
    throttler.reset();
  }

  void _resetForTurn(GameSave? currentSave) {
    runScheduler.resetForTurn();
    precomputeCoordinator.clearScheduledKeys();
    cancelQueuedPrecompute();
    if (currentSave == null) {
      precomputeCache.clear();
      return;
    }
    precomputeCache.retainWhere((key) {
      return key.saveId == currentSave.id && key.turn == currentSave.turn;
    });
  }
}
