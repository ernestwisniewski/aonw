part of 'city_production_dialog_view_model.dart';

typedef _ProductionUnitContext = ({
  GameCity city,
  List<GameCity> playerCities,
  GameUnitType? activeUnitType,
  CityRuleset cityRuleset,
  TechnologyRuleset technologyRuleset,
  ResearchState research,
  WorldMap? mapData,
  Iterable<ResourceTradeAgreement> resourceTradeAgreements,
  StrategicResourceAccounts strategicResources,
  bool stockpilesEnabled,
  int effectiveProduction,
  TechnologyEffectSummary technologyEffects,
  CityUnitSupplyBreakdown? unitSupply,
  UnitUpkeepBreakdown unitUpkeep,
  int? currentTurn,
  PaceBalance paceBalance,
  AppLocalizations l10n,
});

typedef _ProductionUnitAvailability = ({
  bool active,
  Set<ResourceType> missingPresenceResources,
  UnitStrategicResourceAvailability? strategic,
  bool strategicBlocked,
  bool resourceBlocked,
  bool coastalBlocked,
});

String? _strategicFreeSummary({
  required bool enabled,
  required String playerId,
  required StrategicResourceAccounts accounts,
  required AppLocalizations l10n,
}) {
  if (!enabled) return null;
  final stockpile = accounts.forPlayer(playerId);
  final resources = ResourceCatalog.stockpiledResources
      .map(
        (resource) =>
            '${stockpile.amountFor(resource)} ${GameDisplayNames.resource(l10n, resource)}',
      )
      .join(' · ');
  return l10n.cityProductionStrategicFree(resources);
}

List<CityProductionItem> _productionUnitItems({
  required GameCity city,
  required List<GameCity> playerCities,
  required GameUnitType? activeUnitType,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required ResearchState research,
  required WorldMap? mapData,
  required Iterable<ResourceTradeAgreement> resourceTradeAgreements,
  required StrategicResourceAccounts strategicResources,
  required bool stockpilesEnabled,
  required int effectiveProduction,
  required TechnologyEffectSummary technologyEffects,
  required CityUnitSupplyBreakdown? unitSupply,
  required UnitUpkeepBreakdown unitUpkeep,
  required int? currentTurn,
  required PaceBalance paceBalance,
  required AppLocalizations l10n,
}) {
  final context = (
    city: city,
    playerCities: playerCities,
    activeUnitType: activeUnitType,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    research: research,
    mapData: mapData,
    resourceTradeAgreements: resourceTradeAgreements,
    strategicResources: strategicResources,
    stockpilesEnabled: stockpilesEnabled,
    effectiveProduction: effectiveProduction,
    technologyEffects: technologyEffects,
    unitSupply: unitSupply,
    unitUpkeep: unitUpkeep,
    currentTurn: currentTurn,
    paceBalance: paceBalance,
    l10n: l10n,
  );
  return [
    for (final type in cityRuleset.units.keys)
      if (_unitCanBeProduced(type, context)) _productionUnitItem(type, context),
  ];
}

bool _unitCanBeProduced(GameUnitType type, _ProductionUnitContext context) {
  final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
    playerId: context.city.ownerPlayerId,
    unitType: type,
    research: context.research,
    ruleset: context.technologyRuleset,
  );
  return CityProductionRules.canProduceUnit(
    type,
    ruleset: context.cityRuleset,
    technologyUnlocked: technologyUnlocked,
  );
}

CityProductionItem _productionUnitItem(
  GameUnitType type,
  _ProductionUnitContext context,
) {
  final availability = _unitAvailability(type, context);
  final supplyCost = CityUnitSupplyRules.supplyCostForType(type);
  final supplyBlocked =
      !availability.active &&
      context.unitSupply != null &&
      context.unitSupply!.used + supplyCost > context.unitSupply!.capacity;
  final cost = CityProductionRules.unitProductionCost(
    type,
    ruleset: context.cityRuleset,
    paceBalance: context.paceBalance,
  );
  final productionPerTurn = CitySpecializationRules.productionPerTurnForTarget(
    productionPerTurn: CityTechnologyEffectRules.unitProductionPerTurn(
      context.effectiveProduction,
      effects: context.technologyEffects,
    ),
    target: UnitProductionTarget(type),
    specialization: context.city.specialization,
  );
  final invested = availability.active
      ? context.city.productionQueue!.investedProduction
      : 0;
  return _buildProductionUnitItem(
    type: type,
    context: context,
    availability: availability,
    supplyCost: supplyCost,
    supplyBlocked: supplyBlocked,
    cost: cost,
    productionPerTurn: productionPerTurn,
    invested: invested,
  );
}

