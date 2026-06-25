import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_action_generation_stats.dart';
import 'package:aonw_core/ai/mcts/mcts_action_generator.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_defense_ranker.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_economy_ranker.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_frontier_ranker.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_map_objective_ranker.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_military_context.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_opening_ranker.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_ranking_queries.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_settler_ranker.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_war_ranker.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';

const _military = StrategyAwareMilitaryContext();

class StrategyAwareMctsActionGenerator implements MctsActionGenerator {
  final MctsActionGenerator inner;
  final int candidateLimit;
  final MctsActionGenerationStatsCollector? stats;

  const StrategyAwareMctsActionGenerator({
    required this.inner,
    required this.candidateLimit,
    this.stats,
  });

  factory StrategyAwareMctsActionGenerator.basic({
    required AiStrategy source,
    required int candidateLimit,
    int? sourcePlanDepthLimit,
    MctsActionGenerationStatsCollector? stats,
  }) {
    return StrategyAwareMctsActionGenerator(
      inner: BasicPlanMctsActionGenerator(
        source: source,
        candidateLimit: expandedCandidateLimit(candidateLimit),
        sourcePlanDepthLimit: sourcePlanDepthLimit,
        stats: stats,
      ),
      candidateLimit: candidateLimit,
      stats: stats,
    );
  }

  @override
  List<MctsAction> candidatesFor(SimulatedState state, AiContext context) {
    final stopwatch = Stopwatch()..start();
    if (state.isTerminal) {
      stopwatch.stop();
      stats?.recordCandidateCall(
        elapsed: stopwatch.elapsed,
        rawCandidates: 0,
        selectedCandidates: 0,
        terminal: true,
      );
      return const [];
    }

    final raw = inner.candidatesFor(state, context);
    if (candidateLimit <= 0) {
      const actions = [EndPlanningAction()];
      stopwatch.stop();
      stats?.recordCandidateCall(
        elapsed: stopwatch.elapsed,
        rawCandidates: raw.length,
        selectedCandidates: actions.length,
      );
      return actions;
    }

    final ranked = <RankedCandidate>[];
    for (var i = 0; i < raw.length; i++) {
      final rawAction = raw[i];
      if (rawAction is! CommandMctsAction) continue;
      final ranking = _rankCommand(rawAction.command, state.view, context);
      if (ranking.score <= blockedCandidateScore) continue;
      ranked.add(
        RankedCandidate(action: rawAction, index: i, ranking: ranking),
      );
    }

    final selected = selectRankedCandidates(
      ranked,
      mode: context.strategicPlan?.mode ?? StrategicMode.consolidate,
      candidateLimit: candidateLimit,
    )..sort(compareRankedCandidates);

    final actions = [
      for (final candidate in selected) candidate.action,
      const EndPlanningAction(),
    ];
    stopwatch.stop();
    stats?.recordCandidateCall(
      elapsed: stopwatch.elapsed,
      rawCandidates: raw.length,
      selectedCandidates: actions.length,
    );
    return actions;
  }
}

CommandRanking _rankCommand(
  GameCommand command,
  GameView view,
  AiContext context,
) {
  if (command case final MoveUnitCommand moveCommand) {
    if (!_isMoveCandidateLegal(moveCommand, view)) {
      return const CommandRanking(CandidatePriority.fallback, -1000);
    }
  }

  final opening = rankOpeningSurvivalCommand(
    command,
    view,
    context,
    context.strategicPlan,
  );
  if (opening != null) return opening;

  final plan = context.strategicPlan;
  if (plan != null) {
    if (command case final MoveUnitCommand moveCommand) {
      final pinnedGarrison = rankPinnedGarrisonMove(moveCommand, view, plan);
      if (pinnedGarrison != null) return pinnedGarrison;
    }

    final earlyDefense = rankEarlyCityDefenseCommand(
      command,
      view,
      context,
      plan,
    );
    if (earlyDefense != null) return earlyDefense;

    final settlerEscort = rankSettlerEscortCommand(
      command,
      view,
      context,
      plan,
    );
    if (settlerEscort != null) return settlerEscort;

    final frontierClearing = rankFrontierClearingCommand(
      command,
      view,
      context,
      plan,
    );
    if (frontierClearing != null) return frontierClearing;

    final founderPressure = rankFounderPressureClearingCommand(
      command,
      view,
      context,
    );
    if (founderPressure != null) return founderPressure;

    final garrison = rankReservedGarrisonCommand(command, view, context, plan);
    if (garrison != null) return garrison;

    final warFocus = rankAssignedWarFocusGuard(command, view, context, plan);
    if (warFocus != null) return warFocus;
  }

  final militaryReserve = rankLastMilitaryReserveCommand(
    command,
    view,
    context,
  );
  if (militaryReserve != null) return militaryReserve;

  if (plan == null) {
    return _rankByModeOnly(command, view, context);
  }

  final war = rankWarCommand(command, view, context, plan);
  if (war != null) return war;

  final settler = rankStrategicSettlerCommand(command, view, context, plan);
  if (settler != null) return settler;

  final discovery = rankCitySiteDiscoveryCommand(command, view, context, plan);
  if (discovery != null) return discovery;

  final mapObjective = rankMapObjectiveCommand(command, view, context);
  if (mapObjective != null) return mapObjective;

  final defense = rankDefenseCommand(command, view, context, plan);
  if (defense != null) return defense;

  final strategic = rankStrategicEconomyCommand(command, view, context, plan);
  if (strategic != null) return strategic;

  return _rankByModeOnly(command, view, context);
}

CommandRanking _rankByModeOnly(
  GameCommand command,
  GameView view,
  AiContext context,
) {
  return switch (command) {
    AttackHexCommand() => rankTacticalAttack(command, view, context),
    FoundCityCommand(:final founderId)
        when context.strategicPlan?.mode == StrategicMode.expand &&
            _canFoundCityWithUnitId(view, founderId) =>
      const CommandRanking(CandidatePriority.settler, 700),
    StartUnitProductionCommand(:final unitType)
        when unitType == GameUnitType.settler &&
            context.strategicPlan?.mode == StrategicMode.expand =>
      const CommandRanking(CandidatePriority.cityRole, 500),
    StartUnitProductionCommand(:final unitType)
        when _military.isType(unitType, context) &&
            context.strategicPlan?.mode == StrategicMode.military =>
      const CommandRanking(CandidatePriority.cityRole, 500),
    _ => const CommandRanking(CandidatePriority.fallback, 0),
  };
}

bool _canFoundCityWithUnitId(GameView view, String unitId) {
  final unit = ownUnitById(view, unitId);
  return unit != null && CityFoundingRules.canFoundCityWith(unit);
}

bool _isMoveCandidateLegal(MoveUnitCommand command, GameView view) {
  final unit = ownUnitById(view, command.unitId);
  if (unit == null || unit.isWorking) return false;
  if (unit.col == command.targetCol && unit.row == command.targetRow) {
    return false;
  }
  if (view.mapData.tileAt(command.targetCol, command.targetRow) == null) {
    return false;
  }
  if (enemyCityAt(view, command.targetCol, command.targetRow) != null) {
    return false;
  }
  for (final other in view.movementBlockingUnits) {
    if (other.id == unit.id) continue;
    if (other.col == command.targetCol && other.row == command.targetRow) {
      return false;
    }
  }
  return true;
}
