import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_statistics_charts.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_statistics_city_comparison.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_statistics_layout.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_statistics_view_data.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
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
    final data = buildEmpireStatisticsViewData(
      viewModel: viewModel,
      l10n: l10n,
      locale: Localizations.localeOf(context),
    );
    return Column(
      key: const Key('empireStatisticsPanel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmpireStatsHeader(l10n: l10n),
        const SizedBox(height: 10),
        _unitSection(data),
        const SizedBox(height: 14),
        _citySection(data),
      ],
    );
  }

  Widget _unitSection(EmpireStatisticsViewData data) {
    return EmpireStatsGroupBlock(
      icon: GameIcons.army,
      title: l10n.unitsSection,
      accent: GameUiTheme.gold,
      children: [
        EmpireMetricGrid(items: data.unitMetrics, compact: compact),
        const SizedBox(height: 10),
        _unitCharts(data),
      ],
    );
  }

  Widget _unitCharts(EmpireStatisticsViewData data) {
    final readiness = EmpireReadinessCard(
      title: l10n.empireStatsReadinessTitle,
      emptyLabel: l10n.empireStatsEmptyUnits,
      data: data.readiness,
      total: viewModel.units.length,
    );
    final composition = EmpireBarChartCard(
      title: l10n.empireStatsUnitCompositionTitle,
      emptyLabel: l10n.empireStatsEmptyUnits,
      data: data.unitComposition,
    );
    if (compact) {
      return Column(
        children: [readiness, const SizedBox(height: 10), composition],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 260, child: readiness),
        const SizedBox(width: 12),
        Expanded(child: composition),
      ],
    );
  }

  Widget _citySection(EmpireStatisticsViewData data) {
    return EmpireStatsGroupBlock(
      icon: GameIcons.cityFilled,
      title: l10n.commonCities,
      accent: GameUiTheme.resourcesAccent,
      children: [
        EmpireMetricGrid(items: data.cityMetrics, compact: compact),
        const SizedBox(height: 10),
        EmpireCityComparisonCard(
          comparisons: viewModel.cityComparisons,
          l10n: l10n,
        ),
      ],
    );
  }
}
