import 'dart:async';

import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_precompute_scheduler.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnPrecomputeCoordinator', () {
    test(
      'schedules pending request and runs it when the timer fires',
      () async {
        final timers = _FakeTimers();
        final coordinator = AiTurnPrecomputeCoordinator(
          timerFactory: timers.create,
        );
        final started = <String>[];
        final run = <String>[];
        var settled = 0;

        coordinator
          ..queue(_request('key_1'))
          ..schedulePending(
            aiTurnRunning: () => false,
            throttle: () => AiRuntimeThrottler().snapshot,
            now: () => DateTime.utc(2026),
            canContinue: () => true,
            onStart: (request, startedCount) {
              started.add('${request.scheduleKey}:$startedCount');
            },
            run: (request) async {
              run.add(request.scheduleKey);
            },
            onSettled: () {
              settled += 1;
            },
          );

        expect(timers.created, hasLength(1));
        timers.fireLatest();
        await Future<void>.delayed(Duration.zero);

        expect(started, const ['key_1:1']);
        expect(run, const ['key_1']);
        expect(settled, 1);
        expect(coordinator.hasPending, isFalse);
        expect(
          coordinator.stats(),
          'queued=1 replaced=0 canceled=0 started=1 completed=0 failed=0',
        );
      },
    );

    test('cancels pending request and active timer together', () {
      final timers = _FakeTimers();
      final coordinator =
          AiTurnPrecomputeCoordinator(timerFactory: timers.create)
            ..queue(_request('key_1'))
            ..schedulePending(
              aiTurnRunning: () => false,
              throttle: () => AiRuntimeThrottler().snapshot,
              now: () => DateTime.utc(2026),
              canContinue: () => true,
              onStart: (request, startedCount) {
                fail('canceled timer should not start precompute');
              },
              run: (request) async {},
              onSettled: () {},
            )
            ..cancelPending();

      expect(coordinator.hasPending, isFalse);
      expect(timers.latest.isActive, isFalse);
      expect(
        coordinator.stats(),
        'queued=1 replaced=0 canceled=1 started=0 completed=0 failed=0',
      );
    });

    test('does not start when continuation is lost before timer fires', () {
      final timers = _FakeTimers();
      var canContinue = true;
      final coordinator =
          AiTurnPrecomputeCoordinator(timerFactory: timers.create)
            ..queue(_request('key_1'))
            ..schedulePending(
              aiTurnRunning: () => false,
              throttle: () => AiRuntimeThrottler().snapshot,
              now: () => DateTime.utc(2026),
              canContinue: () => canContinue,
              onStart: (request, startedCount) {
                fail('lost continuation should stop precompute start');
              },
              run: (request) async {},
              onSettled: () {},
            );

      canContinue = false;
      timers.fireLatest();

      expect(coordinator.hasPending, isTrue);
    });

    test(
      'reschedules another pending request after the running one settles',
      () async {
        final timers = _FakeTimers();
        final coordinator = AiTurnPrecomputeCoordinator(
          timerFactory: timers.create,
        );
        final run = <String>[];

        coordinator
          ..queue(_request('key_1'))
          ..schedulePending(
            aiTurnRunning: () => false,
            throttle: () => AiRuntimeThrottler().snapshot,
            now: () => DateTime.utc(2026),
            canContinue: () => true,
            onStart: (request, startedCount) {},
            run: (request) async {
              run.add(request.scheduleKey);
              if (request.scheduleKey == 'key_1') {
                coordinator.queue(_request('key_2'));
              }
            },
            onSettled: () {},
          );

        timers.fireLatest();
        await Future<void>.delayed(Duration.zero);

        expect(run, const ['key_1']);
        expect(timers.created, hasLength(2));

        timers.fireLatest();
        await Future<void>.delayed(Duration.zero);

        expect(run, const ['key_1', 'key_2']);
      },
    );
  });
}

AiTurnPrecomputeRequest _request(String key) {
  return AiTurnPrecomputeRequest(
    saveId: 'save_1',
    playerId: 'ai_1',
    scheduleKey: key,
  );
}

final class _FakeTimers {
  final created = <_FakeTimer>[];

  _FakeTimer get latest => created.last;

  Timer create(Duration delay, void Function() onElapsed) {
    final timer = _FakeTimer(delay, onElapsed);
    created.add(timer);
    return timer;
  }

  void fireLatest() {
    latest.fire();
  }
}

final class _FakeTimer implements Timer {
  final Duration delay;
  final void Function() onElapsed;
  var _active = true;
  var _tick = 0;

  _FakeTimer(this.delay, this.onElapsed);

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    _active = false;
  }

  void fire() {
    if (!_active) return;
    _active = false;
    _tick += 1;
    onElapsed();
  }
}
