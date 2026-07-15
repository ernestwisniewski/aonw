part of 'map_workload.dart';

const _fogRevealRange = 3;

/// Measures bounded fog traversal through the canonical WorldMap read view.
///
/// Every canonical scale uses one source with the same range away from map
/// edges. Stable lookup metrics must therefore stay constant as the total map
/// grows. Structural instrumentation runs outside the stopwatch; wall-clock
/// samples cover the raw view and calculator and remain diagnostic only.
PerformanceCaseResult runFogRevealWorkload({
  Iterable<int> scales = mapLookupScales,
  int timingSamples = 21,
}) {
  _validateTimingSamples(timingSamples);

  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  for (final scale in scales) {
    final result = _runFogRevealScale(scale, timingSamples);
    stable['$scale'] = result.stable;
    observations['$scale'] = result.observations;
  }

  return PerformanceCaseResult(
    'map.fog-reveal',
    {'sizes': stable},
    {'sizes': observations},
  );
}

_ScaleResult _runFogRevealScale(int scale, int timingSamples) {
  final fixture = _FogRevealFixture.forScale(scale);
  final stableResult = _executeCountedFogReveal(fixture);
  _visibleHexesFor(fixture.mapTiles, fixture.source);

  final samples = <Duration>[];
  for (var run = 0; run < timingSamples; run++) {
    final measured = measureSync(
      () => _visibleHexesFor(fixture.mapTiles, fixture.source),
    );
    samples.add(measured.elapsed);
    _verifyFogRevealOutput(stableResult, measured.value, fixture.source);
  }

  return _ScaleResult(
    stable: {
      'scale': scale,
      'dimensions': {
        'cols': fixture.worldMap.cols,
        'rows': fixture.worldMap.rows,
      },
      'indexedTiles': fixture.worldMap.indexedTileCount,
      'sourceCount': 1,
      'visionRange': fixture.source.range,
      'visibleHexes': stableResult.visibleHexes,
      'tileLookupCalls': stableResult.tileLookupCalls,
      'tileLookupHits': stableResult.tileLookupHits,
      'outputDigest': stableDigest(stableResult.normalizedOutput),
    },
    observations: {'fogRevealTiming': timingObservation(samples)},
  );
}

_FogRevealResult _executeCountedFogReveal(_FogRevealFixture fixture) {
  fixture.countedMapTiles.reset();
  final visible = _visibleHexesFor(fixture.countedMapTiles, fixture.source);
  return _FogRevealResult(
    visibleHexes: visible.length,
    tileLookupCalls: fixture.countedMapTiles.lookupCalls,
    tileLookupHits: fixture.countedMapTiles.lookupHits,
    normalizedOutput: _normalizedFogOutput(visible, fixture.source),
  );
}

Set<HexCoordinate> _visibleHexesFor(
  MapTileLookup mapTiles,
  FogRevealSource source,
) {
  return const FogRevealCalculator().visibleHexesFor(
    mapData: mapTiles,
    sources: [source],
  );
}

List<Map<String, int>> _normalizedFogOutput(
  Iterable<HexCoordinate> visible,
  FogRevealSource source,
) {
  final offsets =
      [
        for (final hex in visible)
          (col: hex.col - source.origin.col, row: hex.row - source.origin.row),
      ]..sort((left, right) {
        final col = left.col.compareTo(right.col);
        return col != 0 ? col : left.row.compareTo(right.row);
      });

  return [
    for (final offset in offsets) {'col': offset.col, 'row': offset.row},
  ];
}

void _verifyFogRevealOutput(
  _FogRevealResult expected,
  Set<HexCoordinate> actual,
  FogRevealSource source,
) {
  if (expected.visibleHexes != actual.length ||
      stableDigest(expected.normalizedOutput) !=
          stableDigest(_normalizedFogOutput(actual, source))) {
    throw StateError(
      'Fog reveal workload produced a non-deterministic result.',
    );
  }
}

final class _FogRevealFixture {
  const _FogRevealFixture({
    required this.worldMap,
    required this.mapTiles,
    required this.countedMapTiles,
    required this.source,
  });

  factory _FogRevealFixture.forScale(int scale) {
    final dimensions = _dimensionsFor(scale);
    final worldMap = WorldMap(
      cols: dimensions.cols,
      rows: dimensions.rows,
      tiles: [
        for (var index = 0; index < scale; index++)
          WorldTile(
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
    var sourceCol = dimensions.cols ~/ 2;
    if (sourceCol.isOdd) sourceCol--;
    final source = FogRevealSource(
      playerId: 'benchmark_player',
      origin: HexCoordinate(col: sourceCol, row: dimensions.rows ~/ 2),
      range: _fogRevealRange,
      observerHeight: 0,
    );
    final mapTiles = WorldMapReadView(worldMap);
    return _FogRevealFixture(
      worldMap: worldMap,
      mapTiles: mapTiles,
      countedMapTiles: _CountingTileLookup(mapTiles),
      source: source,
    );
  }

  final WorldMap worldMap;
  final MapTileLookup mapTiles;
  final _CountingTileLookup countedMapTiles;
  final FogRevealSource source;
}

final class _CountingTileLookup implements MapTileLookup {
  _CountingTileLookup(this._delegate);

  final MapTileLookup _delegate;
  int lookupCalls = 0;
  int lookupHits = 0;

  @override
  MapTileView? tileAt(int col, int row) {
    lookupCalls++;
    final tile = _delegate.tileAt(col, row);
    if (tile != null) lookupHits++;
    return tile;
  }

  void reset() {
    lookupCalls = 0;
    lookupHits = 0;
  }
}

final class _FogRevealResult {
  const _FogRevealResult({
    required this.visibleHexes,
    required this.tileLookupCalls,
    required this.tileLookupHits,
    required this.normalizedOutput,
  });

  final int visibleHexes;
  final int tileLookupCalls;
  final int tileLookupHits;
  final List<Map<String, int>> normalizedOutput;
}
