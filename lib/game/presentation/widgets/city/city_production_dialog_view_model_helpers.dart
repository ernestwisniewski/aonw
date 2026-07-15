part of 'city_production_dialog_view_model.dart';

TileYield _currentCityYieldFor({
  required GameCity city,
  required MapData mapData,
  required List<GameUnit> units,
  required List<WorldArtifact> artifacts,
  required List<FieldImprovement> fieldImprovements,
  required CityRuleset cityRuleset,
  required TechnologyEffectSummary technologyEffects,
  required List<GameCity> cities,
  required WonderRegistry wonderRegistry,
  required WonderRuleset wonderRuleset,
  required PaceBalance paceBalance,
}) {
  final tileYield = CityYieldCalculator.totalFor(
    city,
    mapData,
    fieldImprovements: fieldImprovements,
    units: units,
    artifacts: artifacts,
    ruleset: cityRuleset,
  );
  final economy = CityEconomyBreakdown.from(
    city: city,
    tileYield: tileYield,
    mapData: mapData,
    ruleset: cityRuleset,
    technologyEffects: technologyEffects,
    cities: cities,
    wonderRegistry: wonderRegistry,
    wonderRuleset: wonderRuleset,
    paceBalance: paceBalance,
  );
  return TileYield(
    food: economy.netYield.food,
    production: CityProductionRules.productionPerTurn(
      economy.netYield.production,
    ),
    gold: economy.netYield.gold,
    defense: economy.netYield.defense,
  );
}

int _currentCityScienceFor({
  required GameCity city,
  required List<GameCity> cities,
  required ResearchState research,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required WonderRegistry wonderRegistry,
  required WonderRuleset wonderRuleset,
  required List<WorldArtifact> artifacts,
}) {
  final playerCities = cities.any((candidate) => candidate.id == city.id)
      ? cities
      : [...cities, city];
  final science = ScienceYieldCalculator.totalForPlayer(
    playerId: city.ownerPlayerId,
    cities: playerCities,
    research: research,
    ruleset: technologyRuleset,
    artifacts: artifacts,
    cityRuleset: cityRuleset,
    wonderRegistry: wonderRegistry,
    wonderRuleset: wonderRuleset,
  );
  return science.byCityId[city.id] ?? 0;
}

List<CityProductionItem> _wonderItems({
  required GameCity city,
  required List<GameCity> cities,
  required MapData mapData,
  required ResearchState research,
  required WonderRuleset ruleset,
  required WonderRegistry registry,
  required AppLocalizations l10n,
  required WonderType? activeWonderType,
  required int effectiveProduction,
  required int? currentTurn,
  required PaceBalance paceBalance,
}) {
  return [
    for (final entry in ruleset.wonders.entries)
      _wonderItem(
        city: city,
        cities: cities,
        mapData: mapData,
        research: research,
        ruleset: ruleset,
        registry: registry,
        l10n: l10n,
        wonderType: entry.key,
        active: activeWonderType == entry.key,
        effectiveProduction: effectiveProduction,
        currentTurn: currentTurn,
        paceBalance: paceBalance,
      ),
  ];
}

CityProductionItem _wonderItem({
  required GameCity city,
  required List<GameCity> cities,
  required MapData mapData,
  required ResearchState research,
  required WonderRuleset ruleset,
  required WonderRegistry registry,
  required AppLocalizations l10n,
  required WonderType wonderType,
  required bool active,
  required int effectiveProduction,
  required int? currentTurn,
  required PaceBalance paceBalance,
}) {
  final availability = active
      ? const WonderAvailability(status: WonderAvailabilityStatus.available)
      : WonderAvailabilityPolicy.availabilityFor(
          city: city,
          wonderType: wonderType,
          cities: cities,
          registry: registry,
          research: research,
          mapTiles: mapData,
          ruleset: ruleset,
        );
  final definition = ruleset.definitionFor(wonderType);
  final cost = CityProductionRules.wonderProductionCost(
    wonderType,
    ruleset: ruleset,
    paceBalance: paceBalance,
  );
  final productionPerTurn = CitySpecializationRules.productionPerTurnForTarget(
    productionPerTurn: effectiveProduction,
    target: WonderProductionTarget(wonderType),
    specialization: city.specialization,
  );
  final invested = active ? city.productionQueue!.investedProduction : 0;
  final requirementLabel = _wonderRequirementLabel(
    availability,
    definition,
    l10n,
  );
  return CityProductionItem.wonder(
    l10n: l10n,
    type: wonderType,
    active: active,
    investedProduction: invested,
    totalCost: cost,
    productionPerTurn: productionPerTurn,
    turnsRemaining: CityProductionRules.estimatedTurnsRemaining(
      productionCost: cost,
      investedProduction: invested,
      productionPerTurn: productionPerTurn,
    ),
    currentTurn: currentTurn,
    locked: !active && !availability.isAvailable,
    requirementLabel: requirementLabel,
  );
}

