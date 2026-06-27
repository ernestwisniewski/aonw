import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Entity lookup extensions', () {
    test('find units, cities, and players by id', () {
      final unit = GameUnit(
        id: 'unit_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 2,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Warsaw',
        center: CityHex(col: 3, row: 4),
      );
      const player = Player(
        id: 'player_1',
        name: 'Player',
        colorValue: 0xFF000000,
      );

      expect([unit].byId(unit.id), same(unit));
      expect([city].byId(city.id), same(city));
      expect([player].byId(player.id), same(player));
      expect([unit].byId('missing'), isNull);
      expect([city].byId('missing'), isNull);
      expect([player].byId('missing'), isNull);
    });

    test('finds save players by id', () {
      const player = Player(
        id: 'player_1',
        name: 'Player',
        colorValue: 0xFF000000,
      );
      final save = GameSave(
        id: 'save_1',
        name: 'Save',
        mapName: 'map',
        turn: 1,
        playerStates: const {'player_1': PlayerTurnState.active},
        savedAt: DateTime.utc(2026),
        camera: CameraState.zero,
        players: const [player],
      );

      expect(save.playerById(player.id), same(player));
      expect(save.playerById('missing'), isNull);
    });
  });
}
