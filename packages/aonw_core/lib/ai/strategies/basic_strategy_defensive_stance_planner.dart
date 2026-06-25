import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_defense_movement.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyDefensiveStancePlanner {
  const BasicStrategyDefensiveStancePlanner({
    this.defenseMovement = const BasicStrategyDefenseMovement(),
  });

  final BasicStrategyDefenseMovement defenseMovement;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    final defenses =
        context.strategicPlan?.defenses.values.toList() ?? const [];
    if (defenses.isEmpty) return const [];

    defenses.sort((a, b) {
      final threatCompare = b.threatLevel.compareTo(a.threatLevel);
      if (threatCompare != 0) return threatCompare;
      return a.cityId.compareTo(b.cityId);
    });

    final cityById = {for (final city in view.ownCities) city.id: city};
    final unitById = {for (final unit in view.ownUnits) unit.id: unit};
    final commands = <GameCommand>[];
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

    for (final defense in defenses) {
      final city = cityById[defense.cityId];
      if (city == null) continue;
      for (final unitId in defense.assignedUnitIds) {
        final unit = unitById[unitId];
        if (unit == null || usedUnitIds.contains(unit.id)) continue;
        if (!defenseMovement.canHold(unit, context.ruleset.combat)) continue;

        if (defenseMovement.isInArea(unit, city)) {
          final fortify = _defensiveFortifyFor(
            unit: unit,
            city: city,
            defense: defense,
            view: view,
            context: context,
          );
          if (fortify != null) {
            commands.add(fortify);
            usedUnitIds.add(unit.id);
          } else if (_shouldHoldDefensivePosition(
            unit: unit,
            city: city,
            defense: defense,
            view: view,
            context: context,
          )) {
            usedUnitIds.add(unit.id);
          }
          continue;
        }

        final plannedMove = defenseMovement.moveFor(
          unit: unit,
          city: city,
          view: view,
          occupied: occupied,
          pathfinder: pathfinder,
        );
        if (plannedMove == null) continue;

        final move = plannedMove.command;
        commands.add(move);
        usedUnitIds.add(unit.id);
        occupied
          ..remove(_key(unit.col, unit.row))
          ..addAll(
            plannedMove.reservedHexes.map((hex) => _key(hex.col, hex.row)),
          );
        reservedHexes.addAll(plannedMove.reservedHexes);
      }
    }

    return List.unmodifiable(commands);
  }

  bool _shouldHoldDefensivePosition({
    required GameUnit unit,
    required GameCity city,
    required StrategicDefenseAssignment defense,
    required GameView view,
    required AiContext context,
  }) {
    final stats = UnitCombatStats.derive(unit, ruleset: context.ruleset.combat);
    final hp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
    final damaged = hp < stats.hp;
    return damaged ||
        unit.isFortified ||
        unit.movementPoints <= 0 ||
        defense.threatLevel > 0 ||
        _visibleThreatNearCity(city, view);
  }

  FortifyUnitCommand? _defensiveFortifyFor({
    required GameUnit unit,
    required GameCity city,
    required StrategicDefenseAssignment defense,
    required GameView view,
    required AiContext context,
  }) {
    if (unit.isFortified || unit.movementPoints <= 0) return null;
    final damaged = UnitFortificationRules.canHeal(
      unit,
      ruleset: context.ruleset.combat,
    );
    final threatened =
        defense.threatLevel > 0 || _visibleThreatNearCity(city, view);
    if (!damaged && !threatened) {
      return null;
    }
    return FortifyUnitCommand(unit.id);
  }

  bool _visibleThreatNearCity(GameCity city, GameView view) {
    for (final enemy in view.visibleTargetableEnemyUnits) {
      if (!AiUnitRoles.isMilitaryUnit(enemy)) continue;
      final distance = HexDistance.between(
        HexCoordinate(col: enemy.col, row: enemy.row),
        city.center.toCoordinate(),
      );
      if (distance <= 2) return true;
    }
    return false;
  }

  String _key(int col, int row) => '$col:$row';
}
