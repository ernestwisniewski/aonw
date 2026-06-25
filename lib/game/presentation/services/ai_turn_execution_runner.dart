import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/services/ai_turn_process_preparer.dart';

typedef AiTurnExecutionStarter =
    Future<AiTurnExecutedProcess?> Function({
      required String saveId,
      required String playerId,
      required int scheduledTurn,
      required Duration interCommandDelay,
      required Future<void> Function() onStalePrecomputeDropped,
    });

typedef AiTurnSaveSnapshotInvalidator = void Function(String saveId);
typedef AiTurnExecutionCanContinue = bool Function();
typedef AiTurnExecutionStatsReader = String Function();
typedef AiTurnExecutionThrottleChangeLogger = void Function(String reason);
typedef AiTurnPreparedProcessLoader =
    Future<PreparedAiTurnProcess?> Function({
      required String saveId,
      required String playerId,
      int? scheduledTurn,
    });
typedef AiTurnFollowUpAdvancer =
    Future<String?> Function({
      required GameSave updatedSave,
      required int previousTurn,
      required String playerId,
      required Iterable<UiEffect> terminalUiEffects,
    });

final class AiTurnExecutedProcess {
  final AiTurnReport? report;
  final Future<GameSave> Function() reloadSave;

  const AiTurnExecutedProcess({required this.report, required this.reloadSave});
}

final class AiTurnExecutionResult {
  final bool completed;
  final GameSave? followUpSave;
  final String? followUpAiPlayerId;

  const AiTurnExecutionResult._({
    required this.completed,
    this.followUpSave,
    this.followUpAiPlayerId,
  });

  const AiTurnExecutionResult.notCompleted() : this._(completed: false);

  const AiTurnExecutionResult.completed({
    GameSave? followUpSave,
    String? followUpAiPlayerId,
  }) : this._(
         completed: true,
         followUpSave: followUpSave,
         followUpAiPlayerId: followUpAiPlayerId,
       );
}

final class AiTurnExecutionRunner {
  final GameLogger logger;
  final AiRuntimeThrottler throttler;
  final AiTurnExecutionStarter startTurn;
  final AiTurnSaveSnapshotInvalidator invalidateSaveSnapshot;
  final AiTurnFollowUpAdvancer advanceAfterAiTurn;
  final AiTurnExecutionCanContinue canContinue;
  final AiTurnExecutionStatsReader precomputeStats;
  final AiTurnExecutionStatsReader throttleStats;
  final AiTurnExecutionThrottleChangeLogger logThrottleChange;

  const AiTurnExecutionRunner({
    required this.logger,
    required this.throttler,
    required this.startTurn,
    required this.invalidateSaveSnapshot,
    required this.advanceAfterAiTurn,
    required this.canContinue,
    required this.precomputeStats,
    required this.throttleStats,
    required this.logThrottleChange,
  });

  factory AiTurnExecutionRunner.fromPreparedProcess({
    required GameLogger logger,
    required AiRuntimeThrottler throttler,
    required AiTurnPreparedProcessLoader prepareProcess,
    required AiTurnSaveSnapshotInvalidator invalidateSaveSnapshot,
    required AiTurnFollowUpAdvancer advanceAfterAiTurn,
    required AiTurnExecutionCanContinue canContinue,
    required AiTurnExecutionStatsReader precomputeStats,
    required AiTurnExecutionStatsReader throttleStats,
    required AiTurnExecutionThrottleChangeLogger logThrottleChange,
  }) {
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
            final process = await prepareProcess(
              saveId: saveId,
              playerId: playerId,
              scheduledTurn: scheduledTurn,
            );
            if (process == null) return null;

            final report = await process.execute(
              interCommandDelay: interCommandDelay,
              onStalePrecomputeDropped: onStalePrecomputeDropped,
            );
            return AiTurnExecutedProcess(
              report: report,
              reloadSave: () async {
                return (await process.repository.load(saveId)).save;
              },
            );
          },
      invalidateSaveSnapshot: invalidateSaveSnapshot,
      advanceAfterAiTurn: advanceAfterAiTurn,
      canContinue: canContinue,
      precomputeStats: precomputeStats,
      throttleStats: throttleStats,
      logThrottleChange: logThrottleChange,
    );
  }

  Future<AiTurnExecutionResult> run(
    AiTurnRunRequest request, {
    required Duration interCommandDelay,
  }) async {
    try {
      final process = await startTurn(
        saveId: request.saveId,
        playerId: request.playerId,
        scheduledTurn: request.turn,
        interCommandDelay: interCommandDelay,
        onStalePrecomputeDropped: () {
          logger.info(
            'AI Runtime',
            'stale precompute dropped before fresh AI turn '
                'player=${request.playerId}; '
                '${precomputeStats()} ${throttleStats()}',
          );
          return Future.value();
        },
      );
      if (process == null || !canContinue()) {
        return const AiTurnExecutionResult.notCompleted();
      }

      final report = process.report;
      if (report == null) {
        return const AiTurnExecutionResult.completed();
      }

      final throttleChanged = throttler.recordTurn(
        planningSource: report.planningSource,
        planningDuration: report.planningDuration,
      );
      if (throttleChanged) {
        logThrottleChange('AI turn ${report.planningSource.name}');
      }

      invalidateSaveSnapshot(request.saveId);
      final updatedSave = await process.reloadSave();
      if (!canContinue()) {
        return const AiTurnExecutionResult.notCompleted();
      }

      final followUpAiPlayerId = await advanceAfterAiTurn(
        updatedSave: updatedSave,
        previousTurn: request.turn,
        playerId: request.playerId,
        terminalUiEffects: report.terminalUiEffects,
      );
      return AiTurnExecutionResult.completed(
        followUpSave: updatedSave,
        followUpAiPlayerId: followUpAiPlayerId,
      );
    } catch (error, stackTrace) {
      logger.warn('AI', 'local AI turn failed', error, stackTrace);
      return const AiTurnExecutionResult.notCompleted();
    }
  }
}
