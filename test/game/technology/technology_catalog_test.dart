import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TechnologyCatalog', () {
    const ruleset = TechnologyRulesets.standard;
    final technologies = ruleset.technologies;

    test('defines every technology id exactly once', () {
      expect(technologies, hasLength(TechnologyId.values.length));
      expect(technologies.keys.toSet(), TechnologyId.values.toSet());

      for (final entry in technologies.entries) {
        expect(entry.value.id, entry.key);
      }
    });

    test('contains the intended number of technologies per era', () {
      int countEra(TechnologyEra era) {
        return technologies.values
            .where((technology) => technology.era == era)
            .length;
      }

      expect(countEra(TechnologyEra.foundation), 3);
      expect(countEra(TechnologyEra.settlement), 6);
      expect(countEra(TechnologyEra.expansion), 9);
      expect(countEra(TechnologyEra.specialization), 14);
      expect(countEra(TechnologyEra.industry), 10);
      expect(countEra(TechnologyEra.strategy), 12);
    });

    test('starts from exactly three main branches', () {
      final roots = technologies.values
          .where((technology) => technology.prerequisites.isEmpty)
          .map((technology) => technology.id)
          .toSet();

      expect(roots, {
        TechnologyId.agriculture,
        TechnologyId.mining,
        TechnologyId.hunting,
      });
    });

    test('keeps branch lanes ready for future splits', () {
      expect(
        technologies[TechnologyId.agriculture]!.treePosition,
        const TechnologyTreePosition(column: 0, row: 0),
      );
      expect(
        technologies[TechnologyId.mining]!.treePosition,
        const TechnologyTreePosition(column: 0, row: 4),
      );
      expect(
        technologies[TechnologyId.hunting]!.treePosition,
        const TechnologyTreePosition(column: 0, row: 8),
      );
      expect(technologies[TechnologyId.trade]!.prerequisites, [
        TechnologyId.agriculture,
      ]);
      expect(technologies[TechnologyId.craftsmanship]!.prerequisites, [
        TechnologyId.mining,
      ]);
      expect(technologies[TechnologyId.fishing]!.prerequisites, [
        TechnologyId.hunting,
      ]);
    });

    test('splits main branches into concrete later-era subbranches', () {
      expect(technologies[TechnologyId.irrigation]!.prerequisites, [
        TechnologyId.waterEngineering,
      ]);
      expect(technologies[TechnologyId.banking]!.prerequisites, [
        TechnologyId.advancedTrade,
      ]);
      expect(technologies[TechnologyId.engineering]!.prerequisites, [
        TechnologyId.construction,
      ]);
      expect(technologies[TechnologyId.machinery]!.prerequisites, [
        TechnologyId.engineering,
      ]);
      expect(technologies[TechnologyId.shipbuilding]!.prerequisites, [
        TechnologyId.navigation,
      ]);
      expect(technologies[TechnologyId.tactics]!.prerequisites, [
        TechnologyId.logistics,
      ]);
      expect(technologies[TechnologyId.economy]!.prerequisites, [
        TechnologyId.banking,
      ]);
    });

    test('references only known dependency technologies', () {
      for (final technology in technologies.values) {
        for (final prerequisite in technology.prerequisites) {
          expect(
            technologies.containsKey(prerequisite),
            isTrue,
            reason:
                '${technology.id.name} has unknown prerequisite '
                '${prerequisite.name}',
          );
        }
        for (final blocker in technology.blockedBy) {
          expect(
            technologies.containsKey(blocker),
            isTrue,
            reason:
                '${technology.id.name} has unknown blocker '
                '${blocker.name}',
          );
        }
      }
    });

    test('has no prerequisite cycles', () {
      final visiting = <TechnologyId>{};
      final visited = <TechnologyId>{};

      void visit(TechnologyId id, List<TechnologyId> path) {
        if (visited.contains(id)) return;
        if (!visiting.add(id)) {
          final cycle = [...path, id].map((value) => value.name).join(' -> ');
          fail('Technology prerequisite cycle found: $cycle');
        }

        for (final prerequisite in technologies[id]!.prerequisites) {
          visit(prerequisite, [...path, id]);
        }

        visiting.remove(id);
        visited.add(id);
      }

      for (final id in technologies.keys) {
        visit(id, const []);
      }

      expect(visited, technologies.keys.toSet());
    });

    test('keeps tree positions unique', () {
      final positions = <TechnologyTreePosition>{};
      for (final technology in technologies.values) {
        expect(
          positions.add(technology.treePosition),
          isTrue,
          reason:
              '${technology.id.name} duplicates tree position '
              '${technology.treePosition.column}:${technology.treePosition.row}',
        );
      }
    });

    test('maps important design unlocks to stable targets', () {
      expect(
        technologies[TechnologyId.agriculture]!.unlocks,
        contains(const UnlockFieldImprovement(FieldImprovementType.farm)),
      );
      expect(
        technologies[TechnologyId.agriculture]!.unlocks,
        contains(const UnlockFieldImprovement(FieldImprovementType.riverFarm)),
      );
      expect(
        technologies[TechnologyId.advancedTrade]!.unlocks,
        contains(const UnlockCityBuilding(CityBuildingUnlockId.marketplace)),
      );
      expect(
        technologies[TechnologyId.navigation]!.unlocks,
        contains(const UnlockCityBuilding(CityBuildingUnlockId.port)),
      );
      expect(
        technologies[TechnologyId.irrigation]!.unlocks,
        contains(const UnlockCityBuilding(CityBuildingUnlockId.aqueduct)),
      );
      expect(
        technologies[TechnologyId.banking]!.unlocks,
        contains(const UnlockCityBuilding(CityBuildingUnlockId.bank)),
      );
      expect(
        technologies[TechnologyId.engineering]!.unlocks,
        contains(const UnlockCityBuilding(CityBuildingUnlockId.buildersGuild)),
      );
      expect(
        technologies[TechnologyId.machinery]!.unlocks,
        contains(const UnlockCityBuilding(CityBuildingUnlockId.factory)),
      );
      expect(
        technologies[TechnologyId.shipbuilding]!.unlocks,
        contains(const UnlockCityBuilding(CityBuildingUnlockId.lighthouse)),
      );
      expect(
        technologies[TechnologyId.tactics]!.unlocks,
        contains(
          const UnlockCityBuilding(CityBuildingUnlockId.trainingGrounds),
        ),
      );
      expect(
        technologies[TechnologyId.strategy]!.unlocks,
        contains(const UnlockUnitType(GameUnitType.commander)),
      );
    });

    test('keeps documented boost hooks in the catalog', () {
      expect(
        technologies[TechnologyId.agriculture]!.boosts.single.condition,
        const ControlsAnyResource({ResourceType.wheat, ResourceType.rice}),
      );
      expect(
        technologies[TechnologyId.mining]!.boosts.single.condition,
        const ControlsAnyResource({ResourceType.iron, ResourceType.marble}),
      );
      expect(
        technologies[TechnologyId.fishing]!.boosts.single.condition,
        const ControlsResource(ResourceType.fish),
      );
      expect(
        technologies[TechnologyId.horsebackRiding]!.boosts.single.condition,
        const ControlsResource(ResourceType.horses),
      );
    });
  });
}
