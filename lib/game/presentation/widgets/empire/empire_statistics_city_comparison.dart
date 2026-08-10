import 'dart:math' as math;

import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_statistics_charts.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class EmpireCityComparisonCard extends StatelessWidget {
  const EmpireCityComparisonCard({
    required this.comparisons,
    required this.l10n,
    super.key,
  });

  final List<EmpireCityComparison> comparisons;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final visibleCities = comparisons.take(6).toList(growable: false);
    final maximums = _CityMetricMaximums.from(visibleCities);
    return EmpireChartShell(
      title: l10n.empireStatsCityComparisonTitle,
      child: visibleCities.isEmpty
          ? EmpireChartEmpty(label: l10n.empireStatsEmptyCities)
          : Column(
              children: [
                for (var i = 0; i < visibleCities.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _CityComparisonRow(
                    comparison: visibleCities[i],
                    maximums: maximums,
                    l10n: l10n,
                  ),
                ],
              ],
            ),
    );
  }
}

class _CityMetricMaximums {
  const _CityMetricMaximums({
    required this.population,
    required this.production,
    required this.food,
    required this.gold,
  });

  factory _CityMetricMaximums.from(List<EmpireCityComparison> cities) {
    return _CityMetricMaximums(
      population: cities.fold(0, (max, city) => math.max(max, city.population)),
      production: cities.fold(0, (max, city) => math.max(max, city.production)),
      food: cities.fold(0, (max, city) => math.max(max, city.food)),
      gold: cities.fold(0, (max, city) => math.max(max, city.gold)),
    );
  }

  final int population;
  final int production;
  final int food;
  final int gold;
}

class _CityComparisonRow extends StatelessWidget {
  const _CityComparisonRow({
    required this.comparison,
    required this.maximums,
    required this.l10n,
  });

  final EmpireCityComparison comparison;
  final _CityMetricMaximums maximums;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
          builder: (context, constraints) => _metricGrid(constraints.maxWidth),
        ),
      ],
    );
  }

  Widget _metricGrid(double availableWidth) {
    const spacing = 8.0;
    final metricWidth = availableWidth >= 300
        ? (availableWidth - spacing) / 2
        : availableWidth;
    return Wrap(
      spacing: spacing,
      runSpacing: 4,
      children: [
        _metric(
          width: metricWidth,
          label: l10n.empireStatsMetricPopulation,
          value: comparison.population,
          maximum: maximums.population,
          color: GameUiTheme.resourcesAccent,
        ),
        _metric(
          width: metricWidth,
          label: l10n.empireStatsMetricProduction,
          value: comparison.production,
          maximum: maximums.production,
          color: GameUiTheme.warning,
        ),
        _metric(
          width: metricWidth,
          label: l10n.empireStatsMetricFood,
          value: comparison.food,
          maximum: maximums.food,
          color: GameUiTheme.success,
        ),
        _metric(
          width: metricWidth,
          label: l10n.empireStatsMetricGold,
          value: comparison.gold,
          maximum: maximums.gold,
          color: GameUiTheme.goldLight,
        ),
      ],
    );
  }

  Widget _metric({
    required double width,
    required String label,
    required int value,
    required int maximum,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: _CityMetricBar(
        label: label,
        value: value,
        valueFactor: maximum <= 0 ? 0 : value / maximum,
        color: color,
      ),
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
        Expanded(child: _bar()),
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

  Widget _bar() {
    return ClipRRect(
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
    );
  }
}
