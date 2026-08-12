import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/resource_requirement_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_project_item_factory.dart';
import 'package:aonw/game/presentation/widgets/city/city_specialization_item_factory.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'city_production_dialog_view_model_helpers.dart';
part 'city_production_dialog_view_model_queries.dart';
part 'city_production_dialog_unit_items.dart';

class CityProductionDialogViewModel {
  const CityProductionDialogViewModel({
    required this.cityName,
    required this.productionPerTurn,
    required this.currentCityYield,
    required this.currentCityScience,
    required this.buildings,
    required this.futureBuildings,
    required this.wonders,
    required this.units,
    required this.projects,
    required this.specializations,
    this.strategicResourceSummaryLabel,
  });

  final String cityName;
  final int productionPerTurn;
  final TileYield? currentCityYield;
  final int currentCityScience;
  final List<CityProductionItem> buildings;
  final List<CityProductionItem> futureBuildings;
  final List<CityProductionItem> wonders;
  final List<CityProductionItem> units;
  final List<CityProductionItem> projects;
  final List<CitySpecializationItem> specializations;
  final String? strategicResourceSummaryLabel;

  static CityProductionDialogViewModel from(
    GameCity city, {
    required AppLocalizations l10n,
    required CityRuleset cityRuleset,
    required ResearchState research,
    required TechnologyRuleset technologyRuleset,
    WonderRegistry wonderRegistry = WonderRegistry.empty,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    required WorldMap? mapData,
    required List<GameCity> cities,
    required List<GameUnit> units,
    List<WorldArtifact> artifacts = const [],
    required List<FieldImprovement> fieldImprovements,
    Iterable<ResourceTradeAgreement> resourceTradeAgreements = const [],
    StrategicResourceAccounts strategicResources =
        StrategicResourceAccounts.empty,
    StrategicResourceEconomyProfile strategicResourceEconomy =
        StrategicResourceEconomyProfile.legacyPresenceV0,
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
            cities: cities,
            wonderRegistry: wonderRegistry,
            wonderRuleset: wonderRuleset,
            paceBalance: paceBalance,
          );
    final currentCityScience = _currentCityScienceFor(
      city: city,
      cities: cities,
      research: research,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      wonderRegistry: wonderRegistry,
      wonderRuleset: wonderRuleset,
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
    final activeWonderType = switch (city.productionQueue?.target) {
      WonderProductionTarget(:final wonderType) => wonderType,
      _ => null,
    };
    final playerCities = cities.isEmpty ? [city] : cities;
    final unitSupply = _unitSupplyFor(
      city: city,
      cities: playerCities,
      units: units,
      artifacts: artifacts,
      fieldImprovements: fieldImprovements,
      mapData: mapData,
      cityRuleset: cityRuleset,
      research: research,
      technologyRuleset: technologyRuleset,
    );
    final unitUpkeep = UnitUpkeepRules.forPlayer(
      playerId: city.ownerPlayerId,
      cities: playerCities,
      units: units,
    );
    final stockpilesEnabled =
        strategicResourceEconomy == StrategicResourceEconomyProfile.stockpileV1;
    final strategicResourceSummaryLabel = _strategicFreeSummary(
      enabled: stockpilesEnabled,
      playerId: city.ownerPlayerId,
      accounts: strategicResources,
      l10n: l10n,
    );
    final unitItems = _productionUnitItems(
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
    final projects = CityProjectItemFactory.build(
      l10n: l10n,
      productionPerTurn: effectiveProduction,
      specialization: city.specialization,
      activeProjectType: activeProjectType,
    );
    final wonderItems = mapData == null
        ? const <CityProductionItem>[]
        : _wonderItems(
            city: city,
            cities: playerCities,
            mapData: mapData,
            research: research,
            ruleset: wonderRuleset,
            registry: wonderRegistry,
            l10n: l10n,
            activeWonderType: activeWonderType,
            effectiveProduction: effectiveProduction,
            currentTurn: currentTurn,
            paceBalance: paceBalance,
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
      wonders: wonderItems,
      units: unitItems,
      projects: projects,
      specializations: specializations,
      strategicResourceSummaryLabel: strategicResourceSummaryLabel,
    );
  }
}
