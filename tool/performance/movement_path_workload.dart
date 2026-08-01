part of 'map_workload.dart';

const _movementStart = (col: 4, row: 4);
const _movementTarget = (col: 7, row: 4);

/// Plans the same fixed-distance path through growing canonical maps.
///
/// The stable counters come from an instrumented traversal cache. Raw timing
/// samples use the production zero-copy WorldMap view without instrumentation.
PerformanceCaseResult runMovementPathWorkload({
  Iterable<int> scales = mapLookupScales,
  int timingSamples = 21,
}) {
  _validateTimingSamples(timingSamples);

  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  for (final scale in scales) {
    final result = _runMovementPathScale(scale, timingSamples);
    stable['$scale'] = result.stable;
    observations['$scale'] = result.observations;
  }
  return PerformanceCaseResult(
    'map.movement-path',
    {'sizes': stable},
    {'sizes': observations},
  );
}

_ScaleResult _runMovementPathScale(int scale, int timingSamples) {
  final fixture = _MovementPathFixture.forScale(scale);
  final counted = _executeCountedMovementPath(fixture);
  _executeMovementPath(fixture, fixture.traversalView());

  final samples = <Duration>[];
  for (var run = 0; run < timingSamples; run++) {
    final measured = measureSync(
      () => _executeMovementPath(fixture, fixture.traversalView()),
    );
    samples.add(measured.elapsed);
    _verifyMovementPathOutput(counted.output, measured.value);
  }

  return _ScaleResult(
    stable: {
      'scale': scale,
      'dimensions': {
        'cols': fixture.worldMap.cols,
        'rows': fixture.worldMap.rows,
      },
      'indexedTiles': fixture.worldMap.indexedTileCount,
      'targetDistance': _movementTarget.col - _movementStart.col,
      'pathSteps': counted.output.steps.length,
      'totalCost': counted.output.totalCost,
      ...counted.traversal.toJson(),
      'outputDigest': stableDigest(counted.output.normalized),
    },
    observations: {'movementPathTiming': timingObservation(samples)},
  );
}

_CountedMovementPath _executeCountedMovementPath(_MovementPathFixture fixture) {
  final traversal = _InstrumentedTraversalView(fixture.traversalView());
  final output = _executeMovementPath(fixture, traversal);
  return _CountedMovementPath(output: output, traversal: traversal.snapshot);
}

_MovementPathOutput _executeMovementPath(
  _MovementPathFixture fixture,
  MapTraversalView traversal,
) {
  final target = traversal.tileAt(_movementTarget.col, _movementTarget.row);
  if (target == null) throw StateError('Movement target tile is missing.');
  final plan = UnitMovementPathfinder(
    mapData: traversal,
    units: [fixture.unit],
  ).plan(unit: fixture.unit, targetTile: target);
  if (plan == null) throw StateError('Movement workload found no path.');
  return _MovementPathOutput.fromPlan(plan);
}

void _verifyMovementPathOutput(
  _MovementPathOutput expected,
  _MovementPathOutput actual,
) {
  if (stableDigest(expected.normalized) != stableDigest(actual.normalized)) {
    throw StateError(
      'Movement path workload produced a non-deterministic result.',
    );
  }
}

final class _MovementPathFixture {
  const _MovementPathFixture({required this.worldMap, required this.unit});

  factory _MovementPathFixture.forScale(int scale) {
    final worldMap = _openPlainsWorldMap(scale);
    return _MovementPathFixture(
      worldMap: worldMap,
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

final class _MovementPathOutput {
  const _MovementPathOutput({required this.totalCost, required this.steps});

  factory _MovementPathOutput.fromPlan(UnitMovementPlan plan) {
    return _MovementPathOutput(
      totalCost: plan.totalCost,
      steps: [
        for (final step in plan.steps)
          {
            'col': step.col,
            'row': step.row,
            'enterCost': step.enterCost,
            'cumulativeCost': step.cumulativeCost,
          },
      ],
    );
  }

  final int totalCost;
  final List<Map<String, int>> steps;

  Map<String, Object?> get normalized => {
    'unitId': 'benchmark_scout',
    'target': {'col': _movementTarget.col, 'row': _movementTarget.row},
    'totalCost': totalCost,
    'steps': steps,
  };
}

final class _CountedMovementPath {
  const _CountedMovementPath({required this.output, required this.traversal});

  final _MovementPathOutput output;
  final _TraversalSnapshot traversal;
}

final class _InstrumentedTraversalView implements MapTraversalView {
  _InstrumentedTraversalView(this._delegate);

  final MapTraversalView _delegate;
  final Map<String, MapTileView?> _tilesByCoordinate = {};
  int _lookupCalls = 0;
  int _lookupHits = 0;
  int _uniqueLookupCoordinates = 0;
  int _uniqueTileHits = 0;

  @override
  int get cols => _delegate.cols;

  @override
  int get rows => _delegate.rows;

  @override
  MapTileView? tileAt(int col, int row) {
    _lookupCalls++;
    final key = '$col:$row';
    if (_tilesByCoordinate.containsKey(key)) {
      final cached = _tilesByCoordinate[key];
      if (cached != null) _lookupHits++;
      return cached;
    }

    _uniqueLookupCoordinates++;
    final tile = _delegate.tileAt(col, row);
    _tilesByCoordinate[key] = tile;
    if (tile != null) {
      _lookupHits++;
      _uniqueTileHits++;
    }
    return tile;
  }

  _TraversalSnapshot get snapshot => _TraversalSnapshot(
    lookupCalls: _lookupCalls,
    lookupHits: _lookupHits,
    uniqueLookupCoordinates: _uniqueLookupCoordinates,
    uniqueTileHits: _uniqueTileHits,
  );
}

final class _TraversalSnapshot {
  const _TraversalSnapshot({
    required this.lookupCalls,
    required this.lookupHits,
    required this.uniqueLookupCoordinates,
    required this.uniqueTileHits,
  });

  final int lookupCalls;
  final int lookupHits;
  final int uniqueLookupCoordinates;
  final int uniqueTileHits;

  Map<String, Object?> toJson() => {
    'tileLookupCalls': lookupCalls,
    'tileLookupHits': lookupHits,
    'uniqueTileHits': uniqueTileHits,
    'uniqueTileLookupCoordinates': uniqueLookupCoordinates,
  };
}

WorldMap _openPlainsWorldMap(int scale) {
  final dimensions = _dimensionsFor(scale);
  return WorldMap(
    cols: dimensions.cols,
    rows: dimensions.rows,
    tiles: [
      for (var index = 0; index < scale; index++)
        WorldTile.at(
          coordinate: HexCoord(
            col: index % dimensions.cols,
            row: index ~/ dimensions.cols,
          ),
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
