import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/hex.dart';

final class BasicStrategyMilitaryAwareness {
  const BasicStrategyMilitaryAwareness();

  int? nearestVisibleEnemyMilitaryDistance(
    HexCoordinate target,
    GameView view,
  ) {
    int? nearest;
    for (final enemy in view.visibleTargetableEnemyUnits) {
      if (!AiUnitRoles.isMilitaryUnit(enemy)) continue;
      final distance = HexDistance.between(
        target,
        HexCoordinate(col: enemy.col, row: enemy.row),
      );
      if (nearest == null || distance < nearest) nearest = distance;
    }
    return nearest;
  }

  bool ownMilitaryNear(HexCoordinate target, GameView view, int maxDistance) {
    for (final own in view.ownUnits) {
      if (!AiUnitRoles.isMilitaryUnit(own)) continue;
      final distance = HexDistance.between(
        target,
        HexCoordinate(col: own.col, row: own.row),
      );
      if (distance <= maxDistance) return true;
    }
    return false;
  }

  Map<String, StrategicDefenseAssignment> defenseByUnitId(AiContext context) {
    final byUnitId = <String, StrategicDefenseAssignment>{};
    final defenses = context.strategicPlan?.defenses.values ?? const [];
    for (final defense in defenses) {
      for (final unitId in defense.assignedUnitIds) {
        byUnitId.putIfAbsent(unitId, () => defense);
      }
    }
    return byUnitId;
  }
}
