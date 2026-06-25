import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/military_assessment.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategic/war_front.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_military_awareness.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

final class BasicStrategyCombatReactionsPlanner {
  const BasicStrategyCombatReactionsPlanner({
    this.militaryAssessment = const AiMilitaryAssessment(),
    this.militaryAwareness = const BasicStrategyMilitaryAwareness(),
  });

  final AiMilitaryAssessment militaryAssessment;
  final BasicStrategyMilitaryAwareness militaryAwareness;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    final targetableEnemies = view.visibleTargetableEnemyUnits;
    if (view.ownUnits.isEmpty || targetableEnemies.isEmpty) {
      return const [];
    }

    final retreats = <GameCommand>[];
    final attacks = <GameCommand>[];
    final reservedEnemyTargets = <String>{};
    final occupied = <String>{
      for (final own in view.ownUnits) _key(own.col, own.row),
      for (final enemy in view.visibleEnemyUnits) _key(enemy.col, enemy.row),
      for (final hex in reservedHexes) _key(hex.col, hex.row),
    };
    final ownUnits = [...view.ownUnits]..sort((a, b) => a.id.compareTo(b.id));
    final offensiveWarTargetsByUnitId =
        _offensiveWarTargetPlayerIdsByAssignedUnit(
          context.strategicPlan?.warGoals ?? const <WarGoal>[],
        );
    final preferredTargetPlayerIds =
        _preferredWarTargetPlayerIds(
            context.strategicPlan?.warGoals ?? const <WarGoal>[],
          )
          ..addAll(view.activeHostilePlayerIds)
          ..addAll(view.recentHostilePlayerIds)
          ..addAll(view.pressureTargetPlayerIds);
    final pendingCityAttackerUnitIds = {
      for (final threat in view.pendingCityAttackThreats) threat.attackerUnitId,
    };
    final defenseByUnitId = militaryAwareness.defenseByUnitId(context);

    for (final unit in ownUnits) {
      if (usedUnitIds.contains(unit.id) ||
          unit.isWorking ||
          unit.movementPoints <= 0) {
        continue;
      }

      final stats = UnitCombatStats.derive(
        unit,
        ruleset: context.ruleset.combat,
      );
      if (stats.attack <= 0) continue;

      final currentHp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
      final effectiveAggression = AiCombatTactics.effectiveAggression(context);
      final retreatThreshold = stats.hp * (0.5 / effectiveAggression);
      final nearbyEnemyDistance = militaryAwareness
          .nearestVisibleEnemyMilitaryDistance(
            HexCoordinate(col: unit.col, row: unit.row),
            view,
          );
      if (currentHp < retreatThreshold &&
          nearbyEnemyDistance != null &&
          nearbyEnemyDistance <= 2) {
        final retreat = _moveAwayFromEnemies(
          unit: unit,
          view: view,
          context: context,
          occupied: occupied,
        );
        if (retreat != null) {
          retreats.add(retreat);
          usedUnitIds.add(unit.id);
          occupied
            ..remove(_key(unit.col, unit.row))
            ..add(_key(retreat.targetCol, retreat.targetRow));
        }
        continue;
      }

      final target = _nearestTargetableEnemy(
        unit: unit,
        attackerStats: stats,
        view: view,
        context: context,
        enemies: targetableEnemies.where(
          (enemy) => !reservedEnemyTargets.contains(_key(enemy.col, enemy.row)),
        ),
        plan: context.strategicPlan,
        preferredPlayerIds: preferredTargetPlayerIds,
        urgentTargetUnitIds: pendingCityAttackerUnitIds,
      );
      if (target == null) continue;

      final targetIsRecentHostile = view.recentHostilePlayerIds.contains(
        target.unit.ownerPlayerId,
      );
      final targetIsPreferredPressure = preferredTargetPlayerIds.contains(
        target.unit.ownerPlayerId,
      );
      final assignedOffensiveWarTargets =
          offensiveWarTargetsByUnitId[unit.id] ?? const <String>{};
      final targetMatchesAssignedWar = assignedOffensiveWarTargets.contains(
        target.unit.ownerPlayerId,
      );
      final targetIsWarFrontBlocker = isOffensiveWarFrontBlocker(
        view: view,
        plan: context.strategicPlan,
        blockerHex: HexCoordinate(col: target.unit.col, row: target.unit.row),
        unitId: unit.id,
      );
      final targetIsPendingCityAttacker = pendingCityAttackerUnitIds.contains(
        target.unit.id,
      );
      final targetThreatensOwnCity = militaryAssessment.isThreateningOwnCity(
        target.unit,
        view,
        maxDistance: 2,
      );
      final targetHasClearAdvantage = militaryAssessment
          .hasClearVisibleMilitaryAdvantage(
            view,
            context.ruleset.combat,
            target.unit.ownerPlayerId,
            targetableOnly: true,
            includeDefensiveUnits: true,
          );
      if (assignedOffensiveWarTargets.isNotEmpty &&
          !targetMatchesAssignedWar &&
          !targetIsWarFrontBlocker &&
          !targetIsPendingCityAttacker &&
          !targetThreatensOwnCity) {
        continue;
      }
      if (defenseByUnitId.containsKey(unit.id) &&
          !targetIsRecentHostile &&
          !targetIsPreferredPressure &&
          !targetIsPendingCityAttacker &&
          !targetHasClearAdvantage) {
        continue;
      }

      final isLastMilitaryReserve = militaryAssessment
          .isLastMilitaryReserveUnit(unit, view, context.ruleset.combat);
      if (isLastMilitaryReserve &&
          !militaryAssessment.isThreateningOwnCity(
            target.unit,
            view,
            maxDistance: 2,
          )) {
        continue;
      }

      if (currentHp < retreatThreshold) {
        final retreat = _moveAwayFromEnemies(
          unit: unit,
          view: view,
          context: context,
          occupied: occupied,
        );
        if (retreat != null) {
          retreats.add(retreat);
          usedUnitIds.add(unit.id);
          occupied
            ..remove(_key(unit.col, unit.row))
            ..add(_key(retreat.targetCol, retreat.targetRow));
        }
        continue;
      }

      if (isLastMilitaryReserve &&
          !militaryAssessment.lastMilitarySurvivesAttack(
            attacker: unit,
            defender: target.unit,
            ruleset: context.ruleset.combat,
            attackerStats: stats,
            defenderStats: UnitCombatStats.derive(
              target.unit,
              ruleset: context.ruleset.combat,
            ),
            currentHp: currentHp,
          )) {
        continue;
      }
      attacks.add(AttackHexCommand(unit.id, target.unit.col, target.unit.row));
      usedUnitIds.add(unit.id);
      reservedEnemyTargets.add(_key(target.unit.col, target.unit.row));
    }

