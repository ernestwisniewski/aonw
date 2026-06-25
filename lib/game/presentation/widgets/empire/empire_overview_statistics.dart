import 'dart:math' as math;

import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class EmpireStatisticsPanel extends StatelessWidget {
  const EmpireStatisticsPanel({
    required this.viewModel,
    required this.l10n,
    required this.compact,
    super.key,
  });

  final EmpireOverviewViewModel viewModel;
  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final readiness = _readinessData(viewModel, l10n);
    final unitData = _unitCompositionData(viewModel, l10n);
    final unitMetrics = _unitMetricItems(viewModel, l10n);
    final cityMetrics = _cityMetricItems(context, viewModel, l10n);

    return Column(
      key: const Key('empireStatisticsPanel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsHeader(l10n: l10n),
        const SizedBox(height: 10),
        _StatsGroupBlock(
          icon: GameIcons.army,
          title: l10n.unitsSection,
          accent: GameUiTheme.gold,
          children: [
            _MetricGrid(items: unitMetrics, compact: compact),
            const SizedBox(height: 10),
            if (compact)
              Column(
                children: [
                  _ReadinessCard(
                    data: readiness,
                    total: viewModel.units.length,
                  ),
                  const SizedBox(height: 10),
                  _BarChartCard(
                    title: l10n.empireStatsUnitCompositionTitle,
                    emptyLabel: l10n.empireStatsEmptyUnits,
                    data: unitData,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 260,
                    child: _ReadinessCard(
                      data: readiness,
                      total: viewModel.units.length,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BarChartCard(
                      title: l10n.empireStatsUnitCompositionTitle,
                      emptyLabel: l10n.empireStatsEmptyUnits,
                      data: unitData,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        _StatsGroupBlock(
          icon: GameIcons.cityFilled,
          title: l10n.commonCities,
          accent: GameUiTheme.resourcesAccent,
          children: [
            _MetricGrid(items: cityMetrics, compact: compact),
            const SizedBox(height: 10),
            _CityComparisonCard(
              comparisons: viewModel.cityComparisons,
              l10n: l10n,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsGroupBlock extends StatelessWidget {
  const _StatsGroupBlock({
    required this.icon,
    required this.title,
    required this.accent,
    required this.children,
  });

  final GameIconData icon;
  final String title;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GameIcon(icon, size: GameIconSize.small, color: accent),
            const SizedBox(width: 7),
            Text(
              GameText.uppercase(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.sectionHeader.copyWith(
                color: accent,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withAlpha(130), accent.withAlpha(0)],
                  ),
                ),
                child: const SizedBox(height: 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ...children,
      ],
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const GameIcon(
          GameIcons.stats,
          size: GameIconSize.small,
          color: GameUiTheme.gold,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameText.uppercase(l10n.empireStatsTitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.sectionHeader.copyWith(
                  color: GameUiTheme.goldLight,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.empireStatsSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final GameIconData icon;
  final String label;
  final String value;
  final Color color;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items, required this.compact});

  final List<_MetricItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact || constraints.maxWidth < 640 ? 2 : 4;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _MetricTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 126,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        child: Row(
          children: [
            GameIcon(item.icon, size: GameIconSize.small, color: item.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                GameText.uppercase(item.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.toolbarLabel.copyWith(
                  color: GameUiTheme.textSecondary,
                  fontSize: 8.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.value,
              style: TextStyle(
                color: item.color,
                fontFamily: GameUiTheme.headingFont,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFeatures: GameUiTheme.tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartDatum {
  const _ChartDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.data, required this.total});

  final List<_ChartDatum> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    return _ChartShell(
      title: AppLocalizations.of(context).empireStatsReadinessTitle,
      child: total == 0
          ? _ChartEmpty(
              label: AppLocalizations.of(context).empireStatsEmptyUnits,
            )
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

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
    required this.title,
    required this.emptyLabel,
    required this.data,
  });

  final String title;
  final String emptyLabel;
  final List<_ChartDatum> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(
      0,
      (max, item) => math.max(max, item.value),
    );
    return _ChartShell(
      title: title,
      child: data.isEmpty
          ? _ChartEmpty(label: emptyLabel)
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

class _CityComparisonCard extends StatelessWidget {
  const _CityComparisonCard({required this.comparisons, required this.l10n});

  final List<EmpireCityComparison> comparisons;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final visibleCities = comparisons.take(6).toList(growable: false);
    final maxPopulation = visibleCities.fold<int>(
      0,
      (max, city) => math.max(max, city.population),
    );
    final maxProduction = visibleCities.fold<int>(
      0,
      (max, city) => math.max(max, city.production),
    );
    final maxFood = visibleCities.fold<int>(
      0,
      (max, city) => math.max(max, city.food),
    );
    final maxGold = visibleCities.fold<int>(
      0,
      (max, city) => math.max(max, city.gold),
    );

    return _ChartShell(
      title: l10n.empireStatsCityComparisonTitle,
      child: visibleCities.isEmpty
          ? _ChartEmpty(label: l10n.empireStatsEmptyCities)
          : Column(
              children: [
                for (var i = 0; i < visibleCities.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _CityComparisonRow(
                    comparison: visibleCities[i],
                    maxPopulation: maxPopulation,
                    maxProduction: maxProduction,
                    maxFood: maxFood,
                    maxGold: maxGold,
                    l10n: l10n,
                  ),
                ],
              ],
            ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  const _ChartShell({required this.title, required this.child});

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

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.data, required this.total});

  final List<_ChartDatum> data;
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

  final List<_ChartDatum> data;
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

  final List<_ChartDatum> data;

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

class _CityComparisonRow extends StatelessWidget {
  const _CityComparisonRow({
    required this.comparison,
    required this.maxPopulation,
    required this.maxProduction,
    required this.maxFood,
    required this.maxGold,
    required this.l10n,
  });

  final EmpireCityComparison comparison;
  final int maxPopulation;
  final int maxProduction;
  final int maxFood;
  final int maxGold;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final populationFactor = maxPopulation <= 0
        ? 0.0
        : comparison.population / maxPopulation;
    final productionFactor = maxProduction <= 0
        ? 0.0
        : comparison.production / maxProduction;
    final foodFactor = maxFood <= 0 ? 0.0 : comparison.food / maxFood;
    final goldFactor = maxGold <= 0 ? 0.0 : comparison.gold / maxGold;
    final artifact = comparison.storedArtifact;
    final detail = l10n.empireStatsCityComparisonDetail(
      comparison.population,
      comparison.production,
      comparison.food,
      comparison.gold,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          GameDisplayNames.city(l10n, comparison.city),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.chipLabel.copyWith(
            color: GameUiTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          artifact == null
              ? detail
              : '$detail • '
                    '${l10n.empireCityStoredArtifact(GameDisplayNames.worldArtifact(l10n, artifact.type))}',
          maxLines: artifact == null ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.chipLabel.copyWith(
            color: GameUiTheme.textMuted,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final metricWidth = constraints.maxWidth >= 300
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: spacing,
              runSpacing: 4,
              children: [
                SizedBox(
                  width: metricWidth,
                  child: _CityMetricBar(
                    label: l10n.empireStatsMetricPopulation,
                    value: comparison.population,
                    valueFactor: populationFactor,
                    color: GameUiTheme.resourcesAccent,
                  ),
                ),
                SizedBox(
                  width: metricWidth,
                  child: _CityMetricBar(
                    label: l10n.empireStatsMetricProduction,
                    value: comparison.production,
                    valueFactor: productionFactor,
                    color: GameUiTheme.warning,
                  ),
                ),
                SizedBox(
                  width: metricWidth,
                  child: _CityMetricBar(
                    label: l10n.empireStatsMetricFood,
                    value: comparison.food,
                    valueFactor: foodFactor,
                    color: GameUiTheme.success,
                  ),
                ),
                SizedBox(
                  width: metricWidth,
                  child: _CityMetricBar(
                    label: l10n.empireStatsMetricGold,
                    value: comparison.gold,
                    valueFactor: goldFactor,
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CityMetricBar extends StatelessWidget {
  const _CityMetricBar({
    required this.label,
    required this.value,
    required this.valueFactor,
    required this.color,
  });

  final String label;
  final int value;
  final double valueFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.chipLabel.copyWith(
              color: GameUiTheme.textMuted,
              fontSize: 9,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: GameUiTheme.bg.withAlpha(118)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: valueFactor.clamp(0.0, 1.0),
                    child: ColoredBox(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: GameUiTheme.textBright,
              fontFamily: GameUiTheme.bodyFont,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFeatures: GameUiTheme.tabularFigures,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.label});

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

List<_MetricItem> _unitMetricItems(
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n,
) {
  final ordered = _orderedUnitCount(viewModel.units);
  return [
    _MetricItem(
      icon: GameIcons.army,
      label: l10n.unitsSection,
      value: '${viewModel.units.length}',
      color: GameUiTheme.gold,
    ),
    _MetricItem(
      icon: GameIcons.move,
      label: l10n.commonReady,
      value: '${viewModel.readyUnitCount}',
      color: GameUiTheme.success,
    ),
    _MetricItem(
      icon: GameIcons.checkCircle,
      label: l10n.empireStatsOrders,
      value: '$ordered',
      color: GameUiTheme.info,
    ),
  ];
}

List<_MetricItem> _cityMetricItems(
  BuildContext context,
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n,
) {
  final totalBuildings = viewModel.cities.fold<int>(
    0,
    (total, city) => total + city.buildings.length,
  );
  final territory = viewModel.cities.fold<int>(
    0,
    (total, city) => total + city.controlledHexes.length + 1,
  );
  final producing = viewModel.cities
      .where((city) => city.productionQueue != null)
      .length;
  final averagePopulation = viewModel.cities.isEmpty
      ? '0'
      : _formatDecimal(
          context,
          viewModel.totalPopulation / viewModel.cities.length,
        );

  return [
    _MetricItem(
      icon: GameIcons.cityFilled,
      label: l10n.commonCities,
      value: '${viewModel.cities.length}',
      color: GameUiTheme.goldLight,
    ),
    _MetricItem(
      icon: GameIcons.population,
      label: l10n.commonPopulation,
      value: '${viewModel.totalPopulation}',
      color: GameUiTheme.resourcesAccent,
    ),
    _MetricItem(
      icon: GameIcons.growth,
      label: l10n.empireStatsAveragePopulation,
      value: averagePopulation,
      color: GameUiTheme.resourcesAccent,
    ),
    _MetricItem(
      icon: GameIcons.city,
      label: l10n.empireStatsTotalBuildings,
      value: '$totalBuildings',
      color: GameUiTheme.info,
    ),
    _MetricItem(
      icon: GameIcons.artifact,
      label: l10n.empireStatsStoredArtifacts,
      value: '${viewModel.storedArtifactCount}',
      color: GameUiTheme.gold,
    ),
    _MetricItem(
      icon: GameIcons.workedHexes,
      label: l10n.empireStatsTerritory,
      value: '$territory',
      color: GameUiTheme.scienceAccent,
    ),
    _MetricItem(
      icon: GameIcons.production,
      label: l10n.empireStatsCitiesProducing,
      value: '$producing/${viewModel.cities.length}',
      color: GameUiTheme.warning,
    ),
  ];
}

List<_ChartDatum> _readinessData(
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n,
) {
  final ordered = _orderedUnitCount(viewModel.units);
  final ready = viewModel.units
      .where((unit) => unit.movementPoints > 0 && !_hasOrders(unit))
      .length;
  final waiting = math.max(0, viewModel.units.length - ordered - ready);
  return [
    _ChartDatum(
      label: l10n.commonReady,
      value: ready,
      color: GameUiTheme.success,
    ),
    _ChartDatum(
      label: l10n.empireStatsOrders,
      value: ordered,
      color: GameUiTheme.info,
    ),
    _ChartDatum(
      label: l10n.empireStatsNoMovement,
      value: waiting,
      color: GameUiTheme.textMuted,
    ),
  ];
}

List<_ChartDatum> _unitCompositionData(
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n,
) {
  final sorted = [...viewModel.unitGroups]
    ..sort((a, b) => b.units.length.compareTo(a.units.length));
  final top = sorted.take(5).toList(growable: false);
  final otherCount = sorted
      .skip(5)
      .fold<int>(0, (total, group) => total + group.units.length);
  final colors = [
    GameUiTheme.gold,
    GameUiTheme.info,
    GameUiTheme.resourcesAccent,
    GameUiTheme.scienceAccent,
    GameUiTheme.warning,
  ];
  return [
    for (var i = 0; i < top.length; i++)
      _ChartDatum(
        label: GameDisplayNames.unitType(l10n, top[i].type),
        value: top[i].units.length,
        color: colors[i % colors.length],
      ),
    if (otherCount > 0)
      _ChartDatum(
        label: l10n.empireStatsOther,
        value: otherCount,
        color: GameUiTheme.textMuted,
      ),
  ];
}

int _orderedUnitCount(List<GameUnit> units) {
  return units.where(_hasOrders).length;
}

bool _hasOrders(GameUnit unit) {
  return UnitTurnActionRules.hasStandingOrders(unit) ||
      unit.workerJob != null ||
      unit.workerAssignment != null;
}

String _formatDecimal(BuildContext context, double value) {
  final text = value.toStringAsFixed(1);
  return Localizations.localeOf(context).languageCode == 'pl'
      ? text.replaceAll('.', ',')
      : text;
}
