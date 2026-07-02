import 'dart:math' as math;

import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

part 'resource_breakdown_popup_models.dart';
part 'resource_breakdown_popup_sections.dart';
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
  final List<GameCity> cities;
  final String? activeTechnologyName;
  final int? activeTechnologyTurnsRemaining;
  final int? activeTechnologyCompletionTurn;
  final AppLocalizations l10n;
  final VoidCallback onClose;
  final double maxWidth;
  final double maxHeight;
  final bool showDragHandle;

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
    this.maxWidth = 330,
    this.maxHeight = 380,
    this.showDragHandle = false,
    this.activeTechnologyCompletionTurn,
    this.resourceNetwork = EmpireResourceNetwork.empty,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      ResourceBreakdownType.gold => GameUiTheme.gold,
      ResourceBreakdownType.science => GameUiTheme.scienceAccent,
      ResourceBreakdownType.stability => _stabilityColor(stabilityBand),
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
        content: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle) ...[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: ShapeDecoration(
                      color: SurfaceElevation.flat.fill(
                        background: GameUiTheme.copper,
                        alpha: 120,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              GameUiEpicHeader(
                label: title,
                accent: color,
                alignment: Alignment.centerLeft,
                leading: GameIcon(
                  icon,
                  size: GameIconSize.regular,
                  color: color,
                ),
                trailing: _PopupIconButton(
                  icon: GameIcons.close,
                  tooltip: l10n.closeAction,
                  onTap: onClose,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _BreakdownSection(section: sections[i], accent: color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _stabilityColor(StabilityBand band) => switch (band) {
    StabilityBand.content => GameUiTheme.success,
    StabilityBand.stable => GameUiTheme.gold,
    StabilityBand.strained => GameUiTheme.warning,
    StabilityBand.unrest => GameUiTheme.danger,
  };
}
