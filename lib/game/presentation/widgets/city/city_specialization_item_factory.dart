import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

abstract final class CitySpecializationItemFactory {
  static CitySpecializationItem from(
    GameCity city,
    CitySpecializationType type,
    AppLocalizations l10n, {
    CitySpecializationType? bestFit,
  }) {
    final active = city.specialization == type;
    final requiredBuilding = CitySpecializationRules.requiredBuildingFor(type);
    final hasRequiredBuilding = CitySpecializationRules.hasRequiredBuilding(
      city.buildings,
      type,
    );
    final isBestFit = bestFit == type;
    return CitySpecializationItem(
      type: type,
      title: title(type, l10n),
      icon: icon(type),
      active: active,
      locked: !active && !hasRequiredBuilding,
      bestFit: isBestFit,
      metaLabels: [
        if (isBestFit) l10n.citySpecializationBestFit,
        ...labels(type, l10n),
        if (!active && !hasRequiredBuilding)
          l10n.requirementResourcesName(
            GameDisplayNames.cityBuilding(l10n, requiredBuilding),
          ),
      ],
    );
  }

  static String title(CitySpecializationType type, AppLocalizations l10n) {
    return switch (type) {
      CitySpecializationType.growth => l10n.citySpecializationGrowth,
      CitySpecializationType.industry => l10n.citySpecializationIndustry,
      CitySpecializationType.commerce => l10n.citySpecializationCommerce,
      CitySpecializationType.science => l10n.commonScience,
      CitySpecializationType.military => l10n.citySpecializationMilitary,
    };
  }

  static GameIconData icon(CitySpecializationType type) {
    return switch (type) {
      CitySpecializationType.growth => GameIcons.food,
      CitySpecializationType.industry => GameIcons.production,
      CitySpecializationType.commerce => GameIcons.gold,
      CitySpecializationType.science => GameIcons.science,
      CitySpecializationType.military => GameIcons.defense,
    };
  }

  static List<String> labels(
    CitySpecializationType type,
    AppLocalizations l10n,
  ) {
    return switch (type) {
      CitySpecializationType.growth => [l10n.citySpecializationGrowthBonus],
      CitySpecializationType.industry => [l10n.citySpecializationIndustryBonus],
      CitySpecializationType.commerce => [l10n.citySpecializationCommerceBonus],
      CitySpecializationType.science => [l10n.citySpecializationScienceBonus],
      CitySpecializationType.military => [
        l10n.citySpecializationMilitaryProductionBonus,
        l10n.citySpecializationMilitaryDefenseBonus,
        l10n.citySpecializationMilitaryUnitProductionBonus,
      ],
    };
  }
}
