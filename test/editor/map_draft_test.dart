import 'package:aonw/editor/domain/map_draft.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/map/domain/map_constraints.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapDraft', () {
    test('preserves the complete map contract through freeze', () {
      final source = _sentinelMap();

      final draft = MapDraft.fromWorldMap(source);
      final frozen = draft.freeze();

      _expectFrozenWorldMatches(frozen, source);
    });

    test('owns deep copies across persistence and freeze boundaries', () {
      final source = _sentinelMap();
      final draft = MapDraft.fromWorldMap(source);

      expect(draft.cols, 2);
      expect(draft.rows, 1);
      expect(draft.mapName, 'sentinel');
      expect(draft.defaultZoom, 1.75);
      expect(draft.objectives.single.id, 'pass_1');
      expect(draft.tileAt(1, 0)?.terrains, [
        TerrainType.hills,
        TerrainType.forest,
      ]);
      expect(() => draft.tiles.clear(), throwsUnsupportedError);
      expect(
        () => draft.tileAt(1, 0)!.terrains.add(TerrainType.river),
        throwsUnsupportedError,
      );

      final projected = draft.toWorldMap();
      expect(() => projected.tiles.clear(), throwsUnsupportedError);
      expect(() => projected.objectives.clear(), throwsUnsupportedError);

      expect(draft.tiles, hasLength(2));
      expect(draft.objectives.single.id, 'pass_1');
      expect(draft.mapName, 'sentinel');

      final frozen = draft.freeze(mapName: 'exported');
      expect(draft.mapName, 'sentinel');
      draft
        ..mapName = 'draft-change'
        ..defaultZoom = 2.5
        ..updateTile(
          col: 1,
          row: 0,
          terrains: const [TerrainType.desert],
          resources: const [],
          height: 1,
        )
        ..removeObjectiveAt(1, 0);

      expect(frozen.mapName, 'exported');
      expect(frozen.defaultZoom, 1.75);
      expect(frozen.objectives.single.id, 'pass_1');
      expect(frozen.tileAtHex(const HexCoord(col: 1, row: 0))?.terrains, [
        TerrainType.hills,
        TerrainType.forest,
      ]);
      expect(
        () => frozen.tiles.first.terrains.add(TerrainType.river),
        throwsUnsupportedError,
      );
    });

    test('keeps incomplete terrain editable until freeze', () {
      final draft = MapDraft.fromWorldMap(_sentinelMap());

      expect(draft.clearTerrainsAt(1, 0), isTrue);
      expect(draft.tileAt(1, 0)?.terrains, isEmpty);
      expect(() => draft.freeze(), throwsA(isA<WorldMapException>()));
      expect(draft.tileAt(1, 0)?.terrains, isEmpty);
    });

    test('validates tile values before map metadata when freezing', () {
      final draft = MapDraft.fromWorldMap(_sentinelMap())
        ..defaultZoom = 0
        ..clearTerrainsAt(1, 0);

      expect(
        draft.freeze,
        throwsA(
          isA<WorldMapException>().having(
            (error) => error.message,
            'message',
            'Tile terrains must not be empty',
          ),
        ),
      );
    });

    test('updates tiles and bounds while retaining valid objectives', () {
      const cols = MapConstraints.minCols + 1;
      const rows = MapConstraints.minRows + 1;
      final draft = MapDraft(
        cols: cols,
        rows: rows,
        tiles: [
          for (var row = 0; row < rows; row++)
            for (var col = 0; col < cols; col++)
              WorldTile(
                col: col,
                row: row,
                terrains: const [TerrainType.plains],
                resources: const [],
                height: 0,
              ),
        ],
        objectives: [
          const MapObjectiveDefinition(
            id: 'keep',
            type: MapObjectiveType.ruins,
            hex: HexCoord(col: 0, row: 0),
          ),
          const MapObjectiveDefinition(
            id: 'drop',
            type: MapObjectiveType.strategicPass,
            hex: HexCoord(col: cols - 1, row: rows - 1),
          ),
        ],
      );

      expect(
        draft.updateTile(
          col: 0,
          row: 0,
          terrains: const [TerrainType.desert],
          resources: const [ResourceType.iron],
          height: 2,
        ),
        isTrue,
      );
      expect(draft.removeColumn(), isTrue);
      expect(draft.removeRow(), isTrue);
      expect(draft.objectives.map((objective) => objective.id), ['keep']);
      expect(draft.addColumn(terrains: const [TerrainType.ocean]), isTrue);
      expect(draft.addRow(terrains: const [TerrainType.grassland]), isTrue);

      expect(draft.cols, cols);
      expect(draft.rows, rows);
      expect(draft.tileAt(0, 0)?.resources, [ResourceType.iron]);
      expect(draft.tileAt(cols - 1, 0)?.terrains, [TerrainType.ocean]);
      expect(draft.tileAt(0, rows - 1)?.terrains, [TerrainType.grassland]);
      expect(draft.freeze().objectives.single.id, 'keep');
    });

    test('keeps public resize operations within editor dimensions', () {
      final minDraft = _filledDraft(
        cols: MapConstraints.minCols,
        rows: MapConstraints.minRows,
      );
      final maxColsDraft = _filledDraft(cols: MapConstraints.maxCols, rows: 1);
      final maxRowsDraft = _filledDraft(cols: 1, rows: MapConstraints.maxRows);

      expect(minDraft.removeColumn(), isFalse);
      expect(minDraft.removeRow(), isFalse);
      expect(
        maxColsDraft.addColumn(terrains: const [TerrainType.ocean]),
        isFalse,
      );
      expect(maxRowsDraft.addRow(terrains: const [TerrainType.ocean]), isFalse);
    });

    test('rejects invalid dimensions, coordinates, and duplicate tiles', () {
      expect(() => MapDraft(cols: 0, rows: 1, tiles: []), throwsArgumentError);
      expect(
        () => MapDraft(
          cols: 1,
          rows: 1,
          tiles: [
            WorldTile(
              col: 1,
              row: 0,
              terrains: [TerrainType.ocean],
              resources: [],
              height: 0,
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => MapDraft(
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
            WorldTile(
              col: 0,
              row: 0,
              terrains: [TerrainType.plains],
              resources: [],
              height: 0,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}

MapDraft _filledDraft({required int cols, required int rows}) => MapDraft(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: [TerrainType.ocean],
          resources: [],
          height: 0,
        ),
  ],
);

WorldMap _sentinelMap() {
  final oceanTerrains = <TerrainType>[TerrainType.ocean];
  final hillsTerrains = <TerrainType>[TerrainType.hills, TerrainType.forest];
  final ironResources = <ResourceType>[ResourceType.iron];

  return WorldMap(
    cols: 2,
    rows: 1,
    mapName: 'sentinel',
    defaultZoom: 1.75,
    tiles: [
      WorldTile(
        col: 0,
        row: 0,
        terrains: oceanTerrains,
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 1,
        row: 0,
        terrains: hillsTerrains,
        resources: ironResources,
        height: 3,
      ),
    ],
    objectives: const [
      MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: HexCoord(col: 1, row: 0),
        requiredHoldTurns: 2,
        victoryPoints: 4,
        goldPerTurn: 1,
      ),
    ],
  );
}

void _expectFrozenWorldMatches(WorldMap world, WorldMap source) {
  expect(world.cols, source.cols);
  expect(world.rows, source.rows);
  expect(world.mapName, source.mapName);
  expect(world.defaultZoom, source.defaultZoom);
  expect(world.indexedTileCount, source.tiles.length);
  expect(
    world.tiles
        .map(
          (tile) => {
            'col': tile.col,
            'row': tile.row,
            'terrains': tile.terrains.toList(),
            'resources': tile.resources.toList(),
            'height': tile.height,
          },
        )
        .toList(),
    source.tiles
        .map(
          (tile) => {
            'col': tile.col,
            'row': tile.row,
            'terrains': tile.terrains.toList(),
            'resources': tile.resources.toList(),
            'height': tile.height,
          },
        )
        .toList(),
  );
  expect(
    world.objectives.map((objective) => objective.toJson()).toList(),
    source.objectives.map((objective) => objective.toJson()).toList(),
  );
}
