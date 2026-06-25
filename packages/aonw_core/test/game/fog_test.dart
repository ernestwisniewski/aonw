import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('FogOfWarState', () {
    test('round-trips discovered and visible hexes through JSON', () {
      final state = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {const HexCoordinate(col: 1, row: 2)},
            visibleHexes: {const HexCoordinate(col: 2, row: 3)},
          ),
        },
      );

      final restored = FogOfWarState.fromJson(state.toJson());

      expect(restored, state);
      expect(
        restored.isVisible('player_1', const HexCoordinate(col: 2, row: 3)),
        isTrue,
      );
    });

    test('query treats empty player id as fully visible', () {
      const query = FogVisibilityQuery(
        playerId: '',
        state: FogOfWarState.empty,
      );

      expect(query.canSeeDynamicAt(99, 99), isTrue);
      expect(query.canRememberStaticAt(99, 99), isTrue);
    });
  });

  group('FogRevealCalculator', () {
    test('reveals source and adjacent passable tiles', () {
      final map = MapData(
        cols: 2,
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
            col: 1,
            row: 0,
            terrains: [TerrainType.forest],
            resources: [],
            height: 0,
          ),
        ],
      );

      final visible = const FogRevealCalculator().visibleHexesFor(
        mapData: map,
        sources: const [
          FogRevealSource(
            playerId: 'player_1',
            origin: HexCoordinate(col: 0, row: 0),
            range: 1,
          ),
        ],
      );

      expect(visible, {
        const HexCoordinate(col: 0, row: 0),
        const HexCoordinate(col: 1, row: 0),
      });
    });
  });
}
