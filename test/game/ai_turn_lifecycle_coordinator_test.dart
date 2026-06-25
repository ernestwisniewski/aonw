import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/ai_turn_precompute_scheduler.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/services/ai_turn_lifecycle_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnLifecycleCoordinator', () {
    test('save change resets run/precompute/throttle state', () async {
      final runScheduler = AiTurnRunScheduler();
      final completed = runScheduler.schedule(
        saveId: 'save_old',
        turn: 1,
        playerId: 'ai_1',
      )!;
      runScheduler
        ..markCompleted(completed)
        ..markFinished(completed);

      final precomputeCoordinator = AiTurnPrecomputeCoordinator()
        ..queue(
          const AiTurnPrecomputeRequest(
            saveId: 'save_old',
            playerId: 'ai_1',
            scheduleKey: 'old-key',
          ),
        );
      final precomputeCache = AiTurnPlanPrecomputeCache();
      final oldKey = _cacheKey(saveId: 'save_old', turn: 1);
      await precomputeCache.start(key: oldKey, planFactory: _emptyPlan);
      final throttler = AiRuntimeThrottler()..recordPrecomputeFailed();
      var cancelCount = 0;
      _lifecycle(
        runScheduler: runScheduler,
        precomputeCoordinator: precomputeCoordinator,
        precomputeCache: precomputeCache,
        throttler: throttler,
        cancelQueuedPrecompute: () {
          cancelCount += 1;
          precomputeCoordinator.cancelPending();
        },
      ).handleSaveChange(
        previousSave: _save(id: 'save_old', turn: 1),
        currentSave: _save(id: 'save_new', turn: 1),
      );

      expect(cancelCount, 1);
      expect(precomputeCoordinator.pendingScheduleKey, isNull);
      expect(precomputeCache.contains(oldKey), isFalse);
      expect(throttler.snapshot.pressureLevel, 0);
      expect(
        runScheduler.schedule(saveId: 'save_old', turn: 1, playerId: 'ai_1'),
        isNotNull,
      );
    });

    test(
      'turn change clears scheduled work and retains current-turn cache',
      () async {
        final runScheduler = AiTurnRunScheduler();
        final completed = runScheduler.schedule(
          saveId: 'save_1',
          turn: 1,
          playerId: 'ai_1',
        )!;
        runScheduler.markCompleted(completed);

        final precomputeCoordinator = AiTurnPrecomputeCoordinator()
          ..queue(
            const AiTurnPrecomputeRequest(
              saveId: 'save_1',
              playerId: 'ai_1',
              scheduleKey: 'turn-1-key',
            ),
          );
        final precomputeCache = AiTurnPlanPrecomputeCache();
        final currentKey = _cacheKey(saveId: 'save_1', turn: 2);
        final staleTurnKey = _cacheKey(saveId: 'save_1', turn: 1);
        final staleSaveKey = _cacheKey(saveId: 'save_old', turn: 2);
        await Future.wait([
          precomputeCache.start(key: currentKey, planFactory: _emptyPlan),
          precomputeCache.start(key: staleTurnKey, planFactory: _emptyPlan),
          precomputeCache.start(key: staleSaveKey, planFactory: _emptyPlan),
        ]);
        var cancelCount = 0;
        _lifecycle(
          runScheduler: runScheduler,
          precomputeCoordinator: precomputeCoordinator,
          precomputeCache: precomputeCache,
          cancelQueuedPrecompute: () {
            cancelCount += 1;
            precomputeCoordinator.cancelPending();
          },
        ).handleSaveChange(
          previousSave: _save(id: 'save_1', turn: 1),
          currentSave: _save(id: 'save_1', turn: 2),
        );

        expect(cancelCount, 1);
        expect(precomputeCoordinator.pendingScheduleKey, isNull);
        expect(precomputeCache.contains(currentKey), isTrue);
        expect(precomputeCache.contains(staleTurnKey), isFalse);
        expect(precomputeCache.contains(staleSaveKey), isFalse);
        expect(
          runScheduler.schedule(saveId: 'save_1', turn: 1, playerId: 'ai_1'),
          isNull,
        );
        expect(
          runScheduler.schedule(saveId: 'save_1', turn: 2, playerId: 'ai_1'),
          isNotNull,
        );
      },
    );

    test(
      'pause clears pending work and shutdowns precompute executor once',
      () async {
        final precomputeCoordinator = AiTurnPrecomputeCoordinator()
          ..queue(
            const AiTurnPrecomputeRequest(
              saveId: 'save_1',
              playerId: 'ai_1',
              scheduleKey: 'pending-key',
            ),
          );
        final precomputeCache = AiTurnPlanPrecomputeCache();
        final key = _cacheKey(saveId: 'save_1', turn: 1);
        await precomputeCache.start(key: key, planFactory: _emptyPlan);
        var cancelCount = 0;
        var shutdownCount = 0;
        _lifecycle(
            precomputeCoordinator: precomputeCoordinator,
            precomputeCache: precomputeCache,
            cancelQueuedPrecompute: () {
              cancelCount += 1;
              precomputeCoordinator.cancelPending();
            },
            shutdownPrecomputeExecutor: () => shutdownCount += 1,
          )
          ..handleLifecyclePaused(true)
          ..handleLifecyclePaused(true);

        expect(cancelCount, 1);
        expect(shutdownCount, 1);
        expect(precomputeCoordinator.lifecyclePaused, isTrue);
        expect(precomputeCoordinator.pendingScheduleKey, isNull);
        expect(precomputeCache.contains(key), isFalse);
      },
    );

    test('resume schedules pending precompute once after pause', () {
      var scheduleCount = 0;
      _lifecycle(schedulePendingPrecompute: () => scheduleCount += 1)
        ..handleLifecyclePaused(true)
        ..handleLifecyclePaused(false)
        ..handleLifecyclePaused(false);

      expect(scheduleCount, 1);
    });

    test('dispose cancels pending work and clears transient caches', () async {
      final precomputeCoordinator = AiTurnPrecomputeCoordinator()
        ..queue(
          const AiTurnPrecomputeRequest(
            saveId: 'save_1',
            playerId: 'ai_1',
            scheduleKey: 'pending-key',
          ),
        );
      final precomputeCache = AiTurnPlanPrecomputeCache();
      final key = _cacheKey(saveId: 'save_1', turn: 1);
      await precomputeCache.start(key: key, planFactory: _emptyPlan);
      var cancelCount = 0;
      _lifecycle(
        precomputeCoordinator: precomputeCoordinator,
        precomputeCache: precomputeCache,
        cancelQueuedPrecompute: () {
          cancelCount += 1;
          precomputeCoordinator.cancelPending();
        },
      ).dispose();

      expect(cancelCount, 1);
      expect(precomputeCoordinator.pendingScheduleKey, isNull);
      expect(precomputeCache.contains(key), isFalse);
    });
  });
}

