import 'dart:ui' as ui;

import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'frame_budget_policy.dart';
import 'measurement.dart';

const rendererFrameWorkloadScales = [100, 600, 1000];
const rendererAssetMode = 'fallback-no-assets';

const _defaultWarmupFrames = 3;
const _defaultSampleFrames = 21;
const _displaySettings = HexDisplaySettings(
  showHeightBadge: true,
  showTerrain: true,
  showResources: true,
  hexBorderColor: Color(0xCC172033),
  wallTintColor: Color(0xFF121722),
);

List<PerformanceCaseResult> runRendererFrameWorkloads({
  int warmupFrames = _defaultWarmupFrames,
  int sampleFrames = _defaultSampleFrames,
}) => [
  for (final scale in rendererFrameWorkloadScales)
    runRendererFrameWorkload(
      scale: scale,
      warmupFrames: warmupFrames,
      sampleFrames: sampleFrames,
    ),
];

PerformanceCaseResult runRendererFrameWorkload({
  required int scale,
  int warmupFrames = _defaultWarmupFrames,
  int sampleFrames = _defaultSampleFrames,
}) {
  _validateRunCounts(warmupFrames: warmupFrames, sampleFrames: sampleFrames);
  final fixture = _RendererFixture.forScale(scale);
  final paintedTilesByFrame = <int>[];
  for (var frame = 0; frame < warmupFrames; frame++) {
    paintedTilesByFrame.add(_paintFrame(fixture));
  }
  final samples = <Duration>[];
  for (var frame = 0; frame < sampleFrames; frame++) {
    final measured = _measurePaintFrame(fixture);
    samples.add(measured.elapsed);
    paintedTilesByFrame.add(measured.value);
  }
  return PerformanceCaseResult(
    'renderer.frame.$scale',
    _stableMetrics(fixture, warmupFrames, sampleFrames, paintedTilesByFrame),
    _timingDiagnostics(samples),
  );
}

void _validateRunCounts({
  required int warmupFrames,
  required int sampleFrames,
}) {
  if (warmupFrames < 0) {
    throw ArgumentError.value(
      warmupFrames,
      'warmupFrames',
      'Must be non-negative.',
    );
  }
  if (sampleFrames < 1) {
    throw ArgumentError.value(sampleFrames, 'sampleFrames', 'Must be >= 1.');
  }
}

Map<String, Object?> _stableMetrics(
  _RendererFixture fixture,
  int warmupFrames,
  int sampleFrames,
  List<int> paintedTilesByFrame,
) => {
  'assetMode': rendererAssetMode,
  'referenceProfileBudget': rendererReferenceProfileBudget,
  'dimensions': {'cols': fixture.map.cols, 'rows': fixture.map.rows},
  'warmupFrames': warmupFrames,
  'sampleFrames': sampleFrames,
  'paintedTilesPerFrame': _uniformPaintCount(paintedTilesByFrame),
  'totalPaintedTiles': paintedTilesByFrame.fold<int>(
    0,
    (sum, value) => sum + value,
  ),
  'scenarioDigest': fixture.scenarioDigest,
};

Map<String, Object?> _timingDiagnostics(List<Duration> samples) => {
  'portableTimingGateEnabled': false,
  'timingPolicy': 'diagnostic_only',
  'headlessRenderTreeTiming': {
    ...timingObservation(samples),
    'diagnosticReferenceBudgetMicros': rendererRenderSubmissionBudgetMicros,
    'samplesOverDiagnosticReferenceBudget': samples
        .where(
          (sample) =>
              sample.inMicroseconds > rendererRenderSubmissionBudgetMicros,
        )
        .length,
  },
};

int _paintFrame(_RendererFixture fixture) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paintedTiles = _paintInto(fixture, canvas);
  recorder.endRecording().dispose();
  return paintedTiles;
}

Measured<int> _measurePaintFrame(_RendererFixture fixture) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final measured = measureSync(() => _paintInto(fixture, canvas));
  recorder.endRecording().dispose();
  return measured;
}

int _paintInto(_RendererFixture fixture, ui.Canvas canvas) {
  final paintsBefore = fixture.paintCollector.paintCalls;
  fixture.grid.renderTree(canvas);
  return fixture.paintCollector.paintCalls - paintsBefore;
}

int _uniformPaintCount(List<int> paintedTilesByFrame) {
  final expected = paintedTilesByFrame.first;
  if (paintedTilesByFrame.any((count) => count != expected)) {
    throw StateError(
      'Renderer painted a non-deterministic number of tiles per frame: '
      '$paintedTilesByFrame.',
    );
  }
  return expected;
}

final class _RendererFixture {
  const _RendererFixture({
    required this.map,
    required this.grid,
    required this.paintCollector,
    required this.scenarioDigest,
  });

