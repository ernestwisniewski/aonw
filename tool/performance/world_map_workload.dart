part of 'map_workload.dart';

/// Runs the same probes through the canonical constant-time coordinate index.
PerformanceCaseResult runWorldMapLookupWorkload({
  Iterable<int> scales = mapLookupScales,
  int timingSamples = 21,
}) {
  _validateTimingSamples(timingSamples);

  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  for (final scale in scales) {
    final result = _runWorldScale(scale, timingSamples);
    stable['$scale'] = result.stable;
    observations['$scale'] = result.observations;
  }

  return PerformanceCaseResult(
    'map.world-lookup',
    {'sizes': stable},
    {'sizes': observations},
  );
}

_ScaleResult _runWorldScale(int scale, int timingSamples) {
  final fixture = _WorldMapFixture.forScale(scale);
  _executeWorldProbeBatch(fixture);

  final samples = <Duration>[];
  _WorldProbeBatchResult? stableResult;
  for (var run = 0; run < timingSamples; run++) {
    final measured = measureSync(() => _executeWorldProbeBatch(fixture));
    samples.add(measured.elapsed);
    stableResult ??= measured.value;
    _verifyWorldStableResult(stableResult, measured.value);
  }

  return _ScaleResult(
    stable: {
      'scale': scale,
      'dimensions': {'cols': fixture.map.cols, 'rows': fixture.map.rows},
      'probeCount': stableResult!.lookupCallsByProbe.length,
      'indexedTiles': fixture.map.indexedTileCount,
      'lookupCalls': stableResult.lookupCalls,
      'lookupCallsByProbe': stableResult.lookupCallsByProbe,
      'outputDigest': stableDigest(stableResult.output),
    },
    observations: {'lookupBatchTiming': timingObservation(samples)},
  );
}

_WorldProbeBatchResult _executeWorldProbeBatch(_WorldMapFixture fixture) {
  final lookupCallsByProbe = <String, int>{};
  final output = <String, Object?>{};
  var lookupCalls = 0;
  for (final probe in fixture.probes) {
    final tile = fixture.map.tileAt(HexCoord(col: probe.col, row: probe.row));
    lookupCalls++;
    lookupCallsByProbe[probe.name] = 1;
    output[probe.name] = tile == null
        ? null
        : {'col': tile.coordinate.col, 'row': tile.coordinate.row};
  }
  return _WorldProbeBatchResult(
    lookupCalls: lookupCalls,
    lookupCallsByProbe: Map.unmodifiable(lookupCallsByProbe),
    output: Map.unmodifiable(output),
  );
}

void _verifyWorldStableResult(
  _WorldProbeBatchResult expected,
  _WorldProbeBatchResult actual,
) {
  final callsMatch = _mapsEqual(
    expected.lookupCallsByProbe,
    actual.lookupCallsByProbe,
  );
  if (expected.lookupCalls != actual.lookupCalls ||
      stableDigest(expected.output) != stableDigest(actual.output) ||
      !callsMatch) {
    throw StateError(
      'World map lookup workload produced a non-deterministic result.',
    );
  }
}

final class _WorldMapFixture {
  const _WorldMapFixture({required this.map, required this.probes});

  factory _WorldMapFixture.forScale(int scale) {
    final dimensions = _dimensionsFor(scale);
    final tiles = [
      for (var index = 0; index < scale; index++)
        WorldTile(
          coordinate: HexCoord(
            col: index % dimensions.cols,
            row: index ~/ dimensions.cols,
          ),
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
    ];
    final middle = tiles[scale ~/ 2].coordinate;
    return _WorldMapFixture(
      map: WorldMap(cols: dimensions.cols, rows: dimensions.rows, tiles: tiles),
      probes: [
        const _Probe('first', 0, 0),
        _Probe('middle', middle.col, middle.row),
        _Probe('last', dimensions.cols - 1, dimensions.rows - 1),
        _Probe('miss', dimensions.cols, dimensions.rows),
      ],
    );
  }

  final WorldMap map;
  final List<_Probe> probes;
}

final class _WorldProbeBatchResult {
  const _WorldProbeBatchResult({
    required this.lookupCalls,
    required this.lookupCallsByProbe,
    required this.output,
  });

  final int lookupCalls;
  final Map<String, int> lookupCallsByProbe;
  final Map<String, Object?> output;
}
