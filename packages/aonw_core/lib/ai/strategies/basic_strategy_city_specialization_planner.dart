import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';

final class BasicStrategyCitySpecializationPlanner {
  const BasicStrategyCitySpecializationPlanner();

  static const double _respecializationThreshold = 1.25;

  List<SetCitySpecializationCommand> plan(GameView view, AiContext context) {
    if (!view.ownResearch.hasUnlocked(TechnologyId.specialization)) {
      return const [];
    }

    return [
      for (final city in view.ownCities)
        if (_pickCitySpecialization(
              city: city,
              view: view,
              weights: context.effectiveWeights,
            )
            case final specialization?)
          if (specialization != city.specialization)
            SetCitySpecializationCommand(city.id, specialization),
    ];
  }

  CitySpecializationType? _pickCitySpecialization({
    required GameCity city,
    required GameView view,
    required PersonaWeights weights,
  }) {
    final maxWeight = [
      weights.aggression,
      weights.expansion,
      weights.economy,
      weights.science,
    ].reduce((a, b) => a > b ? a : b);

    final scores = <CitySpecializationType, double>{
      CitySpecializationType.industry: maxWeight <= 1.05 ? 1.2 : 1.0,
      CitySpecializationType.military: weights.aggression,
      CitySpecializationType.growth: weights.expansion,
      CitySpecializationType.commerce: weights.economy,
      CitySpecializationType.science: weights.science,
    };

    _mergeScores(
      scores,
      CitySpecializationScorer.localScores(
        city: city,
        mapData: view.mapData,
        research: view.research,
      ),
    );
    _addThreatScores(scores: scores, city: city, view: view);

    scores.removeWhere(
      (type, _) =>
          !CitySpecializationRules.hasRequiredBuilding(city.buildings, type),
    );
    if (scores.isEmpty) return null;

    final best = _bestSpecialization(scores);
    final current = city.specialization;
    if (current == null || current == best) return best;

    final currentScore = scores[current];
    if (currentScore == null) return best;
    final bestScore = scores[best] ?? 0;
    if (bestScore - currentScore < _respecializationThreshold) {
      return current;
    }
    return best;
  }

  void _addThreatScores({
    required Map<CitySpecializationType, double> scores,
    required GameCity city,
    required GameView view,
  }) {
    if (view.pendingCityAttackThreats.any(
      (threat) => threat.cityId == city.id,
    )) {
      _add(scores, CitySpecializationType.military, 2.0);
    }

    final center = city.center.toCoordinate();
    for (final enemy in view.visibleTargetableEnemyUnits) {
      final enemyHex = HexCoordinate(col: enemy.col, row: enemy.row);
      if (HexDistance.between(center, enemyHex) <= 3) {
        _add(scores, CitySpecializationType.military, 1.0);
        return;
      }
    }
  }

  CitySpecializationType _bestSpecialization(
    Map<CitySpecializationType, double> scores,
  ) {
    const preferenceOrder = [
      CitySpecializationType.industry,
      CitySpecializationType.military,
      CitySpecializationType.growth,
      CitySpecializationType.commerce,
      CitySpecializationType.science,
    ];

    var best = preferenceOrder.first;
    var bestScore = scores[best] ?? 0;
    for (final type in preferenceOrder.skip(1)) {
      final score = scores[type] ?? 0;
      if (score > bestScore) {
        best = type;
        bestScore = score;
      }
    }
    return best;
  }

  void _mergeScores(
    Map<CitySpecializationType, double> scores,
    Map<CitySpecializationType, double> localScores,
  ) {
    for (final entry in localScores.entries) {
      _add(scores, entry.key, entry.value);
    }
  }

  void _add(
    Map<CitySpecializationType, double> scores,
    CitySpecializationType type,
    double value,
  ) {
    scores[type] = (scores[type] ?? 0) + value;
  }
}
