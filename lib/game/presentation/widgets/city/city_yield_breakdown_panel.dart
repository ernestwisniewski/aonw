import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';

class CityYieldBreakdownPanel extends StatelessWidget {
  const CityYieldBreakdownPanel({required this.model, super.key});

  final CityYieldBreakdownViewModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.surface,
        backgroundAlpha: 150,
        border: BorderEmphasis.subtle,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BreakdownHeader(model: model, compact: compact),
              const SizedBox(height: 10),
              _CitySourceCharts(model: model, compact: compact),
              const SizedBox(height: 10),
              _BreakdownRows(rows: model.rows, compact: compact),
            ],
          );
        },
      ),
    );
  }
}

class _BreakdownHeader extends StatelessWidget {
  const _BreakdownHeader({required this.model, required this.compact});

  final CityYieldBreakdownViewModel model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 280 : 340),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GameUiEpicHeader(
                label: l10n.cityYieldBreakdownTitle,
                alignment: Alignment.centerLeft,
                compact: true,
                textKey: const Key('cityYieldBreakdown.title'),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.cityYieldBreakdownSubtitle(
                  model.growthLabel,
                  model.growthEta.compactLabel(l10n),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _YieldChips(yield: model.totalYield, compact: compact),
      ],
    );
  }
}

class _CitySourceCharts extends StatelessWidget {
  const _CitySourceCharts({required this.model, required this.compact});

  final CityYieldBreakdownViewModel model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = CityYieldBreakdownText(l10n);
    final productionData = _productionSources(model.rows, text);
    final scienceData = _scienceSources(model.scienceRows, text);
    final charts = [
      _InsightChartCard(
        icon: GameIcons.production,
        title: l10n.cityYieldBreakdownProductionSources,
        accent: GameUiTheme.gold,
        total: _sum(productionData),
        totalSuffix: l10n.cityYieldBreakdownPerTurnSuffix,
        data: productionData,
        emptyLabel: l10n.cityYieldBreakdownNoProduction,
      ),
      _InsightChartCard(
        icon: GameIcons.science,
        title: l10n.cityYieldBreakdownScienceSources,
        accent: GameUiTheme.scienceAccent,
        total: model.scienceTotal,
        totalSuffix: l10n.cityYieldBreakdownPerTurnSuffix,
        data: scienceData,
        emptyLabel: l10n.cityYieldBreakdownNoScience,
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < charts.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            charts[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: charts[0]),
        const SizedBox(width: 10),
        Expanded(child: charts[1]),
      ],
    );
  }

  static int _sum(List<_SourceDatum> data) {
    var total = 0;
    for (final item in data) {
      total += item.value;
    }
    return total;
  }

  static List<_SourceDatum> _productionSources(
    List<CityYieldBreakdownRow> rows,
    CityYieldBreakdownText text,
  ) {
    final values = <_SourceBucket, int>{};
    final details = <_SourceBucket, List<String>>{};
    for (final row in rows) {
      final value = row.yield.production;
      if (value <= 0) continue;
      final bucket = _bucketFor(row.label, text);
      values[bucket] = (values[bucket] ?? 0) + value;
      details.putIfAbsent(bucket, () => []).add(row.label);
    }

    return [
      for (final bucket in _SourceBucket.values)
        if ((values[bucket] ?? 0) > 0)
          _SourceDatum(
            label: bucket.label(text),
            detail: _detailFor(bucket, details[bucket] ?? const [], text),
            value: values[bucket]!,
            color: bucket.color,
          ),
    ];
  }

  static List<_SourceDatum> _scienceSources(
    List<CityScienceBreakdownRow> rows,
    CityYieldBreakdownText text,
  ) {
    return [
      for (final row in rows)
        if (row.value > 0)
          _SourceDatum(
            label: row.label,
            detail: row.detail,
            value: row.value,
            color: _scienceColorFor(row.label, text),
          ),
    ];
  }

  static _SourceBucket _bucketFor(String label, CityYieldBreakdownText text) {
    return switch (label) {
      _ when label == text.center || label == text.populationFields =>
        _SourceBucket.fields,
      _ when label == text.workers || label == text.improvements =>
        _SourceBucket.improvements,
      _ when label == text.buildings => _SourceBucket.buildings,
      _ when label == text.technologies => _SourceBucket.technologies,
      _ when label == text.specialization => _SourceBucket.specialization,
      _ when label == text.goldMultiplier => _SourceBucket.multipliers,
      _ => _SourceBucket.other,
    };
  }

  static String _detailFor(
    _SourceBucket bucket,
    List<String> labels,
    CityYieldBreakdownText text,
  ) {
    final label = bucket.label(text);
    if (labels.isEmpty) return label;
    return '$label: ${labels.join(' + ')}';
  }

  static Color _scienceColorFor(String label, CityYieldBreakdownText text) {
    return switch (label) {
      _ when label == text.baseScience => GameUiTheme.scienceAccent,
      _ when label == text.buildings => GameUiTheme.gold,
      _ when label == text.specialization => GameUiTheme.resourcesAccent,
      _ when label == text.technologies => GameUiTheme.info,
      _ when label == text.researchProject => GameUiTheme.warning,
      _ => GameUiTheme.textSecondary,
    };
  }
}

