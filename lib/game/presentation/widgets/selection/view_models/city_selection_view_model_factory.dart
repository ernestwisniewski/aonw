import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/city_objective_selection_items_factory.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_yield_item.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

abstract final class CitySelectionViewModelFactory {
  static SelectionViewModel from(
    GameSelection selection, {
    CityRuleset cityRuleset = CityRulesets.standard,
    MapData? mapData,
    List<GameUnit> units = const [],
    List<GameCity> cities = const [],
    List<WorldArtifact> artifacts = const [],
    List<FieldImprovement> fieldImprovements = const [],
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    required AppLocalizations l10n,
    String Function(GameCity city)? cityName,
    String Function(CityBuildingType type)? buildingName,
    String Function(CitySpecializationType type)? specializationName,
    int? currentTurn,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final city = selection.city;
    if (city == null) return const SelectionViewModel.empty();

    final cityYield = selection.cityYield;
    final cityEconomy = selection.cityEconomy;
    final colorValue = selection.cityPlayerColor ?? 0xFFaaaaaa;
    final cityColor = PlayerColorTheme.resolve(colorValue);
    final economy = CityEconomy.from(
      city: city,
      yield: cityEconomy?.netYield ?? cityYield ?? TileYield.zero,
    );
    final storedArtifact = _storedArtifactForCity(city, artifacts);
    final objectiveDescriptionItems =
        CityObjectiveSelectionItemsFactory.descriptionItems(
          city: city,
          mapData: mapData,
          units: units,
          l10n: l10n,
        );
    final growthCost = cityEconomy?.growthCost;
    final netFood = cityEconomy?.netFood;
    final maxHexes = CityTechnologyEffectRules.effectiveMaxHexes(
      city,
      ruleset: cityRuleset,
      effects: cityEconomy?.technologyEffects ?? TechnologyEffectSummary.empty,
    );
    final cityBuildingItems = [
      for (final type in city.buildings)
        SelectionCityBuildingItem(
          type: type,
          label:
              buildingName?.call(type) ??
              GameDisplayNames.cityBuilding(l10n, type),
        ),
    ];
    final cohesionItem = _cohesionItem(city: city, cities: cities, l10n: l10n);
    final yieldBreakdown = mapData == null
        ? null
        : CityYieldBreakdownViewModel.fromCity(
            city: city,
            mapData: mapData,
            fieldImprovements: fieldImprovements,
            units: units,
            artifacts: artifacts,
            cityRuleset: cityRuleset,
            research: research,
            technologyRuleset: technologyRuleset,
            currentTurn: currentTurn,
            paceBalance: paceBalance,
            l10n: l10n,
          );

    return SelectionViewModel(
      icon: GameIcons.cityFilled,
      color: cityColor,
      title: cityName?.call(city) ?? GameDisplayNames.city(l10n, city),
      subtitle: _subtitleFor(
        city,
        population: economy.population,
        territoryHexCount: economy.territoryHexCount,
        maxHexes: maxHexes,
        buildingName: buildingName,
        l10n: l10n,
      ),
      assetIcon: SelectionAssetIconViewModel.city(
        cityVisualLevel: _cityVisualLevelFor(city),
        cityTechnologyProfileIndex: _cityTechnologyProfileIndexFor(
          city,
          research: research,
          technologyRuleset: technologyRuleset,
        ),
      ),
      selectionKey: 'city:${city.id}',
      yields: cityYield != null || cityEconomy != null
          ? SelectionYieldItem.fromYield(
              economy.yield,
              foodLabel: l10n.yieldFoodShort,
              productionLabel: l10n.yieldProductionShort,
              goldLabel: l10n.yieldGoldShort,
              defenseLabel: l10n.yieldDefenseShort,
            )
          : const [],
      yieldTitle: cityYield != null || cityEconomy != null
          ? l10n.citySelectionYieldTitle
          : null,
      yieldTooltip: cityYield != null || cityEconomy != null
          ? l10n.citySelectionYieldTooltip
          : null,
      items: [
        SelectionInfoItem(
          icon: GameIcons.population,
          label: l10n.commonPopulation,
          value: '${economy.population}',
          color: cityColor,
        ),
        SelectionInfoItem(
          icon: GameIcons.workedHexes,
          label: l10n.citySelectionTerritoryLabel,
          value: '${economy.territoryHexCount}/$maxHexes',
          color: GameUiTheme.accent,
        ),
        SelectionInfoItem(
          icon: GameIcons.food,
          label: l10n.citySelectionFoodLabel,
          value: growthCost == null
              ? '${city.storedFood}'
              : '${city.storedFood}/$growthCost',
          color: const Color(0xFF89b66f),
        ),
        SelectionInfoItem(
          icon: GameIcons.growth,
          label: l10n.citySelectionNetFoodLabel,
          value: netFood == null ? '—' : '+$netFood',
          color: const Color(0xFF87c96a),
        ),
        SelectionInfoItem(
          icon: GameIcons.city,
          label: l10n.citySelectionBuildingsLabel,
          value: '${city.buildings.length}',
          color: const Color(0xFF8da8e8),
        ),
        ?cohesionItem,
        if (storedArtifact != null)
          SelectionInfoItem(
            icon: GameIcons.artifact,
            label: l10n.citySelectionArtifactLabel,
            value:
                '${GameDisplayNames.worldArtifact(l10n, storedArtifact.type)} '
                '(${GameDisplayNames.worldArtifactShortBonus(l10n, storedArtifact.type)})',
            color: GameUiTheme.gold,
          ),
        if (city.specialization != null)
          SelectionInfoItem(
            icon: GameIcons.flag,
            label: l10n.citySelectionSpecializationLabel,
            value:
                specializationName?.call(city.specialization!) ??
                _specializationName(city.specialization!, l10n),
            color: GameUiTheme.gold,
          ),
      ],
      descriptionItems: objectiveDescriptionItems,
      cityBuildings: [for (final item in cityBuildingItems) item.label],
      cityBuildingItems: cityBuildingItems,
      cityYieldBreakdown: yieldBreakdown,
      tags: const [],
    );
  }

  static SelectionInfoItem? _cohesionItem({
    required GameCity city,
    required List<GameCity> cities,
    required AppLocalizations l10n,
  }) {
    final ownedCities = [
      for (final candidate in cities)
        if (candidate.ownerPlayerId == city.ownerPlayerId) candidate,
    ]..sort((a, b) => a.id.compareTo(b.id));
    if (ownedCities.isEmpty) return null;
    final coreCity = ownedCities.firstWhere(
      (candidate) => candidate.capitalOwnerPlayerId == city.ownerPlayerId,
      orElse: () => ownedCities.first,
    );
    if (city.id == coreCity.id) {
      return SelectionInfoItem(
        icon: GameIcons.defense,
        label: l10n.citySelectionCohesionLabel,
        value: l10n.citySelectionCohesionCore,
        color: GameUiTheme.success,
      );
    }

    final distance = HexDistance.between(
      city.center.toCoordinate(),
      coreCity.center.toCoordinate(),
    );
    final cohesionCost = CohesionCalculator.cityCohesionCost(
      cityCenter: city.center.toCoordinate(),
      nearestCoreCenter: coreCity.center.toCoordinate(),
      isConnected: CityTerritoryRules.isConnected(
        center: city.center,
        controlledHexes: city.controlledHexes,
      ),
      ruleset: StabilityRuleset.standard,
    );
    return SelectionInfoItem(
      icon: GameIcons.defense,
      label: l10n.citySelectionCohesionLabel,
      value: cohesionCost == 0
          ? l10n.citySelectionCohesionIntegrated(distance)
          : l10n.citySelectionCohesionFrontier(distance, cohesionCost),
      color: cohesionCost == 0 ? GameUiTheme.success : GameUiTheme.warning,
    );
  }

  static WorldArtifact? _storedArtifactForCity(
    GameCity city,
    List<WorldArtifact> artifacts,
  ) {
    for (final artifact in artifacts) {
      final location = artifact.location;
      if (location.isStored && location.cityId == city.id) {
        return artifact;
      }
    }
    return null;
  }

  static String _subtitleFor(
    GameCity city, {
    required int population,
    required int territoryHexCount,
    required int maxHexes,
    required String Function(CityBuildingType type)? buildingName,
    required AppLocalizations l10n,
  }) {
    final production = _productionLabelFor(
      city,
      buildingName: buildingName,
      l10n: l10n,
    );
    return l10n.citySelectionSubtitle(
      population,
      territoryHexCount,
      maxHexes,
      production,
    );
  }

  static String _productionLabelFor(
    GameCity city, {
    required String Function(CityBuildingType type)? buildingName,
    required AppLocalizations l10n,
  }) {
    final target = city.productionQueue?.target;
    if (target == null) {
      return l10n.productionNoProduction;
    }
    return switch (target) {
      BuildingProductionTarget(:final buildingType) =>
        buildingName?.call(buildingType) ??
            GameDisplayNames.cityBuilding(l10n, buildingType),
      UnitProductionTarget(:final unitType) => GameDisplayNames.unitType(
        l10n,
        unitType,
      ),
      ProjectProductionTarget(:final projectType) =>
        GameDisplayNames.cityProject(l10n, projectType),
    };
  }

  static String _specializationName(
    CitySpecializationType type,
    AppLocalizations l10n,
  ) {
    return switch (type) {
      CitySpecializationType.growth => l10n.citySpecializationGrowth,
      CitySpecializationType.industry => l10n.citySpecializationIndustry,
      CitySpecializationType.commerce => l10n.citySpecializationCommerce,
      CitySpecializationType.science => l10n.commonScience,
      CitySpecializationType.military => l10n.citySpecializationMilitary,
    };
  }

  static int _cityVisualLevelFor(GameCity city) {
    if (city.population >= 10) return 3;
    if (city.population >= 6) return 2;
    if (city.population >= 4) return 1;
    return 0;
  }

  static int _cityTechnologyProfileIndexFor(
    GameCity city, {
    required ResearchState research,
    required TechnologyRuleset technologyRuleset,
  }) {
    final scores = List<int>.filled(4, 0);
    final playerResearch = research.forPlayer(city.ownerPlayerId);
    for (final technologyId in playerResearch.unlockedTechnologyIds) {
      final profileIndex = _technologyProfileIndexFor(technologyId);
      final technology = technologyRuleset.technologies[technologyId];
      final weight = 1 + (technology?.treePosition.column ?? 0);
      scores[profileIndex] += weight;
    }

    var bestIndex = 0;
    var bestScore = 0;
    for (var i = 0; i < scores.length; i++) {
      final score = scores[i];
      if (score <= bestScore) continue;
      bestIndex = i;
      bestScore = score;
    }
    return bestIndex;
  }

  static int _technologyProfileIndexFor(TechnologyId id) {
    return switch (id) {
      TechnologyId.agriculture ||
      TechnologyId.animalHusbandry ||
      TechnologyId.storage ||
      TechnologyId.waterEngineering ||
      TechnologyId.irrigation ||
      TechnologyId.construction ||
      TechnologyId.medicine ||
      TechnologyId.administration ||
      TechnologyId.civilService ||
      TechnologyId.law ||
      TechnologyId.urbanPlanning ||
      TechnologyId.bureaucracy ||
      TechnologyId.specialization ||
      TechnologyId.urbanization => 0,
      TechnologyId.trade ||
      TechnologyId.writing ||
      TechnologyId.advancedTrade ||
      TechnologyId.banking ||
      TechnologyId.economy ||
      TechnologyId.education ||
      TechnologyId.mathematics ||
      TechnologyId.scientificMethod ||
      TechnologyId.fishing ||
      TechnologyId.navigation ||
      TechnologyId.shipbuilding ||
      TechnologyId.cartography ||
      TechnologyId.navalDoctrine => 1,
      TechnologyId.hunting ||
      TechnologyId.militaryOrganization ||
      TechnologyId.horsebackRiding ||
      TechnologyId.logistics ||
      TechnologyId.tactics ||
      TechnologyId.fortifications ||
      TechnologyId.siegecraft ||
      TechnologyId.strategy ||
      TechnologyId.nationalism => 2,
      TechnologyId.mining ||
      TechnologyId.woodworking ||
      TechnologyId.craftsmanship ||
      TechnologyId.stoneworking ||
      TechnologyId.metallurgy ||
      TechnologyId.engineering ||
      TechnologyId.guilds ||
      TechnologyId.ironWorking ||
      TechnologyId.coalMining ||
      TechnologyId.machinery ||
      TechnologyId.steel ||
      TechnologyId.steamPower ||
      TechnologyId.electricity ||
      TechnologyId.combustion ||
      TechnologyId.flight ||
      TechnologyId.massProduction ||
      TechnologyId.radio ||
      TechnologyId.nuclearPhysics => 3,
    };
  }
}
