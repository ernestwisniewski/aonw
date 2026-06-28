import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_defense_movement.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_garrison_rules.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyGarrisonReservationPlanner {
  const BasicStrategyGarrisonReservationPlanner({
    this.defenseMovement = const BasicStrategyDefenseMovement(),
    this.garrisonRules = const BasicStrategyGarrisonRules(),
  });

  final BasicStrategyDefenseMovement defenseMovement;
  final BasicStrategyGarrisonRules garrisonRules;

  Set<String> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds, [
    Set<HexCoordinate> reservedHexes = const <HexCoordinate>{},
  ]) {
    if (view.ownCities.isEmpty || view.ownUnits.isEmpty) {
      return const <String>{};
    }

    final nonDefenseAssignedUnitIds = _nonDefenseAssignedUnitIds(context);
    final needs = garrisonRules.cityNeeds(view, context);
    final reservedUnitIds = <String>{};
    final occupied = <String>{
      for (final unit in view.ownUnits) _key(unit.col, unit.row),
      for (final unit in view.visibleEnemyUnits) _key(unit.col, unit.row),
      for (final hex in reservedHexes) _key(hex.col, hex.row),
    };
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: view.movementBlockingUnits,
      canEnterTile: (tile) =>
          view.visibility.canSeeDynamicAt(tile.col, tile.row) &&
          !occupied.contains(_key(tile.col, tile.row)),
    );

    for (final need in needs) {
      final anchoredCount = _anchoredUnavailableDefenderCount(
        need.city,
        view,
        context,
        usedUnitIds,
      );
      var remaining = need.requiredCount - anchoredCount;
      if (remaining <= 0) continue;

      final candidates = _candidateDefenders(
        city: need.city,
        view: view,
        context: context,
        usedUnitIds: usedUnitIds,
        reservedUnitIds: reservedUnitIds,
        excludedUnitIds: need.threatLevel > 0
            ? const <String>{}
            : nonDefenseAssignedUnitIds,
        preferredUnitIds: need.preferredUnitIds,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      for (final unit in candidates) {
        if (remaining == 0) break;
        reservedUnitIds.add(unit.id);
        remaining -= 1;
      }
    }

    return Set.unmodifiable(reservedUnitIds);
  }

  int _anchoredUnavailableDefenderCount(
    GameCity city,
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
  ) {
    var count = 0;
    for (final unit in view.ownUnits) {
      if (usedUnitIds.contains(unit.id)) continue;
      if (unit.movementPoints > 0) continue;
      if (!garrisonRules.canServeAsDefender(unit, context.ruleset.combat)) {
        continue;
      }
      if (defenseMovement.isInArea(unit, city)) count += 1;
    }
    return count;
  }

  List<GameUnit> _candidateDefenders({
    required GameCity city,
    required GameView view,
    required AiContext context,
    required Set<String> usedUnitIds,
    required Set<String> reservedUnitIds,
    required Set<String> excludedUnitIds,
    required Set<String> preferredUnitIds,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    final cityCenter = city.center.toCoordinate();
    final units =
        [
          for (final unit in view.ownUnits)
            if (!usedUnitIds.contains(unit.id) &&
                !reservedUnitIds.contains(unit.id) &&
                !excludedUnitIds.contains(unit.id) &&
                unit.movementPoints > 0 &&
                garrisonRules.canServeAsDefender(
                  unit,
                  context.ruleset.combat,
                ) &&
                _canAnchorOrReachCityArea(
                  unit: unit,
                  city: city,
                  view: view,
                  occupied: occupied,
                  pathfinder: pathfinder,
                ))
              unit,
        ]..sort((a, b) {
          final preferredCompare = _sortBool(
            preferredUnitIds.contains(b.id),
            preferredUnitIds.contains(a.id),
          );
          if (preferredCompare != 0) return preferredCompare;
          final areaCompare = _sortBool(
            defenseMovement.isInArea(b, city),
            defenseMovement.isInArea(a, city),
          );
          if (areaCompare != 0) return areaCompare;
          final reconCompare = _sortBool(
            AiUnitRoles.isReconUnit(a),
            AiUnitRoles.isReconUnit(b),
          );
          if (reconCompare != 0) return reconCompare;
          final distanceCompare =
              HexDistance.between(
                HexCoordinate(col: a.col, row: a.row),
                cityCenter,
              ).compareTo(
                HexDistance.between(
                  HexCoordinate(col: b.col, row: b.row),
                  cityCenter,
                ),
              );
          if (distanceCompare != 0) return distanceCompare;
          return a.id.compareTo(b.id);
        });
    return units;
  }

  bool _canAnchorOrReachCityArea({
    required GameUnit unit,
    required GameCity city,
    required GameView view,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    if (defenseMovement.isInArea(unit, city)) return true;
    return defenseMovement.moveFor(
          unit: unit,
          city: city,
          view: view,
          occupied: occupied,
          pathfinder: pathfinder,
        ) !=
        null;
  }

  Set<String> _nonDefenseAssignedUnitIds(AiContext context) {
    final plan = context.strategicPlan;
    if (plan == null) return const <String>{};
    return {
      ...plan.frontierClearingAssignments.keys,
      for (final goal in plan.warGoals)
        if (goal.kind != WarGoalKind.defend) ...goal.assignedUnitIds,
    };
  }

  int _sortBool(bool a, bool b) => (a ? 1 : 0).compareTo(b ? 1 : 0);

  String _key(int col, int row) => '$col:$row';
}
