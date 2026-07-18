part of 'rush_production_command_resolver.dart';

abstract final class _RushProductionEconomy {
  static int productionPerTurn({
    required _RushProductionInput input,
    required GameCity city,
    required CityProductionTarget target,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: input.research,
      ruleset: input.technologyRuleset,
    );
    final economy = _economy(
      input: input,
      city: city,
      technologyEffects: technologyEffects,
    );
    var production = CityProductionRules.productionPerTurn(
      economy.netYield.production,
    );
    if (target is UnitProductionTarget) {
      production = CityTechnologyEffectRules.unitProductionPerTurn(
        production,
        effects: technologyEffects,
      );
    }
    return CitySpecializationRules.productionPerTurnForTarget(
      productionPerTurn: production,
      target: target,
      specialization: city.specialization,
    );
  }

  static CityEconomyBreakdown _economy({
    required _RushProductionInput input,
    required GameCity city,
    required TechnologyEffectSummary technologyEffects,
  }) {
    final cityYield = CityYieldCalculator.totalFor(
      city,
      input.mapTiles,
      fieldImprovements: input.fieldImprovements,
      units: input.units,
      artifacts: input.artifacts,
      ruleset: input.cityRuleset,
    );
    return CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapTiles: input.mapTiles,
      ruleset: input.cityRuleset,
      technologyEffects: technologyEffects,
      paceBalance: input.paceBalance,
      cities: input.cities,
      wonderRegistry: input.wonderRegistry,
      wonderRuleset: input.wonderRuleset,
      stabilityModifier: StabilityPolicy.modifierForNet(
        input.playerStabilityNet[city.ownerPlayerId] ?? 0,
        ruleset: input.stabilityRuleset,
      ),
    );
  }
}
