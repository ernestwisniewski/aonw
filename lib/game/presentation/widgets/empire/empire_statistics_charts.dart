import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/empire/empire_statistics_view_data.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class EmpireReadinessCard extends StatelessWidget {
  const EmpireReadinessCard({
    required this.title,
    required this.emptyLabel,
    required this.data,
    required this.total,
    super.key,
  });

  final String title;
  final String emptyLabel;
  final List<EmpireChartDatum> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    return EmpireChartShell(
      title: title,
      child: total == 0
          ? EmpireChartEmpty(label: emptyLabel)
          : Row(
              children: [
                _DonutChart(data: data, total: total),
                const SizedBox(width: 12),
                Expanded(child: _Legend(data: data)),
              ],
            ),
    );
  }
}

class EmpireBarChartCard extends StatelessWidget {
  const EmpireBarChartCard({
    required this.title,
    required this.emptyLabel,
    required this.data,
    super.key,
  });

  final String title;
  final String emptyLabel;
  final List<EmpireChartDatum> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(
      0,
      (max, item) => math.max(max, item.value),
    );
    return EmpireChartShell(
      title: title,
      child: data.isEmpty
          ? EmpireChartEmpty(label: emptyLabel)
          : Column(
              children: [
                for (var i = 0; i < data.length; i++) ...[
                  if (i > 0) const SizedBox(height: 7),
                  _BarRow(
                    label: data[i].label,
                    value: data[i].value,
                    maxValue: maxValue,
                    color: data[i].color,
                  ),
                ],
              ],
            ),
    );
  }
}

class EmpireChartShell extends StatelessWidget {
  const EmpireChartShell({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

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
            Text(
              GameText.uppercase(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.sectionHeader.copyWith(
                color: GameUiTheme.gold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class EmpireChartEmpty extends StatelessWidget {
  const EmpireChartEmpty({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GameUiTheme.bodySmall.copyWith(color: GameUiTheme.textMuted),
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.data, required this.total});

  final List<EmpireChartDatum> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 92,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _DonutChartPainter(data: data, total: total),
          ),
          Center(
            child: Text(
              '$total',
              style: const TextStyle(
                color: GameUiTheme.textBright,
                fontFamily: GameUiTheme.headingFont,
                fontSize: 22,
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

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.data, required this.total});

  final List<EmpireChartDatum> data;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = GameUiTheme.bg.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, basePaint);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final item in data) {
      if (item.value <= 0) continue;
      final sweep = math.pi * 2 * (item.value / total);
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, math.max(0.02, sweep - 0.04), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.total != total;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.data});

  final List<EmpireChartDatum> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in data)
          Padding(
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
                  '${item.value}',
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
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final factor = maxValue <= 0 ? 0.0 : value / maxValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.chipLabel.copyWith(
                  color: GameUiTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value',
              style: const TextStyle(
                color: GameUiTheme.textBright,
                fontFamily: GameUiTheme.bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontFeatures: GameUiTheme.tabularFigures,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: GameUiTheme.bg.withAlpha(132)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: factor.clamp(0.0, 1.0),
                  child: ColoredBox(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
