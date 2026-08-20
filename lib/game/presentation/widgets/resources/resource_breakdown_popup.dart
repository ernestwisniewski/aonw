import 'dart:math' as math;

import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/stability_band_presentation.dart';
import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_strategic_resource_summary.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_breakdown_popup_category_data.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'resource_breakdown_popup_models.dart';
part 'resource_breakdown_popup_sections.dart';
part 'resource_breakdown_popup_stability_sections.dart';
part 'resource_breakdown_popup_widgets.dart';

class ResourceBreakdownPopup extends StatelessWidget {
  final ResourceBreakdownType type;
  final GoldBreakdown gold;
  final ScienceYieldBreakdown science;
  final StabilityBreakdown stability;
  final int stabilityNet;
  final StabilityBand stabilityBand;
  final int stabilityStandingAdjustment;
  final CityResourceInventory resources;
  final EmpireResourceNetwork resourceNetwork;
  final HudStrategicResourceSummary strategicResources;
  final List<GameCity> cities;
  final String? activeTechnologyName;
  final int? activeTechnologyTurnsRemaining;
  final int? activeTechnologyCompletionTurn;
  final AppLocalizations l10n;
  final VoidCallback onClose;
  final ValueChanged<GameCity>? onCityPressed;
  final VoidCallback? onOpenStrategicEconomy;
  final double maxWidth;
  final double maxHeight;
  final bool showDragHandle;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  const ResourceBreakdownPopup({
    required this.type,
    required this.gold,
    required this.science,
    required this.stability,
    required this.stabilityNet,
    required this.stabilityBand,
    required this.stabilityStandingAdjustment,
    required this.resources,
    required this.cities,
    required this.activeTechnologyName,
    required this.activeTechnologyTurnsRemaining,
    required this.l10n,
    required this.onClose,
    this.onCityPressed,
    this.onOpenStrategicEconomy,
    this.maxWidth = 330,
    this.maxHeight = 380,
    this.showDragHandle = false,
    this.activeTechnologyCompletionTurn,
    this.resourceNetwork = EmpireResourceNetwork.empty,
    this.strategicResources = HudStrategicResourceSummary.empty,
    this.gamepadInputListenable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      ResourceBreakdownType.gold => GameUiTheme.gold,
      ResourceBreakdownType.science => GameUiTheme.scienceAccent,
      ResourceBreakdownType.stability => StabilityBandPresentation.color(
        stabilityBand,
      ),
      ResourceBreakdownType.resources => GameUiTheme.resourcesAccent,
    };
    final title = switch (type) {
      ResourceBreakdownType.gold => l10n.commonGold,
      ResourceBreakdownType.science => l10n.resourceBreakdownScienceTitle,
      ResourceBreakdownType.stability => l10n.commonStability,
      ResourceBreakdownType.resources => l10n.commonResources,
    };
    final icon = switch (type) {
      ResourceBreakdownType.gold => GameIcons.gold,
      ResourceBreakdownType.science => GameIcons.science,
      ResourceBreakdownType.stability => GameIcons.defense,
      ResourceBreakdownType.resources => GameIcons.resources,
    };
    final sections = _resourceBreakdownSections(this);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: GameModalScaffold(
        showCornerDiamonds: false,
        contentPadding: EdgeInsets.zero,
        centerInAvailableSpace: false,
        scrollable: false,
        content: GamepadScrollable(
          input: gamepadInputListenable,
          onCancel: onClose,
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
          child: _ResourceBreakdownContent(
            title: title,
            accent: color,
            icon: icon,
            closeTooltip: l10n.closeAction,
            showDragHandle: showDragHandle,
            showEconomyAction:
                type == ResourceBreakdownType.resources &&
                strategicResources.enabled &&
                onOpenStrategicEconomy != null,
            economyActionLabel: l10n.resourceEconomyOpenAction,
            onClose: onClose,
            onOpenEconomy: onOpenStrategicEconomy,
            sections: sections,
          ),
        ),
      ),
    );
  }
}
