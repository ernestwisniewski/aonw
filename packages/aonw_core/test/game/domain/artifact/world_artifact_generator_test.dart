import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WorldArtifactGenerator', () {
    test('returns no artifacts when the map has no usable tiles', () {
      expect(
        WorldArtifactGenerator.generate(
          mapData: WorldMap(
            cols: 1,
            rows: 1,
            tiles: [
              _tile(0, 0, terrains: const [TerrainType.ocean]),
            ],
          ),
          startingUnits: const [],
        ),
        isEmpty,
      );
    });

    test('places each artifact once on an otherwise unconstrained map', () {
      final mapData = WorldMap(
        cols: 3,
        rows: 3,
        mapName: 'deterministic-seed',
        tiles: [
          for (var row = 0; row < 3; row++)
            for (var col = 0; col < 3; col++) _tile(col, row),
        ],
      );

      final first = WorldArtifactGenerator.generate(
        mapData: mapData,
        startingUnits: const [],
      );
      final second = WorldArtifactGenerator.generate(
        mapData: mapData,
        startingUnits: const [],
      );

      expect(first, hasLength(WorldArtifactGenerator.artifactCount));
      expect(
        first.map((artifact) => artifact.type),
        orderedEquals(WorldArtifactType.values),
      );
      expect(
        first.map(_locationKey).toSet(),
        hasLength(WorldArtifactGenerator.artifactCount),
      );
      expect(second.map(_locationKey), orderedEquals(first.map(_locationKey)));
    });

    test('ignores passable tiles unreachable from the starting unit', () {
      final mapData = WorldMap(
        cols: 7,
        rows: 3,
        tiles: [
          for (var row = 0; row < 3; row++)
            for (var col = 0; col < 7; col++)
              _tile(
                col,
                row,
                terrains: row == 1 && col <= 4
                    ? const [TerrainType.grassland]
                    : row == 1 && col == 6
                    ? const [TerrainType.grassland, TerrainType.hills]
                    : const [TerrainType.ocean],
                height: row == 1 && col == 6 ? 5 : 0,
              ),
        ],
      );
      final scout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 0,
        row: 1,
      );

      final artifacts = WorldArtifactGenerator.generate(
        mapData: mapData,
        startingUnits: [scout],
        seed: 1,
      );
      final locations = artifacts.map(_locationKey).toSet();

      expect(artifacts, isNotEmpty);
      expect(locations, isNot(contains('6:1')));
      expect(locations.difference(const {'1:1', '2:1', '3:1', '4:1'}), isEmpty);
    });

    test('rejects tiles beyond the starting unit movement capacity', () {
      final mapData = WorldMap(
        cols: 3,
        rows: 2,
        tiles: [
          for (var row = 0; row < 2; row++)
            for (var col = 0; col < 3; col++)
              _tile(
                col,
                row,
                terrains: row == 0 && col == 1
                    ? const [
                        TerrainType.snow,
                        TerrainType.forest,
                        TerrainType.hills,
                      ]
                    : const [TerrainType.grassland],
                resources: row == 0 && col == 1
                    ? const [ResourceType.coal]
                    : const [],
                height: row == 0 && col == 1 ? 5 : 0,
              ),
        ],
      );
      final warrior = GameUnit.startingWarrior(
        ownerPlayerId: 'p1',
        col: 0,
        row: 0,
      );

      final artifacts = WorldArtifactGenerator.generate(
        mapData: mapData,
        startingUnits: [warrior],
        seed: 1,
      );

      expect(artifacts, isNotEmpty);
      expect(artifacts.map(_locationKey), isNot(contains('1:0')));
    });

    test('accepts a pickup hex adjacent to the carrier return route', () {
      final mapData = WorldMap(
        cols: 2,
        rows: 1,
        tiles: [
          _tile(0, 0),
          _tile(1, 0, terrains: const [TerrainType.snow]),
        ],
      );
      final warrior = GameUnit.startingWarrior(
        ownerPlayerId: 'p1',
        col: 0,
        row: 0,
      );

      final artifacts = WorldArtifactGenerator.generate(
        mapData: mapData,
        startingUnits: [warrior],
        seed: 2,
      );

      expect(artifacts, hasLength(1));
      expect(_locationKey(artifacts.single), '1:0');
    });

    test('reserves starting and objective hexes', () {
      final mapData = WorldMap(
        cols: 5,
        rows: 1,
        objectives: const [
          MapObjectiveDefinition(
            id: 'pass_1',
            type: MapObjectiveType.strategicPass,
            hex: HexCoord(col: 2, row: 0),
            requiredHoldTurns: 2,
          ),
        ],
        tiles: [
          for (var col = 0; col < 5; col++)
            _tile(
              col,
              0,
              terrains: col == 2
                  ? const [
                      TerrainType.grassland,
                      TerrainType.hills,
                      TerrainType.forest,
                    ]
                  : const [TerrainType.grassland],
              height: col == 2 ? 5 : 0,
            ),
        ],
      );
      final scout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 0,
        row: 0,
      );

      final artifacts = WorldArtifactGenerator.generate(
        mapData: mapData,
        startingUnits: [scout],
        seed: 3,
      );
      final locations = artifacts.map(_locationKey).toSet();

      expect(artifacts, isNotEmpty);
      expect(locations, isNot(contains('0:0')));
      expect(locations, isNot(contains('2:0')));
    });
  });
}

String _locationKey(WorldArtifact artifact) {
  return '${artifact.location.col}:${artifact.location.row}';
}

WorldTile _tile(
  int col,
  int row, {
  List<TerrainType> terrains = const [TerrainType.grassland],
  List<ResourceType> resources = const [],
  int height = 0,
}) {
  return WorldTile(
    col: col,
    row: row,
    terrains: terrains,
    resources: resources,
    height: height,
  );
}
