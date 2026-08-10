part of 'turn_reducer.dart';

List<ShowCityProductionBubbleEffect> _turnStartProductionEffects(
  _ClientState state,
  String playerId,
  MapTileLookup mapTiles, {
  GameRuleset ruleset = GameRuleset.defaults,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  if (playerId.isEmpty) return const [];
  final effects = <ShowCityProductionBubbleEffect>[];
  for (final city in state.cities) {
    if (city.ownerPlayerId != playerId) continue;
    final queue = city.productionQueue;
    if (queue == null) continue;
    effects.add(
      ShowCityProductionBubbleEffect.forCity(
        city: city,
        target: queue.target,
        turnsRemaining: _turnsRemainingForQueue(
          state,
          city,
          queue,
          mapTiles,
          ruleset: ruleset,
          paceBalance: paceBalance,
        ),
        delay: Duration(milliseconds: 120 + effects.length * 140),
      ),
    );
  }
  return effects;
}

int? _turnsRemainingForQueue(
  _ClientState state,
  GameCity city,
  CityProductionQueue queue,
  MapTileLookup mapTiles, {
  GameRuleset ruleset = GameRuleset.defaults,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  if (queue.target is ProjectProductionTarget) return null;
  final targetCost = CityProductionRules.targetCost(
    queue.target,
    ruleset: ruleset.city,
    wonderRuleset: ruleset.wonders,
    paceBalance: paceBalance,
  );
  return CityProductionRules.estimatedTurnsRemaining(
    productionCost: targetCost,
    investedProduction: queue.investedProduction,
    productionPerTurn: _productionPerTurnForQueue(
      state,
      city,
      queue,
      mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    ),
  );
}

int _productionPerTurnForQueue(
  _ClientState state,
  GameCity city,
  CityProductionQueue queue,
  MapTileLookup mapTiles, {
  GameRuleset ruleset = GameRuleset.defaults,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  final technologyEffects = TechnologyEffectSummary.forPlayer(
    playerId: city.ownerPlayerId,
    research: state.research,
    ruleset: ruleset.technology,
  );
  final cityYield = CityYieldCalculator.totalFor(
    city,
    mapTiles,
    fieldImprovements: state.fieldImprovements,
    units: state.units,
    artifacts: state.artifacts,
    ruleset: ruleset.city,
  );
  final cityEconomy = CityEconomyBreakdown.from(
    city: city,
    tileYield: cityYield,
    mapTiles: mapTiles,
    ruleset: ruleset.city,
    technologyEffects: technologyEffects,
    cities: state.cities,
    wonderRegistry: state.wonderRegistry,
    wonderRuleset: ruleset.wonders,
    stabilityModifier: StabilityPolicy.modifierForNet(
      state.playerStabilityNet[city.ownerPlayerId] ?? 0,
      ruleset: ruleset.stability,
    ),
    paceBalance: paceBalance,
  );
  var productionPerTurn = CityProductionRules.productionPerTurn(
    cityEconomy.netYield.production,
  );
  if (queue.target is UnitProductionTarget) {
    productionPerTurn = CityTechnologyEffectRules.unitProductionPerTurn(
      productionPerTurn,
      effects: technologyEffects,
    );
  }
  return CitySpecializationRules.productionPerTurnForTarget(
    productionPerTurn: productionPerTurn,
    target: queue.target,
    specialization: city.specialization,
  );
}
