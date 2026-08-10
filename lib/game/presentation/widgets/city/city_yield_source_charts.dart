import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_yield_source_data.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class CityYieldSourceCharts extends StatelessWidget {
  const CityYieldSourceCharts({
    required this.model,
    required this.compact,
    super.key,
  });

  final CityYieldBreakdownViewModel model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = buildCityYieldSourceData(model, CityYieldBreakdownText(l10n));
    final charts = [
      _InsightChartCard(
        icon: GameIcons.production,
        title: l10n.cityYieldBreakdownProductionSources,
        accent: GameUiTheme.gold,
        total: data.productionTotal,
        totalSuffix: l10n.cityYieldBreakdownPerTurnSuffix,
        data: data.production,
        emptyLabel: l10n.cityYieldBreakdownNoProduction,
      ),
      _InsightChartCard(
        icon: GameIcons.science,
        title: l10n.cityYieldBreakdownScienceSources,
        accent: GameUiTheme.scienceAccent,
        total: model.scienceTotal,
        totalSuffix: l10n.cityYieldBreakdownPerTurnSuffix,
        data: data.science,
        emptyLabel: l10n.cityYieldBreakdownNoScience,
      ),
    ];
    return compact ? _compactCharts(charts) : _wideCharts(charts);
  }

  Widget _compactCharts(List<Widget> charts) =>
      Column(children: [charts[0], const SizedBox(height: 8), charts[1]]);

  Widget _wideCharts(List<Widget> charts) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: charts[0]),
      const SizedBox(width: 10),
      Expanded(child: charts[1]),
    ],
  );
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
  final List<CityYieldSourceDatum> data;
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
            _ChartHeader(
              icon: icon,
              title: title,
              accent: accent,
              totalLabel: '$total$totalSuffix',
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

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({
    required this.icon,
    required this.title,
    required this.accent,
    required this.totalLabel,
  });

  final GameIconData icon;
  final String title;
  final Color accent;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          totalLabel,
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
    );
  }
}

class _SourceDonutChart extends StatelessWidget {
  const _SourceDonutChart({required this.data, required this.total});

  final List<CityYieldSourceDatum> data;
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

  final List<CityYieldSourceDatum> data;
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

  final List<CityYieldSourceDatum> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(children: [for (final item in data) _legendItem(item)]);
  }

  Widget _legendItem(CityYieldSourceDatum item) {
    return Tooltip(
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
