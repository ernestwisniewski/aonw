import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_recent_hostility_tracker.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/ai_turn_preparation_builder.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/ruleset.dart';

class RunAiTurnUseCase {
  final GameRepository repository;
  final AiStrategyRegistry strategyRegistry;
  final AiTurnRunner runner;
  final GameRuleset ruleset;
  final MapData mapData;
  final AiTurnPlanPrecomputeCache? precomputeCache;
  final AiStrategicPlanProvider? strategicPlanProvider;
  final AiRecentHostilityTracker? recentHostilityTracker;

  const RunAiTurnUseCase({
    required this.repository,
    required this.strategyRegistry,
    required this.runner,
    required this.ruleset,
    required this.mapData,
    this.precomputeCache,
    this.strategicPlanProvider,
    this.recentHostilityTracker,
  });

  Future<AiTurnPrecomputeHandle?> precompute({
    required String saveId,
    required String playerId,
    SaveSnapshot? snapshot,
    AiPlanExecutor planExecutor = syncAiPlanExecutor,
  }) async {
    final cache = precomputeCache;
    if (cache == null) return null;

    final prepared = await _prepare(
      saveId: saveId,
      playerId: playerId,
      snapshot: snapshot,
    );
    if (prepared == null) return null;

    final plan = cache.start(
      key: prepared.precomputeKey,
      planFactory: () => planExecutor(
        strategy: prepared.strategy,
        view: prepared.view,
        context: prepared.context,
      ),
    );
    return AiTurnPrecomputeHandle(key: prepared.precomputeKey, plan: plan);
  }

  Future<AiTurnReport?> execute({
    required String saveId,
    required String playerId,
    SaveSnapshot? snapshot,
    AiTerminalCommand? terminalCommand,
    Duration interCommandDelay = const Duration(milliseconds: 200),
    Future<void> Function()? onStalePrecomputeDropped,
  }) async {
    final prepared = await _prepare(
      saveId: saveId,
      playerId: playerId,
      snapshot: snapshot,
    );
    if (prepared == null) return null;

    final precomputedPlan = precomputeCache?.consume(prepared.precomputeKey);
    if (precomputedPlan == null) {
      final stalePlansDropped =
          precomputeCache?.retainWhere((key) {
            return key.saveId != prepared.snapshot.save.id ||
                key.turn != prepared.snapshot.save.turn ||
                key.playerId != playerId;
          }) ??
          0;
      if (stalePlansDropped > 0) {
        await onStalePrecomputeDropped?.call();
      }
    }

    return runner.run(
      saveId: saveId,
      playerId: playerId,
      strategy: prepared.strategy,
      context: prepared.context,
      initialState: prepared.initialState,
      view: prepared.view,
      precomputedPlan: precomputedPlan,
      terminalCommand:
          terminalCommand ??
          _terminalCommandFor(prepared.snapshot.save.gameMode),
      interCommandDelay: interCommandDelay,
    );
  }

  Future<PreparedAiTurn?> _prepare({
    required String saveId,
    required String playerId,
    SaveSnapshot? snapshot,
  }) {
    return AiTurnPreparationBuilder(
      repository: repository,
      strategyRegistry: strategyRegistry,
      ruleset: ruleset,
      mapData: mapData,
      strategicPlanProvider: strategicPlanProvider,
      recentHostilityTracker: recentHostilityTracker,
    ).prepare(saveId: saveId, playerId: playerId, snapshot: snapshot);
  }

  static AiTerminalCommand _terminalCommandFor(GameMode gameMode) {
    return switch (gameMode) {
      GameMode.hotSeat => AiTerminalCommand.endTurn,
      GameMode.multiplayer => AiTerminalCommand.submitTurn,
    };
  }
}
