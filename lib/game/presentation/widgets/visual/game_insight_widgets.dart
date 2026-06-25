import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class GameInsightProgressCard extends StatelessWidget {
  const GameInsightProgressCard({
    required this.title,
    required this.valueLabel,
    required this.progress,
    required this.icon,
    required this.accent,
    this.subtitle,
    this.meta = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final String valueLabel;
  final double progress;
  final GameIconData icon;
  final Color accent;
  final List<String> meta;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: accent,
        background: GameUiTheme.bg,
        backgroundAlpha: 124,
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
            Row(
              children: [
                GameIcon(icon, size: GameIconSize.small, color: accent),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    GameText.uppercase(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.sectionHeader.copyWith(
                      color: accent,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  valueLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GameUiTheme.textBright,
                    fontFamily: GameUiTheme.headingFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFeatures: GameUiTheme.tabularFigures,
                  ),
                ),
              ],
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: ColoredBox(
                color: GameUiTheme.surfaceDeep.withAlpha(170),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: clamped,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent.withAlpha(220),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in meta)
                    _InsightPill(label: label, color: accent),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

class GameYieldDeltaItem {
  const GameYieldDeltaItem({
    required this.icon,
    required this.label,
    required this.before,
    required this.after,
    required this.color,
  });

  final GameIconData icon;
  final String label;
  final int before;
  final int after;
  final Color color;

  int get delta => after - before;
}

class GameYieldDeltaComparison extends StatelessWidget {
  const GameYieldDeltaComparison({
    required this.title,
    required this.beforeLabel,
    required this.afterLabel,
    required this.items,
    this.accent = GameUiTheme.gold,
    super.key,
  });

  final String title;
  final String beforeLabel;
  final String afterLabel;
  final List<GameYieldDeltaItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final visibleItems = [
      for (final item in items)
        if (item.before != 0 || item.after != 0) item,
    ];
    final maxValue = visibleItems.fold<int>(
      0,
      (max, item) =>
          math.max(max, math.max(item.before.abs(), item.after.abs())),
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
            if (visibleItems.isEmpty)
              Text(
                '$beforeLabel -> $afterLabel',
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textMuted,
                ),
              )
            else
              for (var i = 0; i < visibleItems.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _YieldDeltaRow(
                  index: i,
                  item: visibleItems[i],
                  beforeLabel: beforeLabel,
                  afterLabel: afterLabel,
                  maxValue: maxValue,
                ),
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

class _YieldDeltaRow extends StatelessWidget {
  const _YieldDeltaRow({
    required this.index,
    required this.item,
    required this.beforeLabel,
    required this.afterLabel,
    required this.maxValue,
  });

  final int index;
  final GameYieldDeltaItem item;
  final String beforeLabel;
  final String afterLabel;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final beforeFactor = maxValue <= 0
        ? 0.0
        : (item.before.abs() / maxValue).clamp(0.0, 1.0);
    final afterFactor = maxValue <= 0
        ? 0.0
        : (item.after.abs() / maxValue).clamp(0.0, 1.0);
    final afterColor = item.delta >= 0 ? item.color : GameUiTheme.danger;
    return Column(
      key: Key('gameYieldDeltaComparison.row.$index'),
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
              '${item.before} -> ${item.after}',
              style: GameUiTheme.bodyStrong.copyWith(
                color: GameUiTheme.textPrimary,
                fontFeatures: GameUiTheme.tabularFigures,
              ),
            ),
            if (item.delta != 0) ...[
              const SizedBox(width: 6),
              _InsightPill(
                label: '${item.delta > 0 ? '+' : ''}${item.delta}',
                color: item.delta > 0 ? item.color : GameUiTheme.danger,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        _YieldMetricBar(
          label: beforeLabel,
          value: item.before,
          factor: beforeFactor,
          color: item.color,
          muted: true,
          fillKey: Key('gameYieldDeltaComparison.beforeBar.$index'),
        ),
        const SizedBox(height: 5),
        _YieldMetricBar(
          label: afterLabel,
          value: item.after,
          factor: afterFactor,
          color: afterColor,
          muted: false,
          fillKey: Key('gameYieldDeltaComparison.afterBar.$index'),
        ),
      ],
    );
  }
}

class _YieldMetricBar extends StatelessWidget {
  const _YieldMetricBar({
    required this.label,
    required this.value,
    required this.factor,
    required this.color,
    required this.muted,
    required this.fillKey,
  });

  final String label;
  final int value;
  final double factor;
  final Color color;
  final bool muted;
  final Key fillKey;

  @override
  Widget build(BuildContext context) {
    final labelColor = muted ? GameUiTheme.textMuted : color;
    final fillColor = muted ? color.withAlpha(104) : color.withAlpha(220);
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            GameText.uppercase(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.toolbarLabel.copyWith(
              color: labelColor,
              fontSize: 8,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 28,
          child: Text(
            value.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: GameUiTheme.bodySmall.copyWith(
              color: labelColor,
              fontFeatures: GameUiTheme.tabularFigures,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: ColoredBox(
              color: GameUiTheme.surfaceDeep.withAlpha(160),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: factor,
                  child: Container(
                    key: fillKey,
                    height: 5,
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
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

class _InsightPill extends StatelessWidget {
  const _InsightPill({required this.label, required this.color});

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
