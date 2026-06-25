import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw_core/ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiRuntimeThrottler', () {
    test('starts with interactive defaults', () {
      final throttler = AiRuntimeThrottler();

      expect(
        throttler.snapshot.precomputeDebounceDuration,
        AiRuntimeThrottler.basePrecomputeDebounceDuration,
      );
      expect(
        throttler.snapshot.precomputeMinimumStartInterval,
        AiRuntimeThrottler.basePrecomputeMinimumStartInterval,
      );
      expect(
        throttler.snapshot.mctsRuntimeProfile,
        MctsRuntimeProfile.interactive,
      );
    });

    test('raises pressure after replaced precompute queue entries', () {
      final throttler = AiRuntimeThrottler();

      expect(throttler.recordPrecomputeQueued(replaced: true), isTrue);

      expect(throttler.snapshot.pressureLevel, 1);
      expect(
        throttler.snapshot.precomputeDebounceDuration,
        greaterThan(AiRuntimeThrottler.basePrecomputeDebounceDuration),
      );
      expect(
        throttler.snapshot.mctsRuntimeProfile,
        MctsRuntimeProfile.interactive,
      );
    });

    test('switches to battery saver after slow precompute pressure', () {
      final throttler = AiRuntimeThrottler()
        ..recordPrecomputeCompleted(AiRuntimeThrottler.slowPrecomputeThreshold)
        ..recordPrecomputeCompleted(AiRuntimeThrottler.slowPrecomputeThreshold);

      expect(throttler.snapshot.pressureLevel, 2);
      expect(
        throttler.snapshot.mctsRuntimeProfile,
        MctsRuntimeProfile.batterySaver,
      );
    });

    test('uses battery saver for late local single-player turns', () {
      final throttler = AiRuntimeThrottler();

      final snapshot = throttler.snapshotFor(
        localSinglePlayer: true,
        turn: AiRuntimeThrottler.adaptiveLateGameTurnThreshold,
        totalUnitCount: 0,
        totalCityCount: 0,
      );

      expect(snapshot.adaptiveLateGame, isTrue);
      expect(snapshot.pressureLevel, 0);
      expect(snapshot.mctsRuntimeProfile, MctsRuntimeProfile.batterySaver);
    });

    test('can force the battery saver profile from settings', () {
      final throttler = AiRuntimeThrottler();

      final snapshot = throttler.snapshotFor(
        localSinglePlayer: true,
        turn: 1,
        totalUnitCount: 0,
        totalCityCount: 0,
        forceBatterySaver: true,
      );

      expect(snapshot.forcedBatterySaver, isTrue);
      expect(snapshot.adaptiveLateGame, isFalse);
      expect(snapshot.pressureLevel, 0);
      expect(snapshot.mctsRuntimeProfile, MctsRuntimeProfile.batterySaver);
    });

    test('uses battery saver for large local single-player states', () {
      final throttler = AiRuntimeThrottler();

      final unitSnapshot = throttler.snapshotFor(
        localSinglePlayer: true,
        turn: 1,
        totalUnitCount: AiRuntimeThrottler.adaptiveLateGameUnitThreshold,
        totalCityCount: 0,
      );
      final citySnapshot = throttler.snapshotFor(
        localSinglePlayer: true,
        turn: 1,
        totalUnitCount: 0,
        totalCityCount: AiRuntimeThrottler.adaptiveLateGameCityThreshold,
      );

      expect(unitSnapshot.adaptiveLateGame, isTrue);
      expect(unitSnapshot.mctsRuntimeProfile, MctsRuntimeProfile.batterySaver);
      expect(citySnapshot.adaptiveLateGame, isTrue);
      expect(citySnapshot.mctsRuntimeProfile, MctsRuntimeProfile.batterySaver);
    });

    test('keeps interactive profile for non-local late games', () {
      final throttler = AiRuntimeThrottler();

      final snapshot = throttler.snapshotFor(
        localSinglePlayer: false,
        turn: AiRuntimeThrottler.adaptiveLateGameTurnThreshold,
        totalUnitCount: AiRuntimeThrottler.adaptiveLateGameUnitThreshold,
        totalCityCount: AiRuntimeThrottler.adaptiveLateGameCityThreshold,
      );

      expect(snapshot.adaptiveLateGame, isFalse);
      expect(snapshot.mctsRuntimeProfile, MctsRuntimeProfile.interactive);
    });

    test('cools down after repeated fast precomputed turns', () {
      final throttler = AiRuntimeThrottler()
        ..recordPrecomputeFailed()
        ..recordPrecomputeFailed();

      for (var i = 0; i < 3; i++) {
        throttler.recordTurn(
          planningSource: AiPlanSource.precomputed,
          planningDuration: AiRuntimeThrottler.fastPrecomputedPlanningThreshold,
        );
      }

      expect(throttler.snapshot.pressureLevel, 1);
      expect(
        throttler.snapshot.mctsRuntimeProfile,
        MctsRuntimeProfile.interactive,
      );
    });

    test('slow fresh planning increases pressure', () {
      final throttler = AiRuntimeThrottler();

      expect(
        throttler.recordTurn(
          planningSource: AiPlanSource.fresh,
          planningDuration: AiRuntimeThrottler.slowFreshPlanningThreshold,
        ),
        isTrue,
      );

      expect(throttler.snapshot.pressureLevel, 1);
    });

    test('reset returns to defaults', () {
      final throttler = AiRuntimeThrottler()..recordPrecomputeFailed();

      expect(throttler.reset(), isTrue);

      expect(throttler.snapshot.pressureLevel, 0);
      expect(
        throttler.snapshot.mctsRuntimeProfile,
        MctsRuntimeProfile.interactive,
      );
    });
  });
}
