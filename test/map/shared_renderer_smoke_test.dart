import 'dart:ui' as ui;

import 'package:aonw/editor/engine/editor_grid.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _makeMap() => MapData(
  cols: 2,
  rows: 2,
  tiles: [
    for (int row = 0; row < 2; row++)
      for (int col = 0; col < 2; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.ocean],
          resources: col == 0 && row == 0
              ? const [ResourceType.iron]
              : const [],
          height: col + row,
        ),
  ],
);

void _renderTiles(Iterable<HexTile> tiles) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  for (final tile in tiles) {
    tile.render(canvas);
  }
  recorder.endRecording().dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('game HexGrid updates presentation without recreating tiles', () {
    final grid = HexGrid(
      mapData: _makeMap(),
      config: MapConfig.defaultConfig,
      displaySettings: const HexDisplaySettings(showHeightBadge: false),
    )..rebuild();
    final tiles = grid.children.query<HexTile>();
    expect(tiles, hasLength(4));
    _renderTiles(tiles);
    grid.selectTile(0, 0);
    final originalTiles = tiles.toList(growable: false);

    grid
      ..displaySettings = const HexDisplaySettings(showHeightBadge: true)
      ..viewMode = MapViewMode.graphic;

    final graphicTiles = grid.children.query<HexTile>().toList(growable: false);
    expect(graphicTiles, hasLength(4));
    for (var i = 0; i < originalTiles.length; i++) {
      expect(graphicTiles[i], same(originalTiles[i]));
    }
    expect(graphicTiles.first.showHeightBadge, isTrue);
    expect(graphicTiles.first.outlineOnlyTopFace, isTrue);
    expect(grid.selectedTileCoords, (col: 0, row: 0));
    _renderTiles(graphicTiles);
  });

  test('editor EditorGrid paint and resize paths keep renderer valid', () {
    final grid = EditorGrid(
      mapData: _makeMap(),
      config: MapConfig.defaultConfig,
      editorState: const EditorState(
        selectedTerrains: {TerrainType.desert},
        selectedResources: {},
        selectedHeight: 3,
        heightActive: true,
      ),
      displaySettings: const HexDisplaySettings(showHeightBadge: true),
    )..rebuild();
    expect(grid.children.query<HexTile>(), hasLength(4));

    final center = HexGeometry.tilePosition(
      col: 0,
      row: 0,
      hexRadius: MapConfig.defaultConfig.hexRadius,
    );
    grid
      ..startPaintStroke()
      ..paintAtWorld(Vector2(center.x, center.y * HexGrid.perspectiveY))
      ..endPaintStroke();

    _renderTiles(grid.children.query<HexTile>());

    grid
      ..viewMode = MapViewMode.graphic
      ..displaySettings = const HexDisplaySettings(showHeightBadge: false)
      ..addRow();

    final resizedTiles = grid.children.query<HexTile>();
    expect(resizedTiles, hasLength(6));
    _renderTiles(resizedTiles);
  });
}
