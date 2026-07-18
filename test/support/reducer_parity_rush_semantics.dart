import 'dart:convert';

import 'package:aonw_core/domain.dart';

int reviewedRushProductionPerTurn({
  required PersistentGameState state,
  required GameCity city,
  required CityProductionTarget target,
  required MapTileLookup mapTiles,
  required PaceBalance paceBalance,
}) {
  final technologyEffects = TechnologyEffectSummary.forPlayer(
    playerId: city.ownerPlayerId,
    research: state.research,
    ruleset: TechnologyRulesets.standard,
  );
  final cityYield = CityYieldCalculator.totalFor(
    city,
    mapTiles,
    fieldImprovements: state.fieldImprovements,
    units: state.units,
    artifacts: state.artifacts,
    ruleset: CityRulesets.standard,
  );
  final economy = CityEconomyBreakdown.from(
    city: city,
    tileYield: cityYield,
    mapTiles: mapTiles,
    ruleset: CityRulesets.standard,
    technologyEffects: technologyEffects,
    paceBalance: paceBalance,
    cities: state.cities,
    wonderRegistry: state.wonderRegistry,
    wonderRuleset: WonderRuleset.standard,
    stabilityModifier: StabilityPolicy.modifierForNet(
      state.playerStabilityNet[city.ownerPlayerId] ?? 0,
      ruleset: StabilityRuleset.standard,
    ),
  );
  var productionPerTurn = CityProductionRules.productionPerTurn(
    economy.netYield.production,
  );
  if (target is UnitProductionTarget) {
    productionPerTurn = CityTechnologyEffectRules.unitProductionPerTurn(
      productionPerTurn,
      effects: technologyEffects,
    );
  }
  return CitySpecializationRules.productionPerTurnForTarget(
    productionPerTurn: productionPerTurn,
    target: target,
    specialization: city.specialization,
  );
}

void requireAcceptedRushProduction({
  required String fixtureId,
  required RushProductionCommand command,
  required String actorPlayerId,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
  required MapTileLookup mapTiles,
  required PaceBalance paceBalance,
}) {
  final context = _requireAcceptedRushContext(
    fixtureId: fixtureId,
    command: command,
    actorPlayerId: actorPlayerId,
    before: before,
    mapTiles: mapTiles,
    paceBalance: paceBalance,
  );
  final expected = _expectedRushProduction(context);
  if (after != expected.state || !_sameRushEvents(events, expected.events)) {
    throw FormatException(
      '$fixtureId does not match the complete reviewed RushProduction oracle '
      'for gold, cities, units, research, registry, sentinels, and ordered '
      'events.',
    );
  }
}

_AcceptedRushContext _requireAcceptedRushContext({
  required String fixtureId,
  required RushProductionCommand command,
  required String actorPlayerId,
  required PersistentGameState before,
  required MapTileLookup mapTiles,
  required PaceBalance paceBalance,
}) {
  final cityIndex = before.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (cityIndex == -1) {
    throw FormatException('$fixtureId must target an existing rush city.');
  }
  final city = before.cities[cityIndex];
  final queue = city.productionQueue;
  if (city.ownerPlayerId != actorPlayerId ||
      queue == null ||
      !CityProductionRules.canRush(queue.target)) {
    throw FormatException(
      '$fixtureId must be an otherwise valid accepted rush command.',
    );
  }

  final targetCost = CityProductionRules.targetCost(
    queue.target,
    ruleset: CityRulesets.standard,
    wonderRuleset: WonderRuleset.standard,
    paceBalance: paceBalance,
  );
  final productionPerTurn = reviewedRushProductionPerTurn(
    state: before,
    city: city,
    target: queue.target,
    mapTiles: mapTiles,
    paceBalance: paceBalance,
  );
  final rushedProduction = CityProductionRules.rushProductionAmount(
    productionCost: targetCost,
    investedProduction: queue.investedProduction,
    productionPerTurn: productionPerTurn,
  );
  final rushCost = CityProductionRules.rushGoldCost(
    productionCost: targetCost,
    investedProduction: queue.investedProduction,
    productionPerTurn: productionPerTurn,
  );
  final currentGold = before.playerGold[city.ownerPlayerId] ?? 0;
  if (rushedProduction <= 0 || rushCost <= 0 || currentGold < rushCost) {
    throw FormatException(
      '$fixtureId must have positive rush progress and sufficient gold.',
    );
  }

  return _AcceptedRushContext(
    fixtureId: fixtureId,
    actorPlayerId: actorPlayerId,
    before: before,
    mapTiles: mapTiles,
    paceBalance: paceBalance,
    cityIndex: cityIndex,
    city: city,
    queue: queue,
    targetCost: targetCost,
    rushedProduction: rushedProduction,
    rushCost: rushCost,
    currentGold: currentGold,
  );
}

