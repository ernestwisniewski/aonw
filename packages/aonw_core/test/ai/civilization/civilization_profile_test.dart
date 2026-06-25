import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CivilizationProfile', () {
    test('effectiveWeights composes persona and civilization bias', () {
      const profile = CivilizationProfile(
        country: PlayerCountry.germany,
        displayName: 'Germany',
        defaultPersona: AiPersona.aggressive,
        civBias: PersonaWeights(
          aggression: 1.1,
          expansion: 1.0,
          economy: 1.0,
          science: 1.0,
        ),
        belligerence: 1.25,
        expansionDistance: 0.95,
        frontierTolerance: 1.0,
        techBias: TechBranchPreferences.identity,
      );

      final weights = profile.effectiveWeights(AiPersona.aggressive);

      expect(weights.aggression, closeTo(1.35 * 1.1, 1e-9));
      expect(weights.expansion, closeTo(0.95, 1e-9));
    });

    test('reserved phase-B fields default to empty lists', () {
      expect(CivilizationProfiles.poland.uniqueUnits, isEmpty);
      expect(CivilizationProfiles.poland.uniqueBuildings, isEmpty);
      expect(CivilizationProfiles.poland.startingBonuses, isEmpty);
    });
  });
}
