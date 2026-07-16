import 'dart:collection';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('shared map domain', () {
    test('exposes terrain and resource parsers', () {
      expect(TerrainType.fromString('forest'), TerrainType.forest);
      expect(TerrainType.fromString('wetlands'), TerrainType.wetlands);
      expect(TerrainType.fromString('lake'), TerrainType.lake);
      expect(ResourceType.fromString('iron'), ResourceType.iron);
    });

    test('looks up tiles and preserves primary terrain fallback', () {
      final map = MapData(
        cols: 2,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [ResourceType.wheat],
            height: 1,
          ),
          TileData(col: 1, row: 0, terrains: [], resources: [], height: 0),
        ],
      );

      final MapTileSource source = map;

      expect(source.tileAt(0, 0)?.primaryTerrain, TerrainType.plains);
      expect(source.tileAt(1, 0)?.primaryTerrain, TerrainType.ocean);
      expect(source.tileAt(2, 0), isNull);
    });

    test('exposes MapData metadata and terrain survey without copies', () {
      final terrains = <TerrainType>[TerrainType.plains, TerrainType.river];
      final map = MapData(
        cols: 3,
        rows: 2,
        mapName: 'survey',
        tiles: [
          TileData(
            col: 2,
            row: 1,
            terrains: terrains,
            resources: const [],
            height: 1,
          ),
        ],
      );
      final MapReadView view = map;
      final terrainSurvey = view.tileTerrains;
      final tileViews = view.tileViews;

      expect(view.mapName, 'survey');
      expect(view.cols, 3);
      expect(view.rows, 2);
      expect(view.tileCount, 1);
      expect(identical(view.mapTiles, map), isTrue);
      expect(identical(view.objectives, map.objectives), isTrue);
      expect(identical(tileViews.first, map.tiles.first), isTrue);
      expect(identical(terrainSurvey.single, terrains), isTrue);
      expect(terrainSurvey.map((entry) => entry.toList()).toList(), [
        [TerrainType.plains, TerrainType.river],
      ]);
      expect(terrainSurvey.map((entry) => entry.toList()).toList(), [
        [TerrainType.plains, TerrainType.river],
      ]);
    });

    test(
      'indexed MapData view scans once and preserves borrowed tile semantics',
      () {
        const first = TileData(
          col: 1,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [ResourceType.wheat],
          height: 1,
        );
        const other = TileData(
          col: 2,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [],
          height: 0,
        );
        const objective = MapObjectiveDefinition(
          id: 'pass',
          type: MapObjectiveType.strategicPass,
          hex: HexCoord(col: 2, row: 0),
          requiredHoldTurns: 1,
          victoryPoints: 2,
          goldPerTurn: 1,
        );
        final tiles = _CountingTileList([first, other]);
        final map = MapData(
          cols: 3,
          rows: 1,
          tiles: tiles,
          objectives: const [objective],
          mapName: 'indexed',
        );

        final view = map.indexedReadView();

        expect(tiles.elementReads, tiles.length);
        tiles.resetElementReads();
        expect(identical(view.mapTiles, view), isTrue);
        expect(identical(view.tileAt(1, 0), first), isTrue);
        expect(identical(view.tileAt(1, 0), first), isTrue);
        expect(identical(view.tileAt(2, 0), other), isTrue);
        expect(view.tileAt(0, 0), isNull);
        expect(tiles.elementReads, 0);
        expect(view.tileCount, 2);
        expect(view.mapName, 'indexed');
        expect(identical(view.objectives, map.objectives), isTrue);
        expect(identical(view.tileViews.first, first), isTrue);
      },
    );

    test('indexed MapData view rejects duplicate coordinates', () {
      final map = MapData(
        cols: 1,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 0,
          ),
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.forest],
            resources: [],
            height: 1,
          ),
        ],
      );

      expect(
        map.indexedReadView,
        _failsWithWorldMapMessage('Duplicate tile at HexCoord(col: 0, row: 0)'),
      );
    });

    test('indexed MapData validation matches canonical map validation', () {
      final cases = <({String name, MapData map, String message})>[
        (
          name: 'cols',
          map: _mapData(cols: 0),
          message: 'Map cols must be positive, got 0',
        ),
        (
          name: 'rows',
          map: _mapData(rows: 0),
          message: 'Map rows must be positive, got 0',
        ),
        (
          name: 'default zoom',
          map: _mapData(defaultZoom: 0),
          message: 'Map default zoom must be finite and positive, got 0.0',
        ),
        (
          name: 'empty terrains',
          map: _mapData(terrains: const []),
          message: 'Tile terrains must not be empty',
        ),
        (
          name: 'height',
          map: _mapData(height: 6),
          message: 'Tile height 6 out of range [0, 5]',
        ),
        (
          name: 'tile bounds',
          map: _mapData(tileCol: 1),
          message: 'Tile col 1 out of range [0, 1)',
        ),
        (
          name: 'duplicate tile',
          map: _mapData(
            extraTiles: const [
              TileData(
                col: 0,
                row: 0,
                terrains: [TerrainType.forest],
                resources: [],
                height: 1,
              ),
            ],
          ),
          message: 'Duplicate tile at HexCoord(col: 0, row: 0)',
        ),
        (
          name: 'empty objective id',
          map: _mapData(objectives: [_objective(id: ' ')]),
          message: 'Objective id must not be empty',
        ),
        (
          name: 'duplicate objective id',
          map: _mapData(
            objectives: [
              _objective(),
              _objective(hex: const HexCoord(col: 0, row: 0)),
            ],
          ),
          message: 'Duplicate objective id: objective_1',
        ),
        (
          name: 'objective bounds',
          map: _mapData(
            objectives: [_objective(hex: const HexCoord(col: 1, row: 0))],
          ),
          message: 'Objective objective_1 col 1 out of range [0, 1)',
        ),
        (
          name: 'objective tile',
          map: _mapData(
            cols: 2,
            objectives: [_objective(hex: const HexCoord(col: 1, row: 0))],
          ),
          message:
              'Objective objective_1 has no tile at '
              'HexCoord(col: 1, row: 0)',
        ),
        (
          name: 'duplicate objective coordinate',
          map: _mapData(
            objectives: [
              _objective(),
              _objective(id: 'objective_2'),
            ],
          ),
          message: 'Duplicate objective at HexCoord(col: 0, row: 0)',
        ),
        (
          name: 'objective hold turns',
          map: _mapData(objectives: [_objective(requiredHoldTurns: 0)]),
          message: 'Objective objective_1 hold turns must be positive',
        ),
        (
          name: 'objective rewards',
          map: _mapData(objectives: [_objective(victoryPoints: -1)]),
          message: 'Objective objective_1 rewards must be non-negative',
        ),
      ];

      for (final validationCase in cases) {
        final indexedMessage = _worldMapFailureMessage(
          validationCase.map.indexedReadView,
        );
        final canonicalMessage = _worldMapFailureMessage(
          () => _worldMapFromData(validationCase.map),
        );

        expect(indexedMessage, canonicalMessage, reason: validationCase.name);
        expect(
          indexedMessage,
          validationCase.message,
          reason: validationCase.name,
        );
      }
    });

    test('uses odd-q hex topology', () {
      expect(
        HexGridTopology.neighbors(col: 0, row: 0),
        contains((col: 1, row: -1)),
      );
      expect(
        HexGridTopology.neighbors(col: 1, row: 0),
        contains((col: 2, row: 1)),
      );
    });
  });
}

