import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/ai_turn_plan.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategic/strategic_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_artifact_defense_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_artifact_logistics_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_city_assault_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_city_specialization_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_combat_reactions_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_defensive_stance_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_exploration_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_founder_escort_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_founding_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_frontier_clearing_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_garrison_reservation_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_idle_sweep_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_last_military_reserve_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_military_pressure_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_planning_session.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_production_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_research_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_resource_trade_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_war_goal_wake_up_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_worker_planner.dart';
import 'package:aonw_core/ai/technology_scorer.dart';
import 'package:aonw_core/game/domain/command.dart';

part 'basic_strategy_pipeline.dart';

/// Casual-grade opponent.
///
/// Coordinates founding, combat, economy and artifact phases through focused
/// planners while keeping same-turn unit and hex reservations consistent.
class BasicStrategy implements AiStrategy {
  const BasicStrategy({
    this.artifactDefensePlanner = const BasicStrategyArtifactDefensePlanner(),
    this.artifactLogisticsPlanner =
        const BasicStrategyArtifactLogisticsPlanner(),
    this.cityAssaultPlanner = const BasicStrategyCityAssaultPlanner(),
    this.citySpecializationPlanner =
        const BasicStrategyCitySpecializationPlanner(),
    this.combatReactionsPlanner = const BasicStrategyCombatReactionsPlanner(),
    this.defensiveStancePlanner = const BasicStrategyDefensiveStancePlanner(),
    this.explorationPlanner = const BasicStrategyExplorationPlanner(),
    this.founderEscortPlanner = const BasicStrategyFounderEscortPlanner(),
    this.foundingPlanner = const BasicStrategyFoundingPlanner(),
    this.frontierClearingPlanner = const BasicStrategyFrontierClearingPlanner(),
    this.garrisonReservationPlanner =
        const BasicStrategyGarrisonReservationPlanner(),
    this.idleSweepPlanner = const BasicStrategyIdleSweepPlanner(),
    this.lastMilitaryReservePlanner =
        const BasicStrategyLastMilitaryReservePlanner(),
    this.militaryPressurePlanner = const BasicStrategyMilitaryPressurePlanner(),
    this.productionPlanner = const BasicStrategyProductionPlanner(),
    this.resourceTradePlanner = const BasicStrategyResourceTradePlanner(),
    this.technologyScorer = const AiTechnologyScorer(),
    this.warGoalWakeUpPlanner = const BasicStrategyWarGoalWakeUpPlanner(),
    this.workerPlanner = const BasicStrategyWorkerPlanner(),
  });

  final BasicStrategyArtifactDefensePlanner artifactDefensePlanner;
  final BasicStrategyArtifactLogisticsPlanner artifactLogisticsPlanner;
  final BasicStrategyCityAssaultPlanner cityAssaultPlanner;
  final BasicStrategyCitySpecializationPlanner citySpecializationPlanner;
  final BasicStrategyCombatReactionsPlanner combatReactionsPlanner;
  final BasicStrategyDefensiveStancePlanner defensiveStancePlanner;
  final BasicStrategyExplorationPlanner explorationPlanner;
  final BasicStrategyFounderEscortPlanner founderEscortPlanner;
  final BasicStrategyFoundingPlanner foundingPlanner;
  final BasicStrategyFrontierClearingPlanner frontierClearingPlanner;
  final BasicStrategyGarrisonReservationPlanner garrisonReservationPlanner;
  final BasicStrategyIdleSweepPlanner idleSweepPlanner;
  final BasicStrategyLastMilitaryReservePlanner lastMilitaryReservePlanner;
  final BasicStrategyMilitaryPressurePlanner militaryPressurePlanner;
  final BasicStrategyProductionPlanner productionPlanner;
  final BasicStrategyResourceTradePlanner resourceTradePlanner;
  final AiTechnologyScorer technologyScorer;
  final BasicStrategyWarGoalWakeUpPlanner warGoalWakeUpPlanner;
  final BasicStrategyWorkerPlanner workerPlanner;

  @override
  AiTurnPlan plan(GameView view, AiContext context) => _plan(view, context);
}
