import 'package:aonw_core/domain.dart';

import 'measurement.dart';

const _defaultIterationCounts = [100, 1000, 10000];

PerformanceCaseResult runAiMctsWorkload({
  Iterable<int> iterationCounts = _defaultIterationCounts,
  int samplesPerCase = 21,
}) {
  final counts = iterationCounts.toList(growable: false);
  _validateInputs(counts, samplesPerCase);
  final stableBySize = <String, Object?>{};
  final observationsBySize = <String, Object?>{};
  for (final iterations in counts) {
    _measureSearch(iterations);
    final measurements = [
      for (var sample = 0; sample < samplesPerCase; sample += 1)
        _measureSearch(iterations),
    ];
    final stableSamples = [
      for (final measurement in measurements) measurement.value.stable,
    ];
    _requireStableSamples(stableSamples, iterations);
    stableBySize['$iterations'] = stableSamples.first;
    observationsBySize['$iterations'] = _observations(measurements);
  }
  return PerformanceCaseResult(
    'ai.mcts.iteration-search',
    {'iterationCounts': counts, 'planningDepth': 3, 'sizes': stableBySize},
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

Measured<_AiSearchSample> _measureSearch(int iterations) {
  final generator = _CountingActionGenerator();
  final mapData = MapData(cols: 1, rows: 1, tiles: const []);
  final mapView = mapData.indexedReadView();
  final search = MctsSearch(
    actionGenerator: generator,
    simulator: const TracingMctsSimulator(
      simulateOpponentPlans: false,
      simulateTurnEconomy: false,
    ),
    evaluator: const CommandSequenceEvaluator(),
    explorationConstant: 1.4,
  );
  final rootState = SimulatedState.fromView(
    _view(mapView),
    maxPlanningDepth: 3,
  );
  final context = _context(mapView);
  final measured = measureSync(
    () => search.search(
      rootState: rootState,
      context: context,
      budget: MctsBudget.iterations(iterations),
    ),
  );
  return Measured(
    _summarizeSearch(measured.value, generator),
    measured.elapsed,
  );
}

_AiSearchSample _summarizeSearch(
  MctsSearchResult result,
  _CountingActionGenerator generator,
) {
  final summary = MctsDebugSummary.fromResult(result);
  return _AiSearchSample(
    stable: {
      'bestActionsDigest': stableDigest([
        for (final action in result.bestActions) _actionJson(action),
      ]),
      'candidateCalls': generator.calls,
      'candidatesReturned': generator.candidatesReturned,
      'exploredNodes': summary.exploredNodes,
      'iterations': summary.iterations,
      'maxDepth': summary.maxDepth,
      'plannedActions': summary.plannedActions,
      'rootChildren': summary.rootChildren,
      'rootChildVisitsTotal': result.root.children.fold<int>(
        0,
        (total, child) => total + child.visits,
      ),
      'rootVisits': result.root.visits,
      'treeShapeDigest': stableDigest(_treeShapeJson(result.root)),
      'visitedRootChildren': result.root.children
          .where((child) => child.visits > 0)
          .length,
    },
    timings: result.timings,
    rootChildVisits: [for (final child in result.root.children) child.visits],
  );
}

Map<String, Object?> _observations(
  List<Measured<_AiSearchSample>> measurements,
) {
  return {
    'rootChildVisits': measurements.first.value.rootChildVisits,
    'total': timingObservation([
      for (final measurement in measurements) measurement.elapsed,
    ]),
    'selection': _phaseTiming(
      measurements,
      (timings) => timings.selectionElapsed,
    ),
    'expansion': _phaseTiming(
      measurements,
      (timings) => timings.expansionElapsed,
    ),
    'rollout': _phaseTiming(measurements, (timings) => timings.rolloutElapsed),
    'evaluation': _phaseTiming(
      measurements,
      (timings) => timings.evaluationElapsed,
    ),
    'backpropagation': _phaseTiming(
      measurements,
      (timings) => timings.backpropagationElapsed,
    ),
  };
}

Map<String, Object?> _phaseTiming(
  Iterable<Measured<_AiSearchSample>> measurements,
  Duration Function(MctsSearchTimings timings) select,
) {
  return timingObservation([
    for (final measurement in measurements) select(measurement.value.timings),
  ]);
}

void _requireStableSamples(List<Map<String, Object?>> samples, int iterations) {
  final expected = stableDigest(samples.first);
  if (samples.any((sample) => stableDigest(sample) != expected)) {
    throw StateError('MCTS workload is not deterministic at $iterations runs.');
  }
}

Map<String, Object?> _treeShapeJson(MctsNode node) {
  return {
    'action': node.action == null ? null : _actionJson(node.action!),
    'children': [for (final child in node.children) _treeShapeJson(child)],
  };
}

Object _actionJson(MctsAction action) {
  final command = action.toCommand();
  return command == null
      ? const {'type': 'EndPlanning'}
      : GameCommandSerializer.toJson(command);
}

AiContext _context(MapReadView mapView) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapView,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
  );
}

GameView _view(MapReadView mapView) {
  const state = PersistentGameState();
  final engineSnapshot = CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: 'player_1', name: 'player_1', colorValue: 0),
      ],
    ),
    session: MatchSessionState.snapshot(
      gameMode: GameMode.hotSeat,
      turnStatesByPlayerId: const {'player_1': PlayerTurnState.active},
    ),
    metadata: GameSnapshotMetadata(
      id: 'performance-ai-mcts',
      schemaVersion: 3,
      name: 'Performance AI MCTS',
      world: WorldReference(
        name: mapView.mapName ?? 'performance',
        source: MapSource.asset,
      ),
      savedAtUtc: DateTime.utc(1970),
      camera: GameSnapshotCamera.zero,
    ),
  );
  return GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapView,
    ruleset: GameRuleset.defaults,
    engineSnapshot: engineSnapshot,
  );
}

final class _CountingActionGenerator implements MctsActionGenerator {
  int calls = 0;
  int candidatesReturned = 0;

  @override
  List<MctsAction> candidatesFor(SimulatedState state, AiContext context) {
    calls += 1;
    if (state.isTerminal) return const [];
    final depth = state.depth;
    final candidates = <MctsAction>[
      CommandMctsAction(
        SelectTechnologyCommand('player_1', TechnologyId.values[depth * 2]),
      ),
      CommandMctsAction(
        SelectTechnologyCommand('player_1', TechnologyId.values[depth * 2 + 1]),
      ),
      const EndPlanningAction(),
    ];
    candidatesReturned += candidates.length;
    return candidates;
  }
}

final class _AiSearchSample {
  const _AiSearchSample({
    required this.stable,
    required this.timings,
    required this.rootChildVisits,
  });

  final Map<String, Object?> stable;
  final MctsSearchTimings timings;
  final List<int> rootChildVisits;
}
