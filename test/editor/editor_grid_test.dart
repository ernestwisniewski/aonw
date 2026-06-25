import 'package:aonw/editor/engine/editor_grid.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/editor/engine/editor_world.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_constraints.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditorGrid paint stroke', () {
    test('reuses the same tile while dragging over one hex', () {
      final grid = EditorGrid(
        mapData: MapData(
          cols: 1,
          rows: 1,
          tiles: [
            const TileData(
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
    test(
      'clearSelectedTerrains removes terrain from the selected hex only',
      () {
        final mapData = MapData(
          cols: 2,
          rows: 1,
          tiles: [
            const TileData(
              col: 0,
              row: 0,
              terrains: [TerrainType.grassland, TerrainType.hills],
              resources: [ResourceType.iron],
              height: 2,
            ),
            const TileData(
              col: 1,
              row: 0,
              terrains: [TerrainType.ocean],
              resources: [],
              height: 0,
            ),
          ],
        );
        final grid = EditorGrid(
          mapData: mapData,
          config: MapConfig.defaultConfig,
          editorState: const EditorState(
            selectedTerrains: {TerrainType.desert},
            selectedResources: {},
            selectedHeight: 0,
            heightActive: false,
          ),
        )..rebuild();

        _tileByCoordinate(grid, 0, 0).onTapped();

        expect(grid.clearSelectedTerrains(), isTrue);
        expect(mapData.tileAt(0, 0)!.terrains, isEmpty);
        expect(mapData.tileAt(0, 0)!.resources, [ResourceType.iron]);
        expect(mapData.tileAt(0, 0)!.height, 2);
        expect(mapData.tileAt(1, 0)!.terrains, [TerrainType.ocean]);
      },
    );

    test('addColumn uses the latest editor selection', () {
      final grid =
          EditorGrid(
              mapData: MapData(
                cols: 1,
                rows: 2,
                tiles: [
                  const TileData(
                    col: 0,
                    row: 0,
                    terrains: [TerrainType.ocean],
                    resources: [],
                    height: 0,
                  ),
                  const TileData(
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
        mapData: mapData,
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
        mapData: mapData,
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
      final mapData = MapData(
        cols: 1,
        rows: 1,
        tiles: [
          const TileData(
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
            hex: CityHex(col: 0, row: 0),
            victoryPoints: 2,
          ),
        ],
      );
      final grid = EditorGrid(
        mapData: mapData,
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
        final mapData = MapData(
          cols: MapConstraints.minCols + 1,
          rows: 1,
          tiles: [
            for (var col = 0; col <= removedCol; col++)
              TileData(
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
              hex: CityHex(col: removedCol, row: 0),
              victoryPoints: 2,
            ),
          ],
        );
        EditorGrid(
            mapData: mapData,
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

  group('EditorWorld keyboard shortcuts', () {
    test('T clears all terrain from the selected hex', () async {
      final selectedTiles = <String>[];
      final mapData = MapData(
        cols: 1,
        rows: 1,
        tiles: [
          const TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland, TerrainType.hills],
            resources: [ResourceType.iron],
            height: 2,
          ),
        ],
      );
      final world = EditorWorld(
        mapData: mapData,
        editorState: const EditorState(
          selectedTerrains: {TerrainType.grassland},
          selectedResources: {},
          selectedHeight: 0,
          heightActive: false,
        ),
        onTileSelected: (col, row) => selectedTiles.add('$col,$row'),
      )..onGameResize(Vector2(800, 600));
      await world.onLoad();

      _tileByCoordinate(world.grid, 0, 0).onTapped();
      final result = world.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyT,
          logicalKey: LogicalKeyboardKey.keyT,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.keyT},
      );

      expect(result, KeyEventResult.handled);
      expect(mapData.tileAt(0, 0)!.terrains, isEmpty);
      expect(mapData.tileAt(0, 0)!.resources, [ResourceType.iron]);
      expect(mapData.tileAt(0, 0)!.height, 2);
      expect(selectedTiles, ['0,0', '0,0']);
    });
  });

  group('EditorGrid city planning markers', () {
    test('marks terrain that can host or grow a city', () {
      final mapData = MapData(
        cols: 3,
        rows: 1,
        tiles: [
          const TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [],
            height: 0,
          ),
          const TileData(
            col: 1,
            row: 0,
            terrains: [TerrainType.coast],
            resources: [],
            height: 0,
          ),
          const TileData(
            col: 2,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
        ],
      );
      final grid = EditorGrid(
        mapData: mapData,
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
      final mapData = MapData(
        cols: 7,
        rows: 1,
        tiles: [
          const TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [],
            height: 0,
          ),
          const TileData(
            col: 1,
            row: 0,
            terrains: [TerrainType.coast],
            resources: [],
            height: 0,
          ),
          const TileData(
            col: 2,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
          const TileData(
            col: 3,
            row: 0,
            terrains: [TerrainType.grassland, TerrainType.mountain],
            resources: [],
            height: 0,
          ),
          const TileData(
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
          const TileData(
            col: 5,
            row: 0,
            terrains: [TerrainType.snow, TerrainType.forest],
            resources: [],
            height: 0,
          ),
          const TileData(
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
        mapData: mapData,
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
      final mapData = MapData(
        cols: 1,
        rows: 1,
        tiles: [
          const TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [],
            height: 0,
          ),
        ],
      );
      final grid = EditorGrid(
        mapData: mapData,
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

MapData _filledMapData({
  required int cols,
  required int rows,
  required TerrainType terrain,
}) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (int row = 0; row < rows; row++)
      for (int col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: [terrain],
          resources: [],
          height: 0,
        ),
  ],
);
