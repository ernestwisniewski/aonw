part of 'wonder_details_dialog.dart';

List<String> _wonderRequirementLines(
  AppLocalizations l10n,
  WonderDefinition definition,
  TechnologyDefinition? unlockingTechnology,
) {
  final lines = <String>[
    if (unlockingTechnology != null)
      l10n.buildingDetailsRequirementTechnology(
        GameDisplayNames.technology(l10n, unlockingTechnology.id),
      ),
    for (final requirement in definition.requirements)
      switch (requirement) {
        WonderCoastalAccessRequirement() =>
          l10n.buildingDetailsRequirementCoastalAccess,
        WonderResourceRequirement(:final resources) =>
          l10n.buildingDetailsRequirementResources(
            _joinResourceNames(l10n, resources),
          ),
        WonderAdjacentRiverRequirement() =>
          l10n.wonderDetailsRequirementAdjacentRiver,
        WonderAdjacentMountainRequirement() =>
          l10n.wonderDetailsRequirementAdjacentMountain,
        WonderHostTerrainRequirement(:final allowedTerrains) =>
          l10n.wonderDetailsRequirementTerrain(
            _joinTerrainNames(l10n, allowedTerrains),
          ),
      },
  ];
  return lines.isEmpty ? [l10n.buildingDetailsNoRequirements] : lines;
}

List<String> _wonderStandingEffectLines(
  AppLocalizations l10n,
  WonderDefinition definition,
) {
  if (definition.standingEffects.isEmpty) {
    return [l10n.wonderDetailsNoStandingEffects];
  }
  return [
    for (final effect in definition.standingEffects)
      _wonderStandingEffectLabel(l10n, effect),
  ];
}

List<String> _wonderCompletionEffectLines(
  AppLocalizations l10n,
  WonderDefinition definition,
) {
  if (definition.completionEffects.isEmpty) {
    return [l10n.wonderDetailsNoCompletionEffects];
  }
  return [
    for (final effect in definition.completionEffects)
      _wonderCompletionEffectLabel(l10n, effect),
  ];
}

String _wonderStandingEffectLabel(
  AppLocalizations l10n,
  WonderStandingEffect effect,
) {
  return switch (effect) {
    EmpireFlatYieldEffect(:final yieldPerCity) =>
      l10n.wonderDetailsEmpireFlatYieldEffect(_yieldLabel(l10n, yieldPerCity)),
    HostCityFlatYieldEffect(:final yield) =>
      l10n.wonderDetailsHostCityFlatYieldEffect(_yieldLabel(l10n, yield)),
    EmpireScienceEffect(:final perCity) =>
      l10n.wonderDetailsEmpireScienceEffect(_signedValue(perCity)),
    EmpireGoldMultiplierEffect(:final multiplier) =>
      l10n.wonderDetailsEmpireGoldMultiplierEffect(_percent(multiplier)),
    EmpireProductionMultiplierEffect(:final multiplier) =>
      l10n.wonderDetailsEmpireProductionMultiplierEffect(_percent(multiplier)),
    StabilityEffect(:final delta) => l10n.wonderDetailsStabilityEffect(
      _signedValue(delta),
    ),
  };
}

String _wonderCompletionEffectLabel(
  AppLocalizations l10n,
  WonderCompletionEffect effect,
) {
  return switch (effect) {
    GrantFreeTechnology() => l10n.wonderDetailsGrantFreeTechnology,
    ProductionBurst(:final amount) => l10n.wonderDetailsProductionBurst(amount),
    GrantGold(:final amount) => l10n.wonderDetailsGrantGold(amount),
  };
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

String _joinTerrainNames(AppLocalizations l10n, Set<TerrainType> terrains) {
  final names =
      terrains
          .map((terrain) => GameDisplayNames.terrain(l10n, terrain))
          .toList()
        ..sort();
  if (names.length <= 1) return names.join();
  return l10n.commonListOr(names.take(names.length - 1).join(', '), names.last);
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

String _percent(double multiplier) => '+${(multiplier * 100).round()}%';
