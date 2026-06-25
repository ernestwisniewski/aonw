import 'package:aonw_core/domain.dart';

class ScoreComebackTelemetryFixture {
  static const activePlayerId = 'player_1';
  static const leaderPlayerId = 'player_2';
  static int get turnLimit => GameLengthConfig.standard60.turnLimit!;
  static const scorePressureWindow = 5;

  const ScoreComebackTelemetryFixture();

  ScoreComebackTelemetryResult run() {
    final rows = <ScoreComebackTelemetryRow>[];
    final samples = <BalanceTelemetryTurnSample>[];
    const playerIds = [activePlayerId, leaderPlayerId];
    const scoreCalculator = EmpireScoreCalculator();

    for (var index = 0; index <= scorePressureWindow; index++) {
      final turn = turnLimit - scorePressureWindow + index;
      final scenario = _scenarioForIndex(index);
      final state = scenario.state;
      final activeScore = scoreCalculator.scoreFor(
        playerId: activePlayerId,
        state: state,
      );
      final leaderScore = scoreCalculator.scoreFor(
        playerId: leaderPlayerId,
        state: state,
      );
      final scores = scoreCalculator.scoresFor(
        playerIds: playerIds,
        state: state,
      );
      final objectiveActionByPlayerId =
          BalanceTelemetryObjectiveActionDiagnostics.scorePressureSamplesFor(
            state: state,
            playerIds: playerIds,
          );
      final objectiveAction = objectiveActionByPlayerId[activePlayerId];
      final outcome = const GameOutcomeDetector().evaluate(
        playerIds: playerIds,
        state: state,
        matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        turn: turn,
      );

      rows.add(
        ScoreComebackTelemetryRow(
          turn: turn,
          scenarioId: scenario.id,
          scenarioLabel: scenario.label,
          activeScore: activeScore.total,
          leaderScore: leaderScore.total,
          scoreGap: leaderScore.total - activeScore.total,
          advice: objectiveAction?.advice,
          target: objectiveAction?.target,
          outcome: outcome,
        ),
      );
      samples.add(
        BalanceTelemetryTurnSample(
          turn: turn,
          state: state,
          meaningfulCommandsByPlayerId: const {activePlayerId: 1},
          objectiveActionByPlayerId: objectiveActionByPlayerId,
          outcome: outcome.finished
              ? outcome
              : turn == turnLimit
              ? GameOutcome.score(
                  winnerPlayerId: leaderPlayerId,
                  scoreByPlayerId: scores,
                )
              : GameOutcome.ongoing,
        ),
      );
    }

    final milestoneGuardTurn = turnLimit + 1;
    final report = BalanceTelemetryAnalyzer(
      targets: BalanceTelemetryTuningTargets(
        firstTechnologyMaxTurn: milestoneGuardTurn,
        firstBuildingMaxTurn: milestoneGuardTurn,
        secondCityMaxTurn: milestoneGuardTurn,
        firstContactMaxTurn: milestoneGuardTurn,
        firstCombatMaxTurn: milestoneGuardTurn,
        maxDeadTurnStreak: turnLimit,
      ),
    ).analyze(playerIds: const [activePlayerId], samples: samples);

    return ScoreComebackTelemetryResult(
      rows: List.unmodifiable(rows),
      telemetry: report,
    );
  }

  _ScoreComebackScenario _scenarioForIndex(int index) {
    return switch (index) {
      0 || 1 => _productionGap,
      2 || 3 => _researchGap,
      _ => _economyGap,
    };
  }
}

class ScoreComebackTelemetryResult {
  const ScoreComebackTelemetryResult({
    required this.rows,
    required this.telemetry,
  });

  final List<ScoreComebackTelemetryRow> rows;
  final BalanceTelemetryReport telemetry;

  String toCsv() {
    return [
      ScoreComebackTelemetryRow.csvHeader.join(','),
      for (final row in rows) row.toCsvFields().map(_csv).join(','),
    ].join('\n');
  }
}

