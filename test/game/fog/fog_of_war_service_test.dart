import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _landMap(int cols, int rows) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

void main() {
  group('FogOfWarService', () {
    test('keeps separate visibility state for each player', () {
      final map = _landMap(5, 5);
      final playerOneCommander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 0,
        row: 0,
      );
      final playerTwoCommander = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 4,
        row: 4,
      );

      final state = const FogOfWarService().recompute(
        current: FogOfWarState.empty,
        mapData: map,
        playerIds: const ['player_1', 'player_2'],
        units: [playerOneCommander, playerTwoCommander],
        cities: const [],
      );

      expect(
        state.visibilityFor('player_1', const HexCoordinate(col: 0, row: 0)),
        FogVisibility.visible,
      );
      expect(
        state.visibilityFor('player_1', const HexCoordinate(col: 4, row: 4)),
        FogVisibility.hidden,
      );
      expect(
        state.visibilityFor('player_2', const HexCoordinate(col: 4, row: 4)),
        FogVisibility.visible,
      );
    });

    test('preserves discovered memory after a unit moves away', () {
      final map = _landMap(5, 5);
      final initial = const FogOfWarService().recompute(
        current: FogOfWarState.empty,
        mapData: map,
        playerIds: const ['player_1'],
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_1')],
        cities: const [],
      );

      final moved = const FogOfWarService().recompute(
        current: initial,
        mapData: map,
        playerIds: const ['player_1'],
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 4, row: 4),
        ],
        cities: const [],
      );

      expect(
        moved.visibilityFor('player_1', const HexCoordinate(col: 0, row: 0)),
        FogVisibility.discovered,
      );
      expect(
        moved.visibilityFor('player_1', const HexCoordinate(col: 4, row: 4)),
        FogVisibility.visible,
      );
    });

    test('reveals city center and controlled territory', () {
      final map = _landMap(5, 5);
      const city = GameCity(
        id: 'city_player_1_2_2',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [CityHex(col: 3, row: 2)],
      );

      final state = const FogOfWarService().recompute(
        current: FogOfWarState.empty,
        mapData: map,
        playerIds: const ['player_1'],
        units: const [],
        cities: [city],
      );

      expect(
        state.visibilityFor('player_1', const HexCoordinate(col: 2, row: 2)),
        FogVisibility.visible,
      );
      expect(
        state.visibilityFor('player_1', const HexCoordinate(col: 3, row: 2)),
        FogVisibility.visible,
      );
    });

    test('unit on height=2 gets +1 vision range bonus', () {
      // 5x5 map, commander at (1,1) on height=2 tile, rest height=0
      final tiles = [
        for (var row = 0; row < 5; row++)
          for (var col = 0; col < 5; col++)
            TileData(
              col: col,
              row: row,
              terrains: const [TerrainType.plains],
              resources: const [],
              height: (col == 1 && row == 1) ? 2 : 0,
            ),
      ];
      final map = MapData(cols: 5, rows: 5, tiles: tiles);

      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );

      final state = const FogOfWarService().recompute(
        current: FogOfWarState.empty,
        mapData: map,
        playerIds: const ['player_1'],
        units: [commander],
        cities: const [],
      );

      // With height=2 bonus: range = 2 + floor(2/2) = 3
      // hex at (1,4) is 3 rows below (1,1), should be visible with range=3
      expect(
        state.visibilityFor('player_1', const HexCoordinate(col: 1, row: 4)),
        FogVisibility.visible,
      );
    });

    test('unit on height=0 does not get range bonus', () {
      final map = _landMap(5, 5); // all height=0
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );

      final state = const FogOfWarService().recompute(
        current: FogOfWarState.empty,
        mapData: map,
        playerIds: const ['player_1'],
        units: [commander],
        cities: const [],
      );

      // range=2, hex at distance 3 should remain hidden
      expect(
        state.visibilityFor('player_1', const HexCoordinate(col: 1, row: 4)),
        FogVisibility.hidden,
      );
    });

    test(
      'unit on off-map tile falls back to observerHeight=0 and base range',
      () {
        final map = _landMap(3, 3); // 3x3 map, no tile at (5,5)

        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 5,
          row: 5, // off-map
        );

        // Should not throw; off-map origin means no tiles revealed
        final state = const FogOfWarService().recompute(
          current: FogOfWarState.empty,
          mapData: map,
          playerIds: const ['player_1'],
          units: [commander],
          cities: const [],
        );

        // Off-map origin → calculator returns empty set (no tile at origin)
        expect(
          state.visibilityFor('player_1', const HexCoordinate(col: 0, row: 0)),
          FogVisibility.hidden,
        );
      },
    );

    test(
      'unit on height=4 is capped at maxVisionRange=3, does not see distance 4',
      () {
        final tiles = [
          for (var row = 0; row < 9; row++)
            for (var col = 0; col < 9; col++)
              TileData(
                col: col,
                row: row,
                terrains: const [TerrainType.plains],
                resources: const [],
                height: (col == 4 && row == 4) ? 4 : 0,
              ),
        ];
        final map = MapData(cols: 9, rows: 9, tiles: tiles);

        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 4,
          row: 4,
        );

        final state = const FogOfWarService().recompute(
          current: FogOfWarState.empty,
          mapData: map,
          playerIds: const ['player_1'],
          units: [commander],
          cities: const [],
        );

        // height=4: bonus=2, effectiveRange=clamp(4,0,3)=3
        // distance 3 tile should be visible
        expect(
          state.visibilityFor('player_1', const HexCoordinate(col: 4, row: 7)),
          FogVisibility.visible,
        );
        // distance 4 tile should NOT be visible (cap enforced, not range 4)
        expect(
          state.visibilityFor('player_1', const HexCoordinate(col: 4, row: 8)),
          FogVisibility.hidden,
        );
      },
    );
  });
}
