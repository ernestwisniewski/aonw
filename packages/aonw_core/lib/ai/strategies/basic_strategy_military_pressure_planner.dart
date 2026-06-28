import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/military_assessment.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

final class BasicStrategyMilitaryPressurePlanner {
  const BasicStrategyMilitaryPressurePlanner({
    this.militaryAssessment = const AiMilitaryAssessment(),
  });

  final AiMilitaryAssessment militaryAssessment;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    AiEmpireAssessment assessment,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes, {
    bool assignedOnly = false,
  }) {
    final warGoals = context.strategicPlan?.warGoals ?? const <WarGoal>[];
    final goalByUnitId = _warGoalByAssignedUnit(warGoals);
    final holdGenericPressure =
        !assignedOnly &&
        _shouldHoldGenericMilitaryPressureForExpansion(
          view: view,
          context: context,
          assessment: assessment,
        );
    final genericTargets = assignedOnly
        ? const <_PressureTarget>[]
        : holdGenericPressure
        ? const <_PressureTarget>[]
        : _pressureTargets(view, warGoals: warGoals);
    if (genericTargets.isEmpty && goalByUnitId.isEmpty) return const [];

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
    final units = [
      for (final unit in view.ownUnits)
        if (_canApplyMilitaryPressure(
          unit,
          usedUnitIds,
          context.ruleset.combat,
        ))
          unit,
    ]..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in units) {
      final assignedWarGoal = goalByUnitId[unit.id];
      if (assignedOnly && assignedWarGoal == null) continue;
      final targets = assignedWarGoal == null
          ? genericTargets
          : _pressureTargets(view, assignedWarGoal: assignedWarGoal);
      if (targets.isEmpty) continue;

      final plannedMove = _pressureMoveFor(
        unit: unit,
        view: view,
        targets: targets,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (plannedMove == null) continue;

      final move = plannedMove.command;
      commands.add(move);
      occupied
        ..remove(_key(unit.col, unit.row))
        ..addAll(
          plannedMove.reservedHexes.map((hex) => _key(hex.col, hex.row)),
        );
      reservedHexes.addAll(plannedMove.reservedHexes);
      usedUnitIds.add(unit.id);
    }

    return List.unmodifiable(commands);
  }

  bool _shouldHoldGenericMilitaryPressureForExpansion({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
  }) {
    if (view.ownCities.isEmpty) return false;
    if (context.strategicPlan?.mode == StrategicMode.military) return false;
    if (!assessment.wantsExpansion || assessment.cityCount >= 3) return false;
    if (assessment.enemyMilitaryPressure) return false;
    final visibleEnemyPlayerIds = {
      for (final enemy in view.visibleTargetableEnemyUnits) enemy.ownerPlayerId,
    };
    for (final enemyPlayerId in visibleEnemyPlayerIds) {
      if (militaryAssessment.hasClearVisibleMilitaryAdvantage(
        view,
        context.ruleset.combat,
        enemyPlayerId,
      )) {
        return false;
      }
    }
    if (assessment.settlerCount > 0 &&
        assessment.militaryCount >
            assessment.cityCount + assessment.settlerCount + 1) {
      return false;
    }
    return true;
  }

  Map<String, WarGoal> _warGoalByAssignedUnit(List<WarGoal> warGoals) {
    final byUnitId = <String, WarGoal>{};
    for (final goal in warGoals) {
      for (final unitId in goal.assignedUnitIds) {
        byUnitId.putIfAbsent(unitId, () => goal);
      }
    }
    return byUnitId;
  }

  List<_PressureTarget> _pressureTargets(
    GameView view, {
    List<WarGoal> warGoals = const [],
    WarGoal? assignedWarGoal,
  }) {
    final targets = <String, _PressureTarget>{};
    if (assignedWarGoal != null) {
      _addWarGoalTargets(targets, view, assignedWarGoal);
    } else {
      for (final goal in warGoals) {
        _addWarGoalTargets(targets, view, goal);
      }
      for (final enemy in view.visibleTargetableEnemyUnits) {
        _addPressureTarget(
          targets,
          HexCoordinate(col: enemy.col, row: enemy.row),
          1.35,
        );
      }
      for (final city in view.rememberedTargetableEnemyCities) {
        _addPressureTarget(targets, city.center.toCoordinate(), 1.0);
      }
    }

    return targets.values.toList()..sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      final colCompare = a.coordinate.col.compareTo(b.coordinate.col);
      if (colCompare != 0) return colCompare;
      return a.coordinate.row.compareTo(b.coordinate.row);
    });
  }

  void _addWarGoalTargets(
    Map<String, _PressureTarget> targets,
    GameView view,
    WarGoal goal,
  ) {
    if (!view.canTargetPlayer(goal.targetPlayerId)) return;

    final basePriority = _warGoalPressurePriority(goal);
    final visibleGoalEnemies = [
      for (final enemy in view.visibleTargetableEnemyUnits)
        if (enemy.ownerPlayerId == goal.targetPlayerId) enemy,
    ];
    final engagedVisibleEnemies = [
      for (final enemy in visibleGoalEnemies)
        if (warGoalEngagesHex(
          goal,
          HexCoordinate(col: enemy.col, row: enemy.row),
        ))
          enemy,
    ];
    if (goal.kind != WarGoalKind.defend || engagedVisibleEnemies.isEmpty) {
      _addPressureTarget(targets, goal.targetHex, basePriority);
    }
    if (goal.kind != WarGoalKind.defend) {
      for (final city in view.rememberedTargetableEnemyCities) {
        if (city.ownerPlayerId != goal.targetPlayerId) continue;
        _addPressureTarget(
          targets,
          city.center.toCoordinate(),
          basePriority - 0.15,
        );
      }
    }

    final unitPriority = goal.kind == WarGoalKind.defend
        ? basePriority
        : basePriority - 0.35;
    for (final enemy in engagedVisibleEnemies) {
      _addPressureTarget(
        targets,
        HexCoordinate(col: enemy.col, row: enemy.row),
        unitPriority,
      );
    }
  }

  void _addPressureTarget(
    Map<String, _PressureTarget> targets,
    HexCoordinate coordinate,
    double priority,
  ) {
    final key = _key(coordinate.col, coordinate.row);
    final existing = targets[key];
    if (existing != null && existing.priority >= priority) return;
    targets[key] = _PressureTarget(coordinate: coordinate, priority: priority);
  }

  double _warGoalPressurePriority(WarGoal goal) {
    final kindPriority = switch (goal.kind) {
      WarGoalKind.captureCity => 4.0,
      WarGoalKind.eliminateUnits => 3.25,
      WarGoalKind.harass => 2.35,
      WarGoalKind.defend => 2.6,
    };
    final planPriority = goal.priority.clamp(0.0, 4.0).toDouble();
    return kindPriority + planPriority / 10.0;
  }

  bool _canApplyMilitaryPressure(
    GameUnit unit,
    Set<String> usedUnitIds,
    CombatRuleset ruleset,
  ) {
    if (usedUnitIds.contains(unit.id)) return false;
    if (!AiUnitRoles.isMilitaryUnit(unit) ||
        unit.isWorking ||
        unit.queuedPath != null) {
      return false;
    }
    if (unit.movementPoints <= 0) return false;

    final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
    if (stats.attack <= 0) return false;
    final currentHp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
    return currentHp >= (stats.hp * 0.6).ceil();
  }

  _PlannedPressureMove? _pressureMoveFor({
    required GameUnit unit,
    required GameView view,
    required List<_PressureTarget> targets,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    final origin = HexCoordinate(col: unit.col, row: unit.row);
    final currentScore = _pressureScore(origin, targets);
    final candidates = <_PressureMoveCandidate>[];

    final movementCosts = pathfinder.movementCostsFrom(
      unit: unit,
      maxCost: unit.movementPoints,
    );
    for (final entry in movementCosts.entries) {
      final coords = entry.key;
      final movementCost = entry.value;
      if (movementCost > unit.movementPoints) continue;
      if (occupied.contains(_key(coords.col, coords.row))) continue;
      if (_isRememberedTargetableEnemyCityCenter(
        view,
        coords.col,
        coords.row,
      )) {
        continue;
      }
      if (!view.visibility.canSeeDynamicAt(coords.col, coords.row)) continue;
      final tile = view.mapData.tileAt(coords.col, coords.row);
      if (tile == null) continue;

      final candidateHex = HexCoordinate.fromTile(tile);
      final pressureScore = _pressureScore(candidateHex, targets);
      if (pressureScore <= currentScore) continue;
      final targetDistance = _nearestPressureTargetDistance(
        candidateHex,
        targets,
      );
      candidates.add(
        _PressureMoveCandidate(
          tile: tile,
          pressureScore: pressureScore,
          targetDistance: targetDistance,
          movementCost: movementCost,
        ),
      );
    }

    candidates.sort((a, b) {
      final scoreCompare = b.pressureScore.compareTo(a.pressureScore);
      if (scoreCompare != 0) return scoreCompare;
      final distanceCompare = a.targetDistance.compareTo(b.targetDistance);
      if (distanceCompare != 0) return distanceCompare;
      final costCompare = b.movementCost.compareTo(a.movementCost);
      if (costCompare != 0) return costCompare;
      final colCompare = a.tile.col.compareTo(b.tile.col);
      if (colCompare != 0) return colCompare;
      return a.tile.row.compareTo(b.tile.row);
    });

    if (candidates.isEmpty) return null;
    final candidate = candidates.first;
    final target = candidate.tile;
    final plan = pathfinder.plan(unit: unit, targetTile: target);
    if (plan == null || plan.totalCost > unit.movementPoints) return null;
    return _PlannedPressureMove(
      command: MoveUnitCommand(unit.id, target.col, target.row),
      reservedHexes: plan.reservedHexes,
    );
  }

  double _pressureScore(
    HexCoordinate origin,
    Iterable<_PressureTarget> targets,
  ) {
    var best = double.negativeInfinity;
    for (final target in targets) {
      final distance = HexDistance.between(origin, target.coordinate);
      final score = target.priority * 100.0 - distance;
      if (score > best) best = score;
    }
    return best;
  }

  int _nearestPressureTargetDistance(
    HexCoordinate origin,
    Iterable<_PressureTarget> targets,
  ) {
    var nearest = 1 << 30;
    for (final target in targets) {
      final distance = HexDistance.between(origin, target.coordinate);
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }

  bool _isRememberedTargetableEnemyCityCenter(GameView view, int col, int row) {
    for (final city in view.rememberedTargetableEnemyCities) {
      if (city.occupiesCenter(col, row)) return true;
    }
    return false;
  }

  String _key(int col, int row) => '$col:$row';
}

final class _PressureMoveCandidate {
  const _PressureMoveCandidate({
    required this.tile,
    required this.pressureScore,
    required this.targetDistance,
    required this.movementCost,
  });

  final TileData tile;
  final double pressureScore;
  final int targetDistance;
  final int movementCost;
}

final class _PressureTarget {
  const _PressureTarget({required this.coordinate, required this.priority});

  final HexCoordinate coordinate;
  final double priority;
}

final class _PlannedPressureMove {
  const _PlannedPressureMove({
    required this.command,
    required this.reservedHexes,
  });

  final MoveUnitCommand command;
  final Set<HexCoordinate> reservedHexes;
}
