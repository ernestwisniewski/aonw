import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map(List<TileData> tiles) {
  return MapData(cols: 5, rows: 5, tiles: tiles);
}

TileData _tile(
  int col,
  int row, {
  List<TerrainType> terrains = const [TerrainType.plains],
  int height = 0,
}) {
  return TileData(
    col: col,
    row: row,
    terrains: terrains,
    resources: const [],
    height: height,
  );
}

void main() {
  group('FogRevealCalculator', () {
    test('reveals source and passable neighbors within range', () {
      final map = _map([_tile(1, 1), _tile(2, 1), _tile(1, 2), _tile(0, 1)]);

      final visible = const FogRevealCalculator().visibleHexesFor(
        mapData: map,
        sources: const [
          FogRevealSource(
            playerId: 'player_1',
            origin: HexCoordinate(col: 1, row: 1),
            range: 1,
          ),
        ],
      );

      expect(visible, {
        const HexCoordinate(col: 1, row: 1),
        const HexCoordinate(col: 2, row: 1),
        const HexCoordinate(col: 1, row: 2),
        const HexCoordinate(col: 0, row: 1),
      });
    });

    test('multi-terrain forest hills costs more sight range', () {
      final map = _map([
        _tile(1, 1),
        _tile(
          2,
          1,
          terrains: const [
            TerrainType.plains,
            TerrainType.forest,
            TerrainType.hills,
          ],
        ),
        _tile(3, 1),
      ]);

      final shortRange = const FogRevealCalculator().visibleHexesFor(
        mapData: map,
        sources: const [
          FogRevealSource(
            playerId: 'player_1',
            origin: HexCoordinate(col: 1, row: 1),
            range: 2,
          ),
        ],
      );
      final longRange = const FogRevealCalculator().visibleHexesFor(
        mapData: map,
        sources: const [
          FogRevealSource(
            playerId: 'player_1',
            origin: HexCoordinate(col: 1, row: 1),
            range: 3,
          ),
        ],
      );

      // (2,1) is a direct neighbour — always visible regardless of sight cost.
      expect(shortRange, {
        const HexCoordinate(col: 1, row: 1),
        const HexCoordinate(col: 2, row: 1),
      });
      // (3,1) is behind (2,1) which costs 3 — not reachable even at range=3
      // because the full path cost would be 3+1=4.
      expect(longRange, {
        const HexCoordinate(col: 1, row: 1),
        const HexCoordinate(col: 2, row: 1),
      });
    });

    test('mountain can be seen but blocks propagation behind it', () {
      final map = _map([
        _tile(1, 1),
        _tile(2, 1, terrains: const [TerrainType.mountain]),
        _tile(3, 1),
      ]);

      final visible = const FogRevealCalculator().visibleHexesFor(
        mapData: map,
        sources: const [
          FogRevealSource(
            playerId: 'player_1',
            origin: HexCoordinate(col: 1, row: 1),
            range: 3,
          ),
        ],
      );

      expect(visible, {
        const HexCoordinate(col: 1, row: 1),
        const HexCoordinate(col: 2, row: 1),
      });
    });

    test('observer on height=2 gets +1 range bonus', () {
      final map = _map([
        _tile(1, 1, height: 2),
        _tile(2, 1),
        _tile(3, 1),
        _tile(4, 1),
      ]);

      final visible = const FogRevealCalculator().visibleHexesFor(
        mapData: map,
        sources: const [
          FogRevealSource(
            playerId: 'player_1',
            origin: HexCoordinate(col: 1, row: 1),
            range: 3, // 2 base + 1 bonus pre-computed by service
            observerHeight: 2,
          ),
        ],
      );

      expect(
        visible,
        containsAll([
          const HexCoordinate(col: 1, row: 1),
          const HexCoordinate(col: 2, row: 1),
          const HexCoordinate(col: 3, row: 1),
          const HexCoordinate(col: 4, row: 1),
        ]),
      );
    });

    test('high neighbor blocks propagation behind it for low observer', () {
      // Observer at height=0, neighbor at height=2 (threshold=1, so 2 > 0+1 → blocks)
      final map = _map([
        _tile(1, 1, height: 0),
        _tile(2, 1, height: 2),
        _tile(3, 1, height: 0),
      ]);

      final visible = const FogRevealCalculator().visibleHexesFor(
        mapData: map,
        sources: const [
          FogRevealSource(
            playerId: 'player_1',
            origin: HexCoordinate(col: 1, row: 1),
            range: 3,
            observerHeight: 0,
          ),
        ],
      );

      expect(visible, {
        const HexCoordinate(col: 1, row: 1),
        const HexCoordinate(col: 2, row: 1), // visible (you see the ridge)
        // (3,1) NOT visible — blocked by elevation
      });
    });

    test('neighbor at observer_height+1 does not block propagation', () {
      final map = _map([
        _tile(1, 1, height: 1),
        _tile(2, 1, height: 2), // 2 == 1+1, within threshold
        _tile(3, 1, height: 0),
      ]);

      final visible = const FogRevealCalculator().visibleHexesFor(
        mapData: map,
        sources: const [
          FogRevealSource(
            playerId: 'player_1',
            origin: HexCoordinate(col: 1, row: 1),
            range: 3,
            observerHeight: 1,
          ),
        ],
      );

      expect(
        visible,
        containsAll([
          const HexCoordinate(col: 1, row: 1),
          const HexCoordinate(col: 2, row: 1),
          const HexCoordinate(
            col: 3,
            row: 1,
          ), // visible — threshold not exceeded
        ]),
      );
    });
  });
}
