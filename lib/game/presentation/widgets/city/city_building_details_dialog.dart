import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/visual/game_insight_widgets.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_content_scroll_view.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_layout.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';

part 'city_building_details_content.dart';
part 'city_building_details_widgets.dart';

enum CityBuildingYieldImpactMode { planned, active }

class CityBuildingDetailsDialog extends StatelessWidget {
  final CityBuildingType buildingType;
  final CityBuildingDefinition definition;
  final TechnologyDefinition? unlockingTechnology;
  final AppLocalizations l10n;
  final String title;
  final String? emoji;
  final String statusLabel;
  final String costLabel;
  final String? progressLabel;
  final String? paceLabel;
  final CityBuildingYieldImpactMode yieldImpactMode;
  final TileYield? currentCityYield;
  final int currentCityScience;
  final VoidCallback onClose;

  const CityBuildingDetailsDialog({
    required this.buildingType,
    required this.definition,
    required this.unlockingTechnology,
    required this.l10n,
    required this.title,
    required this.emoji,
    required this.statusLabel,
    required this.costLabel,
    this.progressLabel,
    this.paceLabel,
    this.yieldImpactMode = CityBuildingYieldImpactMode.planned,
    this.currentCityYield,
    this.currentCityScience = 0,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return CityBuildingDetailsPanel(
      buildingType: buildingType,
      definition: definition,
      unlockingTechnology: unlockingTechnology,
      l10n: l10n,
      title: title,
      emoji: emoji,
      statusLabel: statusLabel,
      costLabel: costLabel,
      progressLabel: progressLabel,
      paceLabel: paceLabel,
      yieldImpactMode: yieldImpactMode,
      currentCityYield: currentCityYield,
      currentCityScience: currentCityScience,
      maxHeight: GameModalLayout.detailsMaxHeight(size.height * 0.78),
      onClose: onClose,
    );
  }
}

class CityBuildingDetailsPanel extends StatelessWidget {
  final CityBuildingType buildingType;
  final CityBuildingDefinition definition;
  final TechnologyDefinition? unlockingTechnology;
  final AppLocalizations l10n;
  final String title;
  final String? emoji;
  final String statusLabel;
  final String costLabel;
  final String? progressLabel;
  final String? paceLabel;
  final CityBuildingYieldImpactMode yieldImpactMode;
  final TileYield? currentCityYield;
  final int currentCityScience;
  final double maxWidth;
  final double? maxHeight;
  final VoidCallback onClose;

  const CityBuildingDetailsPanel({
    required this.buildingType,
    required this.definition,
    required this.unlockingTechnology,
    required this.l10n,
    required this.title,
    required this.emoji,
    required this.statusLabel,
    required this.costLabel,
    this.progressLabel,
    this.paceLabel,
    this.yieldImpactMode = CityBuildingYieldImpactMode.planned,
    this.currentCityYield,
    this.currentCityScience = 0,
    this.maxWidth = 560,
    this.maxHeight,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final yieldImpactApplied =
        yieldImpactMode == CityBuildingYieldImpactMode.active;
    final yieldImpact = _buildingYieldDeltaItems(
      l10n,
      definition,
      baselineYield: yieldImpactApplied
          ? TileYield.zero
          : currentCityYield ?? TileYield.zero,
      baselineScience: yieldImpactApplied ? 0 : currentCityScience,
    );
    final effectiveMaxHeight = GameModalLayout.detailsMaxHeight(maxHeight);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: effectiveMaxHeight,
      ),
      child: GameModalScaffold(
        surfaceKey: const Key('cityBuildingDetailsPanel.surface'),
        showCornerDiamonds: false,
        contentPadding: EdgeInsets.zero,
        centerInAvailableSpace: false,
        scrollable: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BuildingDetailsHeader(
              buildingType: buildingType,
              title: title,
              emoji: emoji,
              l10n: l10n,
              onClose: onClose,
            ),
            Flexible(
              child: GameModalContentScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  Text(
                    GameDisplayNames.cityBuildingDescription(
                      l10n,
                      buildingType,
                    ),
                    style: GameUiTheme.body.copyWith(
                      color: GameUiTheme.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _BuildingDetailChip(
                        label: l10n.technologyDetailsStatus,
                        value: statusLabel,
                      ),
                      _BuildingDetailChip(
                        label: l10n.technologyDetailsCost,
                        value: costLabel,
                      ),
                      if (progressLabel != null)
                        _BuildingDetailChip(
                          label: l10n.technologyDetailsProgress,
                          value: progressLabel!,
                        ),
                      if (paceLabel != null)
                        _BuildingDetailChip(
                          label: l10n.unitDetailsPace,
                          value: paceLabel!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (yieldImpact.isNotEmpty) ...[
                    if (yieldImpactApplied)
                      GameStatBarGroup(
                        title: l10n.buildingDetailsYieldImpact,
                        accent: GameUiTheme.gold,
                        items: [
                          for (final item in yieldImpact)
                            GameStatBarItem(
                              icon: item.icon,
                              label: item.label,
                              value: item.after,
                              valueLabel: _signedValue(item.after),
                              color: item.color,
                            ),
                        ],
                      )
                    else
                      GameYieldDeltaComparison(
                        title: l10n.buildingDetailsYieldImpact,
                        beforeLabel: l10n.visualCurrentLabel,
                        afterLabel: l10n.visualAfterLabel,
                        accent: GameUiTheme.gold,
                        items: yieldImpact,
                      ),
                    const SizedBox(height: 16),
                  ],
                  _BuildingDetailsSection(
                    title: l10n.technologyDetailsPrerequisites,
                    lines: _buildingRequirementLines(
                      l10n,
                      definition,
                      unlockingTechnology,
                    ),
                  ),
                  _BuildingDetailsSection(
                    title: l10n.technologyDetailsEffects,
                    lines: _buildingEffectLines(l10n, definition),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
