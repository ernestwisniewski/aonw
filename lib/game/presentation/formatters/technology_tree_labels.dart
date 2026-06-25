import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';

class TechnologyTreeLabels {
  const TechnologyTreeLabels._();

  static String buttonLabel(AppLocalizations l10n, TechnologyCardState state) =>
      switch (state) {
        TechnologyCardState.researched => l10n.technologyButtonResearched,
        TechnologyCardState.active => l10n.technologyButtonActive,
        TechnologyCardState.available => l10n.technologyButtonResearch,
        TechnologyCardState.locked => l10n.technologyButtonLocked,
      };

  static String stateLabel(
    AppLocalizations l10n,
    TechnologyCardViewModel card,
  ) {
    return switch (card.state) {
      TechnologyCardState.researched => l10n.technologyStateCompleted,
      TechnologyCardState.active =>
        !card.eta.hasTurns
            ? l10n.technologyStateInProgress
            : card.eta.detailLabel(l10n),
      TechnologyCardState.available =>
        !card.eta.hasTurns
            ? l10n.technologyStateAvailable
            : card.eta.detailLabel(l10n),
      TechnologyCardState.locked => lockedReasonLabel(l10n, card),
    };
  }

  static String unlocksLabel(
    AppLocalizations l10n,
    TechnologyCardViewModel card,
  ) {
    if (card.unlocks.isEmpty) return l10n.technologyUnlockEffect;
    return card.unlocks
        .map((unlock) => GameDisplayNames.technologyUnlock(l10n, unlock))
        .join(', ');
  }

  static String prerequisitesLabel(
    AppLocalizations l10n,
    TechnologyCardViewModel card,
  ) {
    if (card.prerequisiteIds.isEmpty) return l10n.technologyPrerequisitesNone;
    return card.prerequisiteIds
        .map((id) => GameDisplayNames.technology(l10n, id))
        .join(', ');
  }

  static String blockedByLabel(
    AppLocalizations l10n,
    TechnologyCardViewModel card,
  ) {
    if (card.blockedByTechnologyIds.isEmpty) return '';
    return card.blockedByTechnologyIds
        .map((id) => GameDisplayNames.technology(l10n, id))
        .join(', ');
  }

  static String lockedReasonLabel(
    AppLocalizations l10n,
    TechnologyCardViewModel card,
  ) {
    final blockedBy = blockedByLabel(l10n, card);
    if (blockedBy.isNotEmpty) return l10n.technologyBlockedBy(blockedBy);
    return l10n.requirementTechnologyName(prerequisitesLabel(l10n, card));
  }

  static List<String> requirementLines(
    AppLocalizations l10n,
    TechnologyCardViewModel card,
  ) {
    final lines = <String>[prerequisitesLabel(l10n, card)];
    final blockedBy = blockedByLabel(l10n, card);
    if (blockedBy.isNotEmpty) lines.add(l10n.technologyBlockedBy(blockedBy));
    return lines;
  }

  static String detailsCostLabel(TechnologyCardViewModel card) {
    final baseCost = card.baseCost > 0 ? card.baseCost : card.totalCost;
    return baseCost == card.totalCost
        ? '${card.totalCost}'
        : '${card.totalCost} / bazowo $baseCost';
  }

  static String detailsProgressLabel(
    AppLocalizations l10n,
    TechnologyCardViewModel card,
  ) {
    final turns = card.eta.hasTurns ? ' • ${card.eta.detailLabel(l10n)}' : '';
    return '${card.progress}/${card.totalCost}$turns';
  }

  static List<String> effectLines(
    AppLocalizations l10n,
    TechnologyCardViewModel card,
  ) {
    if (card.effects.isEmpty) return [l10n.technologyDetailsNoEffects];
    return [for (final effect in card.effects) _effectLabel(l10n, effect)];
  }

  static List<String> boostLines(
    AppLocalizations l10n,
    TechnologyCardViewModel card,
  ) {
    if (card.boosts.isEmpty) return [l10n.technologyDetailsNoBoosts];
    return [
      if (card.boostActive) l10n.technologyBoostActiveBest,
      for (final boost in card.boosts)
        l10n.technologyBoostLine(
          _boostConditionLabel(l10n, boost.condition),
          _percent(boost.discount),
        ),
    ];
  }

