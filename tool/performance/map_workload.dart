import 'dart:collection';

import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

import 'measurement.dart';

const mapLookupScales = [100, 1000, 10000];

/// Runs deterministic first, middle, last, and missing-tile lookups.
PerformanceCaseResult runMapLookupWorkload({
  Iterable<int> scales = mapLookupScales,
  int timingSamples = 21,
}) {
  if (timingSamples <= 0) {
    throw ArgumentError.value(
      timingSamples,
      'timingSamples',
      'Must be positive.',
    );
  }

  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  for (final scale in scales) {
    final result = _runScale(scale, timingSamples);
    stable['$scale'] = result.stable;
    observations['$scale'] = result.observations;
  }

  return PerformanceCaseResult(
    'map.lookup',
    {'sizes': stable},
    {'sizes': observations},
  );
}

/// Runs the same lookup probes through the second pre-refactor map model.
PerformanceCaseResult runMapDefinitionLookupWorkload({
  Iterable<int> scales = mapLookupScales,
  int timingSamples = 21,
}) {
  if (timingSamples <= 0) {
    throw ArgumentError.value(
      timingSamples,
      'timingSamples',
      'Must be positive.',
    );
  }

  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  for (final scale in scales) {
    final result = _runDefinitionScale(scale, timingSamples);
    stable['$scale'] = result.stable;
    observations['$scale'] = result.observations;
  }

  return PerformanceCaseResult(
    'map.definition-lookup',
    {'sizes': stable},
    {'sizes': observations},
  );
}

_ScaleResult _runScale(int scale, int timingSamples) {
  final fixture = _MapFixture.forScale(scale);
  _executeProbeBatch(fixture);

  final samples = <Duration>[];
  _ProbeBatchResult? stableResult;
  for (var run = 0; run < timingSamples; run++) {
    final measured = measureSync(() => _executeProbeBatch(fixture));
    samples.add(measured.elapsed);
    stableResult ??= measured.value;
    _verifyStableResult(stableResult, measured.value);
  }

  return _ScaleResult(
    stable: {
      'scale': scale,
      'dimensions': {'cols': fixture.map.cols, 'rows': fixture.map.rows},
      'probeCount': stableResult!.readsByProbe.length,
      'elementReads': stableResult.elementReads,
      'elementReadsByProbe': stableResult.readsByProbe,
      'outputDigest': stableDigest(stableResult.output),
    },
    observations: {'lookupBatchTiming': timingObservation(samples)},
  );
}

_ScaleResult _runDefinitionScale(int scale, int timingSamples) {
  final fixture = _MapDefinitionFixture.forScale(scale);
  _executeDefinitionProbeBatch(fixture);

  final samples = <Duration>[];
  _ProbeBatchResult? stableResult;
  for (var run = 0; run < timingSamples; run++) {
    final measured = measureSync(() => _executeDefinitionProbeBatch(fixture));
    samples.add(measured.elapsed);
    stableResult ??= measured.value;
    _verifyStableResult(stableResult, measured.value);
  }

  return _ScaleResult(
    stable: {
      'scale': scale,
      'dimensions': {'cols': fixture.map.cols, 'rows': fixture.map.rows},
      'probeCount': stableResult!.readsByProbe.length,
      'tileInspections': stableResult.elementReads,
      'tileInspectionsByProbe': stableResult.readsByProbe,
      'outputDigest': stableDigest(stableResult.output),
    },
    observations: {'lookupBatchTiming': timingObservation(samples)},
  );
}

_ProbeBatchResult _executeProbeBatch(_MapFixture fixture) {
  final readsByProbe = <String, int>{};
  final output = <String, Object?>{};
  fixture.tiles.resetElementReads();

  for (final probe in fixture.probes) {
    final readsBefore = fixture.tiles.elementReads;
    final tile = fixture.map.tileAt(probe.col, probe.row);
    readsByProbe[probe.name] = fixture.tiles.elementReads - readsBefore;
    output[probe.name] = tile == null
        ? null
        : {'col': tile.col, 'row': tile.row};
  }

  return _ProbeBatchResult(
    elementReads: fixture.tiles.elementReads,
    readsByProbe: Map.unmodifiable(readsByProbe),
    output: Map.unmodifiable(output),
  );
}

_ProbeBatchResult _executeDefinitionProbeBatch(_MapDefinitionFixture fixture) {
  final readsByProbe = <String, int>{};
  final output = <String, Object?>{};
  fixture.inspections.reset();
  for (final probe in fixture.probes) {
    final readsBefore = fixture.inspections.value;
    final tile = fixture.map.tileAt(probe.col, probe.row);
    readsByProbe[probe.name] = fixture.inspections.value - readsBefore;
    output[probe.name] = tile == null
        ? null
        : {'col': tile.col, 'row': tile.row};
  }
  return _ProbeBatchResult(
    elementReads: readsByProbe.values.fold(0, (sum, reads) => sum + reads),
    readsByProbe: Map.unmodifiable(readsByProbe),
    output: Map.unmodifiable(output),
  );
}

