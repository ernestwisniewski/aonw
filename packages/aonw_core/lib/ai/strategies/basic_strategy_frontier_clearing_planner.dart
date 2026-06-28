import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/military_assessment.dart';
import 'package:aonw_core/ai/strategic/frontier_clearing_plan.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyFrontierClearingPlanner {
  const BasicStrategyFrontierClearingPlanner({
    this.militaryAssessment = const AiMilitaryAssessment(),
  });

  final AiMilitaryAssessment militaryAssessment;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    final assignments =
        context.strategicPlan?.frontierClearingAssignments.values.toList() ??
        const <StrategicFrontierClearingAssignment>[];
    if (assignments.isEmpty) return const [];

    final commands = <GameCommand>[];
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
    final sorted = [...assignments]
      ..sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.unitId.compareTo(b.unitId);
      });

    for (final assignment in sorted) {
      if (usedUnitIds.contains(assignment.unitId)) continue;
      final unit = view.ownUnits.byId(assignment.unitId);
      if (unit == null ||
          unit.isWorking ||
          unit.queuedPath != null ||
          unit.movementPoints <= 0) {
        continue;
      }
      final enemy = _visibleEnemyAt(view, assignment.targetHex);
      if (enemy == null || !view.canTargetPlayer(enemy.ownerPlayerId)) {
        continue;
      }

      final action = _frontierClearingAction(
        assignment: assignment,
        unit: unit,
        enemy: enemy,
        view: view,
        context: context,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (action == null) continue;

      commands.add(action.command);
      usedUnitIds.add(unit.id);
      occupied
        ..remove(_key(unit.col, unit.row))
        ..addAll(action.reservedHexes.map((hex) => _key(hex.col, hex.row)));
    }

    return commands;
  }

  ({GameCommand command, Set<HexCoordinate> reservedHexes})?
  _frontierClearingAction({
    required StrategicFrontierClearingAssignment assignment,
    required GameUnit unit,
    required GameUnit enemy,
    required GameView view,
    required AiContext context,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    final stats = UnitCombatStats.derive(unit, ruleset: context.ruleset.combat);
    if (stats.attack <= 0) return null;

    final distance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      assignment.targetHex,
    );
    if (distance <= stats.range) {
      final command = AttackHexCommand(unit.id, enemy.col, enemy.row);
      final evaluation = AiCombatTactics.evaluateAttack(
        view: view,
        context: context,
        command: command,
      );
      if (evaluation != null &&
          AiCombatTactics.shouldConsiderAttack(
            evaluation,
            context,
            protectsCivilian: true,
          )) {
        final currentHp = UnitCombatHealth.currentHp(
          unit,
          effectiveStats: stats,
        );
        final isLastMilitaryReserve = militaryAssessment
            .isLastMilitaryReserveUnit(unit, view, context.ruleset.combat);
        if (!isLastMilitaryReserve ||
            militaryAssessment.lastMilitarySurvivesAttack(
              attacker: unit,
              defender: enemy,
              ruleset: context.ruleset.combat,
              attackerStats: stats,
              defenderStats: UnitCombatStats.derive(
                enemy,
                ruleset: context.ruleset.combat,
              ),
              currentHp: currentHp,
            )) {
          return (command: command, reservedHexes: const <HexCoordinate>{});
        }
      }
    }

    final targetTile = view.mapData.tileAt(
      assignment.targetHex.col,
      assignment.targetHex.row,
    );
    if (targetTile == null) return null;
    final plan = pathfinder.planTowardBlockedTarget(
      unit: unit,
      targetTile: targetTile,
    );
    final step = plan?.furthestReachableStep;
    if (plan == null ||
        !UnitMovementFeasibility.canEventuallyTraverse(
          unit: unit,
          plan: plan,
        ) ||
        step == null ||
        (step.col == unit.col && step.row == unit.row)) {
      return null;
    }

    final afterDistance = HexDistance.between(
      HexCoordinate(col: step.col, row: step.row),
      assignment.targetHex,
    );
    if (afterDistance >= distance) return null;

    return (
      command: MoveUnitCommand(unit.id, step.col, step.row),
      reservedHexes: plan.reservedHexes,
    );
  }

  GameUnit? _visibleEnemyAt(GameView view, HexCoordinate hex) {
    for (final unit in view.visibleEnemyUnits) {
      if (unit.col == hex.col && unit.row == hex.row) return unit;
    }
    return null;
  }

  String _key(int col, int row) => '$col:$row';
}
