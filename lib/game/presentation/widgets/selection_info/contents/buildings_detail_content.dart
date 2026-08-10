import 'dart:async';

import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/building_detail_entry.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/building_detail_tile.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

class BuildingsDetailContent extends StatefulWidget {
  const BuildingsDetailContent({
    required this.model,
    this.compact = false,
    this.cityRuleset = CityRulesets.standard,
    this.technologyRuleset = TechnologyRulesets.standard,
    super.key,
  });

  final SelectionBuildingsDetail model;
  final bool compact;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;

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
    final sortedEntries = sortBuildingDetailEntries(entries, _sortMode);
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
          BuildingDetailTile(
            entry: entry,
            compact: widget.compact,
            onDetails: entry.item.type == null
                ? null
                : () => _showBuildingDetails(context, entry.item.type!),
          ),
      ],
    );
  }

  List<BuildingDetailEntry> _entriesFor(AppLocalizations l10n) {
    return [
      for (final item in widget.model.displayItems)
        BuildingDetailEntry(
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
