import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/ai_turn_execution_runner.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnExecutionRunner', () {
    test(
      'executes turn, reloads save, presents follow-up, and records runtime throttle',
      () async {
        final logger = _RecordingGameLogger();
        final invalidatedSaveIds = <String>[];
        final throttleReasons = <String>[];
        final updatedSave = _save(turn: 2);
        final runner = _runner(
          logger: logger,
          invalidatedSaveIds: invalidatedSaveIds,
          throttleReasons: throttleReasons,
          startTurn:
              ({
                required saveId,
                required playerId,
                required scheduledTurn,
                required interCommandDelay,
                required onStalePrecomputeDropped,
              }) async {
                expect(saveId, 'save_1');
                expect(playerId, 'ai_1');
                expect(scheduledTurn, 1);
                expect(interCommandDelay, const Duration(milliseconds: 40));
                await onStalePrecomputeDropped();
                return AiTurnExecutedProcess(
                  report: _report(
                    planningSource: AiPlanSource.freshAfterPrecomputeFailure,
                    planningDuration: const Duration(milliseconds: 10),
                  ),
                  reloadSave: () async => updatedSave,
                );
              },
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
                expect(terminalUiEffects, contains(isA<JumpCameraEffect>()));
                return 'ai_2';
              },
        );

        final result = await runner.run(
          _request(),
          interCommandDelay: const Duration(milliseconds: 40),
        );

        expect(result.completed, isTrue);
        expect(result.followUpSave, updatedSave);
        expect(result.followUpAiPlayerId, 'ai_2');
        expect(invalidatedSaveIds, const ['save_1']);
        expect(
          logger.infoMessages,
          contains(
            startsWith(
              'AI Runtime: stale precompute dropped before fresh AI turn '
              'player=ai_1;',
            ),
          ),
        );
        expect(throttleReasons, const ['AI turn freshAfterPrecomputeFailure']);
        expect(logger.warnMessages, isEmpty);
      },
    );

    test('leaves turn incomplete when no process is available', () async {
      final logger = _RecordingGameLogger();
      final invalidatedSaveIds = <String>[];
      var advanced = false;
      final runner = _runner(
        logger: logger,
        invalidatedSaveIds: invalidatedSaveIds,
        startTurn:
            ({
              required saveId,
              required playerId,
              required scheduledTurn,
              required interCommandDelay,
              required onStalePrecomputeDropped,
            }) async {
              return null;
            },
        advanceAfterAiTurn:
            ({
              required updatedSave,
              required previousTurn,
              required playerId,
              required terminalUiEffects,
            }) async {
              advanced = true;
              return null;
            },
      );

      final result = await runner.run(
        _request(),
        interCommandDelay: Duration.zero,
      );

      expect(result.completed, isFalse);
      expect(result.followUpSave, isNull);
      expect(result.followUpAiPlayerId, isNull);
      expect(invalidatedSaveIds, isEmpty);
      expect(advanced, isFalse);
      expect(logger.warnMessages, isEmpty);
    });

    test(
      'completes turn without reload when execution returns no report',
      () async {
        final logger = _RecordingGameLogger();
        final invalidatedSaveIds = <String>[];
        var reloaded = false;
        var advanced = false;
        final runner = _runner(
          logger: logger,
          invalidatedSaveIds: invalidatedSaveIds,
          startTurn:
              ({
                required saveId,
                required playerId,
                required scheduledTurn,
                required interCommandDelay,
                required onStalePrecomputeDropped,
              }) async {
                return AiTurnExecutedProcess(
                  report: null,
                  reloadSave: () async {
                    reloaded = true;
                    return _save(turn: 1);
                  },
                );
              },
          advanceAfterAiTurn:
              ({
                required updatedSave,
                required previousTurn,
                required playerId,
                required terminalUiEffects,
              }) async {
                advanced = true;
                return null;
              },
        );

        final result = await runner.run(
          _request(),
          interCommandDelay: Duration.zero,
        );

        expect(result.completed, isTrue);
        expect(result.followUpSave, isNull);
        expect(result.followUpAiPlayerId, isNull);
        expect(reloaded, isFalse);
        expect(advanced, isFalse);
        expect(invalidatedSaveIds, isEmpty);
      },
    );

    test(
      'leaves turn incomplete when continuation is lost after execution',
      () async {
        final logger = _RecordingGameLogger();
        final invalidatedSaveIds = <String>[];
        var canContinue = true;
        final runner = _runner(
          logger: logger,
          invalidatedSaveIds: invalidatedSaveIds,
          canContinue: () => canContinue,
          startTurn:
              ({
                required saveId,
                required playerId,
                required scheduledTurn,
                required interCommandDelay,
                required onStalePrecomputeDropped,
              }) async {
                canContinue = false;
                return AiTurnExecutedProcess(
                  report: _report(),
                  reloadSave: () async => _save(turn: 2),
                );
              },
        );

        final result = await runner.run(
          _request(),
          interCommandDelay: Duration.zero,
        );

        expect(result.completed, isFalse);
        expect(invalidatedSaveIds, isEmpty);
        expect(logger.warnMessages, isEmpty);
      },
    );

    test('logs failure and leaves turn incomplete', () async {
      final logger = _RecordingGameLogger();
      final invalidatedSaveIds = <String>[];
      final runner = _runner(
        logger: logger,
        invalidatedSaveIds: invalidatedSaveIds,
        startTurn:
            ({
              required saveId,
              required playerId,
              required scheduledTurn,
              required interCommandDelay,
              required onStalePrecomputeDropped,
            }) async {
              throw StateError('boom');
            },
      );

      final result = await runner.run(
        _request(),
        interCommandDelay: Duration.zero,
      );

      expect(result.completed, isFalse);
      expect(invalidatedSaveIds, isEmpty);
      expect(
        logger.warnMessages.single,
        startsWith('AI: local AI turn failed'),
      );
    });
  });
}

