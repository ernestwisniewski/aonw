import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlayerCapacityRules', () {
    test('uses bundled map capacities', () {
      expect(MapPlayerCapacityRules.maxPlayersForMapName('verdantia'), 4);
      expect(MapPlayerCapacityRules.maxPlayersForMapName('myranth'), 3);
      expect(MapPlayerCapacityRules.maxPlayersForMapName('terenos'), 3);
    });

    test('infers capacity from unknown map tile counts', () {
      expect(MapPlayerCapacityRules.maxPlayersForTileCount(600), 4);
      expect(MapPlayerCapacityRules.maxPlayersForTileCount(300), 3);
      expect(MapPlayerCapacityRules.maxPlayersForTileCount(120), 2);
    });

    test('uses Verdantia for full multiplayer starts', () {
      final mapName = MapPlayerCapacityRules.multiplayerStartMapName(
        requestedMapName: 'terenos',
        playerCount: 4,
        seed: 0,
      );

      expect(mapName, 'verdantia');
    });

    test('randomizes every eligible bundled map for smaller starts', () {
      final twoPlayerMaps = {
        for (var seed = 0; seed < 3; seed++)
          MapPlayerCapacityRules.multiplayerStartMapName(
            requestedMapName: 'custom_map',
            playerCount: 2,
            seed: seed,
          ),
      };
      final threePlayerMaps = {
        for (var seed = 0; seed < 3; seed++)
          MapPlayerCapacityRules.multiplayerStartMapName(
            requestedMapName: 'myranth',
            playerCount: 3,
            seed: seed,
          ),
      };

      expect(twoPlayerMaps, {'verdantia', 'myranth', 'terenos'});
      expect(threePlayerMaps, {'verdantia', 'myranth', 'terenos'});
    });
  });
}
