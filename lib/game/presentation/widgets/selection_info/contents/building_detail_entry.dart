import 'package:aonw/game/presentation/widgets/city/city_building_sorting.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:flutter/material.dart';

class BuildingDetailEntry {
  BuildingDetailEntry({
    required this.item,
    required this.definition,
    required this.l10n,
  });

  final SelectionCityBuildingItem item;
  final CityBuildingDefinition? definition;
  final AppLocalizations l10n;

  late final CityProductionSortMetrics sortMetrics = _sortMetricsFor(
    definition,
  );
  late final int productionCost = definition?.productionCost ?? 0;
  late final List<BuildingEffectChip> effectChips = _effectChipsFor(
    definition,
    sortMetrics,
    l10n,
  );
}

class BuildingEffectChip {
  const BuildingEffectChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final GameIconData icon;
  final String label;
  final Color color;
}

List<BuildingDetailEntry> sortBuildingDetailEntries(
  List<BuildingDetailEntry> entries,
  CityBuildingSortMode mode,
) {
  if (!entries.any((entry) => entry.item.type != null)) return entries;
  return CityBuildingSorter.sort(
    entries,
    mode,
    (entry) => CityBuildingSortProfile(
      title: entry.item.label,
      productionCost: entry.productionCost,
      investedProduction: 0,
      productionPerTurn: 1,
      turnsRemaining: entry.productionCost > 0 ? entry.productionCost : 1,
      metrics: entry.sortMetrics,
    ),
  );
}

CityProductionSortMetrics _sortMetricsFor(CityBuildingDefinition? definition) {
  if (definition == null) return CityProductionSortMetrics.zero;
  var food = 0;
  var production = 0;
  var gold = 0;
  var defense = 0;
  var science = 0;
  var maxControlledHexes = 0;
  var foodDepositBonusPercent = 0;
  for (final effect in definition.effects) {
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
        final applications = maxApplications ?? 1;
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

List<BuildingEffectChip> _effectChipsFor(
  CityBuildingDefinition? definition,
  CityProductionSortMetrics metrics,
  AppLocalizations l10n,
) {
  if (definition == null) return const [];
  final chips = [
    ..._yieldEffectChips(metrics, l10n),
    ..._capacityEffectChips(metrics, l10n),
  ];
  if (chips.isNotEmpty) return chips;
  return [
    BuildingEffectChip(
      icon: GameIcons.info,
      label: l10n.technologyDetailsNoEffects,
      color: GameUiTheme.textMuted,
    ),
  ];
}

List<BuildingEffectChip> _yieldEffectChips(
  CityProductionSortMetrics metrics,
  AppLocalizations l10n,
) {
  return [
    if (metrics.food != 0)
      BuildingEffectChip(
        icon: GameIcons.food,
        label: '${_signedValue(metrics.food)} ${l10n.yieldFoodShort}',
        color: GameUiTheme.success,
      ),
    if (metrics.production != 0)
      BuildingEffectChip(
        icon: GameIcons.production,
        label:
            '${_signedValue(metrics.production)} ${l10n.yieldProductionShort}',
        color: GameUiTheme.gold,
      ),
    if (metrics.gold != 0)
      BuildingEffectChip(
        icon: GameIcons.gold,
        label: '${_signedValue(metrics.gold)} ${l10n.yieldGoldShort}',
        color: GameUiTheme.resourcesAccent,
      ),
    if (metrics.science != 0)
      BuildingEffectChip(
        icon: GameIcons.science,
        label: l10n.buildingDetailsYieldScience(_signedValue(metrics.science)),
        color: GameUiTheme.scienceAccent,
      ),
    if (metrics.defense != 0)
      BuildingEffectChip(
        icon: GameIcons.defense,
        label: '${_signedValue(metrics.defense)} ${l10n.yieldDefenseShort}',
        color: GameUiTheme.info,
      ),
  ];
}

List<BuildingEffectChip> _capacityEffectChips(
  CityProductionSortMetrics metrics,
  AppLocalizations l10n,
) {
  return [
    if (metrics.maxControlledHexes != 0)
      BuildingEffectChip(
        icon: GameIcons.workedHexes,
        label: l10n.buildingDetailsMaxControlledHexesEffect(
          metrics.maxControlledHexes,
        ),
        color: GameUiTheme.accent,
      ),
    if (metrics.foodDepositBonusPercent != 0)
      BuildingEffectChip(
        icon: GameIcons.growth,
        label: l10n.buildingDetailsFoodDepositMultiplierEffect(
          metrics.foodDepositBonusPercent,
        ),
        color: GameUiTheme.success,
      ),
  ];
}

String _signedValue(int value) {
  final sign = value > 0 ? '+' : '';
  return '$sign$value';
}
