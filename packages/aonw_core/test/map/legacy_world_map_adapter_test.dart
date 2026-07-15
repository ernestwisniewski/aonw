import 'dart:convert';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('LegacyWorldMapAdapter', () {
    test('round-trips complete MapData without aliases', () {
      final terrains = <TerrainType>[TerrainType.hills, TerrainType.forest];
      final resources = <ResourceType>[ResourceType.iron, ResourceType.deer];
      final source = MapData(
        cols: 3,
        rows: 2,
        mapName: 'sentinel',
        defaultZoom: 1.75,
        tiles: [
          TileData(
            col: 2,
            row: 1,
            terrains: terrains,
            resources: resources,
            height: 5,
          ),
          const TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
        ],
        objectives: const [
          MapObjectiveDefinition(
            id: 'pass_1',
            type: MapObjectiveType.strategicPass,
            hex: HexCoord(col: 2, row: 1),
            requiredHoldTurns: 2,
            victoryPoints: 4,
            goldPerTurn: 1,
          ),
        ],
      );
      final expectedJson = jsonDecode(MapDataCodec.toJson(source));

      final world = LegacyWorldMapAdapter.fromMapData(source);
      final roundTripped = LegacyWorldMapAdapter.toMapData(world);
      final persisted = MapDataCodec.toJson(roundTripped);
      final reloadedWorld = LegacyWorldMapAdapter.fromMapData(
        MapDataCodec.fromJson(persisted),
      );

      expect(jsonDecode(MapDataCodec.toJson(roundTripped)), expectedJson);
      expect(
        jsonDecode(
          MapDataCodec.toJson(LegacyWorldMapAdapter.toMapData(reloadedWorld)),
        ),
        expectedJson,
      );
      expect(world.tiles.map((tile) => tile.coordinate), [
        const HexCoord(col: 2, row: 1),
        const HexCoord(col: 0, row: 0),
      ]);
      expect(world.objectives.single.hex, const HexCoord(col: 2, row: 1));

      terrains.add(TerrainType.river);
      resources.clear();
      source
        ..tiles.clear()
        ..objectives = const []
        ..cols = 1
        ..rows = 1
        ..mapName = 'mutated'
        ..defaultZoom = 3;

      expect(world.cols, 3);
      expect(world.rows, 2);
      expect(world.mapName, 'sentinel');
      expect(world.defaultZoom, 1.75);
      expect(world.tiles.first.terrains, [
        TerrainType.hills,
        TerrainType.forest,
      ]);
      expect(world.tiles.first.resources, [
        ResourceType.iron,
        ResourceType.deer,
      ]);
      expect(world.objectives, hasLength(1));

      roundTripped.tiles.first.terrains.add(TerrainType.river);
      roundTripped.tiles.first.resources.clear();
      roundTripped.tiles.clear();
      roundTripped.objectives = const [];
      expect(world.tiles, hasLength(2));
      expect(world.tiles.first.terrains, [
        TerrainType.hills,
        TerrainType.forest,
      ]);
      expect(world.tiles.first.resources, [
        ResourceType.iron,
        ResourceType.deer,
      ]);
      expect(world.objectives, hasLength(1));
    });

    test('makes the legacy codec enforce canonical invariants', () {
      final invalidObjectiveJson = jsonEncode({
        'cols': 1,
        'rows': 1,
        'tiles': [
          {
            'col': 0,
            'row': 0,
            'terrains': ['plains'],
            'resources': <String>[],
            'height': 0,
          },
        ],
        'objectives': [
          {
            'id': ' ',
            'type': 'ruins',
            'hex': {'col': 0, 'row': 0},
          },
        ],
      });

      expect(
        () => MapDataCodec.fromJson(invalidObjectiveJson),
        _failsToLoad('Objective id must not be empty'),
      );
      expect(
        () => MapDataCodec.toJson(MapData(cols: 0, rows: 1, tiles: [])),
        _failsToLoad('Map cols must be positive, got 0'),
      );
    });
  });
}

Matcher _failsToLoad(String message) {
  return throwsA(
    isA<MapDataLoadException>().having(
      (error) => error.message,
      'message',
      message,
    ),
  );
}
