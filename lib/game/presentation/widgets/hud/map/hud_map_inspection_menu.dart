import 'dart:math' as math;

import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers/map/map_inspection_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_artifact_inspection_popover.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_map_objective_inspection.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_tile_inspection_popover.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

part 'hud_map_objective_popover.dart';

class HudMapInspectionMenu extends StatelessWidget {
  const HudMapInspectionMenu({
    required this.inspection,
    required this.selection,
    required this.viewportSize,
    required this.activePlayerId,
    required this.research,
    required this.technologyRuleset,
    required this.onClose,
    super.key,
  });

  static const double _horizontalGap = 20;
  static const double _margin = 12;
  static const double _maxWidth = 308;
  static const double _minWidth = 236;
  static const double _estimatedHeight = 354;

  final MapInspectionState inspection;
  final SelectionViewModel? selection;
  final Size viewportSize;
  final String activePlayerId;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final anchor = inspection.anchor;
    final model = inspection.selection == null ? null : selection;
    final artifact = inspection.artifact;
    final objective = inspection.objectiveProgress;
    if (anchor == null ||
        (model == null && artifact == null && objective == null)) {
      return const SizedBox.shrink();
    }

    final placement = _placementFor(anchor);

    return Positioned(
      key: const Key('hudMapInspectionMenu.positioned'),
      left: placement.left,
      top: placement.top,
      width: placement.width,
      child: artifact != null
          ? HudArtifactInspectionPopover(
              artifact: artifact,
              onClose: onClose,
              arrowOnLeft: placement.arrowOnLeft,
              arrowTop: placement.arrowTop,
              maxHeight: placement.maxHeight,
            )
          : model != null
          ? HudTileInspectionPopover(
              model: model,
              activePlayerId: activePlayerId,
              research: research,
              technologyRuleset: technologyRuleset,
              objectiveProgress: objective,
              onClose: onClose,
              arrowOnLeft: placement.arrowOnLeft,
              arrowTop: placement.arrowTop,
              maxHeight: placement.maxHeight,
            )
          : _ObjectiveInspectionPopover(
              progress: objective!,
              onClose: onClose,
              arrowOnLeft: placement.arrowOnLeft,
              arrowTop: placement.arrowTop,
              maxHeight: placement.maxHeight,
            ),
    );
  }

  _InspectionPlacement _placementFor(Offset anchor) {
    final availableWidth = math.max(0.0, viewportSize.width - _margin * 2);
    final width = math.min(_maxWidth, math.max(_minWidth, availableWidth));
    final preferRight =
        anchor.dx + _horizontalGap + width <= viewportSize.width - _margin;
    final canUseLeft = anchor.dx - _horizontalGap - width >= _margin;
    final placeRight = preferRight || !canUseLeft;
    final left = placeRight
        ? math.min(
            anchor.dx + _horizontalGap,
            viewportSize.width - width - _margin,
          )
        : math.max(_margin, anchor.dx - _horizontalGap - width);
    final maxTop = math.max(_margin, viewportSize.height - _estimatedHeight);
    final top = (anchor.dy - 72).clamp(_margin, maxTop).toDouble();
    return (
      left: left,
      top: top,
      width: width,
      arrowOnLeft: placeRight,
      arrowTop: (anchor.dy - top - 6).clamp(22.0, 232.0).toDouble(),
      maxHeight: math.max(160, viewportSize.height - top - _margin).toDouble(),
    );
  }
}

typedef _InspectionPlacement = ({
  double left,
  double top,
  double width,
  bool arrowOnLeft,
  double arrowTop,
  double maxHeight,
});