CityProductionItem _buildProductionUnitItem({
  required GameUnitType type,
  required _ProductionUnitContext context,
  required _ProductionUnitAvailability availability,
  required int supplyCost,
  required bool supplyBlocked,
  required int cost,
  required int productionPerTurn,
  required int invested,
}) => CityProductionItem.unit(
  l10n: context.l10n,
  type: type,
  title: GameDisplayNames.unitType(context.l10n, type),
  active: availability.active,
  investedProduction: invested,
  totalCost: cost,
  productionPerTurn: productionPerTurn,
  turnsRemaining: CityProductionRules.estimatedTurnsRemaining(
    productionCost: cost,
    investedProduction: invested,
    productionPerTurn: productionPerTurn,
  ),
  currentTurn: context.currentTurn,
  locked:
      supplyBlocked ||
      availability.coastalBlocked ||
      availability.resourceBlocked,
  requirementLabel: _unitRequirementLabel(
    availability,
    supplyBlocked: supplyBlocked,
    unitSupply: context.unitSupply,
    l10n: context.l10n,
  ),
  metaLabels: _unitMetaLabels(
    type: type,
    supplyCost: supplyCost,
    unitSupply: context.unitSupply,
    unitUpkeep: context.unitUpkeep,
    l10n: context.l10n,
  ),
  strategicResourceLabel: _strategicResourceLabel(
    l10n: context.l10n,
    active: availability.active,
    city: context.city,
    availability: availability.strategic,
  ),
  strategicResourceShortage: availability.strategicBlocked,
);

_ProductionUnitAvailability _unitAvailability(
  GameUnitType type,
  _ProductionUnitContext context,
) {
  final active = context.activeUnitType == type;
  final missing = context.mapData == null
      ? const <ResourceType>{}
      : UnitProductionRequirementRules.missingResourceChoices(
          playerId: context.city.ownerPlayerId,
          unitType: type,
          cities: context.playerCities,
          mapTiles: context.mapData!,
          ruleset: context.cityRuleset,
          research: context.research,
          resourceTradeAgreements: context.resourceTradeAgreements,
          ignoreStockpileCosts: context.stockpilesEnabled,
        );
  final strategic = context.stockpilesEnabled
      ? UnitStrategicResourceAvailability.forUnit(
          playerId: context.city.ownerPlayerId,
          unitType: type,
          definition: context.cityRuleset.unitDefinitionFor(type),
          accounts: context.strategicResources,
          replacingCity: context.city,
        )
      : null;
  final strategicBlocked =
      !active && strategic != null && !strategic.isAvailable;
  final coastalBlocked =
      !active &&
      context.mapData != null &&
      !CityUnitProductionRules.canProduceInCity(
        city: context.city,
        unitType: type,
        mapTiles: context.mapData!,
      );
  return (
    active: active,
    missingPresenceResources: missing,
    strategic: strategic,
    strategicBlocked: strategicBlocked,
    resourceBlocked: !active && (missing.isNotEmpty || strategicBlocked),
    coastalBlocked: coastalBlocked,
  );
}

String? _unitRequirementLabel(
  _ProductionUnitAvailability availability, {
  required bool supplyBlocked,
  required CityUnitSupplyBreakdown? unitSupply,
  required AppLocalizations l10n,
}) {
  if (availability.coastalBlocked) return l10n.requirementCoastalAccess;
  if (availability.strategicBlocked) {
    return _strategicShortageLabel(l10n, availability.strategic!);
  }
  if (availability.resourceBlocked) {
    return l10n.requirementResourcesName(
      ResourceRequirementDisplayNames.alternatives(
        l10n,
        availability.missingPresenceResources,
      ),
    );
  }
  if (supplyBlocked) {
    return l10n.cityProductionUnitSupplyLimit(
      unitSupply!.used,
      unitSupply.capacity,
    );
  }
  return null;
}

String? _strategicResourceLabel({
  required AppLocalizations l10n,
  required bool active,
  required GameCity city,
  required UnitStrategicResourceAvailability? availability,
}) {
  if (availability == null || !availability.hasCost) return null;
  final reserved = city.productionQueue?.resourceAllocation;
  final allocation = active && reserved != null && !reserved.isEmpty
      ? reserved
      : !availability.selectedAllocation.isEmpty
      ? availability.selectedAllocation
      : availability.options.first;
  final label = _strategicBundleLabel(l10n, allocation);
  return active
      ? l10n.cityProductionStrategicAllocated(label)
      : l10n.cityProductionStrategicCost(label);
}

String _strategicShortageLabel(
  AppLocalizations l10n,
  UnitStrategicResourceAvailability availability,
) {
  final labels = availability.options.map((option) {
    return option.amounts.entries
        .map((entry) {
          return l10n.cityProductionStrategicAvailable(
            availability.availableFor(entry.key),
            entry.value,
            GameDisplayNames.resource(l10n, entry.key),
          );
        })
        .join(' + ');
  });
  return l10n.cityProductionStrategicMissing(labels.join(' / '));
}

String _strategicBundleLabel(
  AppLocalizations l10n,
  StrategicResourceBundle bundle,
) => bundle.amounts.entries
    .map(
      (entry) => '${entry.value} ${GameDisplayNames.resource(l10n, entry.key)}',
    )
    .join(' + ');
