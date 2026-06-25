import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class SelectionIcon extends StatelessWidget {
  const SelectionIcon({
    required this.icon,
    required this.color,
    required this.density,
    super.key,
  });

  final GameIconData icon;
  final Color color;
  final SelectionDensity density;

  @override
  Widget build(BuildContext context) {
    final spec = SelectionDensitySpec.of(density);
    return Container(
      width: spec.selectionIconTileSize,
      height: spec.selectionIconTileSize,
      decoration: SurfaceElevation.raised.decoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GameUiTheme.chipSurfaceDim, GameUiTheme.surface],
        ),
        borderColor: Color.alphaBlend(
          SurfaceElevation.flat.fill(background: color, alpha: 38),
          SurfaceElevation.flat.fill(
            background: GameUiTheme.gold,
            alpha: GameHudTheme.accentBorderAlpha,
          ),
        ),
        borderAlpha: 255,
        borderWidth: 1.5,
        radius: GameHudTheme.iconTileRadius,
        boxShadow: SurfaceElevation.raised.shadows(alpha: 102),
      ),
      child: GameIcon(
        icon,
        size: spec.selectionIconSize,
        color: GameUiTheme.gold,
      ),
    );
  }
}
