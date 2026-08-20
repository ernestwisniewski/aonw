import 'package:aonw/editor/domain/map_draft.dart';
import 'package:aonw/editor/engine/editor_grid.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart' show WorldTile;
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:aonw_core/map/domain/map_constraints.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('EditorGrid paint stroke', () {
    test('reuses the same tile while dragging over one hex', () {
      final grid = EditorGrid(
        draft: MapDraft(
          cols: 1,
          rows: 1,
          tiles: [
            WorldTile(
              col: 0,
              row: 0,
              terrains: [TerrainType.ocean],
              resources: [],
              height: 0,
            ),
          ],
        ),
        config: MapConfig.defaultConfig,
        editorState: const EditorState(
          selectedTerrains: {TerrainType.desert},
          selectedResources: {},
          selectedHeight: 0,
          heightActive: false,
        ),
      )..rebuild();

      final tileCenter = HexGeometry.tilePosition(
        col: 0,
        row: 0,
        hexRadius: MapConfig.defaultConfig.hexRadius,
      );
      final worldPoint = Vector2(
        tileCenter.x,
        tileCenter.y * HexGrid.perspectiveY,
      );

      final beforePaint = _tileAt(grid, tileCenter);

      grid
        ..startPaintStroke()
        ..paintAtWorld(worldPoint);
      final afterFirstPaint = _tileAt(grid, tileCenter);

      grid.paintAtWorld(worldPoint);
      final afterSecondPaint = _tileAt(grid, tileCenter);

      expect(identical(afterFirstPaint, beforePaint), isFalse);
      expect(identical(afterSecondPaint, afterFirstPaint), isTrue);
    });
  });

  group('EditorGrid selection', () {
    test('addColumn uses the latest editor selection', () {
      final grid =
          EditorGrid(
              draft: MapDraft(
                cols: 1,
                rows: 2,
                tiles: [
                  WorldTile(
                    col: 0,
                    row: 0,
                    terrains: [TerrainType.ocean],
                    resources: [],
                    height: 0,
                  ),
                  WorldTile(
                    col: 0,
                    row: 1,
                    terrains: [TerrainType.ocean],
                    resources: [],
                    height: 0,
                  ),
                ],
              ),
              config: MapConfig.defaultConfig,
              editorState: const EditorState(
                selectedTerrains: {TerrainType.ocean},
                selectedResources: {},
                selectedHeight: 0,
                heightActive: false,
              ),
            )
            ..editorState = const EditorState(
              selectedTerrains: {TerrainType.desert},
              selectedResources: {},
              selectedHeight: 0,
              heightActive: false,
            )
            ..addColumn();

      final newTiles = grid.mapData.tiles
          .where((tile) => tile.col == 1)
          .toList();
      expect(newTiles, hasLength(2));
      expect(
        newTiles.every((tile) => tile.terrains.contains(TerrainType.desert)),
        isTrue,
      );
    });
  });

  group('EditorGrid resize constraints', () {
    test('addColumn and addRow stop at the max editor size', () {
      final mapData = _filledMapData(
        cols: MapConstraints.maxCols,
        rows: MapConstraints.maxRows,
        terrain: TerrainType.grassland,
      );
      final grid = EditorGrid(
        draft: mapData,
        config: MapConfig.defaultConfig,
        editorState: const EditorState(
          selectedTerrains: {TerrainType.desert},
          selectedResources: {},
          selectedHeight: 0,
          heightActive: false,
        ),
      )..rebuild();
      final originalTileCount = mapData.tiles.length;

      grid
        ..addColumn()
        ..addRow();

      expect(mapData.cols, MapConstraints.maxCols);
      expect(mapData.rows, MapConstraints.maxRows);
      expect(mapData.tiles.length, originalTileCount);
    });
  });

  group('EditorGrid map objectives', () {
    test('places a selected objective on the selected hex', () {
      var objectiveChangeCount = 0;
      final mapData = _filledMapData(
        cols: 1,
        rows: 1,
        terrain: TerrainType.grassland,
      );
      final grid = EditorGrid(
        draft: mapData,
        config: MapConfig.defaultConfig,
        editorState: const EditorState(
          selectedTerrains: {TerrainType.grassland},
          selectedResources: {},
          selectedObjectiveType: MapObjectiveType.legendaryResource,
          objectivePaintMode: EditorObjectivePaintMode.place,
          selectedHeight: 0,
          heightActive: false,
        ),
        onObjectivesChanged: () => objectiveChangeCount++,
      )..rebuild();

      _tileByCoordinate(grid, 0, 0).onTapped();
      grid.repaintSelected();

      expect(mapData.objectives, hasLength(1));
      expect(mapData.objectives.single.id, 'legendary_0_0');
      expect(
        mapData.objectives.single.type,
        MapObjectiveType.legendaryResource,
      );
      expect(mapData.objectives.single.victoryPoints, 3);
      expect(mapData.objectives.single.goldPerTurn, 2);
      expect(objectiveChangeCount, 1);
    });

    test('erase mode removes an objective from the selected hex', () {
      final mapData = MapDraft(
        cols: 1,
        rows: 1,
        tiles: [
          WorldTile(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [],
            height: 0,
          ),
        ],
        objectives: const [
          MapObjectiveDefinition(
            id: 'pass_0_0',
            type: MapObjectiveType.strategicPass,
            hex: HexCoord(col: 0, row: 0),
            victoryPoints: 2,
          ),
        ],
      );
      final grid = EditorGrid(
        draft: mapData,
        config: MapConfig.defaultConfig,
        editorState: const EditorState(
          selectedTerrains: {TerrainType.grassland},
          selectedResources: {},
          objectivePaintMode: EditorObjectivePaintMode.erase,
          selectedHeight: 0,
          heightActive: false,
        ),
      )..rebuild();

      _tileByCoordinate(grid, 0, 0).onTapped();
      grid.repaintSelected();

      expect(mapData.objectives, isEmpty);
    });

    test(
      'removing the outer column drops objectives outside the new bounds',
      () {
        const removedCol = MapConstraints.minCols;
        final mapData = MapDraft(
          cols: MapConstraints.minCols + 1,
          rows: 1,
          tiles: [
            for (var col = 0; col <= removedCol; col++)
              WorldTile(
                col: col,
                row: 0,
                terrains: const [TerrainType.grassland],
                resources: const [],
                height: 0,
              ),
          ],
          objectives: const [
            MapObjectiveDefinition(
              id: 'pass_removed',
              type: MapObjectiveType.strategicPass,
              hex: HexCoord(col: removedCol, row: 0),
              victoryPoints: 2,
            ),
          ],
        );
        EditorGrid(
            draft: mapData,
            config: MapConfig.defaultConfig,
            editorState: const EditorState(
              selectedTerrains: {TerrainType.grassland},
              selectedResources: {},
              selectedHeight: 0,
              heightActive: false,
            ),
          )
          ..rebuild()
          ..removeColumn();

        expect(mapData.cols, MapConstraints.minCols);
        expect(mapData.objectives, isEmpty);
      },
    );
  });

  group('EditorGrid city planning markers', () {
    test('marks terrain that can host or grow a city', () {
      final mapData = MapDraft(
        cols: 3,
        rows: 1,
        tiles: [
          WorldTile(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 1,
            row: 0,
            terrains: [TerrainType.coast],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 2,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
        ],
      );
      final grid = EditorGrid(
        draft: mapData,
        config: MapConfig.defaultConfig,
        editorState: const EditorState(
          selectedTerrains: {TerrainType.desert},
          selectedResources: {},
          selectedHeight: 0,
          heightActive: false,
        ),
      )..rebuild();

      final grassland = _tileByCoordinate(grid, 0, 0);
      final coast = _tileByCoordinate(grid, 1, 0);
      final ocean = _tileByCoordinate(grid, 2, 0);

      expect(grassland.markers.canFoundCity, isTrue);
      expect(grassland.markers.canGrowCity, isTrue);
      expect(coast.markers.canFoundCity, isTrue);
      expect(coast.markers.canGrowCity, isTrue);
      expect(ocean.markers.canFoundCity, isFalse);
      expect(ocean.markers.canGrowCity, isTrue);
    });
  });

  group('EditorGrid movement blockers', () {
    test('marks land-impassable and warrior over-budget tiles', () {
      final mapData = MapDraft(
        cols: 7,
        rows: 1,
        tiles: [
          WorldTile(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 1,
            row: 0,
            terrains: [TerrainType.coast],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 2,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 3,
            row: 0,
            terrains: [TerrainType.grassland, TerrainType.mountain],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 4,
            row: 0,
            terrains: [
              TerrainType.plains,
              TerrainType.forest,
              TerrainType.jungle,
              TerrainType.hills,
            ],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 5,
            row: 0,
            terrains: [TerrainType.snow, TerrainType.forest],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 6,
            row: 0,
            terrains: [
              TerrainType.snow,
              TerrainType.tundra,
              TerrainType.forest,
            ],
            resources: [],
            height: 0,
          ),
        ],
      );
      final grid = EditorGrid(
        draft: mapData,
        config: MapConfig.defaultConfig,
        editorState: const EditorState(
          selectedTerrains: {TerrainType.desert},
          selectedResources: {},
          selectedHeight: 0,
          heightActive: false,
        ),
      )..rebuild();

      expect(_tileByCoordinate(grid, 0, 0).movementBlocked, isFalse);
      expect(_tileByCoordinate(grid, 1, 0).movementBlocked, isFalse);
      expect(_tileByCoordinate(grid, 2, 0).movementBlocked, isTrue);
      expect(_tileByCoordinate(grid, 3, 0).movementBlocked, isTrue);
      expect(_tileByCoordinate(grid, 4, 0).movementBlocked, isTrue);
      expect(_tileByCoordinate(grid, 5, 0).movementBlocked, isFalse);
      expect(_tileByCoordinate(grid, 6, 0).movementBlocked, isFalse);
    });

    test('refreshes the blocker overlay when terrain is repainted', () {
      final mapData = MapDraft(
        cols: 1,
        rows: 1,
        tiles: [
          WorldTile(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [],
            height: 0,
          ),
        ],
      );
      final grid = EditorGrid(
        draft: mapData,
        config: MapConfig.defaultConfig,
        editorState: const EditorState(
          selectedTerrains: {
            TerrainType.plains,
            TerrainType.forest,
            TerrainType.jungle,
            TerrainType.hills,
          },
          selectedResources: {},
          selectedHeight: 0,
          heightActive: false,
        ),
      )..rebuild();
      final tileCenter = HexGeometry.tilePosition(
        col: 0,
        row: 0,
        hexRadius: MapConfig.defaultConfig.hexRadius,
      );
      final worldPoint = Vector2(
        tileCenter.x,
        tileCenter.y * HexGrid.perspectiveY,
      );

      expect(_tileByCoordinate(grid, 0, 0).movementBlocked, isFalse);

      grid.paintAtWorld(worldPoint);

      expect(
        mapData.tileAt(0, 0)!.terrains,
        containsAll([
          TerrainType.plains,
          TerrainType.forest,
          TerrainType.jungle,
          TerrainType.hills,
        ]),
      );
      expect(_tileByCoordinate(grid, 0, 0).movementBlocked, isTrue);
    });
  });
}

HexTile _tileAt(EditorGrid grid, Vector2 tileCenter) {
  return grid.children.query<HexTile>().firstWhere(
    (tile) =>
        tile.position.x == tileCenter.x && tile.position.y == tileCenter.y,
  );
}

HexTile _tileByCoordinate(EditorGrid grid, int col, int row) {
  final tileCenter = HexGeometry.tilePosition(
    col: col,
    row: row,
    hexRadius: MapConfig.defaultConfig.hexRadius,
  );
  return _tileAt(grid, tileCenter);
}

MapDraft _filledMapData({
  required int cols,
  required int rows,
  required TerrainType terrain,
}) => MapDraft(
  cols: cols,
  rows: rows,
  tiles: [
    for (int row = 0; row < rows; row++)
      for (int col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: [terrain],
          resources: [],
          height: 0,
        ),
  ],
);
