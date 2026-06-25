import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

enum CityBuildingSortMode {
  recommended,
  fastestImpact,
  bestReturn,
  growth,
  industry,
  science,
  defenseMilitary,
  economy;

  String label(AppLocalizations l10n) => switch (this) {
    CityBuildingSortMode.recommended => l10n.cityBuildingSortRecommended,
    CityBuildingSortMode.fastestImpact => l10n.cityBuildingSortFastestImpact,
    CityBuildingSortMode.bestReturn => l10n.cityBuildingSortBestReturn,
    CityBuildingSortMode.growth => l10n.cityBuildingSortGrowth,
    CityBuildingSortMode.industry => l10n.cityBuildingSortIndustry,
    CityBuildingSortMode.science => l10n.cityBuildingSortScience,
    CityBuildingSortMode.defenseMilitary =>
      l10n.cityBuildingSortDefenseMilitary,
    CityBuildingSortMode.economy => l10n.cityBuildingSortEconomy,
  };
}

class CityBuildingSortProfile {
  const CityBuildingSortProfile({
    required this.title,
    required this.productionCost,
    required this.investedProduction,
    required this.productionPerTurn,
    required this.turnsRemaining,
    required this.metrics,
  });

  final String title;
  final int productionCost;
  final int investedProduction;
  final int productionPerTurn;
  final int? turnsRemaining;
  final CityProductionSortMetrics metrics;
}

abstract final class CityBuildingSorter {
  static const int _unknownTurns = 1 << 30;

  static List<T> sort<T>(
    List<T> items,
    CityBuildingSortMode mode,
    CityBuildingSortProfile Function(T item) profileFor,
  ) {
    if (items.length < 2) return items;
    return [...items]
      ..sort((a, b) => compareProfiles(profileFor(a), profileFor(b), mode));
  }

  static int compareProfiles(
    CityBuildingSortProfile a,
    CityBuildingSortProfile b,
    CityBuildingSortMode mode,
  ) {
    final comparison = switch (mode) {
      CityBuildingSortMode.fastestImpact => _compareInt(
        _turnsForScore(a),
        _turnsForScore(b),
      ),
      _ => _compareInt(_scoreFor(b, mode), _scoreFor(a, mode)),
    };
    if (comparison != 0) return comparison;

    final etaComparison = _compareInt(_turnsForScore(a), _turnsForScore(b));
    if (etaComparison != 0) return etaComparison;
    return a.title.compareTo(b.title);
  }

  static int _scoreFor(
    CityBuildingSortProfile profile,
    CityBuildingSortMode mode,
  ) {
    final metrics = profile.metrics;
    return switch (mode) {
      CityBuildingSortMode.recommended =>
        _bestReturnScore(profile) * 2 +
            _strategicScore(metrics) +
            _speedScore(profile),
      CityBuildingSortMode.fastestImpact => _speedScore(profile),
      CityBuildingSortMode.bestReturn => _bestReturnScore(profile),
      CityBuildingSortMode.growth =>
        metrics.food * 120 +
            metrics.maxControlledHexes * 70 +
            metrics.foodDepositBonusPercent * 5 +
            metrics.gold * 10,
      CityBuildingSortMode.industry =>
        metrics.production * 130 + metrics.food * 10,
      CityBuildingSortMode.science => metrics.science * 140 + metrics.gold * 10,
      CityBuildingSortMode.defenseMilitary =>
        metrics.defense * 120 + metrics.production * 30,
      CityBuildingSortMode.economy =>
        metrics.gold * 120 + metrics.production * 15 + metrics.science * 10,
    };
  }

  static int _bestReturnScore(CityBuildingSortProfile profile) {
    return (_strategicScore(profile.metrics) * 100) ~/ _turnsForScore(profile);
  }

  static int _strategicScore(CityProductionSortMetrics metrics) {
    return metrics.food * 120 +
        metrics.production * 120 +
        metrics.science * 115 +
        metrics.gold * 90 +
        metrics.defense * 75 +
        metrics.maxControlledHexes * 60 +
        metrics.foodDepositBonusPercent * 4;
  }

  static int _speedScore(CityBuildingSortProfile profile) {
    return 1000 ~/ _turnsForScore(profile);
  }

  static int _turnsForScore(CityBuildingSortProfile profile) {
    final turnsRemaining = profile.turnsRemaining;
    if (turnsRemaining != null && turnsRemaining > 0) return turnsRemaining;
    if (profile.productionPerTurn <= 0) return _unknownTurns;

    final remainingCost = profile.productionCost - profile.investedProduction;
    final productionNeeded = remainingCost > 0
        ? remainingCost
        : profile.productionCost;
    if (productionNeeded <= 0) return 1;
    final turns =
        (productionNeeded + profile.productionPerTurn - 1) ~/
        profile.productionPerTurn;
    return turns > 0 ? turns : 1;
  }

  static int _compareInt(int a, int b) => a.compareTo(b);
}
