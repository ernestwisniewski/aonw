import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class TechnologyDetailChip extends StatelessWidget {
  const TechnologyDetailChip({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 120,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GameText.uppercase(label),
              style: GameUiTheme.toolbarLabel.copyWith(
                color: GameUiTheme.textMuted,
                fontSize: 8.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TechnologyDetailsSection extends StatelessWidget {
  const TechnologyDetailsSection({
    required this.title,
    required this.lines,
    super.key,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GameText.uppercase(title),
            style: GameUiTheme.toolbarLabel.copyWith(
              color: GameUiTheme.scienceAccent,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $line',
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textPrimary,
                  height: 1.25,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
