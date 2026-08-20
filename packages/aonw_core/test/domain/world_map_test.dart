import 'package:aonw_core/domain.dart';
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
        map.tileAtHex(const HexCoord(col: 0, row: 0))?.displayTerrain,
        TerrainType.plains,
      );
      expect(
        map.tileAtHex(const HexCoord(col: 2, row: 1))?.displayTerrain,
        TerrainType.ocean,
      );
      expect(map.tileAtHex(const HexCoord(col: 1, row: 0)), isNull);
    });

    test(
      'copyWith preserves defaults and supports explicit metadata changes',
      () {
        final original = WorldMap(
          cols: 1,
          rows: 1,
          mapName: 'original',
          defaultZoom: 1.25,
          tiles: [_tile(0, 0)],
          objectives: [_objective()],
        );

        final unchanged = original.copyWith();
        final updated = original.copyWith(
          cols: 2,
          rows: 2,
          tiles: [_tile(1, 1)],
          objectives: const [],
          mapName: null,
          defaultZoom: 2,
        );

        expect(unchanged.cols, original.cols);
        expect(unchanged.rows, original.rows);
        expect(
          unchanged.tiles.map((tile) => tile.coordinate),
          original.tiles.map((tile) => tile.coordinate),
        );
        expect(unchanged.objectives, original.objectives);
        expect(unchanged.mapName, original.mapName);
        expect(unchanged.defaultZoom, original.defaultZoom);
        expect(updated.cols, 2);
        expect(updated.rows, 2);
        expect(updated.tiles.single.coordinate, const HexCoord(col: 1, row: 1));
        expect(updated.objectives, isEmpty);
        expect(updated.mapName, isNull);
        expect(updated.defaultZoom, 2);
        expect(original.mapName, 'original');
      },
    );

    test('defensively freezes every exposed collection', () {
      final terrains = <TerrainType>[TerrainType.forest];
      final resources = <ResourceType>[ResourceType.deer];
      final tile = WorldTile.at(
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

      expect(map.tiles.single.terrains, [
        TerrainType.grassland,
        TerrainType.forest,
      ]);
      expect(map.tiles.single.terrainTags, [TerrainType.forest]);
      expect(map.tiles.single.resources, [ResourceType.deer]);
      expect(map.objectives.single.id, 'objective_1');
      expect(
        () => map.tiles.single.terrains.add(TerrainType.hills),
        throwsUnsupportedError,
      );
      expect(() => map.tiles.single.resources.clear(), throwsUnsupportedError);
      expect(() => map.tiles.clear(), throwsUnsupportedError);
      expect(() => map.objectives.clear(), throwsUnsupportedError);
    });

    test('freezes representation-neutral tiles in their source order', () {
      final objective = _objective(hex: const HexCoord(col: 2, row: 1));
      final map = WorldMap.fromTileViews(
        cols: 3,
        rows: 2,
        mapName: 'views',
        defaultZoom: 1.75,
        tiles: [
          WorldTile(
            col: 2,
            row: 1,
            terrains: [
              TerrainType.plains,
              TerrainType.hills,
              TerrainType.forest,
            ],
            resources: [ResourceType.iron],
            height: 3,
          ),
          WorldTile(
            col: 0,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
        ],
        objectives: [objective],
      );

      expect(map.cols, 3);
      expect(map.rows, 2);
      expect(map.mapName, 'views');
      expect(map.defaultZoom, 1.75);
      expect(map.objectives, [objective]);
      expect(map.tiles.map((tile) => tile.coordinate), [
        const HexCoord(col: 2, row: 1),
        const HexCoord(col: 0, row: 0),
      ]);
      expect(map.tiles.first.terrains, [
        TerrainType.plains,
        TerrainType.hills,
        TerrainType.forest,
      ]);
      expect(map.tiles.first.resources, [ResourceType.iron]);
      expect(map.tiles.first.height, 3);
    });

    test('deeply freezes mutable tile views', () {
      final tile = _MutableTileView(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland, TerrainType.forest],
        resources: [ResourceType.deer],
        height: 2,
      );
      final tiles = <MapTileView>[tile];
      final objectives = <MapObjectiveDefinition>[_objective()];
      final map = WorldMap.fromTileViews(
        cols: 1,
        rows: 1,
        tiles: tiles,
        objectives: objectives,
      );

      tile
        ..col = 1
        ..row = 1
        ..height = 5
        ..terrains.add(TerrainType.hills)
        ..resources.clear();
      tiles.clear();
      objectives.clear();

      expect(map.tiles.single.coordinate, const HexCoord(col: 0, row: 0));
      expect(map.tiles.single.height, 2);
      expect(map.tiles.single.terrains, [
        TerrainType.grassland,
        TerrainType.forest,
      ]);
      expect(map.tiles.single.resources, [ResourceType.deer]);
      expect(map.objectives.single.id, 'objective_1');
      expect(map.tiles.single, isNot(same(tile)));
      expect(() => map.tiles.clear(), throwsUnsupportedError);
      expect(() => map.tiles.single.terrains.clear(), throwsUnsupportedError);
      expect(() => map.tiles.single.resources.clear(), throwsUnsupportedError);
    });

    test('freezes tile values before validating map metadata', () {
      expect(
        () => WorldMap.fromTileViews(
          cols: 0,
          rows: 1,
          defaultZoom: 0,
          tiles: [
            WorldTile(col: 0, row: 0, terrains: [], resources: [], height: 0),
          ],
        ),
        _failsTerrainSemanticsWith('Authored terrain tags must not be empty'),
      );
    });

    test('rejects invalid dimensions', () {
      expect(
        () => WorldMap(cols: 0, rows: 1, tiles: []),
        _failsWith('Map cols must be positive, got 0'),
      );
      expect(
        () => WorldMap(cols: 1, rows: 0, tiles: []),
        _failsWith('Map rows must be positive, got 0'),
      );
      expect(
        () => WorldMap(cols: 1, rows: 1, tiles: [], defaultZoom: 0),
        _failsContaining('default zoom must be finite and positive'),
      );
      expect(
        () =>
            WorldMap(cols: 1, rows: 1, tiles: [], defaultZoom: double.infinity),
        _failsContaining('default zoom must be finite and positive'),
      );
    });

    test('rejects invalid tile data', () {
      expect(
        () => WorldMap(
          cols: 1,
          rows: 1,
          tiles: [_tile(0, 0, terrains: const [])],
        ),
        _failsTerrainSemanticsWith('Authored terrain tags must not be empty'),
      );
      expect(
        () => WorldMap(cols: 1, rows: 1, tiles: [_tile(0, 0, height: -1)]),
        _failsContaining('height -1'),
      );
      expect(
        () => WorldMap(cols: 1, rows: 1, tiles: [_tile(0, 0, height: 6)]),
        _failsContaining('height 6'),
      );
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
  return WorldTile.at(
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

Matcher _failsTerrainSemanticsWith(String message) {
  return throwsA(
    isA<TileTerrainSemanticsException>().having(
      (error) => error.message,
      'message',
      message,
    ),
  );
}

final class _MutableTileView implements MapTileView {
  _MutableTileView({
    required this.col,
    required this.row,
    required this.terrains,
    required this.resources,
    required this.height,
  });

  @override
  int col;

  @override
  int row;

  final List<TerrainType> terrains;

  @override
  TileTerrainSemantics get terrain =>
      TileTerrainSemantics.fromMovementProfile(terrains);

  @override
  final List<ResourceType> resources;

  @override
  int height;
}
