import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TechnologyEffectSummary', () {
    test('aggregates unlocked technology effects for a player', () {
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {
              TechnologyId.ironWorking,
              TechnologyId.coalMining,
              TechnologyId.logistics,
              TechnologyId.militaryOrganization,
              TechnologyId.tactics,
              TechnologyId.economy,
              TechnologyId.urbanization,
              TechnologyId.fortifications,
              TechnologyId.strategy,
              TechnologyId.specialization,
            },
          ),
        },
      );

      final summary = TechnologyEffectSummary.forPlayer(
        playerId: 'player_1',
        research: research,
        ruleset: TechnologyRulesets.standard,
      );

      expect(summary.strategicResourceProductionByType[ResourceType.iron], 1);
      expect(summary.strategicResourceProductionByType[ResourceType.coal], 1);
      expect(summary.armyProductionMultiplier, 0.15);
      expect(summary.globalGoldMultiplier, 0.10);
      expect(summary.maxCityPopulationBonus, 0);
      expect(summary.maxControlledHexesBonus, 1);
      expect(summary.cityDefenseBonus, 2);
      expect(summary.armyStrengthMultiplier, 0.10);
      expect(summary.armyAttackBonus, 1);
      expect(summary.armyDefenseBonus, 2);
      expect(summary.armyHitPointsBonus, 3);
      expect(summary.cityScienceBonus, 1);
    });
  });
}
