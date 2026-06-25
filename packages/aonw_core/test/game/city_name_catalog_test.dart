import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CityNameCatalog', () {
    test('returns country-specific city names by sequence', () {
      expect(
        CityNameCatalog.nextName(country: PlayerCountry.france, sequence: 1),
        'Paris',
      );
      expect(
        CityNameCatalog.nextName(country: PlayerCountry.japan, sequence: 2),
        'Kyoto',
      );
      expect(
        CityNameCatalog.nextName(country: PlayerCountry.ukraine, sequence: 8),
        'Krym',
      );
      expect(
        CityNameCatalog.nextName(country: PlayerCountry.poland, sequence: 9),
        'Poniatowa',
      );
      expect(
        CityNameCatalog.nextName(country: PlayerCountry.russia, sequence: 1),
        'Moscow',
      );
      expect(
        CityNameCatalog.nextName(country: PlayerCountry.portugal, sequence: 1),
        'Lisbon',
      );
    });

    test('cycles with a suffix after exhausting the list', () {
      expect(
        CityNameCatalog.nextName(country: PlayerCountry.canada, sequence: 9),
        'Ottawa 2',
      );
    });
  });
}
