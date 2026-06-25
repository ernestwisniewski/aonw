import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/game/domain/hex.dart';

const int warFrontBlockerRadius = 4;

bool isOffensiveWarFrontBlocker({
  required GameView view,
  required StrategicPlan? plan,
  required HexCoordinate blockerHex,
  String? unitId,
}) {
  final anchors = offensiveWarFrontAnchors(view, plan, unitId: unitId);
  if (anchors.isEmpty) return false;

  for (final anchor in anchors) {
    if (HexDistance.between(blockerHex, anchor) <= warFrontBlockerRadius) {
      return true;
    }
  }
  return false;
}

List<HexCoordinate> offensiveWarFrontAnchors(
  GameView view,
  StrategicPlan? plan, {
  String? unitId,
}) {
  final anchors = <HexCoordinate>[];
  final targetPlayerIds = <String>{
    ...view.activeHostilePlayerIds,
    ...view.pressureTargetPlayerIds,
  };

  if (plan != null) {
    for (final goal in plan.warGoals) {
      if (goal.kind == WarGoalKind.defend) continue;
      if (unitId != null && !goal.assignedUnitIds.contains(unitId)) continue;
      if (!view.canTargetPlayer(goal.targetPlayerId)) continue;

      targetPlayerIds.add(goal.targetPlayerId);
      anchors.add(goal.targetHex);
      final targetCity = goal.targetCity;
      if (targetCity != null) anchors.add(targetCity.toCoordinate());
    }
  }

  for (final city in view.rememberedTargetableEnemyCities) {
    if (targetPlayerIds.contains(city.ownerPlayerId)) {
      anchors.add(city.center.toCoordinate());
    }
  }
  for (final unit in view.visibleTargetableEnemyUnits) {
    if (targetPlayerIds.contains(unit.ownerPlayerId)) {
      anchors.add(HexCoordinate(col: unit.col, row: unit.row));
    }
  }

  return List.unmodifiable(anchors);
}
