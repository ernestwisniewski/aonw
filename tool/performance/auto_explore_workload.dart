part of 'map_workload.dart';

/// Plans automatic exploration across the complete reachable map.
///
/// Reachability indexing still covers the map, while exact fog evaluation may
/// stop at the first tie-break-preferred destination that reaches the proven
/// vision-score upper bound.
PerformanceCaseResult runAutoExploreWorkload({
  Iterable<int> scales = mapLookupScales,
  int timingSamples = 21,
}) {
  _validateTimingSamples(timingSamples);

  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  for (final scale in scales) {
    final result = _runAutoExploreScale(scale, timingSamples);
    stable['$scale'] = result.stable;
    observations['$scale'] = result.observations;
  }
  return PerformanceCaseResult(
    'map.auto-explore',
    {'sizes': stable},
    {'sizes': observations},
  );
}

_ScaleResult _runAutoExploreScale(int scale, int timingSamples) {
  final fixture = _AutoExploreFixture.forScale(scale);
  final counted = _executeCountedAutoExplore(fixture);
  _executeAutoExplore(fixture, fixture.traversalView());

  final samples = <Duration>[];
  for (var run = 0; run < timingSamples; run++) {
    final measured = measureSync(
      () => _executeAutoExplore(fixture, fixture.traversalView()),
    );
    samples.add(measured.elapsed);
    _verifyAutoExploreOutput(counted.output, measured.value);
  }

  return _ScaleResult(
    stable: {
      'scale': scale,
      'dimensions': {
        'cols': fixture.worldMap.cols,
        'rows': fixture.worldMap.rows,
      },
      'indexedTiles': fixture.worldMap.indexedTileCount,
      'growthModel': 'reachable-index-vision-bound-exit',
      'candidateEvaluations': counted.candidateEvaluations,
      ...counted.traversal.toJson(),
      'outputDigest': stableDigest(counted.output.normalized),
    },
    observations: {'autoExploreTiming': timingObservation(samples)},
  );
}

_CountedAutoExplore _executeCountedAutoExplore(_AutoExploreFixture fixture) {
  final traversal = _InstrumentedTraversalView(fixture.traversalView());
  final revealCalculator = _CountingFogRevealCalculator();
  final planned = _planAutoExplore(
    fixture,
    traversal,
    planner: ScoutAutoExplorePlanner(revealCalculator: revealCalculator),
  );
  final output = _executeAutoExplore(fixture, fixture.traversalView());
  _verifyAutoExploreOutput(planned, output);
  return _CountedAutoExplore(
    output: output,
    candidateEvaluations: revealCalculator.calls,
    traversal: traversal.snapshot,
  );
}

_AutoExploreOutput _executeAutoExplore(
  _AutoExploreFixture fixture,
  MapTraversalView traversal,
) {
  final result = const AutoExploreCommandResolver().resolve(
    state: AutoExploreCommandState(
      movement: MovementCommandState(
        units: [fixture.unit],
        cities: const [],
        fogOfWar: FogOfWarState.empty,
        diplomacy: DiplomacyState.empty,
        playerIds: const ['benchmark_player'],
      ),
      interaction: DomainActionState.empty,
    ),
    command: AutoExploreUnitCommand(fixture.unit.id),
    actorPlayerId: fixture.unit.ownerPlayerId,
    mapData: traversal,
    phase: AutoExploreCommandPhase.direct,
  );
  if (!result.accepted) {
    throw StateError('Auto-explore workload was rejected: ${result.reason}.');
  }
  final unit = result.units.firstWhere(
    (candidate) => candidate.id == fixture.unit.id,
  );
  final target = switch (unit.queuedPath) {
    final queued? => (col: queued.targetCol, row: queued.targetRow),
    null => switch (result.execution) {
      final execution? => (
        col: execution.destination.col,
        row: execution.destination.row,
      ),
      null => throw StateError('Auto-explore workload produced no route.'),
    },
  };
  return _AutoExploreOutput(
    unitId: unit.id,
    targetCol: target.col,
    targetRow: target.row,
  );
}

_AutoExploreOutput _planAutoExplore(
  _AutoExploreFixture fixture,
  MapTraversalView traversal, {
  ScoutAutoExplorePlanner planner = const ScoutAutoExplorePlanner(),
}) {
  final command = planner.commandFor(
    unit: fixture.unit,
    mapData: traversal,
    units: [fixture.unit],
    fogOfWar: FogOfWarState.empty,
    costResolver: const TerrainTraversalCostResolver(),
  );
  if (command == null) {
    throw StateError('Auto-explore workload found no destination.');
  }
  return _AutoExploreOutput.fromCommand(command);
}

void _verifyAutoExploreOutput(
  _AutoExploreOutput expected,
  _AutoExploreOutput actual,
) {
  if (stableDigest(expected.normalized) != stableDigest(actual.normalized)) {
    throw StateError(
      'Auto-explore workload produced a non-deterministic result.',
    );
  }
}

final class _AutoExploreFixture {
  const _AutoExploreFixture({required this.worldMap, required this.unit});

  factory _AutoExploreFixture.forScale(int scale) {
    return _AutoExploreFixture(
      worldMap: _openPlainsWorldMap(scale),
      unit: GameUnit.produced(
        id: 'benchmark_scout',
        ownerPlayerId: 'benchmark_player',
        type: GameUnitType.scout,
        col: _movementStart.col,
        row: _movementStart.row,
      ),
    );
  }

  final WorldMap worldMap;
  final GameUnit unit;

  MapTraversalView traversalView() {
    return worldMap;
  }
}

final class _AutoExploreOutput {
  const _AutoExploreOutput({
    required this.unitId,
    required this.targetCol,
    required this.targetRow,
  });

  factory _AutoExploreOutput.fromCommand(MoveUnitCommand command) {
    return _AutoExploreOutput(
      unitId: command.unitId,
      targetCol: command.targetCol,
      targetRow: command.targetRow,
    );
  }

  final String unitId;
  final int targetCol;
  final int targetRow;

  Map<String, Object?> get normalized => {
    'unitId': unitId,
    'target': {'col': targetCol, 'row': targetRow},
  };
}

final class _CountedAutoExplore {
  const _CountedAutoExplore({
    required this.output,
    required this.candidateEvaluations,
    required this.traversal,
  });

  final _AutoExploreOutput output;
  final int candidateEvaluations;
  final _TraversalSnapshot traversal;
}

final class _CountingFogRevealCalculator extends FogRevealCalculator {
  int calls = 0;

  @override
  Set<HexCoordinate> visibleHexesFor({
    required MapTileLookup mapData,
    required Iterable<FogRevealSource> sources,
  }) {
    calls++;
    return super.visibleHexesFor(mapData: mapData, sources: sources);
  }
}
