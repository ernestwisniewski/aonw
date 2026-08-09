import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlayerCapacityRules', () {
    test('uses bundled map capacities', () {
      expect(MapPlayerCapacityRules.maxPlayersForMapName('verdantia'), 4);
      expect(MapPlayerCapacityRules.maxPlayersForMapName('myranth'), 3);
      expect(MapPlayerCapacityRules.maxPlayersForMapName('terenos'), 3);
      expect(MapPlayerCapacityRules.maxPlayersForMapName('dravonia'), 4);
    });

    test('normalizes names and validates player-count helpers', () {
      expect(
        MapPlayerCapacityRules.singlePlayerPlayersForMapName(' MYRANTH '),
        3,
      );
      expect(MapPlayerCapacityRules.singlePlayerPlayersForMapName('custom'), 4);
      expect(MapPlayerCapacityRules.aiOpponentsForPlayerCount(1), 0);
      expect(MapPlayerCapacityRules.aiOpponentsForPlayerCount(4), 3);
      expect(
        MapPlayerCapacityRules.supportsPlayerCount(
          mapName: 'verdantia',
          playerCount: 4,
        ),
        isTrue,
      );
      expect(
        MapPlayerCapacityRules.supportsPlayerCount(
          mapName: 'terenos',
          playerCount: 4,
        ),
        isFalse,
      );
      expect(
        MapPlayerCapacityRules.supportsPlayerCount(
          mapName: 'verdantia',
          playerCount: 1,
        ),
        isFalse,
      );
    });

    test('infers capacity from unknown map tile counts', () {
      expect(MapPlayerCapacityRules.maxPlayersForTileCount(600), 4);
      expect(MapPlayerCapacityRules.maxPlayersForTileCount(300), 3);
      expect(MapPlayerCapacityRules.maxPlayersForTileCount(120), 2);
    });

    test('uses map metadata primitives without requiring WorldMap', () {
      expect(
        MapPlayerCapacityRules.maxPlayersForMap(
          mapName: 'verdantia',
          tileCount: 1,
        ),
        4,
      );
      expect(
        MapPlayerCapacityRules.singlePlayerPlayersForMap(
          mapName: 'myranth',
          tileCount: 1,
        ),
        3,
      );
      expect(
        MapPlayerCapacityRules.maxPlayersForMap(
          mapName: 'custom',
          tileCount: 300,
        ),
        3,
      );
      expect(
        MapPlayerCapacityRules.singlePlayerPlayersForMap(
          mapName: null,
          tileCount: 600,
        ),
        4,
      );
    });

    test('legacy WorldMap helpers delegate to metadata primitives', () {
      final map = WorldMap(cols: 1, rows: 1, mapName: 'terenos', tiles: []);

      expect(
        MapPlayerCapacityRules.maxPlayersForWorldMap(map),
        MapPlayerCapacityRules.maxPlayersForMap(
          mapName: map.mapName,
          tileCount: map.tileCount,
        ),
      );
      expect(
        MapPlayerCapacityRules.singlePlayerPlayersForWorldMap(map),
        MapPlayerCapacityRules.singlePlayerPlayersForMap(
          mapName: map.mapName,
          tileCount: map.tileCount,
        ),
      );
    });

    test('selects every eligible four-player map deterministically', () {
      final selections = [
        for (final seed in [0, 1, 2, -1])
          MapPlayerCapacityRules.multiplayerStartMapName(
            playerCount: 4,
            seed: seed,
          ),
      ];

      expect(selections, ['verdantia', 'dravonia', 'verdantia', 'dravonia']);
    });

    test('preserves deterministic selection for two and three players', () {
      final twoPlayerMaps = [
        for (var seed = 0; seed < 4; seed++)
          MapPlayerCapacityRules.multiplayerStartMapName(
            playerCount: 2,
            seed: seed,
          ),
      ];
      final threePlayerMaps = [
        for (var seed = 0; seed < 4; seed++)
          MapPlayerCapacityRules.multiplayerStartMapName(
            playerCount: 3,
            seed: seed,
          ),
      ];

      const expected = ['verdantia', 'myranth', 'terenos', 'dravonia'];
      expect(twoPlayerMaps, expected);
      expect(threePlayerMaps, expected);
    });

    test('rejects a player count below the quickplay minimum', () {
      expect(
        () => MapPlayerCapacityRules.multiplayerStartMapName(
          playerCount: MapPlayerCapacityRules.minPlayers - 1,
          seed: 0,
        ),
        throwsRangeError,
      );
    });

    test('fails closed when no official map has enough capacity', () {
      expect(
        () => MapPlayerCapacityRules.multiplayerStartMapName(
          playerCount: MapPlayerCapacityRules.absoluteMaxPlayers + 1,
          seed: 0,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('No official multiplayer map supports 5 players'),
          ),
        ),
      );
    });
  });
}
