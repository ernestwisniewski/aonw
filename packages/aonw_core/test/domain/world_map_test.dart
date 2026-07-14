import 'package:aonw_core/domain.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:test/test.dart';

void main() {
  group('WorldMap', () {
    test('keeps ordered sparse tiles and uses the coordinate index', () {
      final map = WorldMap(
        cols: 3,
        rows: 2,
        mapName: 'sparse',
        defaultZoom: 1.5,
        tiles: [
          _tile(2, 1),
          _tile(0, 0, terrains: const [TerrainType.plains]),
        ],
      );

      expect(map.cols, 3);
      expect(map.rows, 2);
      expect(map.mapName, 'sparse');
      expect(map.defaultZoom, 1.5);
      expect(map.indexedTileCount, 2);
      expect(map.tiles.map((tile) => tile.coordinate), [
        const HexCoord(col: 2, row: 1),
        const HexCoord(col: 0, row: 0),
      ]);
      expect(
        map.tileAt(const HexCoord(col: 0, row: 0))?.primaryTerrain,
        TerrainType.plains,
      );
      expect(
        map.tileAt(const HexCoord(col: 2, row: 1))?.primaryTerrain,
        TerrainType.ocean,
      );
      expect(map.tileAt(const HexCoord(col: 1, row: 0)), isNull);
    });

    test('defensively freezes every exposed collection', () {
      final terrains = <TerrainType>[TerrainType.forest];
      final resources = <ResourceType>[ResourceType.deer];
      final tile = WorldTile(
        coordinate: const HexCoord(col: 0, row: 0),
        terrains: terrains,
        resources: resources,
        height: 2,
      );
      final tiles = <WorldTile>[tile];
      final objectives = <MapObjectiveDefinition>[_objective()];
      final map = WorldMap(
        cols: 1,
        rows: 1,
        tiles: tiles,
        objectives: objectives,
      );

      terrains.add(TerrainType.hills);
      resources.add(ResourceType.iron);
      tiles.clear();
      objectives.clear();

      expect(tile.terrains, [TerrainType.forest]);
      expect(tile.resources, [ResourceType.deer]);
      expect(map.tiles, [tile]);
      expect(map.objectives.single.id, 'objective_1');
      expect(
        () => tile.terrains.add(TerrainType.hills),
        throwsUnsupportedError,
      );
      expect(() => tile.resources.clear(), throwsUnsupportedError);
      expect(() => map.tiles.clear(), throwsUnsupportedError);
      expect(() => map.objectives.clear(), throwsUnsupportedError);
    });

    test('rejects invalid dimensions', () {
      expect(
        () => WorldMap(cols: 0, rows: 1, tiles: const []),
        _failsWith('Map cols must be positive, got 0'),
      );
      expect(
        () => WorldMap(cols: 1, rows: 0, tiles: const []),
        _failsWith('Map rows must be positive, got 0'),
      );
      expect(
        () => WorldMap(cols: 1, rows: 1, tiles: const [], defaultZoom: 0),
        _failsContaining('default zoom must be finite and positive'),
      );
      expect(
        () => WorldMap(
          cols: 1,
          rows: 1,
          tiles: const [],
          defaultZoom: double.infinity,
        ),
        _failsContaining('default zoom must be finite and positive'),
      );
    });

    test('rejects invalid tile data', () {
      expect(
        () => _tile(0, 0, terrains: const []),
        _failsWith('Tile terrains must not be empty'),
      );
      expect(() => _tile(0, 0, height: -1), _failsContaining('height -1'));
      expect(() => _tile(0, 0, height: 6), _failsContaining('height 6'));
    });

    test('rejects out-of-bounds and duplicate tiles', () {
      expect(
        () => WorldMap(cols: 1, rows: 1, tiles: [_tile(-1, 0)]),
        _failsContaining('Tile col -1'),
      );
      expect(
        () => WorldMap(cols: 1, rows: 1, tiles: [_tile(0, 1)]),
        _failsContaining('Tile row 1'),
      );
      expect(
        () => WorldMap(cols: 1, rows: 1, tiles: [_tile(0, 0), _tile(0, 0)]),
        _failsContaining('Duplicate tile at HexCoord(col: 0, row: 0)'),
      );
    });

    test('accepts valid objective defaults and zero rewards', () {
      final objective = _objective();
      final map = WorldMap(
        cols: 1,
        rows: 1,
        tiles: [_tile(0, 0)],
        objectives: [objective],
      );

      expect(map.objectives, [objective]);
      expect(objective.requiredHoldTurns, 3);
      expect(objective.victoryPoints, 0);
      expect(objective.goldPerTurn, 0);
    });

    test('rejects invalid objective identity and placement', () {
      expect(
        () => _worldWithObjective(_objective(id: '  ')),
        _failsContaining('Objective id must not be empty'),
      );
      expect(
        () => WorldMap(
          cols: 1,
          rows: 1,
          tiles: [_tile(0, 0)],
          objectives: [_objective(), _objective()],
        ),
        _failsContaining('Duplicate objective id: objective_1'),
      );
      expect(
        () => _worldWithObjective(
          _objective(hex: const HexCoord(col: 1, row: 0)),
        ),
        _failsContaining('Objective objective_1 col 1'),
      );
      expect(
        () => WorldMap(
          cols: 2,
          rows: 1,
          tiles: [_tile(0, 0)],
          objectives: [_objective(hex: const HexCoord(col: 1, row: 0))],
        ),
        _failsContaining('Objective objective_1 has no tile'),
      );
      expect(
        () => WorldMap(
          cols: 1,
          rows: 1,
          tiles: [_tile(0, 0)],
          objectives: [
            _objective(),
            _objective(id: 'objective_2'),
          ],
        ),
        _failsContaining('Duplicate objective at HexCoord(col: 0, row: 0)'),
      );
    });

    test('rejects invalid objective turns and rewards', () {
      expect(
        () => _worldWithObjective(_objective(requiredHoldTurns: 0)),
        _failsContaining('hold turns must be positive'),
      );
      expect(
        () => _worldWithObjective(_objective(victoryPoints: -1)),
        _failsContaining('rewards must be non-negative'),
      );
      expect(
        () => _worldWithObjective(_objective(goldPerTurn: -1)),
        _failsContaining('rewards must be non-negative'),
      );
    });

    test('reports typed validation failures', () {
      expect(
        const WorldMapException('sentinel').toString(),
        'WorldMapException: sentinel',
      );
    });
  });

  group('MapObjectiveDefinition', () {
    test('keeps its existing JSON shape with a canonical coordinate', () {
      final objective = MapObjectiveDefinition.fromJson({
        'id': 'pass_1',
        'type': 'strategicPass',
        'hex': {'col': 2, 'row': 1},
        'requiredHoldTurns': 2,
        'victoryPoints': 4,
        'goldPerTurn': 1,
      });

      expect(objective.type, MapObjectiveType.strategicPass);
      expect(objective.hex, const HexCoord(col: 2, row: 1));
      expect(objective.toJson(), {
        'id': 'pass_1',
        'type': 'strategicPass',
        'hex': {'col': 2, 'row': 1},
        'requiredHoldTurns': 2,
        'victoryPoints': 4,
        'goldPerTurn': 1,
      });
      expect(_objective().toJson(), {
        'id': 'objective_1',
        'type': 'ruins',
        'hex': {'col': 0, 'row': 0},
      });
    });
  });
}

