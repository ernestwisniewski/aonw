import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/city_site_planner.dart';
import 'package:aonw_core/ai/strategic/defensive_stance_planner.dart';
import 'package:aonw_core/ai/strategic/economy_expectations.dart';
import 'package:aonw_core/ai/strategic/economy_health.dart';
import 'package:aonw_core/ai/strategic/frontier_clearing_planner.dart';
import 'package:aonw_core/ai/strategic/mode_selector.dart';
import 'package:aonw_core/ai/strategic/rival_snapshot.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategic/threat_assessor.dart';
import 'package:aonw_core/ai/strategic/war_goal_generator.dart';
import 'package:aonw_core/ai/strategic/worker_assignment_planner.dart';
import 'package:aonw_core/ai/technology_scorer.dart';

class StrategicPlanner {
  const StrategicPlanner({
    this.threatAssessor = const ThreatAssessor(),
    this.modeSelector = const ModeSelector(),
    this.citySitePlanner = const CitySitePlanner(),
    this.workerAssignmentPlanner = const WorkerAssignmentPlanner(),
    this.frontierClearingPlanner = const FrontierClearingPlanner(),
    this.warGoalGenerator = const WarGoalGenerator(),
    this.defensiveStancePlanner = const DefensiveStancePlanner(),
    this.technologyScorer = const AiTechnologyScorer(),
  });

  final ThreatAssessor threatAssessor;
  final ModeSelector modeSelector;
  final CitySitePlanner citySitePlanner;
  final WorkerAssignmentPlanner workerAssignmentPlanner;
  final FrontierClearingPlanner frontierClearingPlanner;
  final WarGoalGenerator warGoalGenerator;
  final DefensiveStancePlanner defensiveStancePlanner;
  final AiTechnologyScorer technologyScorer;

  StrategicPlan build({
    required GameView view,
    required AiContext context,
    AiEmpireAssessment? assessment,
    StrategicPlan? previousPlan,
    StrategicMode? previousMode,
  }) {
    final resolvedAssessment =
        assessment ?? AiEmpireAssessment.fromView(view, context);
    final expectations = EconomyExpectations.fromAssessment(resolvedAssessment);
    final checkpointPlan =
        previousPlan != null && view.turn - previousPlan.computedAtTurn >= 5
        ? previousPlan
        : null;
    final economyHealth = EconomyHealth.fromView(
      view: view,
      assessment: resolvedAssessment,
      expectations: checkpointPlan?.expectations ?? expectations,
      previous: checkpointPlan?.economyHealth,
    );
    final rivals = RivalSnapshot.fromView(view);
    final threats = threatAssessor.assess(
      assessment: resolvedAssessment,
      rivals: rivals,
      scoreRace: context.scoreRace,
    );
    final mode = modeSelector.select(
      assessment: resolvedAssessment,
      expectations: expectations,
      threats: threats,
      context: context,
      economyHealth: economyHealth,
      previousMode: previousPlan?.mode ?? previousMode,
    );
    final techPath = technologyScorer.rankTechnologies(
      view: view,
      context: context,
      assessment: resolvedAssessment,
      mode: mode,
    );
    final citySitePlan = citySitePlanner.compute(
      view: view,
      context: context,
      assessment: resolvedAssessment,
    );
    final workerPlan = workerAssignmentPlanner.compute(
      view: view,
      context: context,
      assessment: resolvedAssessment,
      mode: mode,
    );
    final defensePlan = defensiveStancePlanner.compute(
      view: view,
      context: context,
      assessment: resolvedAssessment,
      threats: threats,
      mode: mode,
    );
    final defensiveUnitIds = {
      for (final defense in defensePlan.defenses.values)
        ...defense.assignedUnitIds,
    };
    final frontierClearingPlan = frontierClearingPlanner.compute(
      view: view,
      context: context,
      assessment: resolvedAssessment,
      citySitePlan: citySitePlan,
      reservedUnitIds: defensiveUnitIds,
    );
    final frontierClearingUnitIds = frontierClearingPlan.assignments.keys
        .toSet();
    final warGoals = warGoalGenerator.generate(
      view: view,
      context: context,
      assessment: resolvedAssessment,
      threats: threats,
      mode: mode,
      reservedUnitIds: {...defensiveUnitIds, ...frontierClearingUnitIds},
      citySitePlan: citySitePlan,
    );

    return StrategicPlan(
      computedAtTurn: view.turn,
      mode: mode,
      expectations: expectations,
      economyHealth: economyHealth,
      rivalRanking: threats,
      techPath: List.unmodifiable(techPath.take(6)),
      citySiteRanking: [
        for (final candidate in citySitePlan.candidates) candidate.center,
      ],
      settlerAssignments: citySitePlan.settlerAssignments,
      workerAssignments: workerPlan.assignments,
      frontierClearingAssignments: frontierClearingPlan.assignments,
      warGoals: warGoals,
      defenses: defensePlan.defenses,
    );
  }
}
