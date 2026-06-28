part of 'basic_strategy.dart';

extension _BasicStrategyPipeline on BasicStrategy {
  AiTurnPlan _plan(GameView view, AiContext context) {
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

    final reservedGarrisonUnitIds = planning.timed(
      'garrisonReservations',
      () => garrisonReservationPlanner.plan(
        view,
        planningContext,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
    );
    if (reservedGarrisonUnitIds.isNotEmpty) {
      planning.notes.add(
        'reserved ${reservedGarrisonUnitIds.length} garrison unit',
      );
    }
    Set<String> usedWithGarrisonReservations() => {
      ...planning.usedUnitIds,
      ...reservedGarrisonUnitIds,
    };

    runPhase(
      'cityAssaults',
      () => cityAssaultPlanner.plan(
        view,
        planningContext,
        usedWithGarrisonReservations(),
      ),
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
        usedWithGarrisonReservations(),
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
      notesFor: (commands) => [
        'planned ${commands.length} reserve defense action',
      ],
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
        usedWithGarrisonReservations(),
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
          usedWithGarrisonReservations(),
          planning.reservedHexes,
        ),
      );
      planning.addExplorationPlan(exploration);
    }

    runPhase(
      'idleSweep',
      () => idleSweepPlanner.plan(
        view,
        planningContext,
        planning.usedUnitIds,
        planning.reservedHexes,
      ),
      notesFor: (commands) => ['swept ${commands.length} idle unit'],
    );

    return planning.finish(strategyId: 'basic');
  }
}
