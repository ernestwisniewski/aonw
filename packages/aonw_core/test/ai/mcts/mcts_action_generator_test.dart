import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

part 'support/mcts_action_generator_fixtures.dart';
part 'support/mcts_basic_filtering_scenarios.dart';
part 'support/mcts_basic_economy_scenarios.dart';
part 'support/mcts_basic_combat_scenarios.dart';
part 'support/mcts_basic_founding_scenarios.dart';
part 'support/mcts_basic_limit_scenarios.dart';
part 'support/mcts_strategy_war_goal_scenarios.dart';
part 'support/mcts_strategy_settler_discovery_scenarios.dart';
part 'support/mcts_strategy_settler_discovery_assignment_scenarios.dart';
part 'support/mcts_strategy_settler_discovery_danger_crowding_scenarios.dart';
part 'support/mcts_strategy_settler_safety_scenarios.dart';
part 'support/mcts_strategy_settler_safety_escort_attacks_scenarios.dart';
part 'support/mcts_strategy_settler_safety_frontier_threat_scenarios.dart';
part 'support/mcts_strategy_opening_scenarios.dart';
part 'support/mcts_strategy_garrison_scenarios.dart';
part 'support/mcts_strategy_production_scenarios.dart';
part 'support/mcts_strategy_production_opening_reserves_scenarios.dart';
part 'support/mcts_strategy_production_expansion_defense_scenarios.dart';
part 'support/mcts_strategy_production_frontier_pressure_scenarios.dart';
part 'support/mcts_strategy_limit_scenarios.dart';

void main() {
  group('BasicPlanMctsActionGenerator', () {
    _registerMctsBasicFilteringScenarios();
    _registerMctsBasicEconomyScenarios();
    _registerMctsBasicCombatScenarios();
    _registerMctsBasicFoundingScenarios();
    _registerMctsBasicLimitScenarios();
  });
  group('StrategyAwareMctsActionGenerator', () {
    _registerMctsStrategyWarGoalScenarios();
    _registerMctsStrategySettlerDiscoveryScenarios();
    _registerMctsStrategySettlerSafetyScenarios();
    _registerMctsStrategyOpeningScenarios();
    _registerMctsStrategyGarrisonScenarios();
    _registerMctsStrategyProductionScenarios();
    _registerMctsStrategyLimitScenarios();
  });
}
