import 'dart:async';

import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_sorting.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

class BuildingsDetailContent extends StatefulWidget {
  final SelectionBuildingsDetail model;
  final bool compact;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;

  const BuildingsDetailContent({
    required this.model,
    this.compact = false,
    this.cityRuleset = CityRulesets.standard,
    this.technologyRuleset = TechnologyRulesets.standard,
    super.key,
  });

  @override
  State<BuildingsDetailContent> createState() => _BuildingsDetailContentState();
}

class _BuildingsDetailContentState extends State<BuildingsDetailContent> {
  CityBuildingSortMode _sortMode = CityBuildingSortMode.recommended;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = _entriesFor(l10n);
    if (entries.isEmpty) {
      return Text(
        l10n.cityYieldBreakdownNoBuildings,
        style: const TextStyle(
          color: GameUiTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final sortedEntries = _sortEntries(entries, _sortMode);
    final canSort = entries.any((entry) => entry.item.type != null);

    return Column(
      key: const Key('selectionBuildingsDetail.list'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BuildingSectionHeader(
          label: l10n.buildingsSection,
          value: _sortMode,
          compact: widget.compact,
          onChanged: canSort ? _setSortMode : null,
        ),
        for (final entry in sortedEntries)
          _BuildingListTile(
            entry: entry,
            compact: widget.compact,
            onDetails: entry.item.type == null
                ? null
                : () => _showBuildingDetails(context, entry.item.type!),
          ),
      ],
    );
  }

  List<_BuildingListEntry> _entriesFor(AppLocalizations l10n) {
    return [
      for (final item in widget.model.displayItems)
        _BuildingListEntry(
          item: item,
          definition: item.type == null
              ? null
              : widget.cityRuleset.buildingDefinitionFor(item.type!),
          l10n: l10n,
        ),
    ];
  }

  void _setSortMode(CityBuildingSortMode mode) {
    setState(() => _sortMode = mode);
  }

  void _showBuildingDetails(BuildContext context, CityBuildingType type) {
    final l10n = AppLocalizations.of(context);
    final definition = widget.cityRuleset.buildingDefinitionFor(type);

    unawaited(
      showGameModal<void>(
        context: context,
        builder: (dialogContext) => CityBuildingDetailsDialog(
          buildingType: type,
          definition: definition,
          unlockingTechnology:
              TechnologyUnlockQuery.unlockingTechnologyForBuilding(
                buildingType: type,
                ruleset: widget.technologyRuleset,
              ),
          l10n: l10n,
          title: GameDisplayNames.cityBuilding(l10n, type),
          emoji: CityBuildingsPanelViewModelFactory.emojiFor(type),
          statusLabel: l10n.cityProductionBuiltLabel,
          costLabel: l10n.cityProductionCostShort(definition.productionCost),
          yieldImpactMode: CityBuildingYieldImpactMode.active,
          onClose: () => Navigator.of(dialogContext).maybePop(),
        ),
      ),
    );
  }
}

class _BuildingListTile extends StatelessWidget {
  final _BuildingListEntry entry;
  final bool compact;
  final VoidCallback? onDetails;

  const _BuildingListTile({
    required this.entry,
    required this.compact,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = entry.item;
    final onDetails = this.onDetails;
    final radius = BorderRadius.circular(7);

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onDetails,
          child: Container(
            padding: EdgeInsets.all(compact ? 8 : 10),
            decoration: SurfaceElevation.flat.decoration(
              background: GameUiTheme.bg,
              backgroundAlpha: 150,
              borderRadius: radius,
              border: BorderEmphasis.regular,
              includeShadow: false,
            ),
            child: Row(
              children: [
                _BuildingLeading(item: item, compact: compact),
                SizedBox(width: compact ? 9 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameUiTheme.body.copyWith(
                          color: GameUiTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: compact ? 5 : 7),
                      Wrap(
                        spacing: compact ? 6 : 8,
                        runSpacing: 5,
                        children: [
                          _BuildingMetaPill(
                            label: l10n.cityProductionBuiltLabel,
                            compact: compact,
                            highlighted: true,
                          ),
                          if (entry.productionCost > 0)
                            _BuildingMetaPill(
                              label: l10n.cityProductionCostShort(
                                entry.productionCost,
                              ),
                              compact: compact,
                            ),
                          for (final chip in entry.effectChips)
                            _BuildingEffectPill(chip: chip, compact: compact),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDetails != null) ...[
                  SizedBox(width: compact ? 8 : 10),
                  _BuildingDetailsButton(
                    label: l10n.buildingDetailsTooltip,
                    compact: compact,
                    onPressed: onDetails,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildingDetailsButton extends StatelessWidget {
  final String label;
  final bool compact;
  final VoidCallback onPressed;

  const _BuildingDetailsButton({
    required this.label,
    required this.compact,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 16,
        child: Container(
          width: compact ? 30 : 34,
          height: compact ? 30 : 34,
          decoration: SurfaceElevation.flat.decoration(
            background: Colors.white,
            backgroundAlpha: 14,
            border: BorderEmphasis.regular,
            borderRadius: BorderRadius.circular(5),
            includeShadow: false,
          ),
          child: const Center(
            child: GameIcon(
              GameIcons.help,
              size: GameIconSize.small,
              color: GameUiTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildingLeading extends StatelessWidget {
  final SelectionCityBuildingItem item;
  final bool compact;

  const _BuildingLeading({required this.item, required this.compact});

  @override
  Widget build(BuildContext context) {
    final type = item.type;
    return Container(
      width: compact ? 42 : 52,
      height: compact ? 42 : 52,
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 255,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Center(
        child: type == null
            ? const GameIcon(
                GameIcons.city,
                size: GameIconSize.regular,
                color: GameUiTheme.goldLight,
              )
            : BuildingSpriteIcon(
                type: type,
                size: compact ? 38 : 46,
                fallback: const GameIcon(
                  GameIcons.city,
                  size: GameIconSize.regular,
                  color: GameUiTheme.goldLight,
                ),
              ),
      ),
    );
  }
}

class _BuildingMetaPill extends StatelessWidget {
  final String label;
  final bool compact;
  final bool highlighted;

  const _BuildingMetaPill({
    required this.label,
    required this.compact,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: SurfaceElevation.flat.decoration(
        background: highlighted ? GameUiTheme.gold : Colors.white,
        backgroundAlpha: highlighted ? 28 : 10,
        borderColor: highlighted ? GameUiTheme.gold : Colors.white,
        borderAlpha: highlighted ? 100 : 28,
        borderRadius: BorderRadius.circular(4),
        includeShadow: false,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GameUiTheme.bodySmall.copyWith(
          color: highlighted ? GameUiTheme.goldLight : GameUiTheme.textMuted,
          fontSize: compact ? 10 : null,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BuildingEffectPill extends StatelessWidget {
  final _BuildingEffectChip chip;
  final bool compact;

  const _BuildingEffectPill({required this.chip, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: SurfaceElevation.flat.decoration(
        background: chip.color,
        backgroundAlpha: 20,
        borderColor: chip.color,
        borderAlpha: 78,
        borderRadius: BorderRadius.circular(4),
        includeShadow: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(chip.icon, size: GameIconSize.small, color: chip.color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 150 : 220),
            child: Text(
              chip.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontSize: compact ? 10 : null,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingListEntry {
  final SelectionCityBuildingItem item;
  final CityBuildingDefinition? definition;
  late final CityProductionSortMetrics sortMetrics = _sortMetricsFor(
    definition,
  );
  late final int productionCost = definition?.productionCost ?? 0;
  late final List<_BuildingEffectChip> effectChips = _effectChipsFor(
    definition,
    sortMetrics,
    l10n,
  );
  final AppLocalizations l10n;

  _BuildingListEntry({
    required this.item,
    required this.definition,
    required this.l10n,
  });
}

class _BuildingEffectChip {
  final GameIconData icon;
  final String label;
  final Color color;

  const _BuildingEffectChip({
    required this.icon,
    required this.label,
    required this.color,
  });
}

List<_BuildingListEntry> _sortEntries(
  List<_BuildingListEntry> entries,
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

List<_BuildingEffectChip> _effectChipsFor(
  CityBuildingDefinition? definition,
  CityProductionSortMetrics metrics,
  AppLocalizations l10n,
) {
  if (definition == null) return const [];
  final chips = <_BuildingEffectChip>[
    if (metrics.food != 0)
      _BuildingEffectChip(
        icon: GameIcons.food,
        label: '${_signedValue(metrics.food)} ${l10n.yieldFoodShort}',
        color: GameUiTheme.success,
      ),
    if (metrics.production != 0)
      _BuildingEffectChip(
        icon: GameIcons.production,
        label:
            '${_signedValue(metrics.production)} ${l10n.yieldProductionShort}',
        color: GameUiTheme.gold,
      ),
    if (metrics.gold != 0)
      _BuildingEffectChip(
        icon: GameIcons.gold,
        label: '${_signedValue(metrics.gold)} ${l10n.yieldGoldShort}',
        color: GameUiTheme.resourcesAccent,
      ),
    if (metrics.science != 0)
      _BuildingEffectChip(
        icon: GameIcons.science,
        label: l10n.buildingDetailsYieldScience(_signedValue(metrics.science)),
        color: GameUiTheme.scienceAccent,
      ),
    if (metrics.defense != 0)
      _BuildingEffectChip(
        icon: GameIcons.defense,
        label: '${_signedValue(metrics.defense)} ${l10n.yieldDefenseShort}',
        color: GameUiTheme.info,
      ),
    if (metrics.maxControlledHexes != 0)
      _BuildingEffectChip(
        icon: GameIcons.workedHexes,
        label: l10n.buildingDetailsMaxControlledHexesEffect(
          metrics.maxControlledHexes,
        ),
        color: GameUiTheme.accent,
      ),
    if (metrics.foodDepositBonusPercent != 0)
      _BuildingEffectChip(
        icon: GameIcons.growth,
        label: l10n.buildingDetailsFoodDepositMultiplierEffect(
          metrics.foodDepositBonusPercent,
        ),
        color: GameUiTheme.success,
      ),
  ];
  if (chips.isEmpty) {
    return [
      _BuildingEffectChip(
        icon: GameIcons.info,
        label: l10n.technologyDetailsNoEffects,
        color: GameUiTheme.textMuted,
      ),
    ];
  }
  return chips;
}

String _signedValue(int value) {
  final sign = value > 0 ? '+' : '';
  return '$sign$value';
}
