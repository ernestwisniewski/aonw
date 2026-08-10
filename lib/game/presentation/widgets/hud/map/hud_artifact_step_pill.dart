import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class HudArtifactStepPill extends StatelessWidget {
  const HudArtifactStepPill({
    required this.icon,
    required this.label,
    super.key,
  });

  final GameIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: ShapeDecoration(
        color: SurfaceElevation.flat.fill(
          background: GameUiTheme.gold,
          alpha: 34,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(
            color: SurfaceElevation.flat.strokeColor(
              color: GameUiTheme.gold,
              alpha: 104,
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(icon, size: 13, color: GameUiTheme.goldLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: GameUiTheme.toolbarLabel.copyWith(
              color: GameUiTheme.goldLight,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
