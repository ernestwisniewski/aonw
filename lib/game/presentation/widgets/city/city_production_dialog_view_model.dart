import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_project_item_factory.dart';
import 'package:aonw/game/presentation/widgets/city/city_specialization_item_factory.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';

class CityProductionDialogViewModel {
  const CityProductionDialogViewModel({
    required this.cityName,
    required this.productionPerTurn,
    required this.currentCityYield,
    required this.currentCityScience,
    required this.buildings,
    required this.futureBuildings,
    required this.units,
    required this.projects,
    required this.specializations,
  });

  final String cityName;
  final int productionPerTurn;
  final TileYield? currentCityYield;
  final int currentCityScience;
  final List<CityProductionItem> buildings;
  final List<CityProductionItem> futureBuildings;
  final List<CityProductionItem> units;
  final List<CityProductionItem> projects;
  final List<CitySpecializationItem> specializations;

  bool get hasItems =>
      buildings.isNotEmpty ||
      futureBuildings.isNotEmpty ||
      units.isNotEmpty ||
      projects.isNotEmpty ||
      specializations.isNotEmpty;

  CityProductionItem? get activeItem {
    for (final item in [
      ...buildings,
      ...futureBuildings,
      ...units,
      ...projects,
    ]) {
      if (item.active) return item;
    }
    return null;
  }

  CityProductionItem? itemForBuilding(CityBuildingType? buildingType) {
    if (buildingType == null) return null;
    for (final item in [...buildings, ...futureBuildings]) {
      if (item.buildingType == buildingType) return item;
    }
    return null;
  }

  CityProductionItem? itemForUnit(GameUnitType? unitType) {
    if (unitType == null) return null;
    for (final item in units) {
      if (item.unitType == unitType) return item;
    }
    return null;
  }

