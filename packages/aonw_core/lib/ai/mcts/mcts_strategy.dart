import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/ai_turn_plan.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_action_generation_stats.dart';
import 'package:aonw_core/ai/mcts/mcts_action_generator.dart';
import 'package:aonw_core/ai/mcts/mcts_budget.dart';
import 'package:aonw_core/ai/mcts/mcts_command_reconciler.dart';
import 'package:aonw_core/ai/mcts/mcts_config.dart';
import 'package:aonw_core/ai/mcts/mcts_debug.dart';
import 'package:aonw_core/ai/mcts/mcts_evaluator.dart';
import 'package:aonw_core/ai/mcts/mcts_search.dart';
import 'package:aonw_core/ai/mcts/mcts_search_bypass_policy.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/mcts_simulator.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_action_generator.dart';
import 'package:aonw_core/ai/strategies/basic_strategy.dart';

const _commandReconciler = MctsCommandReconciler();
const _searchBypassPolicy = MctsSearchBypassPolicy();

enum MctsRuntimeProfile { standard, interactive, batterySaver }

class MctsStrategy implements AiStrategy {
  final MctsConfig? config;
  final MctsRuntimeProfile runtimeProfile;
  final AiStrategy fallback;
  final MctsActionGenerator? actionGenerator;
  final MctsSimulator? simulator;
  final MctsEvaluator evaluator;

  const MctsStrategy({
    this.config,
    this.runtimeProfile = MctsRuntimeProfile.standard,
    this.fallback = const BasicStrategy(),
    this.actionGenerator,
    this.simulator,
    this.evaluator = const StateHeuristicEvaluator(),
  });

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    final totalStopwatch = Stopwatch()..start();
    final effectiveConfig =
        config ?? _configFor(context.difficulty, runtimeProfile);
    if (!_hasMinimumBudget(context, effectiveConfig)) {
      return fallback.plan(view, context);
    }
    final bypassReason = _searchBypassPolicy.reasonFor(
      view,
      canBypassDefaultSearch:
          config == null && actionGenerator == null && simulator == null,
      isBatterySaver: runtimeProfile == MctsRuntimeProfile.batterySaver,
    );
    if (bypassReason != null) {
      return _fallbackOnlyPlan(
        view,
        context,
        config: effectiveConfig,
        reason: bypassReason,
      );
    }

    final actionGenerationStats = actionGenerator == null
        ? MctsActionGenerationStatsCollector()
        : null;
    final generator =
        actionGenerator ??
        StrategyAwareMctsActionGenerator.basic(
          source: fallback,
          candidateLimit: effectiveConfig.candidateLimit,
          sourcePlanDepthLimit: effectiveConfig.sourcePlanDepthLimit,
          stats: actionGenerationStats,
        );
    final search = MctsSearch(
      actionGenerator: generator,
      simulator: _simulatorFor(effectiveConfig),
      evaluator: evaluator,
      explorationConstant: effectiveConfig.explorationConstant,
    );
    final effectiveSimulator = search.simulator;
    final rootState = SimulatedState.fromView(
      view,
      maxPlanningDepth: effectiveConfig.maxPlanningDepth,
    );
    final result = search.search(
      rootState: rootState,
      context: context,
      budget: MctsBudget.fromConfig(
        config: effectiveConfig,
        deadline: context.deadline,
      ),
    );
    final validationStopwatch = Stopwatch()..start();
    final searchedCommands = _commandReconciler.validatedCommands(
      result.bestActions,
      rootState: rootState,
      simulator: effectiveSimulator,
    );
    validationStopwatch.stop();
    final baselineStopwatch = Stopwatch()..start();
    final baselinePlan = fallback.plan(view, context);
    final baselineCommands = baselinePlan.commands;
    baselineStopwatch.stop();
    final mergeStopwatch = Stopwatch()..start();
    final commands = _commandReconciler.withBaselineSupportCommands(
      searchedCommands,
      baselineCommands,
      view,
      context,
      simulator: effectiveSimulator,
    );
    mergeStopwatch.stop();
    totalStopwatch.stop();
    final debug = MctsDebugSummary.fromResult(
      result,
      actionGeneration: actionGenerationStats?.snapshot(),
      phaseTimings: MctsPhaseTimings(
        searchElapsed: result.elapsed,
        validationElapsed: validationStopwatch.elapsed,
        baselinePlanElapsed: baselineStopwatch.elapsed,
        mergeElapsed: mergeStopwatch.elapsed,
        totalElapsed: totalStopwatch.elapsed,
      ),
    );

