import 'dart:convert';

import 'package:aonw/editor/domain/map_draft.dart';
import 'package:aonw/map/domain/map_constraints.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/map/persistence.dart';
import 'package:aonw_core/map/persistence/legacy_world_map_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapDraft', () {
    test('preserves the complete legacy JSON contract through freeze', () {
      final source = _sentinelMap();
      final expectedJson = jsonDecode(MapDataCodec.toJson(source));

      final draft = MapDraft.fromMapData(source);
      final frozen = draft.freeze();
      final thawed = LegacyWorldMapAdapter.toMapData(frozen);

      expect(jsonDecode(MapDataCodec.toJson(thawed)), expectedJson);
      expect(frozen.tileAt(const HexCoord(col: 1, row: 0))?.height, 3);
      expect(frozen.objectives.single.hex, const HexCoord(col: 1, row: 0));
    });

    test('owns deep copies at both legacy boundaries', () {
      final source = _sentinelMap();
      final draft = MapDraft.fromMapData(source);

      source
        ..cols = 1
        ..rows = 1
        ..mapName = 'changed'
        ..defaultZoom = 3
        ..objectives = const [];
      source.tiles.first.terrains.add(TerrainType.river);
      source.tiles.clear();

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

      draft.toMapData()
        ..tiles.clear()
        ..objectives = const []
        ..mapName = 'legacy-change';

      expect(draft.tiles, hasLength(2));
      expect(draft.objectives.single.id, 'pass_1');
      expect(draft.mapName, 'sentinel');
    });

    test('keeps incomplete terrain editable until freeze', () {
      final draft = MapDraft.fromMapData(_sentinelMap());

      expect(draft.clearTerrainsAt(1, 0), isTrue);
      expect(draft.tileAt(1, 0)?.terrains, isEmpty);
      expect(() => draft.freeze(), throwsA(isA<WorldMapException>()));
      expect(draft.tileAt(1, 0)?.terrains, isEmpty);
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
              TileData(
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
  });
}

MapDraft _filledDraft({required int cols, required int rows}) => MapDraft(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: [TerrainType.ocean],
          resources: [],
          height: 0,
        ),
  ],
);

MapData _sentinelMap() {
  final oceanTerrains = <TerrainType>[TerrainType.ocean];
  final hillsTerrains = <TerrainType>[TerrainType.hills, TerrainType.forest];
  final ironResources = <ResourceType>[ResourceType.iron];

  return MapData(
    cols: 2,
    rows: 1,
    mapName: 'sentinel',
    defaultZoom: 1.75,
    tiles: [
      TileData(
        col: 0,
        row: 0,
        terrains: oceanTerrains,
        resources: [],
        height: 0,
      ),
      TileData(
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
