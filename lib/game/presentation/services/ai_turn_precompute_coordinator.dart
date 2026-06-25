import 'dart:async';

import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_precompute_scheduler.dart';

typedef AiTurnPrecomputeTimerFactory =
    Timer Function(Duration delay, void Function() onElapsed);
typedef AiTurnPrecomputeRequestRunner =
    Future<void> Function(AiTurnPrecomputeRequest request);
typedef AiTurnPrecomputeStartReporter =
    void Function(AiTurnPrecomputeRequest request, int startedCount);

final class AiTurnPrecomputeCoordinator {
  final AiTurnPrecomputeScheduler scheduler;
  final AiTurnPrecomputeTimerFactory timerFactory;
  Timer? _timer;

  AiTurnPrecomputeCoordinator({
    AiTurnPrecomputeScheduler? scheduler,
    this.timerFactory = Timer.new,
  }) : scheduler = scheduler ?? AiTurnPrecomputeScheduler();

  bool get lifecyclePaused => scheduler.lifecyclePaused;
  bool get hasPending => scheduler.hasPending;
  String? get pendingScheduleKey => scheduler.pendingScheduleKey;

  bool setLifecyclePaused(bool paused) {
    return scheduler.setLifecyclePaused(paused);
  }

  bool hasScheduledOrPending(String scheduleKey) {
    return scheduler.hasScheduledOrPending(scheduleKey);
  }

  AiTurnPrecomputeQueueResult queue(AiTurnPrecomputeRequest request) {
    return scheduler.queue(request);
  }

  void schedulePending({
    required bool Function() aiTurnRunning,
    required AiRuntimeThrottleSnapshot Function() throttle,
    required DateTime Function() now,
    required bool Function() canContinue,
    required AiTurnPrecomputeRequestRunner run,
    required AiTurnPrecomputeStartReporter onStart,
    required void Function() onSettled,
  }) {
    if (!canContinue() ||
        !scheduler.canSchedule(aiTurnRunning: aiTurnRunning())) {
      return;
    }

    final delay = scheduler.delayBeforeNextStart(
      throttle: throttle(),
      now: now(),
    );

    _timer?.cancel();
    _timer = timerFactory(
      delay,
      () => _startPending(
        aiTurnRunning: aiTurnRunning,
        now: now,
        canContinue: canContinue,
        throttle: throttle,
        run: run,
        onStart: onStart,
        onSettled: onSettled,
      ),
    );
  }

  void cancelPending() {
    scheduler.cancelPending();
    cancelTimer();
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void clearScheduledKeys() {
    scheduler.clearScheduledKeys();
  }

  void markCompleted() {
    scheduler.markCompleted();
  }

  void markFailed(String scheduleKey) {
    scheduler.markFailed(scheduleKey);
  }

  String stats() {
    return scheduler.stats();
  }

  void _startPending({
    required bool Function() aiTurnRunning,
    required AiRuntimeThrottleSnapshot Function() throttle,
    required DateTime Function() now,
    required bool Function() canContinue,
    required AiTurnPrecomputeRequestRunner run,
    required AiTurnPrecomputeStartReporter onStart,
    required void Function() onSettled,
  }) {
    _timer = null;
    if (!canContinue()) return;

    final request = scheduler.startNext(
      aiTurnRunning: aiTurnRunning(),
      startedAt: now(),
    );
    if (request == null) return;

    onStart(request, scheduler.startedCount);
    unawaited(
      run(request).whenComplete(() {
        scheduler.markStopped();
        onSettled();
        schedulePending(
          aiTurnRunning: aiTurnRunning,
          throttle: throttle,
          now: now,
          canContinue: canContinue,
          run: run,
          onStart: onStart,
          onSettled: onSettled,
        );
      }),
    );
  }
}
