part of 'city_production_dialog_view_model.dart';

typedef _ProductionUnitContext = ({
  GameCity city,
  List<GameCity> playerCities,
  List<GameUnit> units,
  List<WorldArtifact> artifacts,
  List<FieldImprovement> fieldImprovements,
  GameUnitType? activeUnitType,
  CityRuleset cityRuleset,
  TechnologyRuleset technologyRuleset,
  ResearchState research,
  WorldMap? mapData,
  Iterable<ResourceTradeAgreement> resourceTradeAgreements,
  StrategicResourceAccounts strategicResources,
  StrategicResourceEconomyProfile strategicResourceEconomy,
  bool stockpilesEnabled,
  int effectiveProduction,
  TechnologyEffectSummary technologyEffects,
  CityUnitSupplyBreakdown? unitSupply,
  UnitUpkeepBreakdown unitUpkeep,
  int? currentTurn,
  PaceBalance paceBalance,
  AppLocalizations l10n,
});

typedef _ProductionUnitItemFacts = ({
  GameUnitType type,
  _ProductionUnitContext context,
  UnitProductionAvailability availability,
  bool active,
  int supplyCost,
  int cost,
  int productionPerTurn,
  int invested,
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
  required List<GameUnit> units,
  required List<WorldArtifact> artifacts,
  required List<FieldImprovement> fieldImprovements,
  required GameUnitType? activeUnitType,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required ResearchState research,
  required WorldMap? mapData,
  required Iterable<ResourceTradeAgreement> resourceTradeAgreements,
  required StrategicResourceAccounts strategicResources,
  required StrategicResourceEconomyProfile strategicResourceEconomy,
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
    units: units,
    artifacts: artifacts,
    fieldImprovements: fieldImprovements,
    activeUnitType: activeUnitType,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    research: research,
    mapData: mapData,
    resourceTradeAgreements: resourceTradeAgreements,
    strategicResources: strategicResources,
    strategicResourceEconomy: strategicResourceEconomy,
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
  final active = context.activeUnitType == type;
  final supplyCost = CityUnitSupplyRules.supplyCostForType(type);
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
  final invested = active
      ? context.city.productionQueue!.investedProduction
      : 0;
  return _buildProductionUnitItem((
    type: type,
    context: context,
    availability: availability,
    active: active,
    supplyCost: supplyCost,
    cost: cost,
    productionPerTurn: productionPerTurn,
    invested: invested,
  ));
}

CityProductionItem _buildProductionUnitItem(_ProductionUnitItemFacts facts) =>
    CityProductionItem.unit(
      l10n: facts.context.l10n,
      type: facts.type,
      title: GameDisplayNames.unitType(facts.context.l10n, facts.type),
      active: facts.active,
      investedProduction: facts.invested,
      totalCost: facts.cost,
      productionPerTurn: facts.productionPerTurn,
      turnsRemaining: CityProductionRules.estimatedTurnsRemaining(
        productionCost: facts.cost,
        investedProduction: facts.invested,
        productionPerTurn: facts.productionPerTurn,
      ),
      currentTurn: facts.context.currentTurn,
      locked: !facts.active && !facts.availability.isAvailable,
      requirementLabel: _unitRequirementLabels(
        facts.availability,
        unitSupply: facts.context.unitSupply,
        l10n: facts.context.l10n,
      ).firstOrNull,
      unitAvailability: facts.availability,
      unitRequirementLabels: _unitRequirementLabels(
        facts.availability,
        unitSupply: facts.context.unitSupply,
        l10n: facts.context.l10n,
      ),
      metaLabels: _unitMetaLabels(
        type: facts.type,
        supplyCost: facts.supplyCost,
        unitSupply: facts.context.unitSupply,
        unitUpkeep: facts.context.unitUpkeep,
        l10n: facts.context.l10n,
      ),
      strategicResourceLabel: _strategicResourceLabel(
        l10n: facts.context.l10n,
        active: facts.active,
        city: facts.context.city,
        availability: facts.availability.strategic,
      ),
      strategicResourceShortage: facts.availability.blockers.any(
        (blocker) => blocker is UnitStrategicResourceBlocker,
      ),
      spawnBlocked:
          facts.active &&
          facts.invested >= facts.cost &&
          facts.context.mapData != null &&
          !CityUnitProductionRules.canSpawnProducedUnit(
            city: facts.context.city,
            unitType: facts.type,
            units: facts.context.units,
            mapTiles: facts.context.mapData!,
          ),
    );

UnitProductionAvailability _unitAvailability(
  GameUnitType type,
  _ProductionUnitContext context,
) {
  final strategic = context.stockpilesEnabled
      ? UnitStrategicResourceAvailability.forUnit(
          playerId: context.city.ownerPlayerId,
          unitType: type,
          definition: context.cityRuleset.unitDefinitionFor(type),
          accounts: context.strategicResources,
          replacingCity: context.city,
        )
      : null;
  final mapData = context.mapData;
  if (mapData == null) {
    return UnitProductionAvailability(
      blockers: [
        if (strategic != null && !strategic.isAvailable)
          UnitStrategicResourceBlocker(strategic),
      ],
      strategic: strategic,
    );
  }
  return UnitProductionAvailability.evaluate((
    playerId: context.city.ownerPlayerId,
    city: context.city,
    unitType: type,
    cities: context.playerCities,
    units: context.units,
    artifacts: context.artifacts,
    fieldImprovements: context.fieldImprovements,
    research: context.research,
    resourceTradeAgreements: context.resourceTradeAgreements,
    mapView: mapData,
    cityRuleset: context.cityRuleset,
    technologyRuleset: context.technologyRuleset,
    strategicResources: context.strategicResources,
    strategicResourceEconomy: context.strategicResourceEconomy,
    preferredResourceOptionIndex: null,
  ));
}

List<String> _unitRequirementLabels(
  UnitProductionAvailability availability, {
  required CityUnitSupplyBreakdown? unitSupply,
  required AppLocalizations l10n,
}) => [
  for (final blocker in availability.blockers)
    switch (blocker) {
      UnitTechnologyBlocker() => l10n.requirementTechnology,
      UnitPresenceResourceBlocker(:final resources) =>
        l10n.requirementResourcesName(
          ResourceRequirementDisplayNames.alternatives(l10n, resources),
        ),
      UnitStrategicResourceBlocker(:final availability) =>
        _strategicShortageLabel(l10n, availability),
      UnitCoastBlocker() => l10n.requirementCoastalAccess,
      UnitSupplyBlocker() =>
        unitSupply == null
            ? l10n.cityProductionNoProduction
            : l10n.cityProductionUnitSupplyLimit(
                unitSupply.used,
                unitSupply.capacity,
              ),
    },
];

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