void _verifyStableResult(_ProbeBatchResult expected, _ProbeBatchResult actual) {
  final readsMatch = _mapsEqual(expected.readsByProbe, actual.readsByProbe);
  if (expected.elementReads != actual.elementReads ||
      stableDigest(expected.output) != stableDigest(actual.output) ||
      !readsMatch) {
    throw StateError(
      'Map lookup workload produced a non-deterministic result.',
    );
  }
}

final class _MapDefinitionFixture {
  const _MapDefinitionFixture({
    required this.map,
    required this.probes,
    required this.inspections,
  });

  factory _MapDefinitionFixture.forScale(int scale) {
    final dimensions = _dimensionsFor(scale);
    final inspections = _InspectionCounter();
    final tiles = [
      for (var index = 0; index < scale; index++)
        _CountingMapTileDefinition(
          inspections: inspections,
          col: index % dimensions.cols,
          row: index ~/ dimensions.cols,
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
    ];
    final middle = tiles[scale ~/ 2];
    return _MapDefinitionFixture(
      map: MapDefinition(
        cols: dimensions.cols,
        rows: dimensions.rows,
        tiles: tiles,
      ),
      probes: [
        const _Probe('first', 0, 0),
        _Probe('middle', middle.col, middle.row),
        _Probe('last', dimensions.cols - 1, dimensions.rows - 1),
        _Probe('miss', dimensions.cols, dimensions.rows),
      ],
      inspections: inspections,
    );
  }

  final MapDefinition map;
  final List<_Probe> probes;
  final _InspectionCounter inspections;
}

final class _CountingMapTileDefinition extends MapTileDefinition {
  _CountingMapTileDefinition({
    required this.inspections,
    required super.col,
    required super.row,
    required super.terrains,
    required super.resources,
    required super.height,
  });

  final _InspectionCounter inspections;

  @override
  int get col {
    inspections.value++;
    return super.col;
  }
}

final class _InspectionCounter {
  int value = 0;

  void reset() => value = 0;
}

bool _mapsEqual(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

final class _MapFixture {
  const _MapFixture({
    required this.map,
    required this.tiles,
    required this.probes,
  });

  factory _MapFixture.forScale(int scale) {
    final dimensions = _dimensionsFor(scale);
    final backingTiles = [
      for (var index = 0; index < scale; index++)
        TileData(
          col: index % dimensions.cols,
          row: index ~/ dimensions.cols,
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
    ];
    final tiles = _CountingList<TileData>(backingTiles);
    final middle = backingTiles[scale ~/ 2];

    return _MapFixture(
      map: MapData(cols: dimensions.cols, rows: dimensions.rows, tiles: tiles),
      tiles: tiles,
      probes: [
        const _Probe('first', 0, 0),
        _Probe('middle', middle.col, middle.row),
        _Probe('last', dimensions.cols - 1, dimensions.rows - 1),
        _Probe('miss', dimensions.cols, dimensions.rows),
      ],
    );
  }

  final MapData map;
  final _CountingList<TileData> tiles;
  final List<_Probe> probes;
}

({int cols, int rows}) _dimensionsFor(int scale) => switch (scale) {
  100 => (cols: 10, rows: 10),
  1000 => (cols: 25, rows: 40),
  10000 => (cols: 100, rows: 100),
  _ => throw ArgumentError.value(
    scale,
    'scale',
    'Supported scales are 100, 1000, and 10000.',
  ),
};

final class _CountingList<E> extends ListBase<E> {
  _CountingList(List<E> values) : _values = List.unmodifiable(values);

  final List<E> _values;
  int elementReads = 0;

  @override
  int get length => _values.length;

  @override
  set length(int value) => throw UnsupportedError('Counting list is fixed.');

  @override
  E operator [](int index) {
    elementReads++;
    return _values[index];
  }

  @override
  void operator []=(int index, E value) {
    throw UnsupportedError('Counting list is read-only.');
  }

  void resetElementReads() => elementReads = 0;
}

final class _Probe {
  const _Probe(this.name, this.col, this.row);

  final String name;
  final int col;
  final int row;
}

final class _ProbeBatchResult {
  const _ProbeBatchResult({
    required this.elementReads,
    required this.readsByProbe,
    required this.output,
  });

  final int elementReads;
  final Map<String, int> readsByProbe;
  final Map<String, Object?> output;
}

final class _ScaleResult {
  const _ScaleResult({required this.stable, required this.observations});

  final Map<String, Object?> stable;
  final Map<String, Object?> observations;
}