    return AiTurnPlan(
      commands: commands,
      debug: AiDebugInfo(
        strategyId: 'mcts',
        notes: debug.toNotes(),
        metrics: {
          ...debug.toMetrics(),
          ..._prefixedMetrics(
            'mcts.baseline.',
            baselinePlan.debug?.metrics ?? const {},
          ),
        },
      ),
    );
  }

  AiTurnPlan _fallbackOnlyPlan(
    GameView view,
    AiContext context, {
    required MctsConfig config,
    required String reason,
  }) {
    final totalStopwatch = Stopwatch()..start();
    final baselineStopwatch = Stopwatch()..start();
    final plan = fallback.plan(view, context);
    baselineStopwatch.stop();
    final mergeStopwatch = Stopwatch()..start();
    final commands = _commandReconciler.withBaselineSupportCommands(
      const [],
      plan.commands,
      view,
      context,
      simulator: _simulatorFor(config),
    );
    mergeStopwatch.stop();
    totalStopwatch.stop();
    final baselineDebug = plan.debug;
    return AiTurnPlan(
      commands: commands,
      debug: AiDebugInfo(
        strategyId: 'mcts',
        notes: ['bypassed search: $reason', ...?baselineDebug?.notes],
        metrics: {
          'mcts.searchBypassed': true,
          'mcts.bypassReason': reason,
          'mcts.iterations': 0,
          'mcts.elapsedMicros': 0,
          'mcts.plannedActions': 0,
          'mcts.rootChildren': 0,
          'mcts.exploredNodes': 0,
          'mcts.searchElapsedMicros': 0,
          'mcts.candidateCalls': 0,
          'mcts.sourcePlanCalls': 0,
          'mcts.sourcePlanSkipped': 0,
          'mcts.baselinePlanElapsedMicros':
              baselineStopwatch.elapsedMicroseconds,
          'mcts.mergeElapsedMicros': mergeStopwatch.elapsedMicroseconds,
          'mcts.strategyElapsedMicros': totalStopwatch.elapsedMicroseconds,
          ..._prefixedMetrics(
            'mcts.baseline.',
            baselineDebug?.metrics ?? const {},
          ),
        },
      ),
    );
  }

  static Map<String, Object?> _prefixedMetrics(
    String prefix,
    Map<String, Object?> metrics,
  ) {
    if (metrics.isEmpty) return const {};
    return {
      for (final entry in metrics.entries) '$prefix${entry.key}': entry.value,
    };
  }

  static MctsConfig _configFor(
    AiDifficulty difficulty,
    MctsRuntimeProfile profile,
  ) {
    return switch (profile) {
      MctsRuntimeProfile.standard => MctsConfig.fromDifficulty(difficulty),
      MctsRuntimeProfile.interactive => MctsConfig.forInteractive(difficulty),
      MctsRuntimeProfile.batterySaver => MctsConfig.forBatterySaver(difficulty),
    };
  }

  MctsSimulator _simulatorFor(MctsConfig config) {
    final configured = simulator;
    if (configured != null) return configured;
    return TracingMctsSimulator(
      simulateOpponentPlans: config.simulateOpponentResponses,
      simulateTurnEconomy: config.simulateTurnEconomy,
    );
  }

  bool _hasMinimumBudget(AiContext context, MctsConfig config) =>
      context.deadline == null ||
      context.deadline!.toUtc().difference(DateTime.now().toUtc()) >=
          config.minimumBudget;
}