WorldMap _worldWithObjective(MapObjectiveDefinition objective) {
  return WorldMap(
    cols: 1,
    rows: 1,
    tiles: [_tile(0, 0)],
    objectives: [objective],
  );
}

WorldTile _tile(
  int col,
  int row, {
  List<TerrainType> terrains = const [TerrainType.ocean],
  List<ResourceType> resources = const [],
  int height = 0,
}) {
  return WorldTile(
    coordinate: HexCoord(col: col, row: row),
    terrains: terrains,
    resources: resources,
    height: height,
  );
}

MapObjectiveDefinition _objective({
  String id = 'objective_1',
  HexCoord hex = const HexCoord(col: 0, row: 0),
  int requiredHoldTurns = 3,
  int victoryPoints = 0,
  int goldPerTurn = 0,
}) {
  return MapObjectiveDefinition(
    id: id,
    type: MapObjectiveType.ruins,
    hex: hex,
    requiredHoldTurns: requiredHoldTurns,
    victoryPoints: victoryPoints,
    goldPerTurn: goldPerTurn,
  );
}

Matcher _failsWith(String message) {
  return throwsA(
    isA<WorldMapException>().having(
      (error) => error.message,
      'message',
      message,
    ),
  );
}

Matcher _failsContaining(String message) {
  return throwsA(
    isA<WorldMapException>().having(
      (error) => error.message,
      'message',
      contains(message),
    ),
  );
}
