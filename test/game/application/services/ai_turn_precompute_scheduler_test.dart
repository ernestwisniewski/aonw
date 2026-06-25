import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_precompute_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnPrecomputeScheduler', () {
    test('queues and replaces pending requests', () {
      final scheduler = AiTurnPrecomputeScheduler();

      final first = scheduler.queue(_request('key_1', playerId: 'ai_1'));
      final second = scheduler.queue(_request('key_2', playerId: 'ai_2'));

      expect(first.replaced, isFalse);
      expect(second.replaced, isTrue);
      expect(scheduler.hasScheduledOrPending('key_1'), isFalse);
      expect(scheduler.hasScheduledOrPending('key_2'), isTrue);
      expect(
        scheduler.stats(),
        'queued=2 replaced=1 canceled=0 started=0 completed=0 failed=0',
      );
    });

    test('pauses lifecycle and cancels pending work', () {
      final scheduler = AiTurnPrecomputeScheduler()..queue(_request('key_1'));

      expect(scheduler.setLifecyclePaused(true), isTrue);
      expect(scheduler.canSchedule(aiTurnRunning: false), isFalse);

      scheduler.cancelPending();

      expect(scheduler.hasPending, isFalse);
      expect(
        scheduler.stats(),
        'queued=1 replaced=0 canceled=1 started=0 completed=0 failed=0',
      );
      expect(scheduler.setLifecyclePaused(true), isFalse);
    });

    test('starts pending work and blocks duplicate scheduled keys', () {
      final scheduler = AiTurnPrecomputeScheduler();
      final request = _request('key_1');

      scheduler.queue(request);
      expect(
        scheduler.startNext(aiTurnRunning: true, startedAt: DateTime.utc(2026)),
        isNull,
      );

      final started = scheduler.startNext(
        aiTurnRunning: false,
        startedAt: DateTime.utc(2026),
      );
      scheduler
        ..markCompleted()
        ..markStopped();

      final duplicateStart = _queueAndStart(
        scheduler,
        'key_1',
        DateTime.utc(2026, 1, 1, 0, 0, 1),
      );

      expect(started, same(request));
      expect(duplicateStart, isNull);
      expect(scheduler.running, isFalse);
      expect(scheduler.hasPending, isFalse);
      expect(
        scheduler.stats(),
        'queued=2 replaced=0 canceled=0 started=1 completed=1 failed=0',
      );
    });

    test('releases scheduled keys after failure', () {
      final scheduler = AiTurnPrecomputeScheduler();

      final first = _queueAndStart(scheduler, 'key_1', DateTime.utc(2026));
      scheduler
        ..markFailed('key_1')
        ..markStopped();

      final retry = _queueAndStart(
        scheduler,
        'key_1',
        DateTime.utc(2026, 1, 1, 0, 0, 1),
      );

      expect(first, isNotNull);
      expect(retry, isNotNull);
      expect(
        scheduler.stats(),
        'queued=2 replaced=0 canceled=0 started=2 completed=0 failed=1',
      );
    });

    test('uses cooldown before debounce when a previous start is recent', () {
      final scheduler = AiTurnPrecomputeScheduler();
      final throttler = AiRuntimeThrottler();
      final startedAt = DateTime.utc(2026, 1, 1, 12);

      scheduler
        ..queue(_request('key_1'))
        ..startNext(aiTurnRunning: false, startedAt: startedAt)
        ..markStopped();

      final earlyDelay = scheduler.delayBeforeNextStart(
        throttle: throttler.snapshot,
        now: startedAt.add(const Duration(seconds: 1)),
      );
      final lateDelay = scheduler.delayBeforeNextStart(
        throttle: throttler.snapshot,
        now: startedAt.add(const Duration(seconds: 5)),
      );

      expect(
        earlyDelay,
        AiRuntimeThrottler.basePrecomputeMinimumStartInterval -
            const Duration(seconds: 1),
      );
      expect(lateDelay, AiRuntimeThrottler.basePrecomputeDebounceDuration);
    });
  });
}

AiTurnPrecomputeRequest _request(String key, {String playerId = 'ai_1'}) {
  return AiTurnPrecomputeRequest(
    saveId: 'save_1',
    playerId: playerId,
    scheduleKey: key,
  );
}

AiTurnPrecomputeRequest? _queueAndStart(
  AiTurnPrecomputeScheduler scheduler,
  String key,
  DateTime startedAt,
) {
  scheduler.queue(_request(key));
  return scheduler.startNext(aiTurnRunning: false, startedAt: startedAt);
}
