import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScienceYieldCalculator', () {
    const ruleset = TechnologyRulesets.standard;

    test('adds base science from each city owned by the player', () {
      final city1 = _city(id: 'city_1', ownerPlayerId: 'player_1');
      final city2 = _city(id: 'city_2', ownerPlayerId: 'player_1');
      final otherCity = _city(id: 'city_3', ownerPlayerId: 'player_2');

      final science = ScienceYieldCalculator.totalForPlayer(
        playerId: 'player_1',
        cities: [city1, city2, otherCity],
        research: ResearchState.empty,
        ruleset: ruleset,
      );

      expect(science.total, 4);
      expect(science.byCityId, {'city_1': 2, 'city_2': 2});
    });

    test('applies unlocked city science technology effects', () {
      final city = _city(id: 'city_1', ownerPlayerId: 'player_1');
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.specialization},
          ),
        },
      );

      final science = ScienceYieldCalculator.totalForPlayer(
        playerId: 'player_1',
        cities: [city],
        research: research,
        ruleset: ruleset,
      );

      expect(science.total, 3);
      expect(science.byCityId['city_1'], 3);
    });

    test('adds science from selected buildings with diminishing returns', () {
      final city = _city(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        buildings: {
          CityBuildingType.granary,
          CityBuildingType.archive,
          CityBuildingType.academy,
          CityBuildingType.university,
        },
      );

      final science = ScienceYieldCalculator.totalForPlayer(
        playerId: 'player_1',
        cities: [city],
        research: ResearchState.empty,
        ruleset: ruleset,
        cityRuleset: CityRulesets.standard,
      );

      expect(science.total, 8);
      expect(science.byCityId['city_1'], 8);
    });

    test('ignores buildings without science effects', () {
      final city = _city(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        buildings: {
          CityBuildingType.granary,
          CityBuildingType.workshop,
          CityBuildingType.marketplace,
        },
      );

      final science = ScienceYieldCalculator.totalForPlayer(
        playerId: 'player_1',
        cities: [city],
        research: ResearchState.empty,
        ruleset: ruleset,
        cityRuleset: CityRulesets.standard,
      );

      expect(science.total, 2);
      expect(science.byCityId['city_1'], 2);
    });

    test('does not cap science when cap is disabled', () {
      final city = _city(id: 'city_1', ownerPlayerId: 'player_1');
      final customRuleset = TechnologyRuleset(
        science: const ScienceBalance(
          baseSciencePerCity: 6,
          maxSciencePerCity: 0,
          secondScienceBuildingMultiplier: 0.70,
          thirdScienceBuildingMultiplier: 0.50,
        ),
        costs: ruleset.costs,
        technologies: ruleset.technologies,
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.specialization},
          ),
        },
      );

      final science = ScienceYieldCalculator.totalForPlayer(
        playerId: 'player_1',
        cities: [city],
        research: research,
        ruleset: customRuleset,
      );

      expect(science.total, 7);
    });

    test('caps science per city when configured', () {
      final city = _city(id: 'city_1', ownerPlayerId: 'player_1');
      final customRuleset = TechnologyRuleset(
        science: const ScienceBalance(
          baseSciencePerCity: 3,
          maxSciencePerCity: 3,
          secondScienceBuildingMultiplier: 0.70,
          thirdScienceBuildingMultiplier: 0.50,
        ),
        costs: ruleset.costs,
        technologies: ruleset.technologies,
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.specialization},
          ),
        },
      );

      final science = ScienceYieldCalculator.totalForPlayer(
        playerId: 'player_1',
        cities: [city],
        research: research,
        ruleset: customRuleset,
      );

      expect(science.total, 3);
    });
  });
}

GameCity _city({
  required String id,
  required String ownerPlayerId,
  Set<CityBuildingType> buildings = const {},
}) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: 'City',
    center: const CityHex(col: 0, row: 0),
    buildings: buildings,
  );
}
