import 'dart:async';

import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_precompute_scheduler.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/services/ai_turn_execution_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_runtime_coordinator.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnRuntimeCoordinator', () {
    test('runs a scheduled turn and posts a follow-up AI turn', () async {
      final logger = _RecordingGameLogger();
      final runScheduler = AiTurnRunScheduler();
      final precomputeCoordinator = AiTurnPrecomputeCoordinator()
        ..queue(_precomputeRequest('pending-key'));
      final throttler = AiRuntimeThrottler();
      final postFrameCallbacks = <void Function()>[];
      final stateChanges = <String>[];
      final invalidatedSaveIds = <String>[];
      final executionCalls = <String>[];
      final request = runScheduler.schedule(
        saveId: 'save_1',
        turn: 1,
        playerId: 'ai_1',
      )!;
      final runtime = _runtime(
        logger: logger,
        runScheduler: runScheduler,
        precomputeCoordinator: precomputeCoordinator,
        throttler: throttler,
        schedulePostFrame: postFrameCallbacks.add,
        notifyStateChanged: () {
          stateChanges.add('running=${runScheduler.running}');
        },
        executionRunner: () {
          return AiTurnExecutionRunner(
            logger: logger,
            throttler: throttler,
            startTurn:
                ({
                  required saveId,
                  required playerId,
                  required scheduledTurn,
                  required interCommandDelay,
                  required onStalePrecomputeDropped,
                }) async {
                  executionCalls.add(
                    '$saveId:$playerId:$scheduledTurn:'
                    '${interCommandDelay.inMilliseconds}',
                  );
                  return AiTurnExecutedProcess(
                    report: _report(),
                    reloadSave: () async => _save(turn: 2),
                  );
                },
            invalidateSaveSnapshot: invalidatedSaveIds.add,
            advanceAfterAiTurn:
                ({
                  required updatedSave,
                  required previousTurn,
                  required playerId,
                  required terminalUiEffects,
                }) async {
                  expect(updatedSave.turn, 2);
                  expect(previousTurn, 1);
                  expect(playerId, 'ai_1');
                  return 'ai_2';
                },
            canContinue: () => true,
            precomputeStats: precomputeCoordinator.stats,
            throttleStats: () => 'throttle=${throttler.snapshot}',
            logThrottleChange: (_) {},
          );
        },
      );

      await runtime.runTurn(request);

      expect(executionCalls, const ['save_1:ai_1:1:40']);
      expect(precomputeCoordinator.hasPending, isFalse);
      expect(stateChanges, const ['running=true', 'running=false']);
      expect(invalidatedSaveIds, const ['save_1']);
      expect(runScheduler.running, isFalse);
      expect(
        runScheduler.schedule(saveId: 'save_1', turn: 1, playerId: 'ai_1'),
        isNull,
      );
      expect(
        runScheduler.schedule(saveId: 'save_1', turn: 2, playerId: 'ai_2'),
        isNull,
      );
      expect(postFrameCallbacks, hasLength(1));
      expect(logger.warnMessages, isEmpty);
    });

    test('starts pending precompute with runtime diagnostics', () async {
      final logger = _RecordingGameLogger();
      final timers = _FakeTimers();
      final runScheduler = AiTurnRunScheduler();
      final precomputeCoordinator = AiTurnPrecomputeCoordinator(
        timerFactory: timers.create,
      )..queue(_precomputeRequest('pending-key'));
      final throttler = AiRuntimeThrottler();
      final stateChanges = <String>[];
      final started = <String>[];
      _runtime(
        logger: logger,
        runScheduler: runScheduler,
        precomputeCoordinator: precomputeCoordinator,
        throttler: throttler,
        notifyStateChanged: () => stateChanges.add('settled'),
        precomputeRunner: () {
          return AiTurnPrecomputeRunner(
            logger: logger,
            coordinator: precomputeCoordinator,
            throttler: throttler,
            planExecutor: _unusedPlanExecutor,
            startPrecompute:
                ({
                  required saveId,
                  required playerId,
                  required planExecutor,
                }) async {
                  started.add('$saveId:$playerId');
                  return _precomputeHandle();
                },
            cacheSizeReader: () => 1,
            precomputeStats: precomputeCoordinator.stats,
            throttleStats: () => 'throttle=${throttler.snapshot}',
            logThrottleChange: (_) {},
          );
        },
      ).schedulePendingPrecompute();

      final createdTimers = timers.created;
      expect(createdTimers, hasLength(1));
      timers.fireLatest();
      await Future<void>.delayed(Duration.zero);

      expect(started, const ['save_1:ai_1']);
      expect(stateChanges, const ['settled']);
      expect(precomputeCoordinator.stats(), contains('started=1 completed=1'));
      expect(
        logger.infoMessages,
        contains(startsWith('AI Runtime: precompute start #1 player=ai_1;')),
      );
      expect(
        logger.infoMessages,
        contains(
          startsWith('AI Runtime: precompute complete player=ai_1 duration='),
        ),
      );
    });
  });
}

