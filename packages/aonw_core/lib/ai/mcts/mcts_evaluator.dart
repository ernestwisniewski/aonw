import 'dart:math' as math;

import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/mcts/mcts_command_combat_scorer.dart';
import 'package:aonw_core/ai/mcts/mcts_command_movement_scorer.dart';
import 'package:aonw_core/ai/mcts/mcts_command_production_scorer.dart';
import 'package:aonw_core/ai/mcts/mcts_evaluation_queries.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/mcts_stability_scores.dart';
import 'package:aonw_core/ai/mcts/mcts_state_score_estimator.dart';
import 'package:aonw_core/ai/mcts/mcts_strategic_state_scorer.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/outcome.dart';

abstract interface class MctsEvaluator {
  double score(SimulatedState state, String forPlayerId, {AiContext? context});
}

class StateHeuristicEvaluator implements MctsEvaluator {
  final CommandSequenceEvaluator commandEvaluator;
  final MctsStrategicStateScorer strategicScorer;
  final MctsStateScoreEstimator scoreEstimator;

  const StateHeuristicEvaluator({
    this.commandEvaluator = const CommandSequenceEvaluator(),
    this.strategicScorer = const MctsStrategicStateScorer(),
    this.scoreEstimator = const MctsStateScoreEstimator(),
  });

  @override
  double score(SimulatedState state, String forPlayerId, {AiContext? context}) {
    final weights = context?.effectiveWeights ?? PersonaWeights.identity;
    final strategicScore = strategicScorer.score(state, weights);
    final commandScore = commandEvaluator.score(
      state,
      forPlayerId,
      context: context,
    );
    final scoreRace = context?.scoreRace;
    final scoreRaceWeight = scoreRace == null
        ? 0.0
        : (0.08 + scoreRace.urgency * 0.17).clamp(0.0, 0.25).toDouble();
    const commandWeight = 0.22;
    const stabilityWeight = 0.12;
    final strategicWeight =
        1.0 - commandWeight - scoreRaceWeight - stabilityWeight;
    final score =
        strategicScore * strategicWeight +
        commandScore * commandWeight +
        _scoreRaceScore(state, scoreRace) * scoreRaceWeight +
        MctsStabilityScores.stateScore(state, context) * stabilityWeight;
    return score.clamp(-1.0, 1.0).toDouble();
  }

  double _scoreRaceScore(SimulatedState state, ScoreRaceAnalysis? scoreRace) {
    if (scoreRace == null || !scoreRace.hasContestedScoreRace) return 0.0;
    final reference = scoreRace.referenceOpponent;
    if (reference == null) return 0.0;

    final simulatedScore = scoreEstimator.estimate(state);
    final currentScore = scoreRace.player.total;
    final scoreDelta = simulatedScore - currentScore;
    final referenceScore = math.max(1, reference.total);
    final standing =
        ((simulatedScore - reference.total) / math.max(referenceScore, 1))
            .clamp(-1.0, 1.0)
            .toDouble();
    final gap = math.max(1, (reference.total - currentScore).abs());
    final progress = (scoreDelta / gap).clamp(-1.0, 1.0).toDouble();
    final urgency = 0.35 + scoreRace.urgency * 0.65;
    return (standing * 0.55 + progress * 0.45) * urgency;
  }
}

class CommandSequenceEvaluator implements MctsEvaluator {
  final MctsCommandCombatScorer combatScorer;
  final MctsCommandMovementScorer movementScorer;
  final MctsCommandProductionScorer productionScorer;

  const CommandSequenceEvaluator({
    this.combatScorer = const MctsCommandCombatScorer(),
    this.movementScorer = const MctsCommandMovementScorer(),
    this.productionScorer = const MctsCommandProductionScorer(),
  });

  @override
  double score(SimulatedState state, String forPlayerId, {AiContext? context}) {
    var score = 0.0;
    for (final command in state.plannedCommands) {
      score += _commandScore(command, state: state, context: context);
    }
    return score.clamp(-1.0, 1.0).toDouble();
  }

  double _commandScore(
    GameCommand command, {
    required SimulatedState state,
    AiContext? context,
  }) {
    return switch (command) {
      FoundCityCommand() => 0.34,
      AttackHexCommand() => combatScorer.scoreAttack(
        command,
        state: state,
        context: context,
      ),
      SelectTechnologyCommand() => 0.13,
      StartUnitProductionCommand() => productionScorer.score(
        command,
        state: state,
        context: context,
      ),
      StartBuildingCommand(:final buildingType) =>
        MctsStabilityScores.buildingScore(buildingType, state),
      StartCityProjectCommand() => 0.11,
      SetCitySpecializationCommand() => 0.08,
      SelectWorkerImprovementCommand() ||
      ConfirmWorkerImprovementCommand() ||
      AssignWorkerToHexCommand() => 0.08,
      MoveUnitCommand() => movementScorer.score(
        command,
        state: state,
        context: context,
      ),
      SkipUnitTurnCommand() => -0.01,
      CancelUnitActionCommand() => _cancelUnitActionScore(
        command,
        state: state,
        context: context,
      ),
      FortifyUnitCommand() => combatScorer.scoreFortify(
        command,
        state: state,
        context: context,
      ),
      AutoExploreUnitCommand() => 0.02,
      StartArtifactExcavationCommand() => 0.20,
      StoreArtifactInCityCommand() => 0.24,
      _ => 0.0,
    };
  }

  double _cancelUnitActionScore(
    CancelUnitActionCommand command, {
    required SimulatedState state,
    AiContext? context,
  }) {
    final plan = context?.strategicPlan;
    if (plan == null) return 0.0;
    final unit = mctsOwnUnitById(state.view.ownUnits, command.unitId);
    if (unit == null) return 0.0;

    for (final goal in plan.warGoals) {
      if (goal.kind == WarGoalKind.defend) continue;
      if (!goal.assignedUnitIds.contains(command.unitId)) continue;
      return 0.18 + goal.priority.clamp(0.0, 10.0) * 0.01;
    }
    return 0.0;
  }
}