    return [...retreats, ...attacks];
  }

  Set<String> _preferredWarTargetPlayerIds(List<WarGoal> warGoals) {
    return {
      for (final goal in warGoals)
        if (goal.kind != WarGoalKind.defend) goal.targetPlayerId,
    };
  }

  Map<String, Set<String>> _offensiveWarTargetPlayerIdsByAssignedUnit(
    List<WarGoal> warGoals,
  ) {
    final byUnitId = <String, Set<String>>{};
    for (final goal in warGoals) {
      if (goal.kind == WarGoalKind.defend) continue;
      for (final unitId in goal.assignedUnitIds) {
        byUnitId.putIfAbsent(unitId, () => <String>{}).add(goal.targetPlayerId);
      }
    }
    return byUnitId;
  }

  _CombatTarget? _nearestTargetableEnemy({
    required GameUnit unit,
    required CombatStats attackerStats,
    required GameView view,
    required AiContext context,
    required Iterable<GameUnit> enemies,
    required StrategicPlan? plan,
    required Set<String> preferredPlayerIds,
    Set<String> urgentTargetUnitIds = const {},
  }) {
    final origin = HexCoordinate(col: unit.col, row: unit.row);
    final candidates = <_CombatTarget>[];
    for (final enemy in enemies) {
      if (!view.canTargetPlayer(enemy.ownerPlayerId)) continue;
      final target = HexCoordinate(col: enemy.col, row: enemy.row);
      final distance = HexDistance.between(origin, target);
      if (distance > attackerStats.range) continue;
      final command = AttackHexCommand(unit.id, enemy.col, enemy.row);
      final evaluation = AiCombatTactics.evaluateAttack(
        view: view,
        context: context,
        command: command,
      );
      if (evaluation == null) continue;
      final isWarTarget = preferredPlayerIds.contains(enemy.ownerPlayerId);
      final isUrgentTarget = urgentTargetUnitIds.contains(enemy.id);
      final isWarFrontBlocker = isOffensiveWarFrontBlocker(
        view: view,
        plan: plan,
        blockerHex: target,
        unitId: unit.id,
      );
      if (!AiCombatTactics.shouldConsiderAttack(
            evaluation,
            context,
            matchesWarGoal: isWarTarget || isUrgentTarget || isWarFrontBlocker,
            defendingCity:
                isUrgentTarget ||
                militaryAssessment.isThreateningOwnCity(
                  enemy,
                  view,
                  maxDistance: 2,
                ),
          ) &&
          !_shouldPressAdvantagedAttack(
            evaluation,
            view: view,
            context: context,
          )) {
        continue;
      }
      candidates.add(
        _CombatTarget(
          unit: enemy,
          distance: distance,
          priority: isUrgentTarget
              ? 3
              : isWarTarget
              ? 2
              : isWarFrontBlocker
              ? 1
              : 0,
          evaluation: evaluation,
        ),
      );
    }
    candidates.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      final tacticalCompare = b.evaluation.heuristicScore.compareTo(
        a.evaluation.heuristicScore,
      );
      if (tacticalCompare != 0) return tacticalCompare;

      final distanceCompare = a.distance.compareTo(b.distance);
      if (distanceCompare != 0) return distanceCompare;

      final aHp = a.evaluation.defenderHpBefore;
      final bHp = b.evaluation.defenderHpBefore;
      final hpCompare = aHp.compareTo(bHp);
      if (hpCompare != 0) return hpCompare;

      return a.unit.id.compareTo(b.unit.id);
    });
    return candidates.isEmpty ? null : candidates.first;
  }

  bool _shouldPressAdvantagedAttack(
    AiAttackEvaluation evaluation, {
    required GameView view,
    required AiContext context,
  }) {
    if (evaluation.defenderDamage <= 0 || evaluation.attackerKilled) {
      return false;
    }
    if (!militaryAssessment.hasClearVisibleMilitaryAdvantage(
      view,
      context.ruleset.combat,
      evaluation.defender.ownerPlayerId,
      targetableOnly: true,
      includeDefensiveUnits: true,
    )) {
      return false;
    }

    final aggression = AiCombatTactics.effectiveAggression(context);
    final acceptableTrade =
        evaluation.defenderDamage +
            (aggression >= 1.15 || evaluation.threatensOwnCity ? 1 : 0) >=
        evaluation.attackerDamage;
    if (!acceptableTrade) return false;

    return evaluation.defenderKilled ||
        evaluation.attackerHpAfter > 1 ||
        evaluation.rangedAttack;
  }

  MoveUnitCommand? _moveAwayFromEnemies({
    required GameUnit unit,
    required GameView view,
    required AiContext context,
    required Set<String> occupied,
  }) {
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: view.movementBlockingUnits,
      canEnterTile: (tile) =>
          view.visibility.canSeeDynamicAt(tile.col, tile.row) &&
          !occupied.contains(_key(tile.col, tile.row)),
    );

    final candidates = <_RetreatCandidate>[];
    for (final hex in HexNeighbors.existingAround(
      HexCoordinate(col: unit.col, row: unit.row),
      context.mapData,
    )) {
      if (occupied.contains(_key(hex.col, hex.row))) continue;
      final tile = context.mapData.tileAt(hex.col, hex.row);
      if (tile == null ||
          !view.visibility.canSeeDynamicAt(tile.col, tile.row)) {
        continue;
      }

      final plan = pathfinder.plan(unit: unit, targetTile: tile);
      if (plan == null || plan.totalCost > unit.movementPoints) continue;
      candidates.add(
        _RetreatCandidate(
          tile: tile,
          nearestEnemyDistance: _nearestEnemyDistance(tile, view),
        ),
      );
    }

    candidates.sort((a, b) {
      final distanceCompare = b.nearestEnemyDistance.compareTo(
        a.nearestEnemyDistance,
      );
      if (distanceCompare != 0) return distanceCompare;
      final colCompare = a.tile.col.compareTo(b.tile.col);
      if (colCompare != 0) return colCompare;
      return a.tile.row.compareTo(b.tile.row);
    });

    if (candidates.isEmpty) return null;
    final target = candidates.first.tile;
    return MoveUnitCommand(unit.id, target.col, target.row);
  }

  int _nearestEnemyDistance(TileData tile, GameView view) {
    final origin = HexCoordinate(col: tile.col, row: tile.row);
    var nearest = 1 << 30;
    for (final enemy in view.visibleTargetableEnemyUnits) {
      if (!AiUnitRoles.isMilitaryUnit(enemy)) continue;
      final distance = HexDistance.between(
        origin,
        HexCoordinate(col: enemy.col, row: enemy.row),
      );
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }

  String _key(int col, int row) => '$col:$row';
}

final class _CombatTarget {
  const _CombatTarget({
    required this.unit,
    required this.distance,
    required this.priority,
    required this.evaluation,
  });

  final GameUnit unit;
  final int distance;
  final int priority;
  final AiAttackEvaluation evaluation;
}

final class _RetreatCandidate {
  const _RetreatCandidate({
    required this.tile,
    required this.nearestEnemyDistance,
  });

  final TileData tile;
  final int nearestEnemyDistance;
}
