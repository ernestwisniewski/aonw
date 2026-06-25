import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class AiProductionCounterPressureScorer {
  const AiProductionCounterPressureScorer();

  double score(GameUnitType candidate, GameView view) {
    var pressure = 0.0;
    for (final enemy in view.visibleTargetableEnemyUnits) {
      pressure += _counterScore(candidate, enemy.type);
    }
    return pressure;
  }

  double weightedScore(
    GameUnitType candidate,
    GameView view, {
    required bool enemyMilitaryPressure,
  }) {
    final pressure = score(candidate, view);
    if (pressure <= 0) return 0.0;
    return pressure * (enemyMilitaryPressure ? 1.15 : 0.75);
  }

  double _counterScore(GameUnitType candidate, GameUnitType enemy) {
    return switch ((candidate, enemy)) {
      (GameUnitType.spearman, GameUnitType.cavalry) => 8.0,
      (GameUnitType.spearman, GameUnitType.tank) => 2.2,
      (GameUnitType.heavyInfantry, GameUnitType.spearman) => 3.6,
      (GameUnitType.heavyInfantry, GameUnitType.warrior) => 2.0,
      (GameUnitType.archer, GameUnitType.warrior) => 1.7,
      (GameUnitType.archer, GameUnitType.spearman) => 1.4,
      (GameUnitType.cavalry, GameUnitType.archer) => 2.4,
      (GameUnitType.tank, GameUnitType.spearman) => 2.6,
      _ => 0.0,
    };
  }
}
