import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/presentation/engine/authoritative_presentation_scheduler.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waits until the shared authoritative start', () async {
    final clock = _VirtualClock(900000);
    final scheduler = AuthoritativePresentationScheduler(
      clock: clock,
      delay: clock.advance,
    );

    await scheduler.waitFor(_batch(startMicrosUtc: 1000000));

    expect(clock.nowUtc().microsecondsSinceEpoch, 1000000);
  });

  test('accepts one frame of skew and rejects a larger miss', () async {
    final withinBudget = _VirtualClock(
      1000000 + presentationFrameBudget.inMicroseconds,
    );
    await AuthoritativePresentationScheduler(
      clock: withinBudget,
      delay: withinBudget.advance,
    ).waitFor(_batch(startMicrosUtc: 1000000));

    final late = _VirtualClock(
      1000001 + presentationFrameBudget.inMicroseconds,
    );
    expect(
      () => AuthoritativePresentationScheduler(
        clock: late,
        delay: late.advance,
      ).waitFor(_batch(startMicrosUtc: 1000000)),
      throwsA(isA<PresentationScheduleMiss>()),
    );
  });

  test('does not delay interaction-only presentation', () async {
    final clock = _VirtualClock(0);
    var delayed = false;
    final scheduler = AuthoritativePresentationScheduler(
      clock: clock,
      delay: (duration) async {
        delayed = true;
        await clock.advance(duration);
      },
    );

    await scheduler.waitFor(
      ProjectedGameEffectBatch(
        identity: const PresentationBatchIdentity(
          sourceId: 'match_1',
          eventOffset: 1,
          authoritativeStartMicrosUtc: 1000000,
        ),
        sequenceDirective: PresentationSequenceDirective.interactionOnly,
      ),
    );

    expect(delayed, isFalse);
  });

  test('starts immediately when no authoritative timestamp exists', () async {
    final clock = _VirtualClock(1000000);
    var delayed = false;
    final scheduler = AuthoritativePresentationScheduler(
      clock: clock,
      delay: (_) async => delayed = true,
    );

    await scheduler.waitFor(
      ProjectedGameEffectBatch(
        identity: const PresentationBatchIdentity(
          sourceId: 'match_1',
          eventOffset: 1,
        ),
        sequenceDirective: PresentationSequenceDirective.advance,
      ),
    );

    expect(delayed, isFalse);
  });

  test('starts audio and rendering from the same authoritative slot', () async {
    final clock = _VirtualClock(900000);
    final scheduler = AuthoritativePresentationScheduler(
      clock: clock,
      delay: clock.advance,
    );
    final starts = <(String, int)>[];

    await scheduler.presentAtAuthoritativeStart(
      _batch(startMicrosUtc: 1000000),
      () async {
        starts
          ..add(('audio', clock.nowUtc().microsecondsSinceEpoch))
          ..add(('renderer', clock.nowUtc().microsecondsSinceEpoch));
      },
    );

    expect(starts, const [('audio', 1000000), ('renderer', 1000000)]);
  });

  test('starts a late complete presentation immediately', () async {
    final nowMicros = 1000001 + presentationFrameBudget.inMicroseconds;
    final clock = _VirtualClock(nowMicros);
    var delayed = false;
    var startedAt = 0;
    final scheduler = AuthoritativePresentationScheduler(
      clock: clock,
      delay: (_) async => delayed = true,
    );

    await scheduler.presentAtAuthoritativeStart(
      _batch(startMicrosUtc: 1000000),
      () async => startedAt = clock.nowUtc().microsecondsSinceEpoch,
    );

    expect(delayed, isFalse);
    expect(startedAt, nowMicros);
  });
}

ProjectedGameEffectBatch _batch({required int startMicrosUtc}) {
  return ProjectedGameEffectBatch(
    identity: PresentationBatchIdentity(
      sourceId: 'match_1',
      eventOffset: 1,
      authoritativeStartMicrosUtc: startMicrosUtc,
    ),
    sequenceDirective: PresentationSequenceDirective.advance,
    animationPlans: [
      AnimationPlan(
        eventId: 'match_1:1:0',
        eventType: 'TurnEndedEvent',
        policy: 'turn state',
        batchSequence: 1,
        eventSequence: 0,
        authoritativeTick: 1,
        authoritativeStartMicrosUtc: startMicrosUtc,
        startOffset: Duration.zero,
        animations: const [],
      ),
    ],
  );
}

final class _VirtualClock extends Clock {
  _VirtualClock(this._microsUtc);

  int _microsUtc;

  @override
  DateTime now() =>
      DateTime.fromMicrosecondsSinceEpoch(_microsUtc, isUtc: true);

  Future<void> advance(Duration duration) async {
    _microsUtc += duration.inMicroseconds;
  }
}
