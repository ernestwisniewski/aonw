import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_action_generation_stats.dart';
import 'package:aonw_core/ai/mcts/mcts_combat_candidate_collector.dart';
import 'package:aonw_core/ai/mcts/mcts_command_candidate_guard.dart';
import 'package:aonw_core/ai/mcts/mcts_founding_candidate_collector.dart';
import 'package:aonw_core/ai/mcts/mcts_movement_candidate_collector.dart';
import 'package:aonw_core/ai/mcts/mcts_production_candidate_collector.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/mcts_worker_candidate_collector.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';

abstract interface class MctsActionGenerator {
  List<MctsAction> candidatesFor(SimulatedState state, AiContext context);
}

class BasicPlanMctsActionGenerator implements MctsActionGenerator {
  final AiStrategy source;
  final int candidateLimit;
  final int? sourcePlanDepthLimit;
  final MctsActionGenerationStatsCollector? stats;
  final MctsCombatCandidateCollector combatCandidates;
  final MctsFoundingCandidateCollector foundingCandidates;
  final MctsMovementCandidateCollector movementCandidates;
  final MctsWorkerCandidateCollector workerCandidates;
  final MctsProductionCandidateCollector productionCandidates;

  const BasicPlanMctsActionGenerator({
    required this.source,
    required this.candidateLimit,
    this.sourcePlanDepthLimit,
    this.stats,
    this.combatCandidates = const MctsCombatCandidateCollector(),
    this.foundingCandidates = const MctsFoundingCandidateCollector(),
    this.movementCandidates = const MctsMovementCandidateCollector(),
    this.workerCandidates = const MctsWorkerCandidateCollector(),
    this.productionCandidates = const MctsProductionCandidateCollector(),
  });

  @override
  List<MctsAction> candidatesFor(SimulatedState state, AiContext context) {
    if (state.isTerminal) return const [];

    final view = state.view;
    final founderReserve = foundingCandidates.candidateReserve(
      view,
      candidateLimit,
    );
    final sourceCandidateLimit = candidateLimit - founderReserve;
    final candidates = <MctsAction>[];
    final seen = <GameCommand>{};
    _addCommands(
      candidates,
      seen,
      state,
      combatCandidates.priorityCommandsFor(view, context),
    );
    if (_shouldUseSourcePlan(state)) {
      final sourceStopwatch = Stopwatch()..start();
      final plan = source.plan(state.view, context);
      sourceStopwatch.stop();
      stats?.recordSourcePlan(
        elapsed: sourceStopwatch.elapsed,
        commandCount: plan.commands.length,
      );
      for (final command in plan.commands) {
        _addCommand(
          candidates: candidates,
          seen: seen,
          state: state,
          command: command,
        );
        if (candidates.length >= sourceCandidateLimit) break;
      }
    } else {
      stats?.recordSourcePlanSkipped();
    }

    if (!_isFull(candidates)) {
      _addCommands(
        candidates,
        seen,
        state,
        foundingCandidates.foundingCommandsFor(view),
      );
      _addCommands(
        candidates,
        seen,
        state,
        foundingCandidates.spacingMovementCommandsFor(view),
      );
      _addUnitActionCandidates(candidates, seen, state, view);
      _addCommands(candidates, seen, state, workerCandidates.commandsFor(view));
      _addResearchCandidates(candidates, seen, state, view);
      _addCommands(
        candidates,
        seen,
        state,
        productionCandidates.commandsFor(view),
      );
      _addCommands(candidates, seen, state, combatCandidates.commandsFor(view));
      _addCommands(
        candidates,
        seen,
        state,
        movementCandidates.commandsFor(view),
      );
    }

    return [...candidates, const EndPlanningAction()];
  }

  bool _shouldUseSourcePlan(SimulatedState state) {
    final depthLimit = sourcePlanDepthLimit;
    return depthLimit == null || state.depth <= depthLimit;
  }

  void _addResearchCandidates(
    List<MctsAction> candidates,
    Set<GameCommand> seen,
    SimulatedState state,
    GameView view,
  ) {
    if (_isFull(candidates) || view.ownResearch.activeTechnologyId != null) {
      return;
    }

    final technologies = [...view.availableTechnologyIds]
      ..sort((a, b) => a.index.compareTo(b.index));
    for (final technologyId in technologies) {
      _addCommand(
        candidates: candidates,
        seen: seen,
        state: state,
        command: SelectTechnologyCommand(view.forPlayerId, technologyId),
      );
      if (_isFull(candidates)) return;
    }
  }

  void _addUnitActionCandidates(
    List<MctsAction> candidates,
    Set<GameCommand> seen,
    SimulatedState state,
    GameView view,
  ) {
    if (_isFull(candidates)) return;

    final units = [...view.ownUnits]..sort((a, b) => a.id.compareTo(b.id));
    for (final unit in units) {
      if (!unit.isReadyToAct || unit.isFortified) continue;
      if (unit.isWorker || CityFoundingRules.canFoundCityWith(unit)) continue;
      final stats = UnitCombatStats.derive(unit, ruleset: view.ruleset.combat);
      if (stats.attack <= 0 && stats.defense <= 0) continue;
      _addCommand(
        candidates: candidates,
        seen: seen,
        state: state,
        command: FortifyUnitCommand(unit.id),
      );
      if (_isFull(candidates)) return;
    }
  }

  void _addCommands(
    List<MctsAction> candidates,
    Set<GameCommand> seen,
    SimulatedState state,
    Iterable<GameCommand> commands,
  ) {
    for (final command in commands) {
      _addCommand(
        candidates: candidates,
        seen: seen,
        state: state,
        command: command,
      );
      if (_isFull(candidates)) return;
    }
  }

  void _addCommand({
    required List<MctsAction> candidates,
    required Set<GameCommand> seen,
    required SimulatedState state,
    required GameCommand command,
  }) {
    if (_isFull(candidates) || _isTerminal(command)) return;
    if (!isLegalMctsCommandCandidate(command, state.view)) return;
    if (state.hasCommand(command) || !seen.add(command)) return;
    candidates.add(CommandMctsAction(command));
  }

  bool _isFull(List<MctsAction> candidates) =>
      candidates.length >= candidateLimit;

  static bool _isTerminal(GameCommand command) {
    return command is EndTurnCommand || command is SubmitTurnCommand;
  }
}
