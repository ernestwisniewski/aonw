import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_precompute_schedule.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_turn_precompute_scheduler.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/services/ai_turn_auto_scheduler.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_rules.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnAutoScheduler', () {
    test('schedules runnable AI turn before considering precompute', () {
      final turnRequests = <AiTurnRunRequest>[];
      final pendingStarts = <String>[];
      _scheduler(
        turnRequests: turnRequests,
        pendingStarts: pendingStarts,
      ).evaluate(
        save: _save(
          gameMode: GameMode.hotSeat,
          playerStates: const {
            'human': PlayerTurnState.finished,
            'ai_1': PlayerTurnState.active,
            'ai_2': PlayerTurnState.active,
          },
        ),
        control: const PlayerControlState(
          activePlayerId: 'human',
          canAct: false,
        ),
        handoff: null,
        networkSession: null,
        gameState: const GameState(
          activePlayerId: 'human',
          activePlayerCanAct: false,
        ),
      );

      expect(turnRequests.map((request) => request.playerId), const ['ai_1']);
      expect(pendingStarts, isEmpty);
    });

    test(
      'queues first precompute target and retains only relevant cache',
      () async {
        final precomputeCache = AiTurnPlanPrecomputeCache();
        final keepKey = _cacheKey(playerId: 'ai_1');
        final stalePlayerKey = _cacheKey(playerId: 'ai_old');
        final staleTurnKey = _cacheKey(playerId: 'ai_1', turn: 8);
        await Future.wait([
          precomputeCache.start(key: keepKey, planFactory: _emptyPlan),
          precomputeCache.start(key: stalePlayerKey, planFactory: _emptyPlan),
          precomputeCache.start(key: staleTurnKey, planFactory: _emptyPlan),
        ]);
        final precomputeCoordinator = AiTurnPrecomputeCoordinator();
        final pendingStarts = <String>[];
        final scheduler = _scheduler(
          precomputeCache: precomputeCache,
          precomputeCoordinator: precomputeCoordinator,
          pendingStarts: pendingStarts,
        );
        final save = _save(gameMode: GameMode.hotSeat);
        const gameState = GameState(
          activePlayerId: 'human',
          activePlayerCanAct: true,
        );

        scheduler.evaluate(
          save: save,
          control: const PlayerControlState(activePlayerId: 'human'),
          handoff: null,
          networkSession: null,
          gameState: gameState,
        );

        expect(pendingStarts, const ['pending']);
        expect(
          precomputeCoordinator.pendingScheduleKey,
          _scheduleKey(save: save, gameState: gameState, player: _aiPlayer1),
        );
        expect(precomputeCache.contains(keepKey), isTrue);
        expect(precomputeCache.contains(stalePlayerKey), isFalse);
        expect(precomputeCache.contains(staleTurnKey), isFalse);
      },
    );

    test('keeps relevant pending precompute instead of replacing it', () {
      final logger = _RecordingGameLogger();
      final precomputeCoordinator = AiTurnPrecomputeCoordinator();
      final pendingStarts = <String>[];
      final scheduler = _scheduler(
        logger: logger,
        precomputeCoordinator: precomputeCoordinator,
        pendingStarts: pendingStarts,
      );
      final save = _save(gameMode: GameMode.hotSeat);
      const gameState = GameState(
        activePlayerId: 'human',
        activePlayerCanAct: true,
      );

      scheduler
        ..evaluate(
          save: save,
          control: const PlayerControlState(activePlayerId: 'human'),
          handoff: null,
          networkSession: null,
          gameState: gameState,
        )
        ..evaluate(
          save: save,
          control: const PlayerControlState(activePlayerId: 'human'),
          handoff: null,
          networkSession: null,
          gameState: gameState,
        );

      expect(pendingStarts, const ['pending']);
      expect(
        precomputeCoordinator.pendingScheduleKey,
        _scheduleKey(save: save, gameState: gameState, player: _aiPlayer1),
      );
      expect(logger.infoMessages, isEmpty);
    });

    test('replaces stale pending precompute and records throttle pressure', () {
      final logger = _RecordingGameLogger();
      final throttleReasons = <String>[];
      final precomputeCoordinator = AiTurnPrecomputeCoordinator()
        ..queue(
          const AiTurnPrecomputeRequest(
            saveId: 'save_1',
            playerId: 'stale_ai',
            scheduleKey: 'stale-key',
          ),
        );
      final pendingStarts = <String>[];
      final scheduler = _scheduler(
        logger: logger,
        precomputeCoordinator: precomputeCoordinator,
        pendingStarts: pendingStarts,
        throttleReasons: throttleReasons,
      );
      final save = _save(gameMode: GameMode.hotSeat);
      const gameState = GameState(
        activePlayerId: 'human',
        activePlayerCanAct: true,
      );

      scheduler.evaluate(
        save: save,
        control: const PlayerControlState(activePlayerId: 'human'),
        handoff: null,
        networkSession: null,
        gameState: gameState,
      );

      expect(pendingStarts, const ['pending']);
      expect(
        precomputeCoordinator.pendingScheduleKey,
        _scheduleKey(save: save, gameState: gameState, player: _aiPlayer1),
      );
      expect(
        logger.infoMessages.single,
        startsWith('AI Runtime: precompute queue replaced for ai_1;'),
      );
      expect(throttleReasons, const ['precompute queue replaced']);
    });

    test('does nothing while running, during handoff, or without a save', () {
      final turnRequests = <AiTurnRunRequest>[];
      final pendingStarts = <String>[];
      _scheduler(turnRequests: turnRequests, pendingStarts: pendingStarts)
        ..evaluate(
          save: null,
          control: const PlayerControlState(activePlayerId: 'human'),
          handoff: null,
          networkSession: null,
          gameState: const GameState(activePlayerId: 'human'),
        )
        ..evaluate(
          save: _save(gameMode: GameMode.hotSeat),
          control: const PlayerControlState(activePlayerId: 'human'),
          handoff: const HandoffData(
            playerId: 'human',
            playerName: 'Human',
            playerColorValue: 0xFF2563EB,
            turnNumber: 9,
          ),
          networkSession: null,
          gameState: const GameState(activePlayerId: 'human'),
        );

      expect(turnRequests, isEmpty);
      expect(pendingStarts, isEmpty);
    });
  });
}