AiTurnRuntimeCoordinator _runtime({
  required GameLogger logger,
  required AiTurnRunScheduler runScheduler,
  required AiTurnPrecomputeCoordinator precomputeCoordinator,
  required AiRuntimeThrottler throttler,
  AiTurnExecutionRunnerReader? executionRunner,
  AiTurnPrecomputeRunnerReader? precomputeRunner,
  AiTurnPostFrameScheduler? schedulePostFrame,
  AiTurnRuntimeStateNotifier? notifyStateChanged,
}) {
  return AiTurnRuntimeCoordinator(
    logger: logger,
    runScheduler: runScheduler,
    precomputeCoordinator: precomputeCoordinator,
    throttler: throttler,
    executionRunner:
        executionRunner ??
        () => throw StateError('unexpected execution runner request'),
    precomputeRunner:
        precomputeRunner ??
        () => throw StateError('unexpected precompute runner request'),
    schedulePostFrame: schedulePostFrame ?? (_) {},
    canContinue: () => true,
    notifyStateChanged: notifyStateChanged ?? () {},
    interCommandDelay: () => const Duration(milliseconds: 40),
    now: () => DateTime.utc(2026, 6, 2),
  );
}

AiTurnPrecomputeRequest _precomputeRequest(String key) {
  return AiTurnPrecomputeRequest(
    saveId: 'save_1',
    playerId: 'ai_1',
    scheduleKey: key,
  );
}

AiTurnPrecomputeHandle _precomputeHandle() {
  return AiTurnPrecomputeHandle(
    key: const AiTurnPlanPrecomputeKey(
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
    ),
    plan: Future.value(AiTurnPlan(commands: const [])),
  );
}

Future<AiTurnPlan> _unusedPlanExecutor({
  required AiStrategy strategy,
  required GameView view,
  required AiContext context,
}) async {
  fail('runtime coordinator test should not call the plan executor');
}

AiTurnReport _report() {
  return AiTurnReport(
    plannedCommands: const [],
    dispatchedCommands: const [],
    rejectedCommands: const [],
    skippedTerminalCommands: const [],
    planningDuration: Duration.zero,
    executionDuration: Duration.zero,
    totalDuration: Duration.zero,
    delayedCommandCount: 0,
    planningSource: AiPlanSource.fresh,
    terminalCommand: const EndTurnCommand('ai_1'),
    finalState: const GameState(activePlayerId: 'ai_1'),
  );
}

GameSave _save({required int turn}) {
  return GameSave(
    id: 'save_1',
    name: 'Runtime coordinator test',
    mapName: 'verdantia',
    turn: turn,
    playerStates: const {'ai_1': PlayerTurnState.finished},
    savedAt: DateTime.utc(2026, 6, 2),
    camera: CameraState.zero,
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
