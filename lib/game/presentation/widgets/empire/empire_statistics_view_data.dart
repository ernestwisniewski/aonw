import 'dart:math' as math;

import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class EmpireMetricItem {
  const EmpireMetricItem({
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

class EmpireChartDatum {
  const EmpireChartDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class EmpireStatisticsViewData {
  const EmpireStatisticsViewData({
    required this.unitMetrics,
    required this.cityMetrics,
    required this.readiness,
    required this.unitComposition,
  });

  final List<EmpireMetricItem> unitMetrics;
  final List<EmpireMetricItem> cityMetrics;
  final List<EmpireChartDatum> readiness;
  final List<EmpireChartDatum> unitComposition;
}

EmpireStatisticsViewData buildEmpireStatisticsViewData({
  required EmpireOverviewViewModel viewModel,
  required AppLocalizations l10n,
  required Locale locale,
}) {
  return EmpireStatisticsViewData(
    unitMetrics: _unitMetricItems(viewModel, l10n),
    cityMetrics: _cityMetricItems(viewModel, l10n, locale),
    readiness: _readinessData(viewModel, l10n),
    unitComposition: _unitCompositionData(viewModel, l10n),
  );
}

List<EmpireMetricItem> _unitMetricItems(
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n,
) {
  return [
    EmpireMetricItem(
      icon: GameIcons.army,
      label: l10n.unitsSection,
      value: '${viewModel.units.length}',
      color: GameUiTheme.gold,
    ),
    EmpireMetricItem(
      icon: GameIcons.move,
      label: l10n.commonReady,
      value: '${viewModel.readyUnitCount}',
      color: GameUiTheme.success,
    ),
    EmpireMetricItem(
      icon: GameIcons.checkCircle,
      label: l10n.empireStatsOrders,
      value: '${_orderedUnitCount(viewModel.units)}',
      color: GameUiTheme.info,
    ),
  ];
}

List<EmpireMetricItem> _cityMetricItems(
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n,
  Locale locale,
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
          locale,
          viewModel.totalPopulation / viewModel.cities.length,
        );
  return [
    ..._cityDemographicMetrics(viewModel, l10n, averagePopulation),
    ..._cityOperationalMetrics(
      viewModel,
      l10n,
      totalBuildings: totalBuildings,
      territory: territory,
      producing: producing,
    ),
  ];
}

List<EmpireMetricItem> _cityDemographicMetrics(
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n,
  String averagePopulation,
) {
  return [
    EmpireMetricItem(
      icon: GameIcons.cityFilled,
      label: l10n.commonCities,
      value: '${viewModel.cities.length}',
      color: GameUiTheme.goldLight,
    ),
    EmpireMetricItem(
      icon: GameIcons.population,
      label: l10n.commonPopulation,
      value: '${viewModel.totalPopulation}',
      color: GameUiTheme.resourcesAccent,
    ),
    EmpireMetricItem(
      icon: GameIcons.growth,
      label: l10n.empireStatsAveragePopulation,
      value: averagePopulation,
      color: GameUiTheme.resourcesAccent,
    ),
  ];
}

List<EmpireMetricItem> _cityOperationalMetrics(
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n, {
  required int totalBuildings,
  required int territory,
  required int producing,
}) {
  return [
    EmpireMetricItem(
      icon: GameIcons.city,
      label: l10n.empireStatsTotalBuildings,
      value: '$totalBuildings',
      color: GameUiTheme.info,
    ),
    EmpireMetricItem(
      icon: GameIcons.artifact,
      label: l10n.empireStatsStoredArtifacts,
      value: '${viewModel.storedArtifactCount}',
      color: GameUiTheme.gold,
    ),
    EmpireMetricItem(
      icon: GameIcons.workedHexes,
      label: l10n.empireStatsTerritory,
      value: '$territory',
      color: GameUiTheme.scienceAccent,
    ),
    EmpireMetricItem(
      icon: GameIcons.production,
      label: l10n.empireStatsCitiesProducing,
      value: '$producing/${viewModel.cities.length}',
      color: GameUiTheme.warning,
    ),
  ];
}

List<EmpireChartDatum> _readinessData(
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n,
) {
  final ordered = _orderedUnitCount(viewModel.units);
  final ready = viewModel.units
      .where((unit) => unit.movementPoints > 0 && !_hasOrders(unit))
      .length;
  final waiting = math.max(0, viewModel.units.length - ordered - ready);
  return [
    EmpireChartDatum(
      label: l10n.commonReady,
      value: ready,
      color: GameUiTheme.success,
    ),
    EmpireChartDatum(
      label: l10n.empireStatsOrders,
      value: ordered,
      color: GameUiTheme.info,
    ),
    EmpireChartDatum(
      label: l10n.empireStatsNoMovement,
      value: waiting,
      color: GameUiTheme.textMuted,
    ),
  ];
}

List<EmpireChartDatum> _unitCompositionData(
  EmpireOverviewViewModel viewModel,
  AppLocalizations l10n,
) {
  final sorted = [...viewModel.unitGroups]
    ..sort((a, b) => b.units.length.compareTo(a.units.length));
  final top = sorted.take(5).toList(growable: false);
  final otherCount = sorted
      .skip(5)
      .fold<int>(0, (total, group) => total + group.units.length);
  const colors = [
    GameUiTheme.gold,
    GameUiTheme.info,
    GameUiTheme.resourcesAccent,
    GameUiTheme.scienceAccent,
    GameUiTheme.warning,
  ];
  return [
    for (var i = 0; i < top.length; i++)
      EmpireChartDatum(
        label: GameDisplayNames.unitType(l10n, top[i].type),
        value: top[i].units.length,
        color: colors[i % colors.length],
      ),
    if (otherCount > 0)
      EmpireChartDatum(
        label: l10n.empireStatsOther,
        value: otherCount,
        color: GameUiTheme.textMuted,
      ),
  ];
}

int _orderedUnitCount(List<GameUnit> units) => units.where(_hasOrders).length;

bool _hasOrders(GameUnit unit) {
  return UnitTurnActionRules.hasStandingOrders(unit) ||
      unit.workerJob != null ||
      unit.workerAssignment != null;
}

String _formatDecimal(Locale locale, double value) {
  final text = value.toStringAsFixed(1);
  return locale.languageCode == 'pl' ? text.replaceAll('.', ',') : text;
}