AiTurnAutoScheduler _scheduler({
  GameLogger? logger,
  AiTurnRunScheduler? runScheduler,
  AiTurnPrecomputeCoordinator? precomputeCoordinator,
  AiTurnPlanPrecomputeCache? precomputeCache,
  AiRuntimeThrottler? throttler,
  List<AiTurnRunRequest>? turnRequests,
  List<String>? pendingStarts,
  List<String>? throttleReasons,
}) {
  final resolvedLogger = logger ?? _RecordingGameLogger();
  final resolvedPrecomputeCoordinator =
      precomputeCoordinator ?? AiTurnPrecomputeCoordinator();
  final resolvedThrottler = throttler ?? AiRuntimeThrottler();
  return AiTurnAutoScheduler(
    logger: resolvedLogger,
    runScheduler: runScheduler ?? AiTurnRunScheduler(),
    precomputeCoordinator: resolvedPrecomputeCoordinator,
    precomputeCache: precomputeCache ?? AiTurnPlanPrecomputeCache(),
    throttler: resolvedThrottler,
    shouldRunLocalAi: GameAiTurnAutoPilotRules.shouldRunLocalAi,
    aiPlayerToRun: GameAiTurnAutoPilotRules.aiPlayerToRun,
    scheduleTurn: turnRequests?.add ?? (_) {},
    schedulePendingPrecompute: () {
      pendingStarts?.add('pending');
    },
    precomputeStats: resolvedPrecomputeCoordinator.stats,
    throttleStats: () => 'throttle=${resolvedThrottler.snapshot}',
    logThrottleChange: throttleReasons?.add ?? (_) {},
  );
}

Future<AiTurnPlan> _emptyPlan() async {
  return AiTurnPlan(commands: const []);
}

String _scheduleKey({
  required GameSave save,
  required GameState gameState,
  required Player player,
}) {
  return AiPrecomputeScheduleKey.build(
    save: save,
    gameState: gameState,
    player: player,
  );
}

AiTurnPlanPrecomputeKey _cacheKey({required String playerId, int turn = 4}) {
  return AiTurnPlanPrecomputeKey(
    saveId: 'save_1',
    turn: turn,
    gameMode: GameMode.hotSeat,
    playerId: playerId,
    country: PlayerCountry.poland,
    strategyId: AiStrategyId.mcts,
    difficulty: AiDifficulty.normal,
    persona: AiPersona.balanced,
    seed: 99,
    matchRulesHash: 1,
    worldStateHash: 1,
  );
}

GameSave _save({
  required GameMode gameMode,
  Map<String, PlayerTurnState> playerStates = const {
    'human': PlayerTurnState.active,
    'ai_1': PlayerTurnState.active,
    'ai_2': PlayerTurnState.active,
  },
}) {
  return GameSave(
    id: 'save_1',
    name: 'AI auto scheduler test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 4,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 6, 2),
    camera: CameraState.zero,
    players: const [_humanPlayer, _aiPlayer1, _aiPlayer2],
    gameMode: gameMode,
  );
}

const _humanPlayer = Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB);

const _aiPlayer1 = Player(
  id: 'ai_1',
  name: 'AI 1',
  colorValue: 0xFFDC2626,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.mcts, seed: 99),
);

const _aiPlayer2 = Player(
  id: 'ai_2',
  name: 'AI 2',
  colorValue: 0xFF16A34A,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.mcts, seed: 199),
);

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