  static String unlockCategoryLabel(
    AppLocalizations l10n,
    TechnologyUnlock unlock,
  ) {
    return switch (unlock) {
      UnlockCityBuilding() => GameText.uppercase(
        l10n.productionCategoryBuilding,
      ),
      UnlockUnitType() => GameText.uppercase(l10n.productionCategoryUnit),
      UnlockFieldImprovement() => GameText.uppercase(
        l10n.technologyUnlockFieldImprovementCategory,
      ),
    };
  }

  static String _effectLabel(AppLocalizations l10n, TechnologyEffect effect) {
    return switch (effect) {
      StrategicResourceProductionBonus(
        :final resourceType,
        :final production,
      ) =>
        l10n.technologyEffectStrategicResourceProductionBonus(
          production,
          _resourceName(l10n, resourceType),
        ),
      GlobalGoldMultiplier(:final multiplier) =>
        l10n.technologyEffectGlobalGoldMultiplier(_percent(multiplier)),
      CityDefenseBonus(:final amount) => l10n.technologyEffectCityDefenseBonus(
        amount,
      ),
      ArmyProductionMultiplier(:final multiplier) =>
        l10n.technologyEffectArmyProductionMultiplier(_percent(multiplier)),
      ArmyStrengthMultiplier(:final multiplier) =>
        l10n.technologyEffectArmyStrengthMultiplier(_percent(multiplier)),
      ArmyCombatStatsBonus(:final attack, :final defense, :final hp) =>
        _armyCombatStatsBonusLabel(
          l10n,
          attack: attack,
          defense: defense,
          hp: hp,
        ),
      MaxCityPopulationBonus(:final amount) =>
        l10n.technologyEffectMaxCityPopulationBonus(amount),
      MaxControlledHexesBonus(:final amount) =>
        l10n.technologyEffectMaxControlledHexesBonus(amount),
      CityScienceBonus(:final amount) => l10n.technologyEffectCityScienceBonus(
        amount,
      ),
    };
  }

  static String _boostConditionLabel(
    AppLocalizations l10n,
    TechnologyBoostCondition condition,
  ) {
    return switch (condition) {
      HasImprovementCount(:final improvementType, :final count) =>
        l10n.technologyBoostConditionImprovementCount(
          count,
          GameDisplayNames.fieldImprovement(l10n, improvementType),
        ),
      HasAnyImprovement(:final improvementType) =>
        l10n.technologyBoostConditionHasImprovement(
          GameDisplayNames.fieldImprovement(l10n, improvementType),
        ),
      ControlsResource(:final resourceType) =>
        l10n.technologyBoostConditionControlsResource(
          _resourceName(l10n, resourceType),
        ),
      ControlsAnyResource(:final resourceTypes) =>
        l10n.technologyBoostConditionControlsAnyResource(
          _joinResourceNames(l10n, resourceTypes),
        ),
    };
  }

  static String _joinResourceNames(
    AppLocalizations l10n,
    Set<ResourceType> resources,
  ) {
    final names =
        resources.map((resource) => _resourceName(l10n, resource)).toList()
          ..sort();
    if (names.length <= 1) return names.join();
    return l10n.commonListOr(
      names.take(names.length - 1).join(', '),
      names.last,
    );
  }

  static String _percent(double value) => '${(value * 100).round()}%';

  static String _armyCombatStatsBonusLabel(
    AppLocalizations l10n, {
    required int attack,
    required int defense,
    required int hp,
  }) {
    final parts = <String>[
      if (attack != 0) l10n.technologyEffectAttackBonus(_signed(attack)),
      if (defense != 0) l10n.technologyEffectDefenseBonus(_signed(defense)),
      if (hp != 0) '${_signed(hp)} HP',
    ];
    if (parts.isEmpty) return l10n.technologyEffectNoArmyStatsBonus;
    return l10n.technologyEffectArmyStatsBonus(parts.join(', '));
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';

  static String _resourceName(AppLocalizations l10n, ResourceType resource) {
    return GameDisplayNames.resource(l10n, resource);
  }
}
