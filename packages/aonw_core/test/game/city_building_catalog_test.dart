import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('City building catalog', () {
    test('defines every stable building id exactly once', () {
      const catalog = CityBuildingCatalog.standard;

      expect(catalog, hasLength(CityBuildingType.values.length));
      expect(catalog.keys.toSet(), CityBuildingType.values.toSet());

      for (final type in CityBuildingType.values) {
        expect(CityBuildingType.fromString(type.name), type);
        expect(catalog[type]?.type, type);
        expect(
          catalog[type]?.productionCost,
          greaterThan(0),
          reason: '${type.name} needs a positive production cost',
        );
      }
    });

    test('keeps catalog buildings aligned with technology unlocks', () {
      const ruleset = TechnologyRulesets.standard;

      for (final type in CityBuildingType.values) {
        final unlockId = TechnologyUnlockQuery.unlockIdForBuilding(type);
        final technology = TechnologyUnlockQuery.unlockingTechnologyForBuilding(
          buildingType: type,
          ruleset: ruleset,
        );

        if (type == CityBuildingType.granary) {
          expect(unlockId, isNull);
          expect(technology, isNull);
          continue;
        }

        expect(unlockId?.name, type.name);
        expect(
          technology,
          isNotNull,
          reason: '${type.name} needs a technology unlock',
        );
        expect(
          technology?.unlocks,
          contains(UnlockCityBuilding(unlockId!)),
          reason: '${type.name} must use the same stable unlock id',
        );
      }
    });
  });
}
