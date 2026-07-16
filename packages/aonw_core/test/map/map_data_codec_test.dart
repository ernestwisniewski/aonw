import 'dart:convert';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MapDataCodec canonical validation', () {
    test('describes load failures', () {
      expect(
        const MapDataLoadException('broken').toString(),
        'MapDataLoadException: broken',
      );
    });

    test('fromJson preserves exact validation messages', () {
      final cases =
          <({String name, Map<String, Object?> json, String message})>[
            (
              name: 'empty tile terrain',
              json: _jsonMap(terrains: const []),
              message: 'Tile terrains list must not be empty',
            ),
            (
              name: 'invalid dimensions',
              json: _jsonMap(cols: 0, tiles: const []),
              message: 'Map cols must be positive, got 0',
            ),
            (
              name: 'invalid default zoom',
              json: _jsonMap(defaultZoom: 0),
              message: 'Map default zoom must be finite and positive, got 0.0',
            ),
            (
              name: 'duplicate tile',
              json: _jsonMap(tiles: [_jsonTile(), _jsonTile()]),
              message: 'Duplicate tile at HexCoord(col: 0, row: 0)',
            ),
            (
              name: 'unknown terrain',
              json: _jsonMap(terrains: const ['volcano']),
              message: 'Unknown terrain type: volcano',
            ),
            (
              name: 'unknown resource',
              json: _jsonMap(resources: const ['amber']),
              message: 'Unknown resource type: amber',
            ),
            (
              name: 'tile col',
              json: _jsonMap(tileCol: 1),
              message: 'Tile col 1 out of range [0, 1)',
            ),
            (
              name: 'tile row',
              json: _jsonMap(tileRow: 1),
              message: 'Tile row 1 out of range [0, 1)',
            ),
            (
              name: 'tile height',
              json: _jsonMap(tileHeight: 6),
              message: 'Tile height 6 out of range [0, 5]',
            ),
            (
              name: 'invalid objective',
              json: _jsonMap(objectives: [_jsonObjective(id: ' ')]),
              message: 'Objective id must not be empty',
            ),
          ];

      for (final validationCase in cases) {
        expect(
          () => MapDataCodec.fromJson(jsonEncode(validationCase.json)),
          _failsToLoad(validationCase.message),
          reason: validationCase.name,
        );
      }
    });

    test('wraps malformed JSON failures', () {
      expect(
        () => MapDataCodec.fromJson('{'),
        throwsA(
          isA<MapDataLoadException>().having(
            (error) => error.message,
            'message',
            startsWith('Failed to parse map JSON: FormatException:'),
          ),
        ),
      );
    });

    test('toJson preserves exact canonical validation messages', () {
      final cases = <({String name, MapData map, String message})>[
        (
          name: 'invalid dimensions',
          map: _mapData(cols: 0, tiles: const []),
          message: 'Map cols must be positive, got 0',
        ),
        (
          name: 'invalid default zoom',
          map: _mapData(defaultZoom: 0),
          message: 'Map default zoom must be finite and positive, got 0.0',
        ),
        (
          name: 'duplicate tile',
          map: _mapData(tiles: const [_tile, _tile]),
          message: 'Duplicate tile at HexCoord(col: 0, row: 0)',
        ),
        (
          name: 'tile bounds',
          map: _mapData(
            tiles: const [
              TileData(
                col: 1,
                row: 0,
                terrains: [TerrainType.plains],
                resources: [],
                height: 0,
              ),
            ],
          ),
          message: 'Tile col 1 out of range [0, 1)',
        ),
        (
          name: 'invalid objective',
          map: _mapData(objectives: [_objective(id: ' ')]),
          message: 'Objective id must not be empty',
        ),
        (
          name: 'objective without tile',
          map: _mapData(
            cols: 2,
            objectives: [
              _objective(
                id: 'objective_1',
                hex: const HexCoord(col: 1, row: 0),
              ),
            ],
          ),
          message:
              'Objective objective_1 has no tile at HexCoord(col: 1, row: 0)',
        ),
        (
          name: 'tile validation precedes map metadata',
          map: _mapData(
            cols: 0,
            tiles: const [
              TileData(col: 0, row: 0, terrains: [], resources: [], height: 0),
            ],
          ),
          message: 'Tile terrains must not be empty',
        ),
      ];

      for (final validationCase in cases) {
        expect(
          () => MapDataCodec.toJson(validationCase.map),
          _failsToLoad(validationCase.message),
          reason: validationCase.name,
        );
      }
    });

    test('serializes optional metadata and tile payloads', () {
      final encoded = MapDataCodec.toJson(
        MapData(
          cols: 1,
          rows: 1,
          mapName: 'sentinel',
          defaultZoom: 1.5,
          tiles: const [
            TileData(
              col: 0,
              row: 0,
              terrains: [TerrainType.forest],
              resources: [ResourceType.deer],
              height: 2,
            ),
          ],
          objectives: [_objective(id: 'ruins')],
        ),
      );

      expect(jsonDecode(encoded), {
        'cols': 1,
        'rows': 1,
        'mapName': 'sentinel',
        'defaultZoom': 1.5,
        'objectives': [_jsonObjective(id: 'ruins')],
        'tiles': [
          {
            'col': 0,
            'row': 0,
            'terrains': ['forest'],
            'resources': ['deer'],
            'height': 2,
          },
        ],
      });
    });
  });
}

const _tile = TileData(
  col: 0,
  row: 0,
  terrains: [TerrainType.plains],
  resources: [],
  height: 0,
);

MapData _mapData({
  int cols = 1,
  double defaultZoom = 1,
  List<TileData> tiles = const [_tile],
  List<MapObjectiveDefinition> objectives = const [],
}) {
  return MapData(
    cols: cols,
    rows: 1,
    defaultZoom: defaultZoom,
    tiles: tiles,
    objectives: objectives,
  );
}

Map<String, Object?> _jsonMap({
  int cols = 1,
  num defaultZoom = 1,
  List<Map<String, Object?>>? tiles,
  List<Object?> objectives = const [],
  List<String> terrains = const ['plains'],
  List<String> resources = const [],
  int tileCol = 0,
  int tileRow = 0,
  int tileHeight = 0,
}) {
  return {
    'cols': cols,
    'rows': 1,
    'defaultZoom': defaultZoom,
    'tiles':
        tiles ??
        [
          _jsonTile(
            col: tileCol,
            row: tileRow,
            terrains: terrains,
            resources: resources,
            height: tileHeight,
          ),
        ],
    'objectives': objectives,
  };
}

Map<String, Object?> _jsonTile({
  int col = 0,
  int row = 0,
  List<String> terrains = const ['plains'],
  List<String> resources = const [],
  int height = 0,
}) {
  return {
    'col': col,
    'row': row,
    'terrains': terrains,
    'resources': resources,
    'height': height,
  };
}

Map<String, Object?> _jsonObjective({required String id}) {
  return {
    'id': id,
    'type': 'ruins',
    'hex': {'col': 0, 'row': 0},
    'requiredHoldTurns': 1,
  };
}

MapObjectiveDefinition _objective({
  required String id,
  HexCoord hex = const HexCoord(col: 0, row: 0),
}) {
  return MapObjectiveDefinition(
    id: id,
    type: MapObjectiveType.ruins,
    hex: hex,
    requiredHoldTurns: 1,
  );
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
