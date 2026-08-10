import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class GameInsightPill extends StatelessWidget {
  const GameInsightPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: color,
        backgroundAlpha: 24,
        borderColor: color,
        borderAlpha: 115,
        borderRadius: BorderRadius.circular(999),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.chipLabel.copyWith(color: color),
        ),
      ),
    );
  }
}
