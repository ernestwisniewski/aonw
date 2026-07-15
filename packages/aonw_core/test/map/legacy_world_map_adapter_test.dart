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

    test('projects an individual WorldMap tile without aliases', () {
      final world = WorldMap(
        cols: 2,
        rows: 1,
        tiles: [
          WorldTile(
            coordinate: const HexCoord(col: 1, row: 0),
            terrains: const [TerrainType.plains],
            resources: const [ResourceType.wheat],
            height: 2,
          ),
        ],
      );

      final tile = LegacyWorldMapAdapter.tileDataAt(world, 1, 0);

      expect(tile?.col, 1);
      expect(tile?.row, 0);
      expect(tile?.terrains, [TerrainType.plains]);
      expect(tile?.resources, [ResourceType.wheat]);
      expect(LegacyWorldMapAdapter.tileDataAt(world, 0, 0), isNull);
      expect(LegacyWorldMapAdapter.tileDataAt(null, 1, 0), isNull);

      tile!.terrains.add(TerrainType.river);
      tile.resources.clear();
      expect(world.tileAt(const HexCoord(col: 1, row: 0))?.terrains, [
        TerrainType.plains,
      ]);
      expect(world.tileAt(const HexCoord(col: 1, row: 0))?.resources, [
        ResourceType.wheat,
      ]);
    });

    test('exposes sparse tiles through bounded lookup without aliases', () {
      final world = WorldMap(
        cols: 8,
        rows: 6,
        tiles: [
          WorldTile(
            coordinate: const HexCoord(col: 6, row: 4),
            terrains: const [TerrainType.hills],
            resources: const [ResourceType.iron],
            height: 3,
          ),
        ],
      );
      final MapTileLookup lookup = LegacyWorldMapAdapter.asTileLookup(world);

      final first = lookup.tileAt(6, 4);

      expect(first?.col, 6);
      expect(first?.row, 4);
      expect(first?.terrains, [TerrainType.hills]);
      expect(first?.resources, [ResourceType.iron]);
      expect(first?.height, 3);
      expect(lookup.tileAt(0, 0), isNull);

      first!.terrains.add(TerrainType.river);
      first.resources.clear();
      final second = lookup.tileAt(6, 4);

      expect(identical(first, second), isFalse);
      expect(second?.terrains, [TerrainType.hills]);
      expect(second?.resources, [ResourceType.iron]);
      expect(world.tileAt(const HexCoord(col: 6, row: 4))?.terrains, [
        TerrainType.hills,
      ]);
      expect(world.tileAt(const HexCoord(col: 6, row: 4))?.resources, [
        ResourceType.iron,
      ]);
    });

    test('exposes a sparse, zero-copy terrain survey through a read view', () {
      final world = WorldMap(
        cols: 8,
        rows: 6,
        mapName: 'sparse',
        tiles: [
          WorldTile(
            coordinate: const HexCoord(col: 6, row: 4),
            terrains: const [TerrainType.hills, TerrainType.forest],
            resources: const [ResourceType.iron],
            height: 3,
          ),
        ],
      );

      final view = LegacyWorldMapAdapter.asReadView(world);
      final terrainSurvey = view.tileTerrains;

      expect(view.mapName, 'sparse');
      expect(view.tileCount, 1);
      expect(identical(view.mapTiles, view), isTrue);
      expect(
        identical(terrainSurvey.single, world.tiles.single.terrains),
        isTrue,
      );
      expect(terrainSurvey.map((terrains) => terrains.toList()).toList(), [
        [TerrainType.hills, TerrainType.forest],
      ]);
      expect(terrainSurvey.map((terrains) => terrains.toList()).toList(), [
        [TerrainType.hills, TerrainType.forest],
      ]);

      final projectedTile = view.mapTiles.tileAt(6, 4)!;
      expect(
        identical(projectedTile.terrains, world.tiles.single.terrains),
        false,
      );
      projectedTile.terrains.add(TerrainType.river);
      expect(world.tiles.single.terrains, [
        TerrainType.hills,
        TerrainType.forest,
      ]);
      expect(view.mapTiles.tileAt(0, 0), isNull);
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