  factory _RendererFixture.forScale(int scale) {
    final dimensions = _dimensionsFor(scale);
    final map = _syntheticMap(dimensions);
    final paintCollector = _TilePaintCollector();
    final grid = _BenchmarkHexGrid(
      mapData: map,
      config: MapConfig.defaultConfig,
      displaySettings: _displaySettings,
      paintCollector: paintCollector,
    )..rebuild();
    final tiles = grid.children.query<HexTile>().toList(growable: false);
    if (tiles.length != scale) {
      throw StateError('Renderer built ${tiles.length} of $scale tiles.');
    }
    return _RendererFixture(
      map: map,
      grid: grid,
      paintCollector: paintCollector,
      scenarioDigest: _scenarioDigest(map),
    );
  }

  final WorldMap map;
  final _BenchmarkHexGrid grid;
  final _TilePaintCollector paintCollector;
  final String scenarioDigest;
}

final class _BenchmarkHexGrid extends HexGrid {
  _BenchmarkHexGrid({
    required super.mapData,
    required super.config,
    required super.displaySettings,
    required this.paintCollector,
  });

  final _TilePaintCollector paintCollector;

  @override
  HexTile buildTileComponent({
    required WorldTile tileData,
    required Vector2 position,
    required void Function() onTapped,
    required List<int?> neighborHeights,
    required List<int?> outlineNeighborHeights,
  }) {
    return _CountingHexTile(
      paintCollector: paintCollector,
      hexRadius: config.hexRadius,
      terrains: tileData.terrains,
      resources: tileData.resources,
      tileHeight: tileData.height,
      neighborHeights: neighborHeights,
      outlineNeighborHeights: outlineNeighborHeights,
      outlineOnlyTopFace: viewMode.usesOutlineHexes,
      showTerrain: displaySettings.showTerrain,
      showResources: displaySettings.showResources,
      showCitySites: displaySettings.showCitySites,
      showCityGrowth: displaySettings.showCityGrowth,
      showHeightBadge: displaySettings.showHeightBadge,
      outlineColor: displaySettings.hexBorderColor,
      selectionColor: displaySettings.selectedHexColor,
      wallTintColor: displaySettings.wallTintColor,
      markers: markersForTile(tileData),
      position: position,
      onTapped: onTapped,
    );
  }
}

final class _CountingHexTile extends HexTile {
  _CountingHexTile({
    required this.paintCollector,
    required super.hexRadius,
    required super.terrains,
    required super.resources,
    required super.onTapped,
    required super.tileHeight,
    required super.neighborHeights,
    required super.outlineNeighborHeights,
    required super.outlineOnlyTopFace,
    required super.showTerrain,
    required super.showResources,
    required super.showCitySites,
    required super.showCityGrowth,
    required super.showHeightBadge,
    required super.outlineColor,
    required super.selectionColor,
    required super.wallTintColor,
    required super.markers,
    required super.position,
  });

  final _TilePaintCollector paintCollector;

  @override
  void render(ui.Canvas canvas) {
    paintCollector.recordPaint();
    super.render(canvas);
  }
}

final class _TilePaintCollector {
  int paintCalls = 0;

  void recordPaint() => paintCalls++;
}

WorldMap _syntheticMap(({int cols, int rows}) dimensions) => WorldMap(
  cols: dimensions.cols,
  rows: dimensions.rows,
  tiles: [
    for (var row = 0; row < dimensions.rows; row++)
      for (var col = 0; col < dimensions.cols; col++)
        _syntheticTile(col: col, row: row, cols: dimensions.cols),
  ],
);

WorldTile _syntheticTile({
  required int col,
  required int row,
  required int cols,
}) {
  final index = row * cols + col;
  return WorldTile(
    col: col,
    row: row,
    terrains: [
      TerrainType.values[(col * 7 + row * 11) % TerrainType.values.length],
    ],
    resources: index % 5 == 0
        ? [ResourceType.values[(index * 3) % ResourceType.values.length]]
        : const [],
    height: (col * 3 + row * 5) % 6,
  );
}

String _scenarioDigest(WorldMap map) => stableDigest({
  'renderer': 'HexGrid.renderTree.headless',
  'assetMode': rendererAssetMode,
  'dimensions': {'cols': map.cols, 'rows': map.rows},
  'hexRadius': MapConfig.defaultConfig.hexRadius,
  'perspectiveY': HexGrid.perspectiveY,
  'display': {
    'showHeightBadge': _displaySettings.showHeightBadge,
    'showTerrain': _displaySettings.showTerrain,
    'showResources': _displaySettings.showResources,
    'hexBorderColor': _displaySettings.hexBorderColor.toARGB32(),
    'wallTintColor': _displaySettings.wallTintColor.toARGB32(),
  },
  'tiles': map.tiles.map((tile) => tile.toJson()).toList(growable: false),
});

({int cols, int rows}) _dimensionsFor(int scale) => switch (scale) {
  100 => (cols: 10, rows: 10),
  600 => (cols: 30, rows: 20),
  1000 => (cols: 40, rows: 25),
  _ => throw ArgumentError.value(
    scale,
    'scale',
    'Supported scales are 100, 600, and 1000.',
  ),
};
