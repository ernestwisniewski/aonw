import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WorldMapReadView', () {
    test('borrows canonical sparse tiles and metadata without projection', () {
      const objective = MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: HexCoord(col: 6, row: 4),
      );
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
          WorldTile(
            coordinate: const HexCoord(col: 1, row: 0),
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 1,
          ),
        ],
        objectives: const [objective],
      );
      final view = WorldMapReadView(world);

      expect(view.cols, 8);
      expect(view.rows, 6);
      expect(view.mapName, 'sparse');
      expect(view.tileCount, 2);
      expect(identical(view.mapTiles, view), isTrue);
      expect(identical(view.objectives, world.objectives), isTrue);
      expect(view.tileViews.map((tile) => (tile.col, tile.row)), [
        (6, 4),
        (1, 0),
      ]);
      expect(identical(view.tileViews.first, world.tiles.first), isTrue);
      expect(
        identical(view.tileTerrains.first, world.tiles.first.terrains),
        isTrue,
      );
    });

    test('preserves tile identity for hits and sparse misses', () {
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
      final firstView = WorldMapReadView(world);
      final secondView = WorldMapReadView(world);

      final first = firstView.tileAt(1, 0);
      final repeated = firstView.tileAt(1, 0);
      final fromSecondView = secondView.tileAt(1, 0);

      expect(first, isA<WorldTile>());
      expect(identical(first, repeated), isTrue);
      expect(identical(first, fromSecondView), isTrue);
      expect(
        identical(first, world.tileAt(const HexCoord(col: 1, row: 0))),
        isTrue,
      );
      expect(identical(first, firstView.tileViews.single), isTrue);
      expect(firstView.tileAt(0, 0), isNull);
      expect(secondView.tileAt(0, 0), isNull);
      expect(identical(firstView, secondView), isFalse);
    });

    test('exposes the canonical immutable tile collections', () {
      final world = WorldMap(
        cols: 1,
        rows: 1,
        tiles: [
          WorldTile(
            coordinate: const HexCoord(col: 0, row: 0),
            terrains: const [TerrainType.hills],
            resources: const [ResourceType.iron],
            height: 1,
          ),
        ],
      );
      final tile = WorldMapReadView(world).tileAt(0, 0)!;

      expect(identical(tile.terrains, world.tiles.single.terrains), isTrue);
      expect(identical(tile.resources, world.tiles.single.resources), isTrue);
      expect(
        () => tile.terrains.add(TerrainType.river),
        throwsUnsupportedError,
      );
      expect(() => tile.resources.clear(), throwsUnsupportedError);
    });
  });
}
