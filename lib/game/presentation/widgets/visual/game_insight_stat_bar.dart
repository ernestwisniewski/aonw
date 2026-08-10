import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class GameStatBarItem {
  const GameStatBarItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.valueLabel,
  });

  final GameIconData icon;
  final String label;
  final int value;
  final Color color;
  final String? valueLabel;
}

class GameStatBarGroup extends StatelessWidget {
  const GameStatBarGroup({
    required this.title,
    required this.items,
    this.accent = GameUiTheme.gold,
    this.emptyLabel,
    super.key,
  });

  final String title;
  final List<GameStatBarItem> items;
  final Color accent;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<int>(
      0,
      (max, item) => math.max(max, item.value.abs()),
    );
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: accent,
        background: GameUiTheme.bg,
        backgroundAlpha: 116,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(7),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              GameText.uppercase(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.toolbarLabel.copyWith(color: accent),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                emptyLabel ?? '',
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textMuted,
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 7),
                _StatBarRow(item: items[i], maxValue: maxValue),
              ],
          ],
        ),
      ),
    );
  }
}

class _StatBarRow extends StatelessWidget {
  const _StatBarRow({required this.item, required this.maxValue});

  final GameStatBarItem item;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final factor = maxValue <= 0
        ? 0.0
        : (item.value.abs() / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GameIcon(item.icon, size: GameIconSize.tiny, color: item.color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.valueLabel ?? item.value.toString(),
              style: GameUiTheme.bodyStrong.copyWith(
                color: item.color,
                fontFeatures: GameUiTheme.tabularFigures,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: ColoredBox(
            color: GameUiTheme.surfaceDeep.withAlpha(160),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: factor,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(210),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
