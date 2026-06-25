part of 'city_building_details_dialog.dart';

List<String> _buildingRequirementLines(
  AppLocalizations l10n,
  CityBuildingDefinition definition,
  TechnologyDefinition? unlockingTechnology,
) {
  final lines = <String>[
    if (unlockingTechnology != null)
      l10n.buildingDetailsRequirementTechnology(
        GameDisplayNames.technology(l10n, unlockingTechnology.id),
      ),
    for (final requirement in definition.requirements)
      switch (requirement) {
        CoastalAccessRequirement() =>
          l10n.buildingDetailsRequirementCoastalAccess,
        CityResourceRequirement(:final resources) =>
          l10n.buildingDetailsRequirementResources(
            _joinResourceNames(l10n, resources),
          ),
      },
  ];
  return lines.isEmpty ? [l10n.buildingDetailsNoRequirements] : lines;
}

String _joinResourceNames(AppLocalizations l10n, Set<ResourceType> resources) {
  final names =
      resources
          .map((resource) => GameDisplayNames.resource(l10n, resource))
          .toList()
        ..sort();
  if (names.length <= 1) return names.join();
  return l10n.commonListOr(names.take(names.length - 1).join(', '), names.last);
}

List<String> _buildingEffectLines(
  AppLocalizations l10n,
  CityBuildingDefinition definition,
) {
  if (definition.effects.isEmpty) return [l10n.technologyDetailsNoEffects];
  return [
    for (final effect in definition.effects) _buildingEffectLabel(l10n, effect),
  ];
}

List<GameYieldDeltaItem> _buildingYieldDeltaItems(
  AppLocalizations l10n,
  CityBuildingDefinition definition, {
  required TileYield baselineYield,
  required int baselineScience,
}) {
  var food = 0;
  var production = 0;
  var gold = 0;
  var defense = 0;
  var science = 0;
  for (final effect in definition.effects) {
    switch (effect) {
      case FlatCityYieldEffect(:final yield):
        food += yield.food;
        production += yield.production;
        gold += yield.gold;
        defense += yield.defense;
      case FlatCityScienceEffect(:final amount):
        science += amount;
      case RiverHexCityYieldEffect() ||
          MaxControlledHexesEffect() ||
          FoodDepositMultiplierEffect():
        break;
    }
  }

  return [
    GameYieldDeltaItem(
      icon: GameIcons.food,
      label: l10n.yieldFoodShort,
      before: baselineYield.food,
      after: baselineYield.food + food,
      color: GameUiTheme.success,
    ),
    GameYieldDeltaItem(
      icon: GameIcons.production,
      label: l10n.yieldProductionShort,
      before: baselineYield.production,
      after: baselineYield.production + production,
      color: GameUiTheme.gold,
    ),
    GameYieldDeltaItem(
      icon: GameIcons.gold,
      label: l10n.yieldGoldShort,
      before: baselineYield.gold,
      after: baselineYield.gold + gold,
      color: GameUiTheme.resourcesAccent,
    ),
    GameYieldDeltaItem(
      icon: GameIcons.science,
      label: l10n.commonScience,
      before: baselineScience,
      after: baselineScience + science,
      color: GameUiTheme.scienceAccent,
    ),
    GameYieldDeltaItem(
      icon: GameIcons.defense,
      label: l10n.yieldDefenseShort,
      before: baselineYield.defense,
      after: baselineYield.defense + defense,
      color: GameUiTheme.info,
    ),
  ].where((item) => item.delta != 0).toList(growable: false);
}

String _buildingEffectLabel(AppLocalizations l10n, CityBuildingEffect effect) {
  return switch (effect) {
    FlatCityYieldEffect(:final yield) => l10n.buildingDetailsFlatYieldEffect(
      _yieldLabel(l10n, yield),
    ),
    FlatCityScienceEffect(:final amount) => l10n.buildingDetailsYieldScience(
      _signedValue(amount),
    ),
    RiverHexCityYieldEffect(:final yieldPerRiverHex, :final maxApplications) =>
      maxApplications == null
          ? l10n.buildingDetailsRiverHexYieldEffect(
              _yieldLabel(l10n, yieldPerRiverHex),
            )
          : l10n.buildingDetailsRiverHexYieldEffectWithMax(
              _yieldLabel(l10n, yieldPerRiverHex),
              maxApplications,
            ),
    MaxControlledHexesEffect(:final amount) =>
      l10n.buildingDetailsMaxControlledHexesEffect(amount),
    FoodDepositMultiplierEffect(:final multiplier) =>
      l10n.buildingDetailsFoodDepositMultiplierEffect(
        ((multiplier - 1) * 100).round(),
      ),
  };
}

String _yieldLabel(AppLocalizations l10n, TileYield yield) {
  final parts = <String>[
    if (yield.food != 0)
      l10n.buildingDetailsYieldFood(_signedValue(yield.food)),
    if (yield.production != 0)
      l10n.buildingDetailsYieldProduction(_signedValue(yield.production)),
    if (yield.gold != 0)
      l10n.buildingDetailsYieldGold(_signedValue(yield.gold)),
    if (yield.defense != 0)
      l10n.buildingDetailsYieldDefense(_signedValue(yield.defense)),
  ];
  return parts.isEmpty ? l10n.buildingDetailsNoYieldChange : parts.join(', ');
}

String _signedValue(int value) {
  final sign = value > 0 ? '+' : '';
  return '$sign$value';
}
