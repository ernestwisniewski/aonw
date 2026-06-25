import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/military_assessment.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_defense_movement.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyLastMilitaryReservePlanner {
  const BasicStrategyLastMilitaryReservePlanner({
    this.defenseMovement = const BasicStrategyDefenseMovement(),
    this.militaryAssessment = const AiMilitaryAssessment(),
  });

  final BasicStrategyDefenseMovement defenseMovement;
  final AiMilitaryAssessment militaryAssessment;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    if (view.ownCities.isEmpty) return const [];

    final military = militaryAssessment.ownMilitaryUnits(
      view,
      context.ruleset.combat,
    );
    if (military.length != 1) return const [];

    final unit = military.single;
    if (usedUnitIds.contains(unit.id) ||
        unit.isWorking ||
        unit.queuedPath != null ||
        unit.movementPoints <= 0) {
      return const [];
    }

    final city = _nearestOwnCity(unit, view);
    if (city == null) return const [];

    if (!defenseMovement.isInArea(unit, city)) {
      final occupied = <String>{
        for (final own in view.ownUnits) _key(own.col, own.row),
        for (final enemy in view.visibleEnemyUnits) _key(enemy.col, enemy.row),
        for (final hex in reservedHexes) _key(hex.col, hex.row),
      };
      final pathfinder = UnitMovementPathfinder(
        mapData: context.mapData,
        units: view.movementBlockingUnits,
        canEnterTile: (tile) =>
            view.visibility.canSeeDynamicAt(tile.col, tile.row) &&
            !occupied.contains(_key(tile.col, tile.row)),
      );
      final plannedMove = defenseMovement.moveFor(
        unit: unit,
        city: city,
        view: view,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      return plannedMove == null ? const [] : [plannedMove.command];
    }

    final stats = UnitCombatStats.derive(unit, ruleset: context.ruleset.combat);
    final currentHp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
    if (currentHp < stats.hp ||
        (view.pressureTargetPlayerIds.isEmpty &&
            view.activeHostilePlayerIds.isEmpty &&
            view.recentHostilePlayerIds.isEmpty)) {
      return [FortifyUnitCommand(unit.id)];
    }

    return const [];
  }

  GameCity? _nearestOwnCity(GameUnit unit, GameView view) {
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

  String _key(int col, int row) => '$col:$row';
}
