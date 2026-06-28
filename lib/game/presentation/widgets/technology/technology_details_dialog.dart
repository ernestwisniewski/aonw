import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/technology_tree_labels.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_details_header.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_details_sections.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_unlocks_section.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/game/presentation/widgets/unit/unit_details_panel.dart';
import 'package:aonw/game/presentation/widgets/visual/game_insight_widgets.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_content_scroll_view.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_layout.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class TechnologyDetailsDialog extends StatelessWidget {
  final TechnologyCardViewModel card;
  final AppLocalizations l10n;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final VoidCallback onClose;

  const TechnologyDetailsDialog({
    required this.card,
    required this.l10n,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return TechnologyDetailsPanel(
      card: card,
      l10n: l10n,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      maxHeight: GameModalLayout.detailsMaxHeight(size.height * 0.78),
      onClose: onClose,
    );
  }
}

class TechnologyDetailsPanel extends StatefulWidget {
  final TechnologyCardViewModel card;
  final AppLocalizations l10n;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final double maxWidth;
  final double? maxHeight;
  final VoidCallback onClose;

  const TechnologyDetailsPanel({
    required this.card,
    required this.l10n,
    required this.cityRuleset,
    required this.technologyRuleset,
    this.maxWidth = 560,
    this.maxHeight,
    required this.onClose,
    super.key,
  });

  @override
  State<TechnologyDetailsPanel> createState() => _TechnologyDetailsPanelState();
}

class _TechnologyDetailsPanelState extends State<TechnologyDetailsPanel> {
  CityBuildingType? _selectedBuildingType;
  GameUnitType? _selectedUnitType;

  @override
  void didUpdateWidget(covariant TechnologyDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _selectedBuildingType = null;
      _selectedUnitType = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedBuildingType = _selectedBuildingType;
    if (selectedBuildingType != null) {
      final definition = widget.cityRuleset.buildingDefinitionFor(
        selectedBuildingType,
      );
      return CityBuildingDetailsPanel(
        buildingType: selectedBuildingType,
        definition: definition,
        unlockingTechnology:
            TechnologyUnlockQuery.unlockingTechnologyForBuilding(
              buildingType: selectedBuildingType,
              ruleset: widget.technologyRuleset,
            ),
        l10n: widget.l10n,
        title: GameDisplayNames.cityBuilding(widget.l10n, selectedBuildingType),
        emoji: CityBuildingsPanelViewModelFactory.emojiFor(
          selectedBuildingType,
        ),
        statusLabel: widget.l10n.technologyDetailsUnlockStatus,
        costLabel: widget.l10n.cityProductionCostShort(
          definition.productionCost,
        ),
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
        onClose: () => setState(() => _selectedBuildingType = null),
      );
    }
    final selectedUnitType = _selectedUnitType;
    if (selectedUnitType != null) {
      final definition = _unitDefinitionFor(selectedUnitType);
      return UnitDetailsPanel(
        unitType: selectedUnitType,
        unlockingTechnology: TechnologyUnlockQuery.unlockingTechnologyForUnit(
          unitType: selectedUnitType,
          ruleset: widget.technologyRuleset,
        ),
        l10n: widget.l10n,
        title: GameDisplayNames.unitType(widget.l10n, selectedUnitType),
        icon: gameIconForUnitType(selectedUnitType),
        statusLabel: widget.l10n.technologyDetailsUnlockStatus,
        costLabel: definition == null
            ? null
            : widget.l10n.cityProductionCostShort(definition.productionCost),
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
        onClose: () => setState(() => _selectedUnitType = null),
      );
    }

    final name = GameDisplayNames.technology(widget.l10n, widget.card.id);
    final era = GameDisplayNames.technologyEra(widget.l10n, widget.card.era);
    final effectiveMaxHeight = GameModalLayout.detailsMaxHeight(
      widget.maxHeight,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: effectiveMaxHeight,
      ),
      child: GameModalScaffold(
        surfaceKey: const Key('technologyDetailsPanel.surface'),
        showCornerDiamonds: false,
        contentPadding: EdgeInsets.zero,
        centerInAvailableSpace: false,
        scrollable: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TechnologyDetailsHeader(
              technologyId: widget.card.id,
              title: name,
              subtitle: era,
              l10n: widget.l10n,
              onClose: widget.onClose,
            ),
            Flexible(
              child: GameModalContentScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  Text(
                    GameDisplayNames.technologyDescription(
                      widget.l10n,
                      widget.card.id,
                    ),
                    style: GameUiTheme.body.copyWith(
                      color: GameUiTheme.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GameInsightProgressCard(
                    title: widget.l10n.technologyDetailsProgress,
                    valueLabel: TechnologyTreeLabels.detailsProgressLabel(
                      widget.l10n,
                      widget.card,
                    ),
                    progress: widget.card.progressRatio,
                    icon: GameIcons.science,
                    accent: GameUiTheme.scienceAccent,
                    meta: [
                      TechnologyTreeLabels.stateLabel(widget.l10n, widget.card),
                      TechnologyTreeLabels.detailsCostLabel(widget.card),
                      widget.card.eta.compactLabel(widget.l10n),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TechnologyDetailsSection(
                    title: widget.l10n.technologyDetailsPrerequisites,
                    lines: TechnologyTreeLabels.requirementLines(
                      widget.l10n,
                      widget.card,
                    ),
                  ),
                  TechnologyUnlocksSection(
                    title: widget.l10n.technologyDetailsUnlocks,
                    unlocks: widget.card.unlocks,
                    l10n: widget.l10n,
                    onBuildingDetails: _openBuildingDetails,
                    onUnitDetails: _openUnitDetails,
                  ),
                  TechnologyDetailsSection(
                    title: widget.l10n.technologyDetailsEffects,
                    lines: TechnologyTreeLabels.effectLines(
                      widget.l10n,
                      widget.card,
                    ),
                  ),
                  TechnologyDetailsSection(
                    title: widget.l10n.technologyDetailsBoosts,
                    lines: TechnologyTreeLabels.boostLines(
                      widget.l10n,
                      widget.card,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBuildingDetails(CityBuildingType buildingType) {
    setState(() {
      _selectedBuildingType = buildingType;
      _selectedUnitType = null;
    });
  }

  void _openUnitDetails(GameUnitType unitType) {
    setState(() {
      _selectedBuildingType = null;
      _selectedUnitType = unitType;
    });
  }

  UnitProductionDefinition? _unitDefinitionFor(GameUnitType unitType) {
    try {
      return widget.cityRuleset.unitDefinitionFor(unitType);
    } on ArgumentError {
      return null;
    }
  }
}