WorldMap _worldMapFromData(MapData source) {
  return WorldMap.fromTileViews(
    cols: source.cols,
    rows: source.rows,
    tiles: source.tiles,
    objectives: source.objectives,
    mapName: source.mapName,
    defaultZoom: source.defaultZoom,
  );
}

MapData _mapData({
  int cols = 1,
  int rows = 1,
  double defaultZoom = 1,
  int tileCol = 0,
  List<TerrainType> terrains = const [TerrainType.plains],
  int height = 0,
  List<TileData> extraTiles = const [],
  List<MapObjectiveDefinition> objectives = const [],
}) {
  return MapData(
    cols: cols,
    rows: rows,
    defaultZoom: defaultZoom,
    tiles: [
      TileData(
        col: tileCol,
        row: 0,
        terrains: terrains,
        resources: const [],
        height: height,
      ),
      ...extraTiles,
    ],
    objectives: objectives,
  );
}

MapObjectiveDefinition _objective({
  String id = 'objective_1',
  HexCoord hex = const HexCoord(col: 0, row: 0),
  int requiredHoldTurns = 3,
  int victoryPoints = 0,
}) {
  return MapObjectiveDefinition(
    id: id,
    type: MapObjectiveType.ruins,
    hex: hex,
    requiredHoldTurns: requiredHoldTurns,
    victoryPoints: victoryPoints,
  );
}

String _worldMapFailureMessage(void Function() action) {
  try {
    action();
  } on WorldMapException catch (error) {
    return error.message;
  }
  throw StateError('Expected WorldMapException');
}

Matcher _failsWithWorldMapMessage(String message) {
  return throwsA(
    isA<WorldMapException>().having(
      (error) => error.message,
      'message',
      message,
    ),
  );
}

final class _CountingTileList extends ListBase<TileData> {
  _CountingTileList(List<TileData> values) : _values = List.of(values);

  final List<TileData> _values;
  int elementReads = 0;

  @override
  int get length => _values.length;

  @override
  set length(int value) => _values.length = value;

  @override
  TileData operator [](int index) {
    elementReads += 1;
    return _values[index];
  }

  @override
  void operator []=(int index, TileData value) => _values[index] = value;

  void resetElementReads() => elementReads = 0;
}
