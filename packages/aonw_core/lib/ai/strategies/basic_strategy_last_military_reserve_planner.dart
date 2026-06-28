import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/military_assessment.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_defense_movement.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_garrison_rules.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyLastMilitaryReservePlanner {
  const BasicStrategyLastMilitaryReservePlanner({
    this.defenseMovement = const BasicStrategyDefenseMovement(),
    this.garrisonRules = const BasicStrategyGarrisonRules(),
    this.militaryAssessment = const AiMilitaryAssessment(),
  });

  final BasicStrategyDefenseMovement defenseMovement;
  final BasicStrategyGarrisonRules garrisonRules;
  final AiMilitaryAssessment militaryAssessment;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    if (view.ownCities.isEmpty) return const [];

    final commands = <GameCommand>[];
    final claimedUnitIds = <String>{};
    final localUsedUnitIds = {...usedUnitIds};
    final localReservedHexes = {...reservedHexes};
    final occupied = <String>{
      for (final own in view.ownUnits) _key(own.col, own.row),
      for (final enemy in view.visibleEnemyUnits) _key(enemy.col, enemy.row),
      for (final hex in localReservedHexes) _key(hex.col, hex.row),
    };
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: view.movementBlockingUnits,
      canEnterTile: (tile) =>
          view.visibility.canSeeDynamicAt(tile.col, tile.row) &&
          !occupied.contains(_key(tile.col, tile.row)),
    );
    final cityNeeds = garrisonRules.cityNeeds(view, context);

    for (final need in cityNeeds) {
      var remaining =
          need.requiredCount -
          _inactiveOrCommittedDefenderCount(
            need: need,
            view: view,
            context: context,
            usedUnitIds: localUsedUnitIds,
          );
      if (remaining <= 0) continue;

      for (final unit in _readyDefendersInArea(
        need: need,
        view: view,
        context: context,
        usedUnitIds: localUsedUnitIds,
        claimedUnitIds: claimedUnitIds,
      )) {
        if (remaining <= 0) break;
        claimedUnitIds.add(unit.id);
        localUsedUnitIds.add(unit.id);
        remaining -= 1;
        if (!unit.isFortified) {
          commands.add(FortifyUnitCommand(unit.id));
        }
      }
      if (remaining <= 0) continue;

      for (final unit in _nearestReadyDefenders(
        need: need,
        view: view,
        context: context,
        usedUnitIds: localUsedUnitIds,
        claimedUnitIds: claimedUnitIds,
      )) {
        if (remaining <= 0) break;
        final plannedMove = defenseMovement.moveFor(
          unit: unit,
          city: need.city,
          view: view,
          occupied: occupied,
          pathfinder: pathfinder,
        );
        if (plannedMove == null) continue;

        commands.add(plannedMove.command);
        claimedUnitIds.add(unit.id);
        localUsedUnitIds.add(unit.id);
        occupied
          ..remove(_key(unit.col, unit.row))
          ..addAll(
            plannedMove.reservedHexes.map((hex) => _key(hex.col, hex.row)),
          );
        localReservedHexes.addAll(plannedMove.reservedHexes);
        remaining -= 1;
      }
    }

    return List.unmodifiable(commands);
  }

  int _inactiveOrCommittedDefenderCount({
    required BasicStrategyGarrisonNeed need,
    required GameView view,
    required AiContext context,
    required Set<String> usedUnitIds,
  }) {
    var count = 0;
    for (final unit in view.ownUnits) {
      if (!defenseMovement.isInArea(unit, need.city)) continue;
      if (!garrisonRules.canServeAsDefender(unit, context.ruleset.combat)) {
        continue;
      }
      if (usedUnitIds.contains(unit.id) || unit.movementPoints <= 0) {
        count += 1;
      }
    }
    return count;
  }

  List<GameUnit> _readyDefendersInArea({
    required BasicStrategyGarrisonNeed need,
    required GameView view,
    required AiContext context,
    required Set<String> usedUnitIds,
    required Set<String> claimedUnitIds,
  }) {
    return [
      for (final unit in view.ownUnits)
        if (!usedUnitIds.contains(unit.id) &&
            !claimedUnitIds.contains(unit.id) &&
            unit.movementPoints > 0 &&
            garrisonRules.canServeAsDefender(unit, context.ruleset.combat) &&
            defenseMovement.isInArea(unit, need.city))
          unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
  }

  List<GameUnit> _nearestReadyDefenders({
    required BasicStrategyGarrisonNeed need,
    required GameView view,
    required AiContext context,
    required Set<String> usedUnitIds,
    required Set<String> claimedUnitIds,
  }) {
    final cityCenter = need.city.center.toCoordinate();
    return [
      for (final unit in militaryAssessment.ownMilitaryUnits(
        view,
        context.ruleset.combat,
      ))
        if (!usedUnitIds.contains(unit.id) &&
            !claimedUnitIds.contains(unit.id) &&
            unit.movementPoints > 0 &&
            garrisonRules.canServeAsDefender(unit, context.ruleset.combat))
          unit,
    ]..sort((a, b) {
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
  }

  String _key(int col, int row) => '$col:$row';
}
