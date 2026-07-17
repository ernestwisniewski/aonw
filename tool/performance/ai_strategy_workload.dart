import 'package:aonw_core/domain.dart';

import 'measurement.dart';

const _defaultIterationCounts = [100, 1000, 10000];

PerformanceCaseResult runAiStrategyWorkload({
  Iterable<int> iterationCounts = _defaultIterationCounts,
  int samplesPerCase = 21,
}) {
  final counts = iterationCounts.toList(growable: false);
  _validateInputs(counts, samplesPerCase);
  final stableBySize = <String, Object?>{};
  final observationsBySize = <String, Object?>{};
  for (final iterations in counts) {
    _measurePlan(iterations);
    final measurements = [
      for (var sample = 0; sample < samplesPerCase; sample += 1)
        _measurePlan(iterations),
    ];
    final stableSamples = [
      for (final measurement in measurements) measurement.value,
    ];
    _requireStableSamples(stableSamples, iterations);
    stableBySize['$iterations'] = stableSamples.first;
    observationsBySize['$iterations'] = {
      'planTiming': timingObservation([
        for (final measurement in measurements) measurement.elapsed,
      ]),
    };
  }
  return PerformanceCaseResult(
    'ai.mcts.strategy-aware-plan',
    {
      'iterationCounts': counts,
      'candidateLimit': 8,
      'planningDepth': 4,
      'simulateOpponentResponses': false,
      'simulateTurnEconomy': false,
      'sizes': stableBySize,
    },
    {
      'portableTimingGate': false,
      'samplesPerCase': samplesPerCase,
      'sizes': observationsBySize,
    },
  );
}

void _validateInputs(List<int> counts, int samplesPerCase) {
  if (counts.isEmpty || counts.any((count) => count <= 0)) {
    throw ArgumentError.value(
      counts,
      'iterationCounts',
      'Must contain positive values.',
    );
  }
  if (counts.toSet().length != counts.length) {
    throw ArgumentError.value(counts, 'iterationCounts', 'Must be unique.');
  }
  if (samplesPerCase <= 0) {
    throw ArgumentError.value(
      samplesPerCase,
      'samplesPerCase',
      'Must be positive.',
    );
  }
}

Measured<Map<String, Object?>> _measurePlan(int iterations) {
  final fixture = _StrategyFixture.create();
  final strategy = MctsStrategy(
    config: MctsConfig(
      wallClockBudget: Duration.zero,
      iterationBudget: iterations,
      minIterations: iterations,
      maxPlanningDepth: 4,
      candidateLimit: 8,
      sourcePlanDepthLimit: 4,
      simulateOpponentResponses: false,
      simulateTurnEconomy: false,
    ),
  );
  final measured = measureSync(
    () => strategy.plan(fixture.view, fixture.context),
  );
  return Measured(_stablePlan(measured.value), measured.elapsed);
}

Map<String, Object?> _stablePlan(AiTurnPlan plan) {
  final metrics = plan.debug?.metrics;
  if (plan.debug?.strategyId != 'mcts' || metrics == null) {
    throw StateError('Strategy-aware workload bypassed MCTS.');
  }
  return {
    'candidateCalls': _metricInt(metrics, 'mcts.candidateCalls'),
    'commandDigest': stableDigest([
      for (final command in plan.commands)
        GameCommandSerializer.toJson(command),
    ]),
    'commands': plan.commands.length,
    'exploredNodes': _metricInt(metrics, 'mcts.exploredNodes'),
    'iterations': _metricInt(metrics, 'mcts.iterations'),
    'maxDepth': _metricInt(metrics, 'mcts.maxDepth'),
    'plannedActions': _metricInt(metrics, 'mcts.plannedActions'),
    'rawCandidates': _metricInt(metrics, 'mcts.rawCandidates'),
    'rootChildren': _metricInt(metrics, 'mcts.rootChildren'),
    'selectedCandidates': _metricInt(metrics, 'mcts.selectedCandidates'),
    'sourcePlanCalls': _metricInt(metrics, 'mcts.sourcePlanCalls'),
    'sourcePlanCommands': _metricInt(metrics, 'mcts.sourcePlanCommands'),
    'sourcePlanSkipped': _metricInt(metrics, 'mcts.sourcePlanSkipped'),
  };
}

int _metricInt(Map<String, Object?> metrics, String name) {
  final value = metrics[name];
  if (value is int) return value;
  throw StateError('MCTS metric $name is missing or is not an int.');
}

void _requireStableSamples(List<Map<String, Object?>> samples, int iterations) {
  final expected = stableDigest(samples.first);
  if (samples.any((sample) => stableDigest(sample) != expected)) {
    throw StateError(
      'Strategy-aware MCTS is not deterministic at $iterations iterations.',
    );
  }
}

final class _StrategyFixture {
  const _StrategyFixture({required this.view, required this.context});

  factory _StrategyFixture.create() {
    final mapData = _mapData();
    final mapView = mapData.indexedReadView();
    return _StrategyFixture(
      view: _view(mapView),
      context: AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapView,
        turn: 5,
        rng: AiRng.fromTurn(turn: 5, playerId: _playerId, baseSeed: 77),
      ),
    );
  }

  final GameView view;
  final AiContext context;
}

GameView _view(MapReadView mapView) => GameView.fromPersistentState(
  PersistentGameState.snapshot(
    playerGold: const {_playerId: 12, _enemyId: 8},
    units: [
      GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ),
      GameUnit(
        id: 'worker_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 1,
      ),
      GameUnit.produced(
        id: 'settler_2',
        ownerPlayerId: _enemyId,
        type: GameUnitType.settler,
        col: 1,
        row: 0,
      ),
      GameUnit.produced(
        id: 'warrior_2',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        col: 2,
        row: 1,
      ),
    ],
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
        population: 3,
      ),
      GameCity(
        id: 'city_2',
        ownerPlayerId: _enemyId,
        name: 'Outpost',
        center: CityHex(col: 2, row: 1),
        population: 2,
      ),
    ],
    research: ResearchState(
      players: {
        _playerId: PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.agriculture},
          activeTechnologyId: TechnologyId.mining,
          progressByTechnologyId: {TechnologyId.mining: 3},
        ),
        _enemyId: PlayerResearchState(
          activeTechnologyId: TechnologyId.agriculture,
        ),
      },
    ),
    fogOfWar: _visibleFog(mapView),
  ),
  forPlayerId: _playerId,
  turn: 5,
  mapData: mapView,
  ruleset: GameRuleset.defaults,
);

FogOfWarState _visibleFog(MapReadView mapView) => FogOfWarState(
  players: {
    _playerId: PlayerFogOfWar(
      playerId: _playerId,
      visibleHexes: {
        for (final tile in mapView.tileViews)
          HexCoordinate(col: tile.col, row: tile.row),
      },
    ),
  },
);

MapData _mapData() => MapData(
  cols: 4,
  rows: 3,
  tiles: [
    for (var col = 0; col < 4; col++)
      for (var row = 0; row < 3; row++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

const _playerId = 'player_1';
const _enemyId = 'player_2';
