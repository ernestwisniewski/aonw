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

  group('FogOfWarService', () {
    test('recomputes a moved unit owner without changing other players', () {
      final map = MapData(
        cols: 8,
        rows: 8,
        tiles: [
          for (var row = 0; row < 8; row++)
            for (var col = 0; col < 8; col++)
              TileData(
                col: col,
                row: row,
                terrains: const [TerrainType.plains],
                resources: const [],
                height: 0,
              ),
        ],
      );
      final playerOne = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 0,
        row: 0,
      );
      final playerTwo = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 7,
        row: 7,
      );
      final initial = const FogOfWarService().recompute(
        current: FogOfWarState.empty,
        mapData: map,
        playerIds: const ['player_1', 'player_2'],
        units: [playerOne, playerTwo],
        cities: const [],
      );
      final movedPlayerOne = playerOne.copyWith(col: 4, row: 4);
      final movedUnits = [movedPlayerOne, playerTwo];

      final incremental = const FogOfWarService().recomputePlayer(
        current: initial,
        mapData: map,
        playerId: 'player_1',
        units: movedUnits,
        cities: const [],
      );
      final full = const FogOfWarService().recompute(
        current: initial,
        mapData: map,
        playerIds: const ['player_1', 'player_2'],
        units: movedUnits,
        cities: const [],
      );

      expect(incremental, full);
      expect(
        incremental.fogForPlayer('player_2'),
        initial.fogForPlayer('player_2'),
      );
      expect(
        incremental.visibilityFor(
          'player_1',
          const HexCoordinate(col: 0, row: 0),
        ),
        FogVisibility.discovered,
      );
      expect(
        incremental.visibilityFor(
          'player_1',
          const HexCoordinate(col: 4, row: 6),
        ),
        FogVisibility.visible,
      );
    });

    test('ignores empty player ids when recomputing one player', () {
      final state = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        },
      );
      final map = MapData(cols: 1, rows: 1, tiles: const []);

      final next = const FogOfWarService().recomputePlayer(
        current: state,
        mapData: map,
        playerId: '',
        units: const [],
        cities: const [],
      );

      expect(next, state);
    });
  });
}
