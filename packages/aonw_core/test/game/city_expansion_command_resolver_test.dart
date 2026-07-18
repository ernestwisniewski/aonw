import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'city_expansion_command_resolver_test_support.dart';

void main() {
  group('CityExpansionCommandResolver', () {
    test('selects an immutable preference and shares unrelated cities', () {
      final selected = _expansionCity();
      final unrelated = _expansionCity(
        id: 'city_2',
        ownerPlayerId: _otherPlayerId,
        center: const CityHex(col: 3, row: 3),
      );
      final cities = [selected, unrelated];

      final result = _selectExpansion(cities: cities);

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.cities, cities), isFalse);
      expect(identical(result.cities.last, unrelated), isTrue);
      expect(
        result.cities.first.preferredExpansionHex,
        const CityHex(col: 1, row: 2),
      );
      expect(() => result.cities.clear(), throwsUnsupportedError);
    });

    test('accepted semantic no-op preserves cities identity', () {
      final cities = [
        _expansionCity(preferredExpansionHex: const CityHex(col: 1, row: 2)),
      ];

      final result = _selectExpansion(cities: cities);

      expect(result.accepted, isTrue);
      expect(identical(result.cities, cities), isTrue);
    });

    test('preserves exact rejection precedence and input identity', () {
      _expectExpansionRejected(
        cities: const [],
        actorPlayerId: _otherPlayerId,
        target: const CityHex(col: 0, row: 0),
        reason: 'city_not_found',
      );
      _expectExpansionRejected(
        cities: [_expansionCity(ownerPlayerId: _otherPlayerId)],
        target: const CityHex(col: 0, row: 0),
        reason: 'city_not_controlled',
      );
      _expectExpansionRejected(
        cities: [_expansionCity()],
        target: const CityHex(col: 0, row: 0),
        reason: 'city_expansion_hex_unavailable',
      );
    });

    test('uses research and technology ruleset for expansion capacity', () {
      final city = _expansionCity(maxHexes: 2);
      final cities = [city];
      final research = ResearchState(
        players: {
          _playerId: PlayerResearchState(
            unlockedTechnologyIds: const {TechnologyId.urbanization},
          ),
        },
      );
      final noTechnologies = TechnologyRuleset(
        science: TechnologyRulesets.standard.science,
        costs: TechnologyRulesets.standard.costs,
        technologies: const {},
      );

      final withoutDefinition = _selectExpansion(
        cities: cities,
        research: research,
        technologyRuleset: noTechnologies,
      );
      final withDefinition = _selectExpansion(
        cities: cities,
        research: research,
      );

      expect(withoutDefinition.accepted, isFalse);
      expect(withoutDefinition.reason, 'city_expansion_hex_unavailable');
      expect(withDefinition.accepted, isTrue);
    });

    test('uses the supplied city ruleset for building capacity', () {
      final city = _expansionCity(
        maxHexes: 2,
        buildings: const {CityBuildingType.housing},
      );
      final buildingsWithoutHousingCapacity =
          Map<CityBuildingType, CityBuildingDefinition>.of(
            CityRulesets.standard.buildings,
          );
      buildingsWithoutHousingCapacity[CityBuildingType.housing] =
          const CityBuildingDefinition(
            type: CityBuildingType.housing,
            productionCost: 18,
          );
      final rulesetWithoutCapacity = CityRulesets.standard.copyWith(
        buildings: buildingsWithoutHousingCapacity,
      );

      final withoutCapacity = _selectExpansion(
        cities: [city],
        cityRuleset: rulesetWithoutCapacity,
      );
      final withCapacity = _selectExpansion(cities: [city]);

      expect(withoutCapacity.accepted, isFalse);
      expect(withoutCapacity.reason, 'city_expansion_hex_unavailable');
      expect(withCapacity.accepted, isTrue);
    });
  });
}
