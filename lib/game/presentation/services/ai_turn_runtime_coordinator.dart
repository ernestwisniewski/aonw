import 'dart:async';

import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/presentation/services/ai_turn_execution_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_runner.dart';

typedef AiTurnExecutionRunnerReader = AiTurnExecutionRunner Function();
typedef AiTurnPrecomputeRunnerReader = AiTurnPrecomputeRunner Function();
typedef AiTurnPostFrameScheduler = void Function(void Function() callback);
typedef AiTurnRuntimeCanContinue = bool Function();
typedef AiTurnRuntimeStateNotifier = void Function();
typedef AiTurnRuntimeDelayReader = Duration Function();
typedef AiTurnRuntimeClockReader = DateTime Function();

final class AiTurnRuntimeCoordinator {
  final GameLogger logger;
  final AiTurnRunScheduler runScheduler;
  final AiTurnPrecomputeCoordinator precomputeCoordinator;
  final AiRuntimeThrottler throttler;
  final AiTurnExecutionRunnerReader executionRunner;
  final AiTurnPrecomputeRunnerReader precomputeRunner;
  final AiTurnPostFrameScheduler schedulePostFrame;
  final AiTurnRuntimeCanContinue canContinue;
  final AiTurnRuntimeStateNotifier notifyStateChanged;
  final AiTurnRuntimeDelayReader interCommandDelay;
  final AiTurnRuntimeClockReader now;

  const AiTurnRuntimeCoordinator({
    required this.logger,
    required this.runScheduler,
    required this.precomputeCoordinator,
    required this.throttler,
    required this.executionRunner,
    required this.precomputeRunner,
    required this.schedulePostFrame,
    required this.canContinue,
    required this.notifyStateChanged,
    required this.interCommandDelay,
    required this.now,
  });

  void schedulePendingPrecompute() {
    precomputeCoordinator.schedulePending(
      aiTurnRunning: () => runScheduler.running,
      throttle: () => throttler.snapshot,
      now: now,
      canContinue: canContinue,
      onStart: (request, startedCount) {
        logger.info(
          'AI Runtime',
          'precompute start #$startedCount '
              'player=${request.playerId}; '
              '${precomputeStats()} ${throttleStats()}',
        );
      },
      run: (request) {
        return precomputeRunner().run(request);
      },
      onSettled: () {
        if (canContinue()) notifyStateChanged();
      },
    );
  }

  void cancelQueuedPrecompute() {
    precomputeCoordinator.cancelPending();
  }

  void scheduleTurn(AiTurnRunRequest request) {
    schedulePostFrame(() {
      if (!canContinue()) return;
      unawaited(runTurn(request));
    });
  }

  Future<void> runTurn(AiTurnRunRequest request) async {
    if (!canContinue() || !runScheduler.canStart(request)) return;

    runScheduler.markStarted(request);
    notifyStateChanged();
    cancelQueuedPrecompute();

    var result = const AiTurnExecutionResult.notCompleted();
    try {
      result = await executionRunner().run(
        request,
        interCommandDelay: interCommandDelay(),
      );
      if (result.completed) {
        runScheduler.markCompleted(request);
      }
    } finally {
      if (canContinue()) {
        runScheduler.markFinished(request);
        notifyStateChanged();
        _scheduleFollowUpAiTurn(result);
      } else {
        runScheduler.markFinished(request);
      }
    }
  }

  String precomputeStats() => precomputeCoordinator.stats();

  String throttleStats() => 'throttle=${throttler.snapshot}';

  void logThrottleChange(String reason) {
    logger.info(
      'AI Runtime',
      'throttle adjusted by $reason; ${throttleStats()}',
    );
  }

  void _scheduleFollowUpAiTurn(AiTurnExecutionResult result) {
    final nextSave = result.followUpSave;
    final nextAiPlayerId = result.followUpAiPlayerId;
    if (nextSave == null || nextAiPlayerId == null) return;

    final nextRequest = runScheduler.schedule(
      saveId: nextSave.id,
      turn: nextSave.turn,
      playerId: nextAiPlayerId,
    );
    if (nextRequest != null) {
      scheduleTurn(nextRequest);
    }
  }
}
