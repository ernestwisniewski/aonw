import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/hex.dart';

final class BasicStrategyCityAssaultPlanner {
  const BasicStrategyCityAssaultPlanner();

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
  ) {
    final warGoals =
        context.strategicPlan?.warGoals
            .where((goal) => goal.kind != WarGoalKind.defend)
            .toList() ??
        const <WarGoal>[];
    final pressureTargetPlayerIds = {
      ...view.activeHostilePlayerIds,
      ...view.pressureTargetPlayerIds,
      ...view.recentHostilePlayerIds,
      for (final goal in warGoals) goal.targetPlayerId,
    };
    if ((warGoals.isEmpty && pressureTargetPlayerIds.isEmpty) ||
        view.rememberedTargetableEnemyCities.isEmpty) {
      return const [];
    }

    final assignedGoalByUnitId = <String, List<WarGoal>>{};
    for (final goal in warGoals) {
      if (!view.canTargetPlayer(goal.targetPlayerId)) continue;
      for (final unitId in goal.assignedUnitIds) {
        assignedGoalByUnitId.putIfAbsent(unitId, () => []).add(goal);
      }
    }

    final candidates = <_CityAssaultCandidate>[];
    final units = [...view.ownUnits]..sort((a, b) => a.id.compareTo(b.id));
    for (final unit in units) {
      if (usedUnitIds.contains(unit.id) ||
          unit.isWorking ||
          unit.movementPoints <= 0 ||
          !AiUnitRoles.isMilitaryUnit(unit)) {
        continue;
      }
      final goals = assignedGoalByUnitId[unit.id] ?? const <WarGoal>[];
      final stats = UnitCombatStats.derive(
        unit,
        ruleset: context.ruleset.combat,
      );
      if (stats.attack <= 0) continue;
      final origin = HexCoordinate(col: unit.col, row: unit.row);

      for (final city in view.rememberedTargetableEnemyCities) {
        final cityHex = city.center.toCoordinate();
        final matchingGoals = [
          for (final goal in goals)
            if (city.ownerPlayerId == goal.targetPlayerId &&
                warGoalEngagesHex(goal, cityHex))
              goal,
        ];
        final pressureTarget = pressureTargetPlayerIds.contains(
          city.ownerPlayerId,
        );
        if (matchingGoals.isEmpty && !pressureTarget) continue;
        final centerOccupant = view.movementBlockingUnits.unitAt(
          city.center.col,
          city.center.row,
        );
        if (centerOccupant != null && centerOccupant.id != unit.id) {
          continue;
        }
        if (HexDistance.between(origin, cityHex) > stats.range) continue;
        final command = AttackHexCommand(
          unit.id,
          city.center.col,
          city.center.row,
        );
        final evaluation = AiCombatTactics.evaluateCityAttack(
          view: view,
          context: context,
          command: command,
        );
        if (evaluation == null ||
            !AiCombatTactics.shouldConsiderCityAttack(
              evaluation,
              context,
              matchesWarGoal: true,
            )) {
          continue;
        }
        final goalPriority = matchingGoals.isEmpty
            ? 6.0
            : matchingGoals
                  .map((goal) => goal.priority)
                  .reduce((a, b) => a > b ? a : b);
        final targetDistance = matchingGoals.isEmpty
            ? 0
            : matchingGoals
                  .map((goal) => HexDistance.between(cityHex, goal.targetHex))
                  .reduce((a, b) => a < b ? a : b);
        final score =
            goalPriority * 100 +
            evaluation.defenderDamage * 8 -
            evaluation.attackerDamage * 6 -
            targetDistance +
            (evaluation.cityDefeated ? 180 : 0);
        candidates.add(
          _CityAssaultCandidate(
            command: command,
            unitId: unit.id,
            cityHex: cityHex,
            score: score,
          ),
        );
      }
    }
    if (candidates.isEmpty) return const [];

    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final unitCompare = a.unitId.compareTo(b.unitId);
      if (unitCompare != 0) return unitCompare;
      final colCompare = a.cityHex.col.compareTo(b.cityHex.col);
      if (colCompare != 0) return colCompare;
      return a.cityHex.row.compareTo(b.cityHex.row);
    });

    final commands = <GameCommand>[];
    final usedAssaultUnitIds = <String>{};
    final assaultedCityHexes = <String>{};
    for (final candidate in candidates) {
      if (commands.length >= 3) break;
      final cityKey = _key(candidate.cityHex.col, candidate.cityHex.row);
      if (!usedAssaultUnitIds.add(candidate.unitId)) continue;
      if (!assaultedCityHexes.add(cityKey)) continue;
      commands.add(candidate.command);
    }
    return List.unmodifiable(commands);
  }

  String _key(int col, int row) => '$col:$row';
}

final class _CityAssaultCandidate {
  const _CityAssaultCandidate({
    required this.command,
    required this.unitId,
    required this.cityHex,
    required this.score,
  });

  final AttackHexCommand command;
  final String unitId;
  final HexCoordinate cityHex;
  final double score;
}
