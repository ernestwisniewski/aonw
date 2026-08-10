import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class CityYieldSourceDatum {
  const CityYieldSourceDatum({
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

class CityYieldSourceData {
  const CityYieldSourceData({required this.production, required this.science});

  final List<CityYieldSourceDatum> production;
  final List<CityYieldSourceDatum> science;

  int get productionTotal =>
      production.fold(0, (total, item) => total + item.value);
}

CityYieldSourceData buildCityYieldSourceData(
  CityYieldBreakdownViewModel model,
  CityYieldBreakdownText text,
) {
  return CityYieldSourceData(
    production: _productionSources(model.rows, text),
    science: _scienceSources(model.scienceRows, text),
  );
}

List<CityYieldSourceDatum> _productionSources(
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
        CityYieldSourceDatum(
          label: bucket.label(text),
          detail: _detailFor(bucket, details[bucket] ?? const [], text),
          value: values[bucket]!,
          color: bucket.color,
        ),
  ];
}

List<CityYieldSourceDatum> _scienceSources(
  List<CityScienceBreakdownRow> rows,
  CityYieldBreakdownText text,
) {
  return [
    for (final row in rows)
      if (row.value > 0)
        CityYieldSourceDatum(
          label: row.label,
          detail: row.detail,
          value: row.value,
          color: _scienceColorFor(row.label, text),
        ),
  ];
}

_SourceBucket _bucketFor(String label, CityYieldBreakdownText text) {
  final bucketsByLabel = {
    text.center: _SourceBucket.fields,
    text.populationFields: _SourceBucket.fields,
    text.workers: _SourceBucket.improvements,
    text.improvements: _SourceBucket.improvements,
    text.buildings: _SourceBucket.buildings,
    text.technologies: _SourceBucket.technologies,
    text.specialization: _SourceBucket.specialization,
    text.goldMultiplier: _SourceBucket.multipliers,
  };
  return bucketsByLabel[label] ?? _SourceBucket.other;
}

String _detailFor(
  _SourceBucket bucket,
  List<String> labels,
  CityYieldBreakdownText text,
) {
  final label = bucket.label(text);
  return labels.isEmpty ? label : '$label: ${labels.join(' + ')}';
}

Color _scienceColorFor(String label, CityYieldBreakdownText text) {
  final colorsByLabel = {
    text.baseScience: GameUiTheme.scienceAccent,
    text.buildings: GameUiTheme.gold,
    text.specialization: GameUiTheme.resourcesAccent,
    text.technologies: GameUiTheme.info,
    text.researchProject: GameUiTheme.warning,
  };
  return colorsByLabel[label] ?? GameUiTheme.textSecondary;
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