  static CityProductionDialogViewModel from(
    GameCity city, {
    required AppLocalizations l10n,
    required CityRuleset cityRuleset,
    required ResearchState research,
    required TechnologyRuleset technologyRuleset,
    required MapData? mapData,
    required List<GameCity> cities,
    required List<GameUnit> units,
    List<WorldArtifact> artifacts = const [],
    required List<FieldImprovement> fieldImprovements,
    Iterable<ResourceTradeAgreement> resourceTradeAgreements = const [],
    required int productionPerTurn,
    int? currentTurn,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final cityName = GameDisplayNames.city(l10n, city);
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: research,
      ruleset: technologyRuleset,
    );
    final productionYield = productionPerTurn;
    final effectiveProduction = CityProductionRules.productionPerTurn(
      productionYield,
    );
    final currentCityYield = mapData == null
        ? null
        : _currentCityYieldFor(
            city: city,
            mapData: mapData,
            units: units,
            artifacts: artifacts,
            fieldImprovements: fieldImprovements,
            cityRuleset: cityRuleset,
            technologyEffects: technologyEffects,
            paceBalance: paceBalance,
          );
    final currentCityScience = _currentCityScienceFor(
      city: city,
      cities: cities,
      research: research,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      artifacts: artifacts,
    );
    final buildingPanel = CityBuildingsPanelViewModelFactory.from(
      city,
      l10n: l10n,
      cityRuleset: cityRuleset,
      research: research,
      technologyRuleset: technologyRuleset,
      mapData: mapData,
      productionPerTurn: productionYield,
      cityName: cityName,
      paceBalance: paceBalance,
    );
    final buildings = [
      for (final building in buildingPanel.buildings)
        if (building.state == CityBuildingCardState.available ||
            building.state == CityBuildingCardState.inProgress)
          CityProductionItem.building(
            building,
            l10n: l10n,
            currentTurn: currentTurn,
            sortMetrics: _buildingSortMetricsFor(
              city,
              building.type,
              cityRuleset: cityRuleset,
              mapData: mapData,
            ),
          ),
    ];
    final futureBuildings = [
      for (final building in buildingPanel.buildings)
        if (building.state == CityBuildingCardState.locked)
          CityProductionItem.building(
            building,
            l10n: l10n,
            currentTurn: currentTurn,
            sortMetrics: _buildingSortMetricsFor(
              city,
              building.type,
              cityRuleset: cityRuleset,
              mapData: mapData,
            ),
          ),
    ];
    final activeUnitType = switch (city.productionQueue?.target) {
      UnitProductionTarget(:final unitType) => unitType,
      _ => null,
    };
    final activeProjectType = switch (city.productionQueue?.target) {
      ProjectProductionTarget(:final projectType) => projectType,
      _ => null,
    };
    final playerCities = cities.isEmpty ? [city] : cities;
    final unitSupply = mapData == null
        ? null
        : CityUnitSupplyRules.forPlayer(
            playerId: city.ownerPlayerId,
            cities: playerCities,
            units: units,
            fieldImprovements: fieldImprovements,
            mapData: mapData,
            cityRuleset: cityRuleset,
            research: research,
            technologyRuleset: technologyRuleset,
            replacingCityId: city.id,
          );
    final unitUpkeep = UnitUpkeepRules.forPlayer(
      playerId: city.ownerPlayerId,
      cities: playerCities,
      units: units,
    );
    final unitItems = <CityProductionItem>[];
    for (final type in cityRuleset.units.keys) {
      final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
        playerId: city.ownerPlayerId,
        unitType: type,
        research: research,
        ruleset: technologyRuleset,
      );
      if (!CityProductionRules.canProduceUnit(
        type,
        ruleset: cityRuleset,
        technologyUnlocked: technologyUnlocked,
      )) {
        continue;
      }
      final active = activeUnitType == type;
      final missingResourceChoices = mapData == null
          ? const <ResourceType>{}
          : UnitProductionRequirementRules.missingResourceChoices(
              playerId: city.ownerPlayerId,
              unitType: type,
              cities: playerCities,
              mapData: mapData,
              ruleset: cityRuleset,
              research: research,
              resourceTradeAgreements: resourceTradeAgreements,
            );
      final resourceBlocked = !active && missingResourceChoices.isNotEmpty;
      final coastalBlocked =
          !active &&
          mapData != null &&
          !CityUnitProductionRules.canProduceInCity(
            city: city,
            unitType: type,
            mapData: mapData,
          );
      final cost = CityProductionRules.unitProductionCost(
        type,
        ruleset: cityRuleset,
        paceBalance: paceBalance,
      );
      final unitProductionPerTurn =
          CitySpecializationRules.productionPerTurnForTarget(
            productionPerTurn: CityTechnologyEffectRules.unitProductionPerTurn(
              effectiveProduction,
              effects: technologyEffects,
            ),
            target: UnitProductionTarget(type),
            specialization: city.specialization,
          );
      final supplyCost = CityUnitSupplyRules.supplyCostForType(type);
      final supplyBlocked =
          !active &&
          unitSupply != null &&
          unitSupply.used + supplyCost > unitSupply.capacity;
      final requirementLabel = coastalBlocked
          ? l10n.requirementCoastalAccess
          : resourceBlocked
          ? l10n.requirementResourcesName(
              _joinResourceNames(l10n, missingResourceChoices),
            )
          : supplyBlocked
          ? l10n.cityProductionUnitSupplyLimit(
              unitSupply.used,
              unitSupply.capacity,
            )
          : null;
      final invested = active ? city.productionQueue!.investedProduction : 0;
      unitItems.add(
        CityProductionItem.unit(
          l10n: l10n,
          type: type,
          title: GameDisplayNames.unitType(l10n, type),
          active: active,
          investedProduction: invested,
          totalCost: cost,
          productionPerTurn: unitProductionPerTurn,
          turnsRemaining: CityProductionRules.estimatedTurnsRemaining(
            productionCost: cost,
            investedProduction: invested,
            productionPerTurn: unitProductionPerTurn,
          ),
          currentTurn: currentTurn,
          locked: supplyBlocked || coastalBlocked || resourceBlocked,
          requirementLabel: requirementLabel,
          metaLabels: _unitMetaLabels(
            type: type,
            supplyCost: supplyCost,
            unitSupply: unitSupply,
            unitUpkeep: unitUpkeep,
            l10n: l10n,
          ),
        ),
      );
    }
    final projects = CityProjectItemFactory.build(
      l10n: l10n,
      productionPerTurn: effectiveProduction,
      specialization: city.specialization,
      activeProjectType: activeProjectType,
    );
    final specializationUnlocked = research
        .forPlayer(city.ownerPlayerId)
        .hasUnlocked(TechnologyId.specialization);
    final bestSpecializationFit = mapData == null
        ? null
        : CitySpecializationScorer.bestLocalFit(
            city: city,
            mapData: mapData,
            research: research,
          );
    final specializations = specializationUnlocked
        ? [
            for (final type in CitySpecializationType.values)
              CitySpecializationItemFactory.from(
                city,
                type,
                l10n,
                bestFit: bestSpecializationFit,
              ),
          ]
        : const <CitySpecializationItem>[];

    return CityProductionDialogViewModel(
      cityName: cityName,
      productionPerTurn: effectiveProduction,
      currentCityYield: currentCityYield,
      currentCityScience: currentCityScience,
      buildings: buildings,
      futureBuildings: futureBuildings,
      units: unitItems,
      projects: projects,
      specializations: specializations,
    );
  }
}

TileYield _currentCityYieldFor({
  required GameCity city,
  required MapData mapData,
  required List<GameUnit> units,
  required List<WorldArtifact> artifacts,
  required List<FieldImprovement> fieldImprovements,
  required CityRuleset cityRuleset,
  required TechnologyEffectSummary technologyEffects,
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
  );
  return science.byCityId[city.id] ?? 0;
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

String _joinResourceNames(AppLocalizations l10n, Set<ResourceType> resources) {
  final names =
      resources
          .map((resource) => GameDisplayNames.resource(l10n, resource))
          .toList()
        ..sort();
  if (names.isEmpty) return l10n.requirementTechnology;
  if (names.length == 1) return names.single;
  return '${names.take(names.length - 1).join(', ')} lub ${names.last}';
}
