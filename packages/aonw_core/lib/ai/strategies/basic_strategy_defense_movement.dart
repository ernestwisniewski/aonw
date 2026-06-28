import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyDefenseMovement {
  const BasicStrategyDefenseMovement();

  bool canHold(GameUnit unit, CombatRuleset ruleset) {
    if (unit.isWorking || unit.queuedPath != null || unit.movementPoints <= 0) {
      return false;
    }
    if (!AiUnitRoles.isMilitaryUnit(unit)) return false;
    final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
    return stats.attack > 0 || stats.defense > 0;
  }

  bool isInArea(GameUnit unit, GameCity city) {
    final unitHex = CityHex(col: unit.col, row: unit.row);
    if (city.center == unitHex || city.controlledHexes.contains(unitHex)) {
      return true;
    }
    return HexDistance.between(
          HexCoordinate(col: unit.col, row: unit.row),
          city.center.toCoordinate(),
        ) <=
        1;
  }

  GameCity? nearestOwnCity(GameUnit unit, GameView view) {
    GameCity? best;
    var bestDistance = 1 << 30;
    final origin = HexCoordinate(col: unit.col, row: unit.row);
    for (final city in view.ownCities) {
      final distance = HexDistance.between(origin, city.center.toCoordinate());
      if (distance < bestDistance ||
          (distance == bestDistance &&
              (best == null || city.id.compareTo(best.id) < 0))) {
        best = city;
        bestDistance = distance;
      }
    }
    return best;
  }

  GameCity? preferredOwnCity(GameUnit unit, GameView view, AiContext context) {
    final cities = preferredOwnCities(unit, view, context);
    return cities.isEmpty ? null : cities.first;
  }

  List<GameCity> preferredOwnCities(
    GameUnit unit,
    GameView view,
    AiContext context, {
    bool threatenedOnly = false,
  }) {
    final defenses = context.strategicPlan?.defenses ?? const {};
    final origin = HexCoordinate(col: unit.col, row: unit.row);
    return [
      for (final city in view.ownCities)
        if (!threatenedOnly || (defenses[city.id]?.threatLevel ?? 0) > 0) city,
    ]..sort((a, b) {
      final aThreat = defenses[a.id]?.threatLevel ?? 0;
      final bThreat = defenses[b.id]?.threatLevel ?? 0;
      final threatPresence = _sortBool(bThreat > 0, aThreat > 0);
      if (threatPresence != 0) return threatPresence;
      final threatCompare = bThreat.compareTo(aThreat);
      if (threatCompare != 0) return threatCompare;
      final distanceCompare = HexDistance.between(
        origin,
        a.center.toCoordinate(),
      ).compareTo(HexDistance.between(origin, b.center.toCoordinate()));
      if (distanceCompare != 0) return distanceCompare;
      return a.id.compareTo(b.id);
    });
  }

  BasicStrategyPlannedDefenseMove? moveFor({
    required GameUnit unit,
    required GameCity city,
    required GameView view,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    final targetHexes =
        <CityHex>{
          city.center,
          ...city.controlledHexes,
          for (final neighbor in HexNeighbors.existingAround(
            city.center.toCoordinate(),
            view.mapData,
          ))
            CityHex(col: neighbor.col, row: neighbor.row),
        }.toList()..sort((a, b) {
          final aDistance = HexDistance.between(
            HexCoordinate(col: unit.col, row: unit.row),
            HexCoordinate(col: a.col, row: a.row),
          );
          final bDistance = HexDistance.between(
            HexCoordinate(col: unit.col, row: unit.row),
            HexCoordinate(col: b.col, row: b.row),
          );
          final distanceCompare = aDistance.compareTo(bDistance);
          if (distanceCompare != 0) return distanceCompare;
          final aCenterDistance = HexDistance.between(
            HexCoordinate(col: a.col, row: a.row),
            city.center.toCoordinate(),
          );
          final bCenterDistance = HexDistance.between(
            HexCoordinate(col: b.col, row: b.row),
            city.center.toCoordinate(),
          );
          final centerCompare = aCenterDistance.compareTo(bCenterDistance);
          if (centerCompare != 0) return centerCompare;
          final colCompare = a.col.compareTo(b.col);
          if (colCompare != 0) return colCompare;
          return a.row.compareTo(b.row);
        });

    UnitMovementPlan? bestPlan;
    for (final hex in targetHexes) {
      if (unit.occupies(hex.col, hex.row)) continue;
      if (occupied.contains(_key(hex.col, hex.row))) continue;
      final tile = view.mapData.tileAt(hex.col, hex.row);
      if (tile == null || !view.visibility.canSeeDynamicAt(hex.col, hex.row)) {
        continue;
      }
      final plan = pathfinder.plan(unit: unit, targetTile: tile);
      if (plan == null) continue;
      if (!UnitMovementFeasibility.canEventuallyTraverse(
        unit: unit,
        plan: plan,
      )) {
        continue;
      }
      if (bestPlan == null || plan.totalCost < bestPlan.totalCost) {
        bestPlan = plan;
      }
    }

    final step = bestPlan?.furthestReachableStep;
    if (bestPlan == null || step == null || unit.occupies(step.col, step.row)) {
      return null;
    }
    return BasicStrategyPlannedDefenseMove(
      command: MoveUnitCommand(unit.id, step.col, step.row),
      reservedHexes: bestPlan.reservedHexes,
    );
  }

  String _key(int col, int row) => '$col:$row';

  int _sortBool(bool a, bool b) => (a ? 1 : 0).compareTo(b ? 1 : 0);
}

final class BasicStrategyPlannedDefenseMove {
  const BasicStrategyPlannedDefenseMove({
    required this.command,
    required this.reservedHexes,
  });

  final MoveUnitCommand command;
  final Set<HexCoordinate> reservedHexes;
}
