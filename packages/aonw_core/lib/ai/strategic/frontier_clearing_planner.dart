import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/city_site_planner.dart';
import 'package:aonw_core/ai/strategic/frontier_clearing_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

class FrontierClearingPlanner {
  const FrontierClearingPlanner();

  static const int blockedFounderRadius = 5;
  static const int minimumUnreservedMilitary = 1;

  FrontierClearingPlan compute({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required CitySitePlan citySitePlan,
    Set<String> reservedUnitIds = const {},
  }) {
    if (view.ownCities.isEmpty) return FrontierClearingPlan.empty;

    final availableMilitary = [
      for (final unit in view.ownUnits)
        if (_canClearFrontier(unit, context, reservedUnitIds)) unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
    if (availableMilitary.length < minimumUnreservedMilitary) {
      return FrontierClearingPlan.empty;
    }

    final visibleMilitary = [
      for (final enemy in view.visibleTargetableEnemyUnits)
        if (_isMilitaryUnit(enemy, context)) enemy,
    ];
    if (visibleMilitary.isEmpty) return FrontierClearingPlan.empty;

    final founders = [
      for (final unit in view.ownUnits)
        if (_needsClearingSupport(
          unit,
          citySitePlan: citySitePlan,
          enemies: visibleMilitary,
        ))
          unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
    if (founders.isEmpty) return FrontierClearingPlan.empty;

    final assignments = <String, StrategicFrontierClearingAssignment>{};
    final usedMilitaryIds = <String>{};
    for (final founder in founders) {
      final target = _frontierBlockerFor(
        founder: founder,
        enemies: visibleMilitary,
      );
      if (target == null) continue;

      final clearingUnit = _clearingUnitFor(
        target: target,
        units: availableMilitary.where(
          (unit) => !usedMilitaryIds.contains(unit.id),
        ),
      );
      if (clearingUnit == null) continue;

      usedMilitaryIds.add(clearingUnit.id);
      final founderDistance = HexDistance.between(
        HexCoordinate(col: founder.col, row: founder.row),
        HexCoordinate(col: target.col, row: target.row),
      );
      assignments[clearingUnit.id] = StrategicFrontierClearingAssignment(
        unitId: clearingUnit.id,
        founderId: founder.id,
        targetPlayerId: target.ownerPlayerId,
        targetHex: HexCoordinate(col: target.col, row: target.row),
        founderDistance: founderDistance,
        priority:
            (blockedFounderRadius - founderDistance).clamp(0, 5).toDouble() +
            assessment.cityCount * 0.25,
      );
    }

    return assignments.isEmpty
        ? FrontierClearingPlan.empty
        : FrontierClearingPlan(assignments: assignments);
  }

  bool _needsClearingSupport(
    GameUnit unit, {
    required CitySitePlan citySitePlan,
    required Iterable<GameUnit> enemies,
  }) {
    if (!CityFoundingRules.canFoundCityWith(unit)) return false;
    if (unit.isWorking || unit.queuedPath != null) return false;
    final assignment = citySitePlan.settlerAssignments[unit.id];
    if (assignment == null) return true;

    final founderHex = HexCoordinate(col: unit.col, row: unit.row);
    final assignmentHex = assignment.toCoordinate();
    for (final enemy in enemies) {
      final enemyHex = HexCoordinate(col: enemy.col, row: enemy.row);
      if (HexDistance.between(founderHex, enemyHex) <= 3) return true;
      if (HexDistance.between(assignmentHex, enemyHex) <= 3) return true;
    }
    return false;
  }

  bool _canClearFrontier(
    GameUnit unit,
    AiContext context,
    Set<String> reservedUnitIds,
  ) {
    if (reservedUnitIds.contains(unit.id)) return false;
    if (unit.isWorking || unit.queuedPath != null || unit.movementPoints <= 0) {
      return false;
    }
    if (!_isMilitaryUnit(unit, context)) return false;
    final stats = UnitCombatStats.derive(unit, ruleset: context.ruleset.combat);
    if (stats.attack <= 0) return false;
    final hp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
    return hp >= (stats.hp * 0.6).ceil();
  }

  GameUnit? _frontierBlockerFor({
    required GameUnit founder,
    required Iterable<GameUnit> enemies,
  }) {
    final founderHex = HexCoordinate(col: founder.col, row: founder.row);
    final candidates = <({GameUnit enemy, int distance})>[];
    for (final enemy in enemies) {
      final distance = HexDistance.between(
        founderHex,
        HexCoordinate(col: enemy.col, row: enemy.row),
      );
      if (distance > blockedFounderRadius) continue;
      candidates.add((enemy: enemy, distance: distance));
    }
    candidates.sort((a, b) {
      final distanceCompare = a.distance.compareTo(b.distance);
      if (distanceCompare != 0) return distanceCompare;
      return a.enemy.id.compareTo(b.enemy.id);
    });
    return candidates.isEmpty ? null : candidates.first.enemy;
  }

  GameUnit? _clearingUnitFor({
    required GameUnit target,
    required Iterable<GameUnit> units,
  }) {
    final targetHex = HexCoordinate(col: target.col, row: target.row);
    final candidates = <({GameUnit unit, int distance})>[];
    for (final unit in units) {
      final distance = HexDistance.between(
        HexCoordinate(col: unit.col, row: unit.row),
        targetHex,
      );
      candidates.add((unit: unit, distance: distance));
    }
    candidates.sort((a, b) {
      final distanceCompare = a.distance.compareTo(b.distance);
      if (distanceCompare != 0) return distanceCompare;
      return a.unit.id.compareTo(b.unit.id);
    });
    return candidates.isEmpty ? null : candidates.first.unit;
  }

  bool _isMilitaryUnit(GameUnit unit, AiContext context) {
    if (unit.isWorker ||
        unit.type == GameUnitType.settler ||
        unit.hasSettlers) {
      return false;
    }
    final stats = UnitCombatStats.derive(unit, ruleset: context.ruleset.combat);
    return stats.attack > 0 || stats.defense > 0;
  }
}
