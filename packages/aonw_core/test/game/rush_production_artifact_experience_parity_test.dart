import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'persistent_city_production_rush_characterization_test_support.dart';

void main() {
  test('rush and turn completion grant the same artifact experience', () {
    final unitCost = CityProductionRules.targetCost(
      const UnitProductionTarget(GameUnitType.warrior),
    );
    final city = rushCharacterizationCity(
      productionQueue: rushCharacterizationUnitQueue(
        investedProduction: unitCost - 1,
      ),
    );
    final heroSword = rushCharacterizationHeroSword();
    final state = rushCharacterizationState(
      cities: rushCharacterizationCities(city),
      playerGold: const {rushCharacterizationPlayerId: 2},
      artifacts: [heroSword],
    );
    final mapTiles = rushCharacterizationMap();

    final normal = CityTurnProcessor.advanceForPlayer(
      playerId: rushCharacterizationPlayerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      mapData: mapTiles,
    );
    final rushed = const PersistentCityProductionResolver().rushProduction(
      state: state,
      command: const RushProductionCommand('city_1'),
      actorPlayerId: rushCharacterizationPlayerId,
      mapTiles: mapTiles,
    );

    final helperExperience = WorldArtifactBonuses.producedUnitExperienceFor(
      cityId: city.id,
      artifacts: state.artifacts,
    );
    final normalExperience = normal.units.last.experiencePoints;
    final rushedExperience = rushed.state.units.last.experiencePoints;

    expect(helperExperience, 2);
    expect(normalExperience, 2);
    expect(rushedExperience, 2);
    expect(rushedExperience, normalExperience);
    expect(rushed.accepted, isTrue);
    expect(normal.cities.first.productionQueue, isNull);
    expect(rushed.state.cities.first.productionQueue, isNull);
  });
}
