import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/frontier_exploration_scorer.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/military_assessment.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

const _militaryAssessment = AiMilitaryAssessment();

bool mctsIsMilitaryType(GameUnitType unitType, AiContext context) =>
    _militaryAssessment.isMilitaryTypeInContext(unitType, context);

bool mctsCanServeAsMilitaryUnit(GameUnit unit, AiContext context) =>
    _militaryAssessment.canServeAsMilitaryUnitInContext(unit, context);

bool mctsCanDiscoverCitySites(
  GameUnit unit, {
  required GameView view,
  required AiContext context,
  bool requireMovement = false,
}) {
  if (unit.isWorking || unit.queuedPath != null) {
    return false;
  }
  if (requireMovement && unit.movementPoints <= 0) return false;
  if (unit.isWorker || unit.type == GameUnitType.settler || unit.hasSettlers) {
    return false;
  }
  if (mctsIsReconUnit(unit)) return true;
  if (!mctsCanServeAsMilitaryUnit(unit, context)) {
    return false;
  }
  return !mctsHasAvailableReconCitySiteScout(view, context.strategicPlan);
}

bool mctsHasAvailableReconCitySiteScout(GameView view, StrategicPlan? plan) {
  for (final unit in view.ownUnits) {
    if (!mctsIsReconUnit(unit) ||
        unit.isWorking ||
        unit.movementPoints <= 0 ||
        unit.queuedPath != null) {
      continue;
    }
    if (plan?.defenses.values.any(
          (defense) => defense.assignedUnitIds.contains(unit.id),
        ) ??
        false) {
      continue;
    }
    if (plan?.frontierClearingAssignments.containsKey(unit.id) ?? false) {
      continue;
    }
    if (plan?.warGoals.any((goal) => goal.assignedUnitIds.contains(unit.id)) ??
        false) {
      continue;
    }
    return true;
  }
  return false;
}

bool mctsIsReconUnit(GameUnit unit) {
  return mctsIsReconType(unit.type);
}

bool mctsIsReconType(GameUnitType type) {
  return switch (type) {
    GameUnitType.scout ||
    GameUnitType.scoutShip ||
    GameUnitType.reconPlane => true,
    _ => false,
  };
}

bool mctsOwnMilitaryNear(
  SimulatedState state,
  int col,
  int row,
  int range,
  AiContext context,
) {
  final target = HexCoordinate(col: col, row: row);
  for (final unit in state.ownUnits) {
    if (!mctsCanServeAsMilitaryUnit(unit, context)) {
      continue;
    }
    final distance = HexDistance.between(
      target,
      HexCoordinate(col: unit.col, row: unit.row),
    );
    if (distance <= range) return true;
  }
  return false;
}

int mctsNearestOwnCityDistance(SimulatedState state, int col, int row) {
  var best = 1 << 30;
  final target = HexCoordinate(col: col, row: row);
  for (final city in state.ownCities) {
    final distance = HexDistance.between(target, city.center.toCoordinate());
    if (distance < best) best = distance;
  }
  return best;
}

int mctsMinDistance(
  HexCoordinate origin,
  HexCoordinate first,
  HexCoordinate second,
) {
  final firstDistance = HexDistance.between(origin, first);
  final secondDistance = HexDistance.between(origin, second);
  return firstDistance < secondDistance ? firstDistance : secondDistance;
}

bool mctsVisibleMilitaryNear(
  SimulatedState state,
  int col,
  int row,
  int range,
  AiContext context,
) {
  final nearest = mctsNearestVisibleMilitaryDistance(state, col, row, context);
  return nearest != null && nearest <= range;
}

int? mctsNearestVisibleMilitaryDistance(
  SimulatedState state,
  int col,
  int row,
  AiContext context,
) {
  final target = HexCoordinate(col: col, row: row);
  int? nearest;
  for (final enemy in state.visibleTargetableEnemyUnits) {
    if (!mctsCanServeAsMilitaryUnit(enemy, context)) continue;
    final distance = HexDistance.between(
      target,
      HexCoordinate(col: enemy.col, row: enemy.row),
    );
    if (nearest == null || distance < nearest) nearest = distance;
  }
  return nearest;
}

double mctsSettlerFrontierScore(SimulatedState state, int col, int row) {
  return const AiFrontierExplorationScorer().genericFrontierScore(
    view: state.view,
    origin: HexCoordinate(col: col, row: row),
  );
}

GameUnit? mctsOwnUnitById(Iterable<GameUnit> units, String unitId) {
  return units.byId(unitId);
}

GameUnit? mctsEnemyAt(Iterable<GameUnit> units, int col, int row) {
  return units.unitAt(col, row);
}

bool mctsIsNearOwnCity(SimulatedState state, int col, int row, int range) {
  final target = HexCoordinate(col: col, row: row);
  for (final city in state.ownCities) {
    if (HexDistance.between(city.center.toCoordinate(), target) <= range) {
      return true;
    }
  }
  return false;
}

int mctsCoreDefenseDeficit({
  required AiEmpireAssessment assessment,
  required SimulatedState state,
  required AiContext context,
}) {
  if (assessment.cityCount <= 0) return 0;
  final defenses = context.strategicPlan?.defenses.values ?? const [];
  final plannedDefensePressure = defenses.any(
    (defense) => defense.threatLevel > 0 || !defense.hasAssignedGarrison,
  );
  final visiblePressure = state.visibleTargetableEnemyUnits.any(
    (enemy) =>
        mctsCanServeAsMilitaryUnit(enemy, context) &&
        mctsIsNearOwnCity(state, enemy.col, enemy.row, 3),
  );
  if (!plannedDefensePressure && !visiblePressure) return 0;

  final target = switch (assessment.cityCount) {
    <= 1 => 2,
    2 => 3,
    _ => assessment.cityCount,
  };
  final deficit = target - assessment.militaryCount;
  return deficit <= 0 ? 0 : deficit.clamp(0, 3).toInt();
}
