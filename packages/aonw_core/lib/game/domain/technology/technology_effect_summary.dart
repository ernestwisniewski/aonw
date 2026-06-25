import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_effect.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class TechnologyEffectSummary {
  final Map<ResourceType, int> strategicResourceProductionByType;
  final double globalGoldMultiplier;
  final int cityDefenseBonus;
  final double armyProductionMultiplier;
  final double armyStrengthMultiplier;
  final int armyAttackBonus;
  final int armyDefenseBonus;
  final int armyHitPointsBonus;
  final int maxCityPopulationBonus;
  final int maxControlledHexesBonus;
  final int cityScienceBonus;

  const TechnologyEffectSummary({
    this.strategicResourceProductionByType = const {},
    this.globalGoldMultiplier = 0,
    this.cityDefenseBonus = 0,
    this.armyProductionMultiplier = 0,
    this.armyStrengthMultiplier = 0,
    this.armyAttackBonus = 0,
    this.armyDefenseBonus = 0,
    this.armyHitPointsBonus = 0,
    this.maxCityPopulationBonus = 0,
    this.maxControlledHexesBonus = 0,
    this.cityScienceBonus = 0,
  });

  static const empty = TechnologyEffectSummary();

  factory TechnologyEffectSummary.forPlayer({
    required String playerId,
    required ResearchState research,
    required TechnologyRuleset ruleset,
  }) {
    final strategicResourceProductionByType = <ResourceType, int>{};
    var globalGoldMultiplier = 0.0;
    var cityDefenseBonus = 0;
    var armyProductionMultiplier = 0.0;
    var armyStrengthMultiplier = 0.0;
    var armyAttackBonus = 0;
    var armyDefenseBonus = 0;
    var armyHitPointsBonus = 0;
    var maxCityPopulationBonus = 0;
    var maxControlledHexesBonus = 0;
    var cityScienceBonus = 0;

    final playerResearch = research.forPlayer(playerId);
    for (final technologyId in playerResearch.unlockedTechnologyIds) {
      final technology = ruleset.technologies[technologyId];
      if (technology == null) continue;

      for (final effect in technology.effects) {
        switch (effect) {
          case StrategicResourceProductionBonus(
            :final resourceType,
            :final production,
          ):
            strategicResourceProductionByType[resourceType] =
                (strategicResourceProductionByType[resourceType] ?? 0) +
                production;
          case GlobalGoldMultiplier(:final multiplier):
            globalGoldMultiplier += multiplier;
          case CityDefenseBonus(:final amount):
            cityDefenseBonus += amount;
          case ArmyProductionMultiplier(:final multiplier):
            armyProductionMultiplier += multiplier;
          case ArmyStrengthMultiplier(:final multiplier):
            armyStrengthMultiplier += multiplier;
          case ArmyCombatStatsBonus(:final attack, :final defense, :final hp):
            armyAttackBonus += attack;
            armyDefenseBonus += defense;
            armyHitPointsBonus += hp;
          case MaxCityPopulationBonus(:final amount):
            maxCityPopulationBonus += amount;
          case MaxControlledHexesBonus(:final amount):
            maxControlledHexesBonus += amount;
          case CityScienceBonus(:final amount):
            cityScienceBonus += amount;
        }
      }
    }

    return TechnologyEffectSummary(
      strategicResourceProductionByType: Map.unmodifiable(
        strategicResourceProductionByType,
      ),
      globalGoldMultiplier: globalGoldMultiplier,
      cityDefenseBonus: cityDefenseBonus,
      armyProductionMultiplier: armyProductionMultiplier,
      armyStrengthMultiplier: armyStrengthMultiplier,
      armyAttackBonus: armyAttackBonus,
      armyDefenseBonus: armyDefenseBonus,
      armyHitPointsBonus: armyHitPointsBonus,
      maxCityPopulationBonus: maxCityPopulationBonus,
      maxControlledHexesBonus: maxControlledHexesBonus,
      cityScienceBonus: cityScienceBonus,
    );
  }
}
