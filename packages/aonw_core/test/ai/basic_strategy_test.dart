import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'support/basic_strategy_fixtures.dart';
part 'support/basic_strategy_settler_safety_fixtures.dart';
part 'support/basic_strategy_artifact_scenarios.dart';
part 'support/basic_strategy_opening_founding_scenarios.dart';
part 'support/basic_strategy_expansion_founding_scenarios.dart';
part 'support/basic_strategy_settler_safety_scenarios.dart';
part 'support/basic_strategy_settler_safety_movement_waiting_scenarios.dart';
part 'support/basic_strategy_settler_safety_escort_discovery_scenarios.dart';
part 'support/basic_strategy_settler_safety_blocker_founding_scenarios.dart';
part 'support/basic_strategy_research_scenarios.dart';
part 'support/basic_strategy_opening_production_scenarios.dart';
part 'support/basic_strategy_opening_production_defense_expansion_scenarios.dart';
part 'support/basic_strategy_opening_production_personas_civilizations_scenarios.dart';
part 'support/basic_strategy_opening_production_late_opening_scenarios.dart';
part 'support/basic_strategy_economy_production_scenarios.dart';
part 'support/basic_strategy_economy_production_defense_projects_scenarios.dart';
part 'support/basic_strategy_economy_production_expansion_recovery_scenarios.dart';
part 'support/basic_strategy_economy_production_queue_replacement_scenarios.dart';
part 'support/basic_strategy_worker_scenarios.dart';
part 'support/basic_strategy_combat_scenarios.dart';
part 'support/basic_strategy_combat_risk_scenarios.dart';
part 'support/basic_strategy_combat_target_selection_scenarios.dart';
part 'support/basic_strategy_military_pressure_scenarios.dart';
part 'support/basic_strategy_military_pressure_movement_scenarios.dart';
part 'support/basic_strategy_military_pressure_war_goal_scenarios.dart';
part 'support/basic_strategy_military_pressure_city_pressure_scenarios.dart';
part 'support/basic_strategy_garrison_scenarios.dart';
part 'support/basic_strategy_garrison_assignment_scenarios.dart';
part 'support/basic_strategy_garrison_pressure_determinism_scenarios.dart';

void main() {
  group('BasicStrategy', () {
    _registerBasicStrategyArtifactScenarios();
    _registerBasicStrategyOpeningFoundingScenarios();
    _registerBasicStrategyExpansionFoundingScenarios();
    _registerBasicStrategySettlerSafetyScenarios();
    _registerBasicStrategyResearchScenarios();
    _registerBasicStrategyOpeningProductionScenarios();
    _registerBasicStrategyEconomyProductionScenarios();
    _registerBasicStrategyWorkerScenarios();
    _registerBasicStrategyCombatScenarios();
    _registerBasicStrategyMilitaryPressureScenarios();
    _registerBasicStrategyGarrisonScenarios();
  });
}
