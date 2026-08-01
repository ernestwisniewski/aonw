import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/persistence/map_loader.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapLoader.fromJson', () {
    test('parses valid new-format JSON into WorldMap', () {
      const json = '''
      {
        "cols": 2,
        "rows": 2,
        "tiles": [
          { "col": 0, "row": 0, "terrains": ["grassland"], "resources": [], "height": 2 },
          { "col": 1, "row": 0, "terrains": ["ocean"],     "resources": [], "height": 0 },
          { "col": 0, "row": 1, "terrains": ["plains"],    "resources": ["iron"], "height": 3 },
          { "col": 1, "row": 1, "terrains": ["desert"],    "resources": [], "height": 5 }
        ]
      }
      ''';

      final data = MapLoader.fromJson(json);

      expect(data.cols, 2);
      expect(data.rows, 2);
      expect(data.tiles.length, 4);

      final tile0 = data.tiles[0];
      expect(tile0.col, 0);
      expect(tile0.row, 0);
      expect(tile0.primaryTerrain, TerrainType.grassland);
      expect(tile0.resources, isEmpty);
      expect(tile0.height, 2);

      final tile2 = data.tiles[2];
      expect(tile2.primaryTerrain, TerrainType.plains);
      expect(tile2.resources, [ResourceType.iron]);
      expect(tile2.height, 3);
    });

    test('height field is stored correctly at height=0', () {
      const json = '''
      {
        "cols": 1, "rows": 1,
        "tiles": [{ "col": 0, "row": 0, "terrains": ["ocean"], "resources": [], "height": 0 }]
      }
      ''';
      final data = MapLoader.fromJson(json);
      expect(data.tiles[0].height, 0);
    });

    test('height field is stored correctly at height=5', () {
      const json = '''
      {
        "cols": 1, "rows": 1,
        "tiles": [{ "col": 0, "row": 0, "terrains": ["snow"], "resources": [], "height": 5 }]
      }
      ''';
      final data = MapLoader.fromJson(json);
      expect(data.tiles[0].height, 5);
    });

    test('throws MapLoadException for unknown terrain', () {
      const json = '''
      {
        "cols": 1, "rows": 1,
        "tiles": [{ "col": 0, "row": 0, "terrains": ["lava"], "resources": [], "height": 1 }]
      }
      ''';
      expect(() => MapLoader.fromJson(json), throwsA(isA<MapLoadException>()));
    });

    test('throws MapLoadException for missing cols field', () {
      const json = '''
      {
        "rows": 1,
        "tiles": []
      }
      ''';
      expect(() => MapLoader.fromJson(json), throwsA(isA<MapLoadException>()));
    });

    test('throws MapLoadException for height out of range', () {
      const json = '''
      {
        "cols": 1, "rows": 1,
        "tiles": [{ "col": 0, "row": 0, "terrains": ["ocean"], "resources": [], "height": 6 }]
      }
      ''';
      expect(() => MapLoader.fromJson(json), throwsA(isA<MapLoadException>()));
    });

    test('throws MapLoadException when terrains list is empty', () {
      const json = '''
      {
        "cols": 1, "rows": 1,
        "tiles": [{ "col": 0, "row": 0, "terrains": [], "resources": [], "height": 0 }]
      }
      ''';
      expect(() => MapLoader.fromJson(json), throwsA(isA<MapLoadException>()));
    });
  });

  group('WorldTile.copyWith', () {
    test('changes only terrains', () {
      final tile = WorldTile(
        col: 1,
        row: 2,
        terrains: [TerrainType.ocean],
        resources: [],
        height: 3,
      );
      final copy = tile.copyWith(terrains: [TerrainType.desert]);
      expect(copy.col, 1);
      expect(copy.row, 2);
      expect(copy.terrains, [TerrainType.desert]);
      expect(copy.resources, isEmpty);
      expect(copy.height, 3);
    });

    test('changes resources to non-empty', () {
      final tile = WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 1,
      );
      final copy = tile.copyWith(resources: [ResourceType.iron]);
      expect(copy.resources, [ResourceType.iron]);
      expect(copy.primaryTerrain, TerrainType.grassland);
    });

    test('clears resources by passing empty list', () {
      final tile = WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [ResourceType.iron],
        height: 1,
      );
      final copy = tile.copyWith(resources: []);
      expect(copy.resources, isEmpty);
    });

    test('changes height', () {
      final tile = WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      );
      final copy = tile.copyWith(height: 5);
      expect(copy.height, 5);
    });
  });

  group('WorldTile.toJson', () {
    test('serializes all fields in new format', () {
      final tile = WorldTile(
        col: 3,
        row: 2,
        terrains: [TerrainType.plains],
        resources: [ResourceType.iron],
        height: 2,
      );
      final json = tile.toJson();
      expect(json['col'], 3);
      expect(json['row'], 2);
      expect(json['terrains'], ['plains']);
      expect(json['resources'], ['iron']);
      expect(json['height'], 2);
    });

    test('serializes empty resources as empty list', () {
      final tile = WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.ocean],
        resources: [],
        height: 0,
      );
      final json = tile.toJson();
      expect(json['resources'], isEmpty);
    });
  });

  group('WorldTile.primaryTerrain', () {
    test('returns first terrain when list is non-empty', () {
      final tile = WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains, TerrainType.grassland],
        resources: [],
        height: 0,
      );
      expect(tile.primaryTerrain, TerrainType.plains);
    });

    test('returns ocean when terrains is empty', () {
      final tile = WorldTile(
        col: 0,
        row: 0,
        terrains: [],
        resources: [],
        height: 0,
      );
      expect(tile.primaryTerrain, TerrainType.ocean);
    });
  });

  group('mapName', () {
    test('toJson includes mapName when set', () {
      final mapData = WorldMap(
        cols: 2,
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
          WorldTile(
            col: 1,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 1,
            row: 1,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
        ],
        mapName: 'mymap',
      );
      final json = MapLoader.toJson(mapData);
      expect(json, contains('"mapName": "mymap"'));
    });

    test('toJson omits mapName when null', () {
      final mapData = WorldMap(
        cols: 2,
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
          WorldTile(
            col: 1,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
          WorldTile(
            col: 1,
            row: 1,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
        ],
      );
      final json = MapLoader.toJson(mapData);
      expect(json, isNot(contains('mapName')));
    });

    test('fromJson reads mapName', () {
      const jsonStr = '''
{
  "cols": 2,
  "rows": 1,
  "mapName": "testmap",
  "tiles": [
    {"col": 0, "row": 0, "terrains": ["ocean"], "resources": [], "height": 0},
    {"col": 1, "row": 0, "terrains": ["ocean"], "resources": [], "height": 0}
  ]
}''';
      final mapData = MapLoader.fromJson(jsonStr);
      expect(mapData.mapName, 'testmap');
    });

    test('fromJson mapName null when missing', () {
      const jsonStr = '''
{
  "cols": 2,
  "rows": 1,
  "tiles": [
    {"col": 0, "row": 0, "terrains": ["ocean"], "resources": [], "height": 0},
    {"col": 1, "row": 0, "terrains": ["ocean"], "resources": [], "height": 0}
  ]
}''';
      final mapData = MapLoader.fromJson(jsonStr);
      expect(mapData.mapName, isNull);
    });
  });

  group('objectives', () {
    test('fromJson reads map objectives', () {
      const jsonStr = '''
{
  "cols": 2,
  "rows": 1,
  "objectives": [
    {
      "id": "pass_1",
      "type": "strategicPass",
      "hex": {"col": 1, "row": 0},
      "requiredHoldTurns": 2,
      "victoryPoints": 3
    }
  ],
  "tiles": [
    {"col": 0, "row": 0, "terrains": ["plains"], "resources": [], "height": 1},
    {"col": 1, "row": 0, "terrains": ["hills"], "resources": [], "height": 3}
  ]
}''';

      final mapData = MapLoader.fromJson(jsonStr);

      expect(mapData.objectives, hasLength(1));
      expect(mapData.objectives.single.id, 'pass_1');
      expect(mapData.objectives.single.type, MapObjectiveType.strategicPass);
      expect(mapData.objectives.single.hex.col, 1);
      expect(mapData.objectives.single.requiredHoldTurns, 2);
      expect(mapData.objectives.single.victoryPoints, 3);
    });

    test('toJson writes map objectives when present', () {
      final mapData = WorldMap(
        cols: 1,
        rows: 1,
        objectives: const [
          MapObjectiveDefinition(
            id: 'holy_1',
            type: MapObjectiveType.holySite,
            hex: HexCoord(col: 0, row: 0),
            goldPerTurn: 2,
          ),
        ],
        tiles: [
          WorldTile(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 1,
          ),
        ],
      );

      final json = MapLoader.toJson(mapData);
      final restored = MapLoader.fromJson(json);

      expect(json, contains('"objectives"'));
      expect(restored.objectives.single.id, 'holy_1');
      expect(restored.objectives.single.goldPerTurn, 2);
    });

    test('toJson omits objectives when empty', () {
      final mapData = WorldMap(
        cols: 1,
        rows: 1,
        tiles: [
          WorldTile(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 1,
          ),
        ],
      );

      expect(MapLoader.toJson(mapData), isNot(contains('objectives')));
    });
  });
}
