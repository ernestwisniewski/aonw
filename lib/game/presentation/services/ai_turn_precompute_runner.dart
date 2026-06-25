import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_precompute_scheduler.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';

typedef AiTurnPrecomputeStarter =
    Future<AiTurnPrecomputeHandle?> Function({
      required String saveId,
      required String playerId,
      required AiPlanExecutor planExecutor,
    });

typedef AiTurnPrecomputeCacheSizeReader = int Function();
typedef AiTurnRuntimeStatsReader = String Function();
typedef AiTurnThrottleChangeLogger = void Function(String reason);

final class AiTurnPrecomputeRunner {
  final GameLogger logger;
  final AiTurnPrecomputeCoordinator coordinator;
  final AiRuntimeThrottler throttler;
  final AiPlanExecutor planExecutor;
  final AiTurnPrecomputeStarter startPrecompute;
  final AiTurnPrecomputeCacheSizeReader cacheSizeReader;
  final AiTurnRuntimeStatsReader precomputeStats;
  final AiTurnRuntimeStatsReader throttleStats;
  final AiTurnThrottleChangeLogger logThrottleChange;
  final Stopwatch Function() stopwatchFactory;

  const AiTurnPrecomputeRunner({
    required this.logger,
    required this.coordinator,
    required this.throttler,
    required this.planExecutor,
    required this.startPrecompute,
    required this.cacheSizeReader,
    required this.precomputeStats,
    required this.throttleStats,
    required this.logThrottleChange,
    this.stopwatchFactory = Stopwatch.new,
  });

  Future<void> run(AiTurnPrecomputeRequest request) async {
    final stopwatch = stopwatchFactory()..start();
    try {
      final handle = await startPrecompute(
        saveId: request.saveId,
        playerId: request.playerId,
        planExecutor: planExecutor,
      );
      if (handle == null) {
        stopwatch.stop();
        return;
      }

      logger.info(
        'AI',
        'Precomputing plan for ${request.playerId} during human turn.',
      );
      final plan = await handle.plan;
      stopwatch.stop();
      coordinator.markCompleted();
      final throttleChanged = throttler.recordPrecomputeCompleted(
        stopwatch.elapsed,
      );
      logger.info(
        'AI Runtime',
        'precompute complete player=${request.playerId} '
            'duration=${stopwatch.elapsedMilliseconds}ms '
            'commands=${plan.commands.length} '
            'cacheSize=${cacheSizeReader()}; '
            '${precomputeStats()} ${throttleStats()}',
      );
      if (throttleChanged) {
        logThrottleChange('precompute complete');
      }
    } catch (error, stackTrace) {
      stopwatch.stop();
      coordinator.markFailed(request.scheduleKey);
      final throttleChanged = throttler.recordPrecomputeFailed();
      logger.warn(
        'AI Runtime',
        'precompute failed player=${request.playerId} '
            'duration=${stopwatch.elapsedMilliseconds}ms; '
            '${precomputeStats()} ${throttleStats()}',
        error,
        stackTrace,
      );
      if (throttleChanged) {
        logThrottleChange('precompute failed');
      }
    }
  }
}
