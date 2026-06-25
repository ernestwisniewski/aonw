import 'package:aonw/game/application/services/ai_runtime_throttler.dart';

final class AiTurnPrecomputeScheduler {
  final AiTurnPrecomputeQueue _queue;
  final Set<String> _scheduledKeys;

  AiTurnPrecomputeScheduler({
    AiTurnPrecomputeQueue? queue,
    Set<String>? scheduledKeys,
  }) : _queue = queue ?? AiTurnPrecomputeQueue(),
       _scheduledKeys = scheduledKeys ?? <String>{};

  bool get lifecyclePaused => _queue.lifecyclePaused;
  bool get running => _queue.running;
  bool get hasPending => _queue.pending != null;
  String? get pendingScheduleKey => _queue.pending?.scheduleKey;
  int get startedCount => _queue.startedCount;

  bool setLifecyclePaused(bool paused) {
    if (_queue.lifecyclePaused == paused) return false;
    _queue.lifecyclePaused = paused;
    return true;
  }

  bool hasScheduledOrPending(String scheduleKey) {
    return _scheduledKeys.contains(scheduleKey) ||
        _queue.pending?.scheduleKey == scheduleKey;
  }

  AiTurnPrecomputeQueueResult queue(AiTurnPrecomputeRequest request) {
    final replaced =
        _queue.pending != null &&
        _queue.pending!.scheduleKey != request.scheduleKey;
    _queue
      ..recordQueued(replaced: replaced)
      ..pending = request;
    return AiTurnPrecomputeQueueResult(replaced: replaced);
  }

  bool canSchedule({required bool aiTurnRunning}) {
    return !_queue.running &&
        !aiTurnRunning &&
        _queue.pending != null &&
        !_queue.lifecyclePaused;
  }

  Duration delayBeforeNextStart({
    required AiRuntimeThrottleSnapshot throttle,
    required DateTime now,
  }) {
    final elapsed = now.difference(_queue.lastStartedAt);
    final cooldownRemaining = throttle.precomputeMinimumStartInterval - elapsed;
    return cooldownRemaining > throttle.precomputeDebounceDuration
        ? cooldownRemaining
        : throttle.precomputeDebounceDuration;
  }

  AiTurnPrecomputeRequest? startNext({
    required bool aiTurnRunning,
    required DateTime startedAt,
  }) {
    if (!canSchedule(aiTurnRunning: aiTurnRunning)) return null;

    final request = _queue.pending!;
    _queue.clearPending();
    if (!_scheduledKeys.add(request.scheduleKey)) return null;

    _queue.markStarted(startedAt);
    return request;
  }

  void clearScheduledKeys() {
    _scheduledKeys.clear();
  }

  void cancelPending() {
    _queue.cancelPending();
  }

  void markStopped() {
    _queue.markStopped();
  }

  void markCompleted() {
    _queue.markCompleted();
  }

  void markFailed(String scheduleKey) {
    _queue.markFailed();
    _scheduledKeys.remove(scheduleKey);
  }

  String stats() {
    return _queue.stats();
  }
}

final class AiTurnPrecomputeQueue {
  AiTurnPrecomputeRequest? pending;
  bool running = false;
  bool lifecyclePaused = false;
  int queuedCount = 0;
  int replacedCount = 0;
  int canceledCount = 0;
  int startedCount = 0;
  int completedCount = 0;
  int failedCount = 0;
  DateTime lastStartedAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  void recordQueued({required bool replaced}) {
    queuedCount += 1;
    if (replaced) {
      replacedCount += 1;
    }
  }

  void clearPending() {
    pending = null;
  }

  void cancelPending() {
    if (pending != null) {
      canceledCount += 1;
    }
    pending = null;
  }

  void markStarted(DateTime startedAt) {
    running = true;
    startedCount += 1;
    lastStartedAt = startedAt;
  }

  void markStopped() {
    running = false;
  }

  void markCompleted() {
    completedCount += 1;
  }

  void markFailed() {
    failedCount += 1;
  }

  String stats() {
    return 'queued=$queuedCount '
        'replaced=$replacedCount '
        'canceled=$canceledCount '
        'started=$startedCount '
        'completed=$completedCount '
        'failed=$failedCount';
  }
}

final class AiTurnPrecomputeQueueResult {
  final bool replaced;

  const AiTurnPrecomputeQueueResult({required this.replaced});
}

final class AiTurnPrecomputeRequest {
  final String saveId;
  final String playerId;
  final String scheduleKey;

  const AiTurnPrecomputeRequest({
    required this.saveId,
    required this.playerId,
    required this.scheduleKey,
  });
}
