import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CivilizationProfileRegistry', () {
    const registry = CivilizationProfileRegistry();

    test('has a profile for every PlayerCountry', () {
      for (final country in PlayerCountry.values) {
        expect(registry.profileFor(country).country, country);
      }
    });

    test('exposes distinct aggressiveness and expansion knobs', () {
      final germany = registry.profileFor(PlayerCountry.germany);
      final france = registry.profileFor(PlayerCountry.france);
      final netherlands = registry.profileFor(PlayerCountry.netherlands);
      final spain = registry.profileFor(PlayerCountry.spain);
      final korea = registry.profileFor(PlayerCountry.korea);

      expect(germany.belligerence, greaterThan(netherlands.belligerence));
      expect(germany.belligerence, greaterThan(france.belligerence));
      expect(
        france.effectiveWeights(france.defaultPersona).expansion,
        greaterThan(france.effectiveWeights(france.defaultPersona).aggression),
      );
      expect(spain.expansionDistance, greaterThan(korea.expansionDistance));
    });
  });
}
