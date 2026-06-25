import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class SelectionLabelChip extends StatelessWidget {
  const SelectionLabelChip({
    required this.item,
    required this.density,
    super.key,
  });

  final SelectionInfoItem item;
  final SelectionDensity density;

  @override
  Widget build(BuildContext context) {
    final spec = SelectionDensitySpec.of(density);
    final text = item.showLabel
        ? '${item.label}: ${GameText.uppercase(item.value)}'
        : GameText.uppercase(item.value);

    return Container(
      constraints: BoxConstraints(
        maxWidth: density == SelectionDensity.compact ? 122 : 168,
      ),
      height: spec.chipHeight,
      padding: spec.chipPadding,
      decoration: SurfaceElevation.flat.decoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HudPalette.chipSurface, HudPalette.chipSurfaceDim],
        ),
        shape: SurfaceShape.chip,
        border: BorderEmphasis.regular,
        includeShadow: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(item.icon, size: spec.iconSize, color: item.color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameHudTheme.selectionChip.copyWith(
                fontSize: spec.chipFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
