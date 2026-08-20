import 'dart:convert';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WorldMapCodec canonical validation', () {
    test('describes load failures', () {
      expect(
        const WorldMapLoadException('broken').toString(),
        'WorldMapLoadException: broken',
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
              json: _jsonMap(cols: 0, tiles: []),
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
          () => WorldMapCodec.fromJson(jsonEncode(validationCase.json)),
          _failsToLoad(validationCase.message),
          reason: validationCase.name,
        );
      }
    });

    test('wraps malformed JSON failures', () {
      expect(
        () => WorldMapCodec.fromJson('{'),
        throwsA(
          isA<WorldMapLoadException>().having(
            (error) => error.message,
            'message',
            startsWith('Failed to parse map JSON: FormatException:'),
          ),
        ),
      );
    });

    test('serializes optional metadata and tile payloads', () {
      final encoded = WorldMapCodec.toJson(
        WorldMap(
          cols: 1,
          rows: 1,
          mapName: 'sentinel',
          defaultZoom: 1.5,
          tiles: [
            WorldTile.withTerrainSemantics(
              col: 0,
              row: 0,
              terrain: TileTerrainSemantics.fromAuthoredTerrainTags(const [
                TerrainType.forest,
              ]),
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
            'terrains': ['grassland', 'forest'],
            'displayTerrain': 'forest',
            'yieldTerrain': 'forest',
            'terrainTags': ['forest'],
            'resources': ['deer'],
            'height': 2,
          },
        ],
      });
    });
  });
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
    'displayTerrain': terrains.isEmpty ? 'plains' : terrains.first,
    'yieldTerrain': terrains.isEmpty ? 'plains' : terrains.first,
    'terrainTags': terrains.isEmpty ? const ['plains'] : terrains,
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
    isA<WorldMapLoadException>().having(
      (error) => error.message,
      'message',
      message,
    ),
  );
}
