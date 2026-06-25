import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_precompute_schedule.dart';
import 'package:aonw/game/application/services/ai_precompute_targets.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_precompute_scheduler.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_runner.dart';
import 'package:aonw_core/game/domain/player.dart';

typedef AiTurnLocalAiPredicate =
    bool Function({
      required GameSave save,
      required NetworkSession? networkSession,
    });
typedef AiTurnPlayerSelector =
    Player? Function({
      required GameSave save,
      required PlayerControlState control,
      required GameState? gameState,
    });
typedef AiTurnRequestDispatcher = void Function(AiTurnRunRequest request);
typedef AiTurnPendingPrecomputeScheduler = void Function();

final class AiTurnAutoScheduler {
  final GameLogger logger;
  final AiTurnRunScheduler runScheduler;
  final AiTurnPrecomputeCoordinator precomputeCoordinator;
  final AiTurnPlanPrecomputeCache precomputeCache;
  final AiRuntimeThrottler throttler;
  final AiTurnLocalAiPredicate shouldRunLocalAi;
  final AiTurnPlayerSelector aiPlayerToRun;
  final AiTurnRequestDispatcher scheduleTurn;
  final AiTurnPendingPrecomputeScheduler schedulePendingPrecompute;
  final AiTurnRuntimeStatsReader precomputeStats;
  final AiTurnRuntimeStatsReader throttleStats;
  final AiTurnThrottleChangeLogger logThrottleChange;

  const AiTurnAutoScheduler({
    required this.logger,
    required this.runScheduler,
    required this.precomputeCoordinator,
    required this.precomputeCache,
    required this.throttler,
    required this.shouldRunLocalAi,
    required this.aiPlayerToRun,
    required this.scheduleTurn,
    required this.schedulePendingPrecompute,
    required this.precomputeStats,
    required this.throttleStats,
    required this.logThrottleChange,
  });

  void evaluate({
    required GameSave? save,
    required PlayerControlState control,
    required HandoffData? handoff,
    required NetworkSession? networkSession,
    required GameState? gameState,
  }) {
    if (runScheduler.running || save == null || handoff != null) {
      return;
    }

    if (shouldRunLocalAi(save: save, networkSession: networkSession) &&
        _scheduleRunnableAi(
          save: save,
          control: control,
          gameState: gameState,
        )) {
      return;
    }

    _maybePrecompute(
      save: save,
      control: control,
      networkSession: networkSession,
      gameState: gameState,
    );
  }

  bool _scheduleRunnableAi({
    required GameSave save,
    required PlayerControlState control,
    required GameState? gameState,
  }) {
    final player = aiPlayerToRun(
      save: save,
      control: control,
      gameState: gameState,
    );
    if (!_isAiPlayer(player)) return false;

    final request = runScheduler.schedule(
      saveId: save.id,
      turn: save.turn,
      playerId: player!.id,
    );
    if (request == null) return false;

    scheduleTurn(request);
    return true;
  }

  void _maybePrecompute({
    required GameSave save,
    required PlayerControlState control,
    required NetworkSession? networkSession,
    required GameState? gameState,
  }) {
    if (gameState == null || precomputeCoordinator.lifecyclePaused) return;
    if (!shouldRunLocalAi(save: save, networkSession: networkSession)) {
      return;
    }

    final players = AiPrecomputeTargets.duringHumanTurn(
      save: save,
      control: control,
      gameState: gameState,
    );
    if (players.isEmpty) return;

    final playerIds = {for (final player in players) player.id};
    precomputeCache.retainWhere((key) {
      return key.saveId == save.id &&
          key.turn == save.turn &&
          playerIds.contains(key.playerId);
    });

    final candidates = [
      for (final player in players)
        _AiTurnPrecomputeCandidate(
          playerId: player.id,
          scheduleKey: AiPrecomputeScheduleKey.build(
            save: save,
            gameState: gameState,
            player: player,
          ),
        ),
    ];

    final pendingScheduleKey = precomputeCoordinator.pendingScheduleKey;
    if (pendingScheduleKey != null &&
        candidates.any(
          (candidate) => candidate.scheduleKey == pendingScheduleKey,
        )) {
      return;
    }

    for (final candidate in candidates) {
      if (precomputeCoordinator.hasScheduledOrPending(candidate.scheduleKey)) {
        continue;
      }

      _queuePrecompute(
        AiTurnPrecomputeRequest(
          saveId: save.id,
          playerId: candidate.playerId,
          scheduleKey: candidate.scheduleKey,
        ),
      );
      return;
    }
  }

  void _queuePrecompute(AiTurnPrecomputeRequest request) {
    final result = precomputeCoordinator.queue(request);
    if (result.replaced) {
      final throttleChanged = throttler.recordPrecomputeQueued(replaced: true);
      logger.info(
        'AI Runtime',
        'precompute queue replaced for ${request.playerId}; '
            '${precomputeStats()} ${throttleStats()}',
      );
      if (throttleChanged) {
        logThrottleChange('precompute queue replaced');
      }
    } else {
      throttler.recordPrecomputeQueued(replaced: false);
    }
    schedulePendingPrecompute();
  }

  static bool _isAiPlayer(Player? player) {
    return player != null && player.kind == PlayerKind.ai && player.ai != null;
  }
}

final class _AiTurnPrecomputeCandidate {
  final String playerId;
  final String scheduleKey;

  const _AiTurnPrecomputeCandidate({
    required this.playerId,
    required this.scheduleKey,
  });
}