class ScoreComebackTelemetryRow {
  const ScoreComebackTelemetryRow({
    required this.turn,
    required this.scenarioId,
    required this.scenarioLabel,
    required this.activeScore,
    required this.leaderScore,
    required this.scoreGap,
    required this.advice,
    required this.target,
    required this.outcome,
  });

  static const csvHeader = [
    'turn',
    'scenario',
    'active_score',
    'leader_score',
    'score_gap',
    'advice',
    'target',
    'outcome',
  ];

  final int turn;
  final String scenarioId;
  final String scenarioLabel;
  final int activeScore;
  final int leaderScore;
  final int scoreGap;
  final GameObjectiveAdvice? advice;
  final BalanceTelemetryObjectiveActionTarget? target;
  final GameOutcome outcome;

  List<Object?> toCsvFields() {
    return [
      turn,
      scenarioId,
      activeScore,
      leaderScore,
      scoreGap,
      advice?.name,
      target?.name,
      outcome.finished ? outcome.condition.name : '',
    ];
  }
}

String _csv(Object? value) {
  final text = switch (value) {
    null => '',
    final String text => text,
    final Object value => value.toString(),
  };
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }
  return '"${text.replaceAll('"', '""')}"';
}

class _ScoreComebackScenario {
  const _ScoreComebackScenario({
    required this.id,
    required this.label,
    required this.state,
  });

  final String id;
  final String label;
  final PersistentGameState state;
}

const _productionGap = _ScoreComebackScenario(
  id: 'production_gap',
  label: 'Production gap',
  state: PersistentGameState(
    units: [],
    cities: [
      GameCity(
        id: 'score_active_city',
        ownerPlayerId: ScoreComebackTelemetryFixture.activePlayerId,
        name: 'Active',
        center: CityHex(col: 0, row: 0),
      ),
      GameCity(
        id: 'score_leader_city',
        ownerPlayerId: ScoreComebackTelemetryFixture.leaderPlayerId,
        name: 'Leader',
        center: CityHex(col: 5, row: 0),
        buildings: {
          CityBuildingType.granary,
          CityBuildingType.monument,
          CityBuildingType.marketplace,
        },
      ),
    ],
  ),
);

final _researchGap = _ScoreComebackScenario(
  id: 'research_gap',
  label: 'Research gap',
  state: PersistentGameState(
    units: [],
    cities: [
      const GameCity(
        id: 'score_active_city',
        ownerPlayerId: ScoreComebackTelemetryFixture.activePlayerId,
        name: 'Active',
        center: CityHex(col: 0, row: 0),
        productionQueue: CityProductionQueue.target(
          target: BuildingProductionTarget(CityBuildingType.granary),
          investedProduction: 0,
        ),
      ),
      const GameCity(
        id: 'score_leader_city',
        ownerPlayerId: ScoreComebackTelemetryFixture.leaderPlayerId,
        name: 'Leader',
        center: CityHex(col: 5, row: 0),
      ),
    ],
    research: ResearchState(
      players: {
        ScoreComebackTelemetryFixture.activePlayerId: PlayerResearchState(),
        ScoreComebackTelemetryFixture.leaderPlayerId: PlayerResearchState(
          unlockedTechnologyIds: {
            TechnologyId.agriculture,
            TechnologyId.writing,
          },
        ),
      },
    ),
  ),
);

const _economyGap = _ScoreComebackScenario(
  id: 'economy_gap',
  label: 'Economy gap',
  state: PersistentGameState(
    playerGold: {
      ScoreComebackTelemetryFixture.activePlayerId: 0,
      ScoreComebackTelemetryFixture.leaderPlayerId: 250,
    },
    units: [],
    cities: [
      GameCity(
        id: 'score_active_city',
        ownerPlayerId: ScoreComebackTelemetryFixture.activePlayerId,
        name: 'Active',
        center: CityHex(col: 0, row: 0),
      ),
      GameCity(
        id: 'score_leader_city',
        ownerPlayerId: ScoreComebackTelemetryFixture.leaderPlayerId,
        name: 'Leader',
        center: CityHex(col: 5, row: 0),
      ),
    ],
  ),
);