enum _SourceBucket {
  fields,
  improvements,
  buildings,
  technologies,
  specialization,
  multipliers,
  other;

  String label(CityYieldBreakdownText text) => switch (this) {
    _SourceBucket.fields => text.fieldsBucket,
    _SourceBucket.improvements => text.improvements,
    _SourceBucket.buildings => text.buildings,
    _SourceBucket.technologies => text.technologies,
    _SourceBucket.specialization => text.specialization,
    _SourceBucket.multipliers => text.multipliers,
    _SourceBucket.other => text.other,
  };

  Color get color => switch (this) {
    _SourceBucket.fields => GameUiTheme.success,
    _SourceBucket.improvements => GameUiTheme.info,
    _SourceBucket.buildings => GameUiTheme.gold,
    _SourceBucket.technologies => GameUiTheme.scienceAccent,
    _SourceBucket.specialization => GameUiTheme.resourcesAccent,
    _SourceBucket.multipliers => GameUiTheme.copper,
    _SourceBucket.other => GameUiTheme.textSecondary,
  };
}

class _SourceDatum {
  const _SourceDatum({
    required this.label,
    required this.detail,
    required this.value,
    required this.color,
  });

  final String label;
  final String detail;
  final int value;
  final Color color;
}

class _InsightChartCard extends StatelessWidget {
  const _InsightChartCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.total,
    required this.totalSuffix,
    required this.data,
    required this.emptyLabel,
  });

  final GameIconData icon;
  final String title;
  final Color accent;
  final int total;
  final String totalSuffix;
  final List<_SourceDatum> data;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.surface,
        backgroundAlpha: 132,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  '$total$totalSuffix',
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
            const SizedBox(height: 10),
            if (data.isEmpty || total <= 0)
              _ChartEmpty(label: emptyLabel)
            else
              Row(
                children: [
                  _SourceDonutChart(data: data, total: total),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceLegend(data: data, total: total),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceDonutChart extends StatelessWidget {
  const _SourceDonutChart({required this.data, required this.total});

  final List<_SourceDatum> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 82,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _SourceDonutPainter(data: data, total: total),
          ),
          Center(
            child: Text(
              '$total',
              style: const TextStyle(
                color: GameUiTheme.textBright,
                fontFamily: GameUiTheme.headingFont,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFeatures: GameUiTheme.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceDonutPainter extends CustomPainter {
  const _SourceDonutPainter({required this.data, required this.total});

  final List<_SourceDatum> data;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = GameUiTheme.bg.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawCircle(center, radius, basePaint);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final item in data) {
      if (item.value <= 0) continue;
      final sweep = math.pi * 2 * (item.value / total);
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, math.max(0.02, sweep - 0.04), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SourceDonutPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.total != total;
  }
}

class _SourceLegend extends StatelessWidget {
  const _SourceLegend({required this.data, required this.total});

  final List<_SourceDatum> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in data)
          Tooltip(
            message: item.detail,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.chipLabel.copyWith(
                        color: GameUiTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.value} • ${_percent(item.value)}%',
                    style: const TextStyle(
                      color: GameUiTheme.textBright,
                      fontFamily: GameUiTheme.bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFeatures: GameUiTheme.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  int _percent(int value) => total <= 0 ? 0 : (value * 100 / total).round();
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BreakdownRows extends StatelessWidget {
  const _BreakdownRows({required this.rows, required this.compact});

  final List<CityYieldBreakdownRow> rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = compact ? 6.0 : 8.0;
        final itemWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final row in rows)
              SizedBox(
                width: itemWidth,
                child: _BreakdownRow(row: row, compact: compact),
              ),
          ],
        );
      },
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.row, required this.compact});

  final CityYieldBreakdownRow row;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tooltip = '${row.label}: ${row.detail}';
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 42 : 46),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 7 : 8,
          ),
          decoration: SurfaceElevation.flat.decoration(
            background: GameUiTheme.bg,
            backgroundAlpha: 118,
            border: BorderEmphasis.subtle,
            borderRadius: BorderRadius.circular(5),
            includeShadow: false,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.bodyStrong.copyWith(
                        color: GameUiTheme.textPrimary,
                        fontSize: compact ? 11 : 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameHudTheme.textSecondary,
                        fontSize: compact ? 10 : 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _YieldChips(yield: row.yield, compact: true, dense: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _YieldChips extends StatelessWidget {
  const _YieldChips({
    required this.yield,
    required this.compact,
    this.dense = false,
  });

  final TileYield yield;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: dense ? 3 : 5,
      runSpacing: dense ? 3 : 5,
      children: [
        _YieldChip(
          icon: GameIcons.food,
          label: l10n.yieldFoodShort,
          value: yield.food,
          color: const Color(0xFF87c96a),
          compact: compact,
          dense: dense,
        ),
        _YieldChip(
          icon: GameIcons.production,
          label: l10n.yieldProductionShort,
          value: yield.production,
          color: const Color(0xFFc9a95f),
          compact: compact,
          dense: dense,
        ),
        _YieldChip(
          icon: GameIcons.gold,
          label: l10n.yieldGoldShort,
          value: yield.gold,
          color: const Color(0xFFe0c35c),
          compact: compact,
          dense: dense,
        ),
        _YieldChip(
          icon: GameIcons.defense,
          label: l10n.yieldDefenseShort,
          value: yield.defense,
          color: const Color(0xFF8da8e8),
          compact: compact,
          dense: dense,
        ),
      ],
    );
  }
}

class _YieldChip extends StatelessWidget {
  const _YieldChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.compact,
    required this.dense,
  });

  final GameIconData icon;
  final String label;
  final int value;
  final Color color;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final valueText = value > 0 ? '+$value' : '$value';
    return Tooltip(
      message: '$label $valueText',
      child: Container(
        height: dense ? 22 : 26,
        padding: EdgeInsets.symmetric(horizontal: dense ? 5 : 7),
        decoration: SurfaceElevation.flat.decoration(
          accent: color,
          background: color,
          backgroundAlpha: value == 0 ? 12 : 28,
          borderAlpha: value == 0 ? 44 : 105,
          borderRadius: BorderRadius.circular(4),
          includeShadow: false,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIcon(
              icon,
              size: dense ? GameIconSize.tiny : GameIconSize.small,
              color: color,
            ),
            SizedBox(width: dense ? 3 : 4),
            Text(
              valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameHudTheme.yieldValue.copyWith(
                fontSize: dense
                    ? 11
                    : compact
                    ? 12
                    : 13,
                color: value == 0
                    ? GameUiTheme.textSecondary
                    : GameUiTheme.textBright,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