AiTurnLifecycleCoordinator _lifecycle({
  AiTurnRunScheduler? runScheduler,
  AiTurnPrecomputeCoordinator? precomputeCoordinator,
  AiTurnPlanPrecomputeCache? precomputeCache,
  AiStrategicPlanProvider? strategicPlanProvider,
  AiRuntimeThrottler? throttler,
  AiTurnCancelQueuedPrecompute? cancelQueuedPrecompute,
  AiTurnSchedulePendingPrecompute? schedulePendingPrecompute,
  AiTurnShutdownPrecomputeExecutor? shutdownPrecomputeExecutor,
}) {
  return AiTurnLifecycleCoordinator(
    runScheduler: runScheduler ?? AiTurnRunScheduler(),
    precomputeCoordinator:
        precomputeCoordinator ?? AiTurnPrecomputeCoordinator(),
    precomputeCache: precomputeCache ?? AiTurnPlanPrecomputeCache(),
    strategicPlanProvider: strategicPlanProvider ?? AiStrategicPlanProvider(),
    throttler: throttler ?? AiRuntimeThrottler(),
    cancelQueuedPrecompute: cancelQueuedPrecompute ?? () {},
    schedulePendingPrecompute: schedulePendingPrecompute ?? () {},
    shutdownPrecomputeExecutor: shutdownPrecomputeExecutor ?? () {},
  );
}

Future<AiTurnPlan> _emptyPlan() async {
  return AiTurnPlan(commands: const []);
}

AiTurnPlanPrecomputeKey _cacheKey({required String saveId, required int turn}) {
  return AiTurnPlanPrecomputeKey(
    saveId: saveId,
    turn: turn,
    gameMode: GameMode.hotSeat,
    playerId: 'ai_1',
    country: PlayerCountry.poland,
    strategyId: AiStrategyId.basic,
    difficulty: AiDifficulty.normal,
    persona: AiPersona.balanced,
    seed: 7,
    matchRulesHash: 1,
    worldStateHash: 1,
  );
}

GameSave _save({required String id, required int turn}) {
  return GameSave(
    id: id,
    name: 'Lifecycle test',
    mapName: 'verdantia',
    turn: turn,
    playerStates: const {'ai_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 6, 2),
    camera: CameraState.zero,
  );
}
