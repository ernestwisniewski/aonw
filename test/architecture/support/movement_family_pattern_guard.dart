import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

const movementFamilyCommandTypes = {
  'MoveUnitCommand',
  'CancelUnitActionCommand',
  'AutoExploreUnitCommand',
  'AssignMerchantTradeRouteCommand',
  'MoveMerchantToCityCommand',
  'DetachTroopCommand',
};

const reviewedMovementFamilyPatternOccurrences = <String, Map<String, int>>{
  'lib/game/application/services/'
      'accepted_engine_command_interaction_source.dart': {
    'function:_movement::AssignMerchantTradeRouteCommand': 1,
    'function:_movement::AutoExploreUnitCommand': 1,
    'function:_movement::CancelUnitActionCommand': 1,
    'function:_movement::DetachTroopCommand': 1,
    'function:_movement::MoveMerchantToCityCommand': 1,
    'function:_movement::MoveUnitCommand': 1,
  },
  'lib/game/analysis/human_trace_analyzer.dart': {
    'class:HumanTraceAnalyzer/method:_isRepeatedAiCandidate::MoveUnitCommand':
        1,
  },
  'lib/game/analysis/human_trace_benchmark.dart': {
    'class:HumanTraceSimulationBenchmark/method:_repeatSummaryFor::'
            'MoveUnitCommand':
        1,
  },
  'lib/game/application/services/ai_turn_command_executor.dart': {
    'class:AiTurnCommandExecutor/method:describeCommand::'
            'AssignMerchantTradeRouteCommand':
        1,
    'class:AiTurnCommandExecutor/method:describeCommand::'
            'AutoExploreUnitCommand':
        1,
    'class:AiTurnCommandExecutor/method:describeCommand::'
            'CancelUnitActionCommand':
        1,
    'class:AiTurnCommandExecutor/method:describeCommand::DetachTroopCommand': 1,
    'class:AiTurnCommandExecutor/method:describeCommand::'
            'MoveMerchantToCityCommand':
        1,
    'class:AiTurnCommandExecutor/method:describeCommand::MoveUnitCommand': 1,
    'class:AiTurnCommandExecutor/method:executePlan::MoveUnitCommand': 1,
  },
  'lib/game/application/services/local_movement_engine_projection.dart': {
    'function:projectLocalMovementEngineResult::'
            'AssignMerchantTradeRouteCommand':
        1,
    'function:projectLocalMovementEngineResult::AutoExploreUnitCommand': 1,
    'function:projectLocalMovementEngineResult::CancelUnitActionCommand': 1,
    'function:projectLocalMovementEngineResult::DetachTroopCommand': 1,
    'function:projectLocalMovementEngineResult::MoveMerchantToCityCommand': 1,
    'function:projectLocalMovementEngineResult::MoveUnitCommand': 1,
  },
  'lib/game/application/services/replay_service.dart': {
    'class:ReplayStep/method:_inferActorPlayerId::'
            'AssignMerchantTradeRouteCommand':
        1,
    'class:ReplayStep/method:_inferActorPlayerId::AutoExploreUnitCommand': 1,
    'class:ReplayStep/method:_inferActorPlayerId::CancelUnitActionCommand': 1,
    'class:ReplayStep/method:_inferActorPlayerId::DetachTroopCommand': 1,
    'class:ReplayStep/method:_inferActorPlayerId::MoveMerchantToCityCommand': 1,
    'class:ReplayStep/method:_inferActorPlayerId::MoveUnitCommand': 1,
  },
  'lib/game/presentation/audio/game_sound_cue_mapper.dart': {
    'class:GameSoundCueMapper/method:forCommand::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/mcts_baseline_command_merger.dart': {
    'class:MctsBaselineCommandMerger/method:_commandDidNotChangeState::'
            'MoveUnitCommand':
        1,
    'class:MctsBaselineCommandMerger/method:withBaselineSupportCommands::'
            'MoveUnitCommand':
        3,
  },
  'packages/aonw_core/lib/ai/mcts/mcts_baseline_unit_command_policy.dart': {
    'class:MctsBaselineUnitCommandPolicy/method:baselinePriorityUnitIds::'
            'MoveUnitCommand':
        1,
    'class:MctsBaselineUnitCommandPolicy/method:canAppendBaselineUnitCommand::'
            'MoveUnitCommand':
        3,
  },
  'packages/aonw_core/lib/ai/mcts/mcts_command_candidate_guard.dart': {
    'function:isLegalMctsCommandCandidate::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/mcts_command_reconciliation_rules.dart': {
    'class:MctsCommandReconciliationRules/method:actingUnitId::'
            'CancelUnitActionCommand':
        1,
    'class:MctsCommandReconciliationRules/method:actingUnitId::MoveUnitCommand':
        1,
  },
  'packages/aonw_core/lib/ai/mcts/mcts_evaluator.dart': {
    'class:CommandSequenceEvaluator/method:_commandScore::'
            'AutoExploreUnitCommand':
        1,
    'class:CommandSequenceEvaluator/method:_commandScore::'
            'CancelUnitActionCommand':
        1,
    'class:CommandSequenceEvaluator/method:_commandScore::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/'
      'mcts_simulated_movement_command_applier.dart': {
    'class:MctsSimulatedMovementCommandApplier/method:applyUnitAction::'
            'CancelUnitActionCommand':
        1,
  },
  'packages/aonw_core/lib/ai/mcts/mcts_simulated_state.dart': {
    'class:SimulatedState/method:_applyCommand::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/strategy_aware_action_generator.dart': {
    'function:_rankCommand::MoveUnitCommand': 2,
  },
  'packages/aonw_core/lib/ai/mcts/'
      'strategy_aware_defense_early_ranker.dart': {
    'class:_EarlyCityDefenseRanker/method:rank::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/'
      'strategy_aware_defense_garrison_ranker.dart': {
    'class:_ReservedGarrisonRanker/method:rank::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/'
      'strategy_aware_defense_general_ranker.dart': {
    'class:_GeneralDefenseRanker/method:rank::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/'
      'strategy_aware_defense_reserve_ranker.dart': {
    'class:_LastMilitaryReserveRanker/method:rank::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/strategy_aware_economy_ranker.dart': {
    'class:_StrategicEconomyRanker/method:rank::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/strategy_aware_frontier_ranker.dart': {
    'function:rankFrontierClearingCommand::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/strategy_aware_opening_ranker.dart': {
    'function:rankOpeningSurvivalCommand::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/strategy_aware_ranking_queries.dart': {
    'function:unitIdForCommand::CancelUnitActionCommand': 1,
    'function:unitIdForCommand::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/'
      'strategy_aware_settler_move_ranker.dart': {
    'class:_StrategicSettlerRanker/method:rank::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/'
      'strategy_aware_settler_support_rankers.dart': {
    'class:_SettlerEscortRanker/method:rank::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/mcts/strategy_aware_war_ranker.dart': {
    'function:rankWarCommand::CancelUnitActionCommand': 1,
    'function:rankWarCommand::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/simulation/'
      'economy_simulation_command_stats.dart': {
    'class:EconomySimulationCommandStats/method:addApplied::'
            'AssignMerchantTradeRouteCommand':
        1,
    'class:EconomySimulationCommandStats/method:addApplied::'
            'AutoExploreUnitCommand':
        1,
    'class:EconomySimulationCommandStats/method:addApplied::'
            'CancelUnitActionCommand':
        1,
    'class:EconomySimulationCommandStats/method:addApplied::'
            'DetachTroopCommand':
        1,
    'class:EconomySimulationCommandStats/method:addApplied::'
            'MoveMerchantToCityCommand':
        1,
    'class:EconomySimulationCommandStats/method:addApplied::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/strategies/'
      'basic_strategy_idle_sweep_planner.dart': {
    'class:BasicStrategyIdleSweepPlanner/method:plan::MoveUnitCommand': 1,
  },
  'packages/aonw_core/lib/ai/strategies/'
      'basic_strategy_planning_session.dart': {
    'class:BasicStrategyCommandAnalysis/method:unitIdsUsedBy::'
            'CancelUnitActionCommand':
        1,
    'class:BasicStrategyCommandAnalysis/method:unitIdsUsedBy::MoveUnitCommand':
        1,
  },
  'packages/aonw_core/lib/ai/strategies/basic_strategy_worker_planner.dart': {
    'class:BasicStrategyWorkerPlanner/method:_reserveWorkerDestination::'
            'MoveUnitCommand':
        1,
  },
  'server/lib/src/multiplayer/server_command_reducer.dart': {
    'class:ServerCommandReducer/method:_applyCommand::'
            'AssignMerchantTradeRouteCommand':
        1,
    'class:ServerCommandReducer/method:_applyCommand::'
            'AutoExploreUnitCommand':
        1,
    'class:ServerCommandReducer/method:_applyCommand::'
            'CancelUnitActionCommand':
        1,
    'class:ServerCommandReducer/method:_applyCommand::DetachTroopCommand': 1,
    'class:ServerCommandReducer/method:_applyCommand::'
            'MoveMerchantToCityCommand':
        1,
    'class:ServerCommandReducer/method:_applyCommand::MoveUnitCommand': 1,
  },
};

Map<String, Map<String, int>> movementFamilyPatternOccurrencesByPath(
  Map<String, String> sources,
) {
  final occurrences = <String, Map<String, int>>{};
  final paths = sources.keys.toList()..sort();
  for (final path in paths) {
    final visitor = _MovementFamilyPatternVisitor();
    parseString(content: sources[path]!, path: path).unit.accept(visitor);
    if (visitor.occurrences.isNotEmpty) {
      occurrences[path] = visitor.sortedOccurrences();
    }
  }
  return occurrences;
}

Set<String> unreviewedMovementFamilyPatternPaths(Map<String, String> sources) {
  final actual = movementFamilyPatternOccurrencesByPath(sources);
  return {
    for (final path in {
      ...actual.keys,
      ...reviewedMovementFamilyPatternOccurrences.keys,
    })
      if (!_sameCounts(
        actual[path] ?? const {},
        reviewedMovementFamilyPatternOccurrences[path] ?? const {},
      ))
        path,
  };
}

bool _sameCounts(Map<String, int> left, Map<String, int> right) {
  return left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}

final class _MovementFamilyPatternVisitor extends RecursiveAstVisitor<void> {
  final Map<String, int> occurrences = {};
  final List<String> _roles = ['compilation-unit'];

  Map<String, int> sortedOccurrences() {
    final keys = occurrences.keys.toList()..sort();
    return {for (final key in keys) key: occurrences[key]!};
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _visitRole(
      'class:${node.namePart.typeName.lexeme}',
      () => super.visitClassDeclaration(node),
    );
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _visitRole(
      'mixin:${node.name.lexeme}',
      () => super.visitMixinDeclaration(node),
    );
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _visitRole(
      'extension:${node.name?.lexeme ?? '<unnamed>'}',
      () => super.visitExtensionDeclaration(node),
    );
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _visitRole(
      'enum:${node.namePart.typeName.lexeme}',
      () => super.visitEnumDeclaration(node),
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _visitNestedRole(
      'function:${node.name.lexeme}',
      () => super.visitFunctionDeclaration(node),
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _visitNestedRole(
      '${node.isGetter ? 'getter' : 'method'}:${node.name.lexeme}',
      () => super.visitMethodDeclaration(node),
    );
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitNestedRole(
      'constructor:${node.name?.lexeme ?? 'new'}',
      () => super.visitConstructorDeclaration(node),
    );
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    final type = node.type;
    if (type is NamedType) _record(type.name.lexeme);
    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    _record(node.type.name.lexeme);
    super.visitObjectPattern(node);
  }

  void _record(String type) {
    if (!movementFamilyCommandTypes.contains(type)) return;
    final key = '${_roles.last}::$type';
    occurrences[key] = (occurrences[key] ?? 0) + 1;
  }

  void _visitNestedRole(String role, void Function() visit) {
    final parent = _roles.last;
    _visitRole(parent == 'compilation-unit' ? role : '$parent/$role', visit);
  }

  void _visitRole(String role, void Function() visit) {
    _roles.add(role);
    visit();
    _roles.removeLast();
  }
}