AiTurnExecutionRunner _runner({
  required GameLogger logger,
  required List<String> invalidatedSaveIds,
  required AiTurnExecutionStarter startTurn,
  AiTurnFollowUpAdvancer? advanceAfterAiTurn,
  AiTurnExecutionCanContinue? canContinue,
  List<String>? throttleReasons,
}) {
  final throttler = AiRuntimeThrottler();
  return AiTurnExecutionRunner(
    logger: logger,
    throttler: throttler,
    startTurn: startTurn,
    invalidateSaveSnapshot: invalidatedSaveIds.add,
    advanceAfterAiTurn: advanceAfterAiTurn ?? _noFollowUp,
    canContinue: canContinue ?? () => true,
    precomputeStats: () => 'precompute=stats',
    throttleStats: () => 'throttle=${throttler.snapshot}',
    logThrottleChange: throttleReasons?.add ?? (_) {},
  );
}

Future<String?> _noFollowUp({
  required GameSave updatedSave,
  required int previousTurn,
  required String playerId,
  required Iterable<UiEffect> terminalUiEffects,
}) async {
  return null;
}

AiTurnRunRequest _request() {
  return const AiTurnRunRequest(
    saveId: 'save_1',
    turn: 1,
    playerId: 'ai_1',
    turnKey: 'save_1:1:ai_1',
  );
}

AiTurnReport _report({
  AiPlanSource planningSource = AiPlanSource.fresh,
  Duration planningDuration = Duration.zero,
}) {
  return AiTurnReport(
    plannedCommands: const [],
    dispatchedCommands: const [],
    rejectedCommands: const [],
    skippedTerminalCommands: const [],
    planningDuration: planningDuration,
    executionDuration: Duration.zero,
    totalDuration: planningDuration,
    delayedCommandCount: 0,
    planningSource: planningSource,
    terminalCommand: const EndTurnCommand('ai_1'),
    terminalUiEffects: const [JumpCameraEffect(col: 2, row: 3)],
    finalState: const GameState(activePlayerId: 'ai_1'),
  );
}

GameSave _save({required int turn}) {
  return GameSave(
    id: 'save_1',
    name: 'Save',
    mapName: 'Map',
    turn: turn,
    playerStates: const {'ai_1': PlayerTurnState.finished},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
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