_ExpectedRushProduction _expectedRushProduction(_AcceptedRushContext context) {
  final advanced = context.queue.advancedBy(context.rushedProduction);
  final spentGold = {
    ...context.before.playerGold,
    context.city.ownerPlayerId: context.currentGold - context.rushCost,
  };
  final advancedCity = context.city.copyWith(productionQueue: advanced);
  if (!advanced.isCompleteFor(
    CityRulesets.standard,
    wonderRuleset: WonderRuleset.standard,
    paceBalance: context.paceBalance,
  )) {
    return _incompleteRushProduction(context, advancedCity, spentGold);
  }

  final overflow = CityProductionRules.completionOverflow(
    productionCost: context.targetCost,
    investedProduction: advanced.investedProduction,
  );
  return switch (advanced.target) {
    BuildingProductionTarget(:final buildingType) => _completedRushBuilding(
      context,
      advancedCity,
      buildingType,
      overflow,
      spentGold,
    ),
    UnitProductionTarget(:final unitType) => _completedRushUnit(
      context,
      advancedCity,
      unitType,
      overflow,
      spentGold,
    ),
    ProjectProductionTarget() => throw FormatException(
      '${context.fixtureId} cannot accept a continuous project.',
    ),
    WonderProductionTarget() => _completedRushWonder(
      context,
      advancedCity,
      spentGold,
    ),
  };
}

_ExpectedRushProduction _incompleteRushProduction(
  _AcceptedRushContext context,
  GameCity advancedCity,
  Map<String, int> spentGold,
) {
  return _ExpectedRushProduction(
    state: context.before.copyWith(
      cities: _replaceRushCity(
        context.before.cities,
        context.cityIndex,
        advancedCity,
      ),
      playerGold: spentGold,
    ),
  );
}

_ExpectedRushProduction _completedRushBuilding(
  _AcceptedRushContext context,
  GameCity advancedCity,
  CityBuildingType buildingType,
  int overflow,
  Map<String, int> spentGold,
) {
  final completedCity = advancedCity.copyWith(
    buildings: {...advancedCity.buildings, buildingType},
    productionQueue: null,
    productionOverflow: overflow,
  );
  return _ExpectedRushProduction(
    state: context.before.copyWith(
      cities: _replaceRushCity(
        context.before.cities,
        context.cityIndex,
        completedCity,
      ),
      playerGold: spentGold,
    ),
    events: [
      CityBuiltBuildingEvent(
        cityId: completedCity.id,
        buildingType: buildingType,
      ),
    ],
  );
}

_ExpectedRushProduction _completedRushUnit(
  _AcceptedRushContext context,
  GameCity advancedCity,
  GameUnitType unitType,
  int overflow,
  Map<String, int> spentGold,
) {
  final producedUnit = CityUnitProductionRules.produce(
    city: advancedCity,
    unitType: unitType,
    units: context.before.units,
    mapTiles: context.mapTiles,
  );
  if (producedUnit == null) {
    return _incompleteRushProduction(context, advancedCity, spentGold);
  }

  // This intentionally characterizes today's rush path. Artifact XP is
  // aligned with normal turn completion in a separate behavior slice.
  final completedCity = advancedCity.copyWith(
    productionQueue: null,
    productionOverflow: overflow,
  );
  return _ExpectedRushProduction(
    state: context.before.copyWith(
      cities: _replaceRushCity(
        context.before.cities,
        context.cityIndex,
        completedCity,
      ),
      units: [...context.before.units, producedUnit],
      playerGold: spentGold,
    ),
    events: [
      CityProducedUnitEvent(
        cityId: completedCity.id,
        unitType: unitType,
        producedUnitId: producedUnit.id,
      ),
    ],
  );
}

_ExpectedRushProduction _completedRushWonder(
  _AcceptedRushContext context,
  GameCity advancedCity,
  Map<String, int> spentGold,
) {
  final completion = WonderCompletionResolver.resolveCompletedForPlayer(
    playerId: context.actorPlayerId,
    cities: _replaceRushCity(
      context.before.cities,
      context.cityIndex,
      advancedCity,
    ),
    registry: context.before.wonderRegistry,
    playerGold: spentGold,
    research: context.before.research,
    ruleset: WonderRuleset.standard,
    paceBalance: context.paceBalance,
  );
  return _ExpectedRushProduction(
    state: context.before.copyWith(
      cities: completion.cities,
      playerGold: completion.playerGold,
      research: completion.research,
      wonderRegistry: completion.registry,
    ),
    events: completion.events,
  );
}

List<GameCity> _replaceRushCity(
  List<GameCity> cities,
  int cityIndex,
  GameCity city,
) {
  return [
    for (var index = 0; index < cities.length; index++)
      if (index == cityIndex) city else cities[index],
  ];
}

bool _sameRushEvents(List<GameEvent> left, List<GameEvent> right) {
  final leftJson = left.map(GameEventSerializer.toJson).toList();
  final rightJson = right.map(GameEventSerializer.toJson).toList();
  return jsonEncode(leftJson) == jsonEncode(rightJson);
}

final class _AcceptedRushContext {
  const _AcceptedRushContext({
    required this.fixtureId,
    required this.actorPlayerId,
    required this.before,
    required this.mapTiles,
    required this.paceBalance,
    required this.cityIndex,
    required this.city,
    required this.queue,
    required this.targetCost,
    required this.rushedProduction,
    required this.rushCost,
    required this.currentGold,
  });

  final String fixtureId;
  final String actorPlayerId;
  final PersistentGameState before;
  final MapTileLookup mapTiles;
  final PaceBalance paceBalance;
  final int cityIndex;
  final GameCity city;
  final CityProductionQueue queue;
  final int targetCost;
  final int rushedProduction;
  final int rushCost;
  final int currentGold;
}

final class _ExpectedRushProduction {
  const _ExpectedRushProduction({required this.state, this.events = const []});

  final PersistentGameState state;
  final List<GameEvent> events;
}
