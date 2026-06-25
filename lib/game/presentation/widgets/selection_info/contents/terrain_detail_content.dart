import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class TerrainDetailContent extends StatelessWidget {
  final SelectionTerrainDetail model;
  final bool compact;

  const TerrainDetailContent({
    required this.model,
    required this.compact,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (model.terrainLabels.isEmpty && model.tags.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Text(
        l10n.terrainDetailEmpty,
        style: const TextStyle(
          color: GameHudTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final label in model.terrainLabels) _TerrainPill(label: label),
          ],
        ),
        if (model.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          SelectionTagStrip(
            tags: model.tags,
            density: compact
                ? SelectionDensity.compact
                : SelectionDensity.comfortable,
          ),
        ],
      ],
    );
  }
}

class _TerrainPill extends StatelessWidget {
  final String label;

  const _TerrainPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 190,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(GameHudTheme.panelRadius),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          GameText.uppercase(label),
          style: const TextStyle(
            color: GameHudTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
