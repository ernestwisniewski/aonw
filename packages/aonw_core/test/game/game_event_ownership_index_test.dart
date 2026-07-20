import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameEventOwnershipIndex', () {
    test(
      'captures ownership independently from mutable source collections',
      () {
        final units = [_unit('unit-1', ownerPlayerId: 'player-1')];
        final cities = [_city('city-1', ownerPlayerId: 'player-2')];

        final index = GameEventOwnershipIndex.from(units, cities);
        units.clear();
        cities.clear();

        expect(index.unitOwner('unit-1'), 'player-1');
        expect(index.cityOwner('city-1'), 'player-2');
        expect(index.unitOwner('missing'), isNull);
        expect(index.cityOwner('missing'), isNull);
      },
    );

    test('keeps first duplicate ownership to match domain entity lookup', () {
      final index = GameEventOwnershipIndex.from(
        [
          _unit('duplicate-unit', ownerPlayerId: 'first-unit-owner'),
          _unit('duplicate-unit', ownerPlayerId: 'second-unit-owner'),
        ],
        [
          _city('duplicate-city', ownerPlayerId: 'first-city-owner'),
          _city('duplicate-city', ownerPlayerId: 'second-city-owner'),
        ],
      );

      expect(index.unitOwner('duplicate-unit'), 'first-unit-owner');
      expect(index.cityOwner('duplicate-city'), 'first-city-owner');
    });
  });
}

GameUnit _unit(String id, {required String ownerPlayerId}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.worker,
    name: id,
    col: 1,
    row: 1,
  );
}

GameCity _city(String id, {required String ownerPlayerId}) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: const CityHex(col: 1, row: 1),
  );
}
