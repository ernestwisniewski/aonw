import 'dart:collection';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('shared map domain', () {
    test('parses terrain and resources with explicit failures', () {
      expect(TerrainType.fromString('forest'), TerrainType.forest);
      expect(ResourceType.fromString('iron'), ResourceType.iron);
      expect(() => TerrainType.fromString('volcano'), throwsArgumentError);
      expect(() => ResourceType.fromString('amber'), throwsArgumentError);
    });

    test('owns deeply immutable tile and objective values', () {
      final terrains = <TerrainType>[TerrainType.plains];
      final objectives = <MapObjectiveDefinition>[_objective()];
      final map = WorldMap(
        cols: 1,
        rows: 1,
        tiles: [
          WorldTile(
            col: 0,
            row: 0,
            terrains: terrains,
            resources: const [ResourceType.wheat],
            height: 0,
          ),
        ],
        objectives: objectives,
      );

      terrains.add(TerrainType.river);
      objectives.clear();

      expect(map.tileAt(0, 0)?.terrains, [TerrainType.plains]);
      expect(map.objectives.single.id, 'objective_1');
      expect(() => map.tiles.clear(), throwsUnsupportedError);
      expect(() => map.tiles.single.terrains.clear(), throwsUnsupportedError);
      expect(() => map.objectives.clear(), throwsUnsupportedError);
    });

    test('builds its O(1) index once', () {
      final first = WorldTile(
        col: 1,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      );
      final second = WorldTile(
        col: 2,
        row: 0,
        terrains: [TerrainType.forest],
        resources: [],
        height: 1,
      );
      final source = _CountingTileList([first, second]);
      final map = WorldMap(cols: 3, rows: 1, tiles: source);
      final readsAfterConstruction = source.elementReads;

      expect(map.tileAt(1, 0)?.primaryTerrain, TerrainType.plains);
      expect(map.tileAtHex(const HexCoord(col: 2, row: 0))?.height, 1);
      expect(map.tileAt(0, 0), isNull);
      expect(source.elementReads, readsAfterConstruction);
      expect(map.indexedTileCount, 2);
    });

    test('rejects invalid maps at construction', () {
      expect(
        () => WorldMap(
          cols: 1,
          rows: 1,
          tiles: [
            WorldTile(col: 0, row: 0, terrains: [], resources: [], height: 0),
          ],
        ),
        throwsA(
          isA<WorldMapException>().having(
            (error) => error.message,
            'message',
            'Tile terrains must not be empty',
          ),
        ),
      );
    });
  });
}

MapObjectiveDefinition _objective() {
  return const MapObjectiveDefinition(
    id: 'objective_1',
    type: MapObjectiveType.ruins,
    hex: HexCoord(col: 0, row: 0),
    requiredHoldTurns: 3,
  );
}

final class _CountingTileList extends ListBase<WorldTile> {
  _CountingTileList(List<WorldTile> values) : _values = List.of(values);

  final List<WorldTile> _values;
  int elementReads = 0;

  @override
  int get length => _values.length;

  @override
  set length(int value) => _values.length = value;

  @override
  WorldTile operator [](int index) {
    elementReads += 1;
    return _values[index];
  }

  @override
  void operator []=(int index, WorldTile value) => _values[index] = value;
}
