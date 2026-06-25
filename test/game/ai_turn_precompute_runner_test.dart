import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_precompute_scheduler.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_runner.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnPrecomputeRunner', () {
    test('marks successful precompute and records runtime logs', () async {
      final logger = _RecordingGameLogger();
      final coordinator = AiTurnPrecomputeCoordinator();
      final runner = _runner(
        logger: logger,
        coordinator: coordinator,
        startPrecompute:
            ({
              required saveId,
              required playerId,
              required planExecutor,
            }) async {
              expect(saveId, 'save_1');
              expect(playerId, 'ai_1');
              return _handle();
            },
      );

      await runner.run(_request());

      expect(
        logger.infoMessages,
        contains('AI: Precomputing plan for ai_1 during human turn.'),
      );
      expect(
        logger.infoMessages,
        contains(
          startsWith('AI Runtime: precompute complete player=ai_1 duration='),
        ),
      );
      expect(logger.infoMessages.last, contains('commands=0 cacheSize=2'));
      expect(logger.infoMessages.last, contains('completed=1 failed=0'));
      expect(coordinator.stats(), contains('completed=1'));
      expect(logger.warnMessages, isEmpty);
    });

    test(
      'does not mark completion when no precompute handle is available',
      () async {
        final logger = _RecordingGameLogger();
        final coordinator = AiTurnPrecomputeCoordinator();
        final runner = _runner(
          logger: logger,
          coordinator: coordinator,
          startPrecompute:
              ({
                required saveId,
                required playerId,
                required planExecutor,
              }) async {
                return null;
              },
        );

        await runner.run(_request());

        expect(coordinator.stats(), contains('completed=0'));
        expect(coordinator.stats(), contains('failed=0'));
        expect(logger.infoMessages, isEmpty);
        expect(logger.warnMessages, isEmpty);
      },
    );

    test('marks failed precompute and records warning', () async {
      final logger = _RecordingGameLogger();
      final coordinator = AiTurnPrecomputeCoordinator();
      final throttleReasons = <String>[];
      final runner = _runner(
        logger: logger,
        coordinator: coordinator,
        logThrottleChange: throttleReasons.add,
        startPrecompute:
            ({
              required saveId,
              required playerId,
              required planExecutor,
            }) async {
              throw StateError('boom');
            },
      );

      await runner.run(_request());

      expect(coordinator.stats(), contains('failed=1'));
      expect(
        logger.warnMessages.single,
        startsWith('AI Runtime: precompute failed player=ai_1 duration='),
      );
      expect(throttleReasons, const ['precompute failed']);
    });
  });
}

AiTurnPrecomputeRunner _runner({
  required GameLogger logger,
  required AiTurnPrecomputeCoordinator coordinator,
  required AiTurnPrecomputeStarter startPrecompute,
  AiTurnThrottleChangeLogger? logThrottleChange,
}) {
  final throttler = AiRuntimeThrottler();
  return AiTurnPrecomputeRunner(
    logger: logger,
    coordinator: coordinator,
    throttler: throttler,
    planExecutor: _unusedPlanExecutor,
    startPrecompute: startPrecompute,
    cacheSizeReader: () => 2,
    precomputeStats: coordinator.stats,
    throttleStats: () => 'throttle=${throttler.snapshot}',
    logThrottleChange: logThrottleChange ?? (_) {},
  );
}

Future<AiTurnPlan> _unusedPlanExecutor({
  required AiStrategy strategy,
  required GameView view,
  required AiContext context,
}) async {
  fail('test precompute starter should not call the plan executor');
}

AiTurnPrecomputeRequest _request() {
  return const AiTurnPrecomputeRequest(
    saveId: 'save_1',
    playerId: 'ai_1',
    scheduleKey: 'key_1',
  );
}

AiTurnPrecomputeHandle _handle() {
  return AiTurnPrecomputeHandle(
    key: _key(),
    plan: Future.value(AiTurnPlan(commands: const [])),
  );
}

AiTurnPlanPrecomputeKey _key() {
  return const AiTurnPlanPrecomputeKey(
    saveId: 'save_1',
    turn: 1,
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

final class _RecordingGameLogger implements GameLogger {
  final infoMessages = <String>[];
  final warnMessages = <String>[];

  @override
  void info(String tag, String message) {
    infoMessages.add('$tag: $message');
  }

  @override
  void warn(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    warnMessages.add('$tag: $message');
  }
}
