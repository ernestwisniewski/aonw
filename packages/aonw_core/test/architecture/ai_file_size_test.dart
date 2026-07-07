import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'large AI/core files cannot grow past their current refactor baseline',
    () {
      expect(_lineCountViolations(_largeFileBaseline), isEmpty);
    },
  );
}

List<String> _lineCountViolations(Map<String, int> baseline) {
  final violations = <String>[];
  for (final entry in baseline.entries) {
    final file = File(entry.key);
    final lineCount = file.readAsLinesSync().length;
    if (lineCount > entry.value) {
      violations.add(
        '${entry.key} has $lineCount lines; max is ${entry.value}',
      );
    }
  }
  return violations;
}

const _largeFileBaseline = <String, int>{
  'lib/ai/strategies/basic_strategy.dart': 86,
  'lib/ai/strategies/basic_strategy_founding_planner.dart': 401,
  'lib/ai/strategies/basic_strategy_founding_move_planner.dart': 405,
  'lib/ai/strategic/defensive_stance_planner.dart': 42,
  'lib/ai/strategic/defensive_stance_planning_engine.dart': 135,
  'lib/ai/strategic/defensive_stance_threat_profiles.dart': 282,
  'lib/ai/strategic/defensive_stance_policies.dart': 85,
  'lib/ai/strategic/defensive_stance_garrison_assignment.dart': 66,
  'lib/ai/mcts/strategy_aware_action_generator.dart': 254,
  'lib/ai/mcts/strategy_aware_defense_ranker.dart': 68,
  'lib/ai/mcts/strategy_aware_defense_early_ranker.dart': 197,
  'lib/ai/mcts/strategy_aware_defense_general_ranker.dart': 113,
  'lib/ai/mcts/strategy_aware_defense_garrison_ranker.dart': 149,
  'lib/ai/mcts/strategy_aware_defense_reserve_ranker.dart': 140,
  'lib/ai/mcts/strategy_aware_economy_ranker.dart': 79,
  'lib/ai/mcts/strategy_aware_economy_worker_ranker.dart': 79,
  'lib/ai/mcts/strategy_aware_economy_queue_ranker.dart': 42,
  'lib/ai/mcts/strategy_aware_economy_production_ranker.dart': 127,
  'lib/ai/mcts/strategy_aware_economy_production_inventory.dart': 37,
  'lib/ai/mcts/strategy_aware_economy_settler_escort.dart': 60,
  'lib/ai/mcts/strategy_aware_economy_settler_production.dart': 271,
  'lib/ai/mcts/mcts_action_generation_stats.dart': 106,
  'lib/ai/simulation/economy_simulation.dart': 321,
  'lib/ai/simulation/economy_simulation_command_applier.dart': 348,
  'lib/ai/simulation/economy_simulation_hostility_memory.dart': 88,
  'lib/ai/simulation/economy_simulation_setup.dart': 103,
  'lib/ai/simulation/economy_simulation_strategy_selector.dart': 143,
  'lib/ai/simulation/economy_simulation_telemetry.dart': 41,
  'lib/ai/simulation/economy_simulation_turn_row_factory.dart': 262,
  'lib/ai/production_scorer.dart': 551,
  'lib/ai/production_unit_scorer.dart': 49,
  'lib/ai/production_scoring_math.dart': 23,
  'lib/ai/production_scoring_cache.dart': 192,
  'lib/ai/production_yield_weights.dart': 50,
  'lib/ai/technology_branch_classifier.dart': 117,
  'lib/ai/technology_persona_scorer.dart': 185,
  'lib/ai/technology_score_snapshot.dart': 206,
  'lib/ai/technology_scorer.dart': 187,
  'lib/ai/technology_state_scorer.dart': 305,
  'lib/ai/mcts/mcts_strategy.dart': 229,
  'lib/ai/mcts/mcts_command_candidate_guard.dart': 172,
  'lib/ai/mcts/mcts_command_combat_scorer.dart': 284,
  'lib/ai/mcts/mcts_command_movement_scorer.dart': 50,
  'lib/ai/mcts/mcts_command_movement_settler_scorer.dart': 366,
  'lib/ai/mcts/mcts_command_movement_support_scorer.dart': 168,
  'lib/ai/mcts/mcts_command_production_scorer.dart': 35,
  'lib/ai/mcts/mcts_baseline_attack_command_policy.dart': 200,
  'lib/ai/mcts/mcts_baseline_command_merger.dart': 244,
  'lib/ai/mcts/mcts_baseline_movement_command_policy.dart': 224,
  'lib/ai/mcts/mcts_baseline_unit_command_policy.dart': 158,
  'lib/ai/mcts/mcts_command_reconciliation_rules.dart': 388,
  'lib/ai/mcts/mcts_command_validator.dart': 93,
  'lib/ai/mcts/mcts_command_reconciler.dart': 50,
  'lib/ai/mcts/mcts_evaluation_queries.dart': 194,
  'lib/ai/mcts/mcts_combat_candidate_collector.dart': 119,
  'lib/ai/mcts/mcts_founding_candidate_collector.dart': 214,
  'lib/ai/mcts/mcts_movement_candidate_collector.dart': 34,
  'lib/ai/mcts/mcts_production_candidate_collector.dart': 135,
  'lib/ai/mcts/mcts_simulated_combat_command_applier.dart': 393,
  'lib/ai/mcts/mcts_simulated_command_application.dart': 11,
  'lib/ai/mcts/mcts_simulated_economy_command_applier.dart': 301,
  'lib/ai/mcts/mcts_simulated_movement_command_applier.dart': 139,
  'lib/ai/mcts/mcts_simulated_state.dart': 291,
  'lib/ai/mcts/mcts_simulator.dart': 373,
  'lib/ai/mcts/mcts_worker_candidate_collector.dart': 56,
  'lib/game/domain/diplomacy/diplomacy_state.dart': 92,
  'lib/game/domain/diplomacy/diplomacy_state_model.dart': 507,
  'lib/game/domain/diplomacy/diplomacy_json_helpers.dart': 166,
  'lib/ai/telemetry/balance_runner.dart': 978,
  'lib/ai/telemetry/balance_runner_recovery_reports.dart': 494,
  'lib/game/domain/telemetry/balance_telemetry.dart': 752,
  'lib/game/domain/telemetry/balance_telemetry_objective_actions.dart': 203,
  'lib/game/domain/telemetry/balance_telemetry_player_activity.dart': 281,
  'lib/ai/mcts/mcts_evaluator.dart': 162,
  'lib/ai/mcts/mcts_action_generator.dart': 204,
  'lib/ai/mcts/strategy_aware_settler_ranker.dart': 51,
  'lib/ai/mcts/strategy_aware_settler_move_ranker.dart': 418,
  'lib/ai/mcts/strategy_aware_settler_policies.dart': 319,
  'lib/ai/mcts/strategy_aware_settler_support_rankers.dart': 214,
};
