import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CityEntryPolicy', () {
    const city = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_2',
      name: 'Rival',
      center: CityHex(col: 2, row: 1),
    );

    test('finds city centers by tile coordinate', () {
      expect(
        CityEntryPolicy.cityCenterAt(cities: const [city], col: 2, row: 1),
        city,
      );
      expect(
        CityEntryPolicy.cityCenterAt(cities: const [city], col: 1, row: 1),
        isNull,
      );
    });

    test('blocks foreign city centers even with friendly relations', () {
      final diplomacy = DiplomacyState.empty.setStatus(
        'player_1',
        'player_2',
        DiplomaticRelationStatus.friendly,
      );

      expect(
        CityEntryPolicy.blocksCityCenterEntry(
          diplomacy: diplomacy,
          cities: const [city],
          unitOwnerPlayerId: 'player_1',
          col: 2,
          row: 1,
        ),
        isTrue,
      );
    });

    test('allows own city centers and non-city tiles', () {
      final ownCity = city.copyWith(ownerPlayerId: 'player_1');

      expect(
        CityEntryPolicy.blocksCityCenterEntry(
          diplomacy: DiplomacyState.empty,
          cities: [ownCity],
          unitOwnerPlayerId: 'player_1',
          col: 2,
          row: 1,
        ),
        isFalse,
      );
      expect(
        CityEntryPolicy.blocksCityCenterEntry(
          diplomacy: DiplomacyState.empty,
          cities: [ownCity],
          unitOwnerPlayerId: 'player_2',
          col: 2,
          row: 2,
        ),
        isFalse,
      );
    });
  });
}