String? _wonderRequirementLabel(
  WonderAvailability availability,
  WonderDefinition definition,
  AppLocalizations l10n,
) {
  return switch (availability.status) {
    WonderAvailabilityStatus.available => null,
    WonderAvailabilityStatus.completed => l10n.cityProductionWonderBuiltBy(
      availability.completedBy ?? '',
    ),
    WonderAvailabilityStatus.technologyLocked =>
      l10n.cityProductionWonderRequiresTechnology(
        GameDisplayNames.technology(l10n, definition.unlockTech),
      ),
    WonderAvailabilityStatus.playerAlreadyBuildingWonder ||
    WonderAvailabilityStatus.cityAlreadyBuildingWonder =>
      l10n.cityProductionWonderAnotherInProgress,
    WonderAvailabilityStatus.requirementsMissing =>
      _wonderMissingRequirementLabel(availability.missingRequirements, l10n),
  };
}

String? _wonderMissingRequirementLabel(
  List<WonderRequirement> requirements,
  AppLocalizations l10n,
) {
  if (requirements.isEmpty) return null;
  return switch (requirements.first) {
    WonderCoastalAccessRequirement() => l10n.requirementCoastalAccess,
    WonderResourceRequirement(:final resources) =>
      l10n.requirementResourcesName(
        ResourceRequirementDisplayNames.alternatives(l10n, resources),
      ),
    WonderAdjacentRiverRequirement() => l10n.cityProductionWonderRequiresRiver,
    WonderAdjacentMountainRequirement() =>
      l10n.cityProductionWonderRequiresMountain,
    WonderHostTerrainRequirement(:final allowedTerrains) =>
      l10n.cityProductionWonderRequiresTerrain(
        allowedTerrains
            .map((terrain) => GameDisplayNames.terrain(l10n, terrain))
            .join(', '),
      ),
  };
}

CityProductionSortMetrics _buildingSortMetricsFor(
  GameCity city,
  CityBuildingType type, {
  required CityRuleset cityRuleset,
  required MapData? mapData,
}) {
  var food = 0;
  var production = 0;
  var gold = 0;
  var defense = 0;
  var science = 0;
  var maxControlledHexes = 0;
  var foodDepositBonusPercent = 0;

  for (final effect in cityRuleset.buildingDefinitionFor(type).effects) {
    switch (effect) {
      case FlatCityYieldEffect(:final yield):
        food += yield.food;
        production += yield.production;
        gold += yield.gold;
        defense += yield.defense;
      case RiverHexCityYieldEffect(
        :final yieldPerRiverHex,
        :final maxApplications,
      ):
        final applications = mapData == null
            ? 1
            : _effectiveApplications(
                _riverHexCount(city, mapData),
                maxApplications,
              );
        food += yieldPerRiverHex.food * applications;
        production += yieldPerRiverHex.production * applications;
        gold += yieldPerRiverHex.gold * applications;
        defense += yieldPerRiverHex.defense * applications;
      case FlatCityScienceEffect(:final amount):
        science += amount;
      case MaxControlledHexesEffect(:final amount):
        maxControlledHexes += amount;
      case FoodDepositMultiplierEffect(:final multiplier):
        foodDepositBonusPercent += ((multiplier - 1) * 100).round();
    }
  }

  return CityProductionSortMetrics(
    food: food,
    production: production,
    gold: gold,
    defense: defense,
    science: science,
    maxControlledHexes: maxControlledHexes,
    foodDepositBonusPercent: foodDepositBonusPercent,
  );
}

int _effectiveApplications(int count, int? maxApplications) {
  if (maxApplications == null) return count;
  return count < maxApplications ? count : maxApplications;
}

int _riverHexCount(GameCity city, MapData mapData) {
  var count = 0;
  for (final hex in city.territoryHexes) {
    final tile = mapData.tileAt(hex.col, hex.row);
    if (tile != null && TileYieldRules.hasRiver(tile)) count++;
  }
  return count;
}

List<String> _unitMetaLabels({
  required GameUnitType type,
  required int supplyCost,
  required CityUnitSupplyBreakdown? unitSupply,
  required UnitUpkeepBreakdown unitUpkeep,
  required AppLocalizations l10n,
}) {
  return [
    if (unitSupply != null) ...[
      l10n.cityProductionUnitSupplyCost(supplyCost),
      l10n.cityProductionUnitSupplyUsed(unitSupply.used, unitSupply.capacity),
    ],
    if (type == GameUnitType.worker)
      l10n.cityProductionNextWorkerUpkeep(unitUpkeep.nextWorkerUpkeep),
  ];
}
