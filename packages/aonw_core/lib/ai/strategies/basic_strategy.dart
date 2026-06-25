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
  final BasicStrategyLastMilitaryReservePlanner lastMilitaryReservePlanner;
  final BasicStrategyMilitaryPressurePlanner militaryPressurePlanner;
  final BasicStrategyProductionPlanner productionPlanner;
  final BasicStrategyResourceTradePlanner resourceTradePlanner;
  final AiTechnologyScorer technologyScorer;
  final BasicStrategyWarGoalWakeUpPlanner warGoalWakeUpPlanner;
  final BasicStrategyWorkerPlanner workerPlanner;

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    final planning = BasicStrategyPlanningSession(view: view);
    final assessment = planning.timed(
      'assessment',
      () => AiEmpireAssessment.fromView(view, context),
    );
    final StrategicPlan strategicPlan =
        context.strategicPlan ??
        planning.timed(
          'strategicPlan',
          () => const StrategicPlanner().build(
            view: view,
            context: context,
            assessment: assessment,
          ),
        );
    final planningContext = context.strategicPlan == null
        ? context.copyWith(strategicPlan: strategicPlan)
        : context;
    final researchPlanner = BasicStrategyResearchPlanner(
      technologyScorer: technologyScorer,
    );
    planning.notes.add('strategic mode ${strategicPlan.mode.name}');
    List<GameCommand> runPhase(
      String phase,
      List<GameCommand> Function() action, {
      Iterable<String> additionalUsedUnitIds = const [],
      Iterable<String> Function(List<GameCommand> commands)? notesFor,
    }) {
      return planning.runCommandPhase(
        phase,
        action,
        additionalUsedUnitIds: additionalUsedUnitIds,
        notesFor: notesFor,
      );
    }

    runPhase(
      'warGoalWakeUps',
      () => warGoalWakeUpPlanner.plan(view, strategicPlan),
      notesFor: (commands) => ['woke ${commands.length} fortified war unit'],
    );

    runPhase(
      'foundings',
      () => foundingPlanner.plan(view, planningContext, assessment),
      additionalUsedUnitIds: BasicStrategyCommandAnalysis.founderUnitIds(view),
      notesFor: (commands) {
        final founded = commands.whereType<FoundCityCommand>().length;
        final relocated = commands.whereType<MoveUnitCommand>().length;
        return [
          if (founded > 0) 'founded $founded city',
          if (relocated > 0) 'relocated $relocated founder',
        ];
      },
    );

    runPhase(
      'founderEscorts',
      () => founderEscortPlanner.plan(
        view,
        planningContext,
        assessment,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
      notesFor: (commands) => [
        'planned ${commands.length} founder escort action',
      ],
    );

    runPhase(
      'artifacts',
      () => artifactLogisticsPlanner.plan(
        view,
        planningContext,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
      notesFor: (commands) => ['planned ${commands.length} artifact action'],
    );

    runPhase(
      'cityAssaults',
      () =>
          cityAssaultPlanner.plan(view, planningContext, planning.usedUnitIds),
      notesFor: (commands) => ['planned ${commands.length} city assault'],
    );
    final combat = runPhase(
      'combat',
      () => combatReactionsPlanner.plan(
        view,
        planningContext,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
      notesFor: (commands) => ['planned ${commands.length} combat reaction'],
    );

    runPhase(
      'defenses',
      () => defensiveStancePlanner.plan(
        view,
        planningContext,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
      notesFor: (commands) => ['planned ${commands.length} defensive action'],
    );

    runPhase(
      'artifactDefense',
      () => artifactDefensePlanner.plan(
        view,
        planningContext,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
      notesFor: (commands) => [
        'planned ${commands.length} artifact defense action',
      ],
    );

    runPhase(
      'frontierClearing',
      () => frontierClearingPlanner.plan(
        view,
        planningContext,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
      notesFor: (commands) => [
        'planned ${commands.length} frontier clearing action',
      ],
    );

    runPhase(
      'militaryReserve',
      () => lastMilitaryReservePlanner.plan(
        view,
        planningContext,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
      notesFor: (_) => ['reserved last military unit'],
    );

    final research = runPhase(
      'research',
      () => researchPlanner.plan(view, planningContext, assessment),
      notesFor: (commands) => ['selected ${commands.length} research target'],
    );

    runPhase(
      'specializations',
      () => citySpecializationPlanner.plan(view, planningContext),
      notesFor: (commands) => [
        'selected ${commands.length} city specialization',
      ],
    );

    runPhase(
      'resourceTrades',
      () => resourceTradePlanner.plan(view),
      notesFor: (commands) => ['opened ${commands.length} resource trade'],
    );

    runPhase(
      'production',
      () => productionPlanner.plan(
        view,
        planningContext,
        assessment,
        hasPlannedResearch: research.isNotEmpty,
      ),
      notesFor: (commands) => ['started ${commands.length} production queue'],
    );

    runPhase(
      'workerActions',
      () => workerPlanner.plan(
        view,
        planningContext,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
      notesFor: (commands) => ['planned ${commands.length} worker action'],
    );

    runPhase(
      'militaryPressure',
      () => militaryPressurePlanner.plan(
        view,
        planningContext,
        assessment,
        planning.usedUnitIds,
        planning.reservedHexes,
        assignedOnly: combat.isNotEmpty,
      ),
      notesFor: (commands) => ['planned ${commands.length} pressure move'],
    );

    if (combat.isEmpty) {
      final exploration = planning.timed(
        'exploration',
        () => explorationPlanner.plan(
          view,
          planningContext,
          planning.usedUnitIds,
          planning.reservedHexes,
        ),
      );
      planning.addExplorationPlan(exploration);
    }

    return planning.finish(strategyId: 'basic');
  }
}
