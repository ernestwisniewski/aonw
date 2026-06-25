import 'package:aonw/game/presentation/widgets/bottom_toolbar/hex_presentation/hex_tag_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class SelectionTagStrip extends StatelessWidget {
  const SelectionTagStrip({
    required this.tags,
    required this.density,
    super.key,
  });

  final List<HexTagViewModel> tags;
  final SelectionDensity density;

  @override
  Widget build(BuildContext context) {
    final spec = SelectionDensitySpec.of(density);
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final tag in tags.take(spec.visibleTagCount))
          _TagChip(tag: tag, spec: spec),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag, required this.spec});

  final HexTagViewModel tag;
  final SelectionDensitySpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: spec.tagMaxWidth),
      height: spec.tagHeight,
      padding: spec.tagPadding,
      decoration: SurfaceElevation.flat.decoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HudPalette.chipSurface, HudPalette.chipSurfaceDim],
        ),
        borderColor: tag.color,
        borderAlpha: 130,
        shape: SurfaceShape.chip,
        includeShadow: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(tag.icon, size: spec.tagIconSize, color: tag.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              GameText.uppercase(tag.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameHudTheme.selectionTag.copyWith(
                fontSize: spec.tagFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
