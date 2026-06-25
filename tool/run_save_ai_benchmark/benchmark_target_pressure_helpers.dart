part of '../run_save_ai_benchmark.dart';

List<HexCoordinate> _humanTargetAnchors(
  GameView view,
  Set<String> humanPlayerIds,
) {
  return _targetAnchorsForOwners(view, humanPlayerIds);
}

List<HexCoordinate> _targetAnchorsForOwners(
  GameView view,
  Set<String> ownerPlayerIds,
) {
  return [
    for (final city in view.rememberedTargetableEnemyCities)
      if (ownerPlayerIds.contains(city.ownerPlayerId))
        city.center.toCoordinate(),
    for (final unit in view.visibleTargetableEnemyUnits)
      if (ownerPlayerIds.contains(unit.ownerPlayerId))
        HexCoordinate(col: unit.col, row: unit.row),
  ];
}

List<HexCoordinate> _warGoalTargetAnchors(
  StrategicPlan? strategicPlan,
  GameView view,
  Set<String> ownerPlayerIds,
) {
  final anchors = <String, HexCoordinate>{};
  for (final goal in strategicPlan?.warGoals ?? const <WarGoal>[]) {
    if (!_isActionableWarGoal(goal, view, ownerPlayerIds)) continue;
    anchors[_coordinateKey(goal.targetHex)] = goal.targetHex;
  }
  return anchors.values.toList(growable: false);
}

Map<String, List<HexCoordinate>> _warGoalTargetAnchorsByUnitId(
  StrategicPlan? strategicPlan,
  GameView view,
  Set<String> ownerPlayerIds,
) {
  final byUnitId = <String, Map<String, HexCoordinate>>{};
  for (final goal in strategicPlan?.warGoals ?? const <WarGoal>[]) {
    if (!_isActionableWarGoal(goal, view, ownerPlayerIds)) continue;
    for (final unitId in goal.assignedUnitIds) {
      byUnitId.putIfAbsent(
        unitId,
        () => <String, HexCoordinate>{},
      )[_coordinateKey(goal.targetHex)] = goal.targetHex;
    }
  }
  return {
    for (final entry in byUnitId.entries)
      entry.key: entry.value.values.toList(growable: false),
  };
}

bool _isActionableWarGoal(
  WarGoal goal,
  GameView view,
  Set<String> ownerPlayerIds,
) {
  return goal.kind != WarGoalKind.defend &&
      ownerPlayerIds.contains(goal.targetPlayerId) &&
      view.canTargetPlayer(goal.targetPlayerId);
}

String _coordinateKey(HexCoordinate coordinate) {
  return '${coordinate.col},${coordinate.row}';
}

List<String> _immediateHumanAttackTargets(
  GameView view,
  AiContext context,
  Set<String> humanPlayerIds,
) {
  return _ImmediateHumanAttackTargetFinder(
    view: view,
    context: context,
    humanPlayerIds: humanPlayerIds,
  ).find();
}

final class _ImmediateHumanAttackTargetFinder {
  const _ImmediateHumanAttackTargetFinder({
    required this.view,
    required this.context,
    required this.humanPlayerIds,
  });

  final GameView view;
  final AiContext context;
  final Set<String> humanPlayerIds;

  List<String> find() {
    final targets = <String>[];
    for (final attacker in view.ownUnits) {
      final stats = UnitCombatStats.derive(
        attacker,
        ruleset: view.ruleset.combat,
      );
      if (stats.attack <= 0) continue;
      targets
        ..addAll(_unitTargetsFor(attacker, stats))
        ..addAll(_cityTargetsFor(attacker, stats));
    }
    return targets;
  }

  Iterable<String> _unitTargetsFor(GameUnit attacker, CombatStats stats) sync* {
    final attackerHex = _unitHex(attacker);
    for (final target in view.visibleTargetableEnemyUnits) {
      if (!_isHumanOwned(target.ownerPlayerId)) continue;
      if (!_canReach(attackerHex, _unitHex(target), stats)) continue;
      if (!_shouldReportUnitTarget(attacker, target)) continue;
      yield '${attacker.id}->unit:${target.id}';
    }
  }

  Iterable<String> _cityTargetsFor(GameUnit attacker, CombatStats stats) sync* {
    final attackerHex = _unitHex(attacker);
    for (final city in view.rememberedTargetableEnemyCities) {
      final cityHex = city.center.toCoordinate();
      if (!_isHumanOwned(city.ownerPlayerId)) continue;
      if (_hasKnownUnitAt(city.center.col, city.center.row)) continue;
      if (!_canReach(attackerHex, cityHex, stats)) continue;
      if (!_shouldReportCityTarget(attacker, city)) continue;
      yield '${attacker.id}->city:${city.id}';
    }
  }

  bool _isHumanOwned(String ownerPlayerId) {
    return humanPlayerIds.contains(ownerPlayerId);
  }

  bool _canReach(
    HexCoordinate attackerHex,
    HexCoordinate targetHex,
    CombatStats stats,
  ) {
    return HexDistance.between(attackerHex, targetHex) <= stats.range;
  }

  bool _shouldReportUnitTarget(GameUnit attacker, GameUnit target) {
    final evaluation = AiCombatTactics.evaluateAttack(
      view: view,
      context: context,
      command: AttackHexCommand(attacker.id, target.col, target.row),
    );
    return evaluation != null &&
        AiCombatTactics.shouldConsiderAttack(
          evaluation,
          context,
          matchesWarGoal: true,
        );
  }

  bool _shouldReportCityTarget(GameUnit attacker, GameCity city) {
    final evaluation = AiCombatTactics.evaluateCityAttack(
      view: view,
      context: context,
      command: AttackHexCommand(attacker.id, city.center.col, city.center.row),
    );
    return evaluation != null &&
        AiCombatTactics.shouldConsiderCityAttack(
          evaluation,
          context,
          matchesWarGoal: true,
        );
  }

  bool _hasKnownUnitAt(int col, int row) {
    return view.ownUnits.any((unit) => _unitOccupies(unit, col, row)) ||
        view.visibleEnemyUnits.any((unit) => _unitOccupies(unit, col, row));
  }
}

HexCoordinate _unitHex(GameUnit unit) {
  return HexCoordinate(col: unit.col, row: unit.row);
}

bool _unitOccupies(GameUnit unit, int col, int row) {
  return unit.col == col && unit.row == row;
}

int _nearestDistance(HexCoordinate origin, List<HexCoordinate> targets) {
  var nearest = 1 << 30;
  for (final target in targets) {
    nearest = math.min(nearest, HexDistance.between(origin, target));
  }
  return nearest;
}

const _nonHumanAttackReasonDefensivePending = 'defensive_pending_city_attack';
const _nonHumanAttackReasonDefensiveNearCity = 'defensive_near_city';
const _nonHumanAttackReasonRecentHostile = 'recent_hostile';
const _nonHumanAttackReasonFrontlineBlocker = 'frontline_blocker';
const _nonHumanAttackReasonParallelSiege = 'parallel_with_siege';
const _nonHumanAttackReasonOpportunistic = 'opportunistic_no_human_pressure';
const _nonHumanAttackReasonDistracting = 'distracting_from_human_pressure';
const _frontlineBlockerDistance = 4;

String _nonHumanAttackReason(
  AttackHexCommand command, {
  required GameView view,
  required String targetOwner,
  required List<HexCoordinate> humanPressureAnchors,
  required bool hasHumanPressureContact,
}) {
  return _NonHumanAttackReasonResolver(
    view: view,
    humanPressureAnchors: humanPressureAnchors,
    hasHumanPressureContact: hasHumanPressureContact,
  ).resolve(command, targetOwner: targetOwner);
}

final class _NonHumanAttackReasonResolver {
  const _NonHumanAttackReasonResolver({
    required this.view,
    required this.humanPressureAnchors,
    required this.hasHumanPressureContact,
  });

  final GameView view;
  final List<HexCoordinate> humanPressureAnchors;
  final bool hasHumanPressureContact;

  String resolve(AttackHexCommand command, {required String targetOwner}) {
    final targetHex = HexCoordinate(
      col: command.defenderCol,
      row: command.defenderRow,
    );
    if (_targetsPendingCityThreat(command)) {
      return _nonHumanAttackReasonDefensivePending;
    }
    if (_isNearOwnCity(targetHex)) {
      return _nonHumanAttackReasonDefensiveNearCity;
    }
    if (_isRecentHostile(targetOwner)) {
      return _nonHumanAttackReasonRecentHostile;
    }
    if (_hasNoHumanPressure) {
      return _nonHumanAttackReasonOpportunistic;
    }
    if (_blocksHumanFrontline(targetHex)) {
      return _nonHumanAttackReasonFrontlineBlocker;
    }
    if (hasHumanPressureContact) {
      return _nonHumanAttackReasonParallelSiege;
    }
    return _nonHumanAttackReasonDistracting;
  }

  bool _targetsPendingCityThreat(AttackHexCommand command) {
    final targetUnit = _visibleEnemyUnitAt(
      view,
      command.defenderCol,
      command.defenderRow,
    );
    if (targetUnit == null) return false;
    return view.pendingCityAttackThreats.any(
      (threat) => threat.attackerUnitId == targetUnit.id,
    );
  }

  bool _isNearOwnCity(HexCoordinate targetHex) {
    return _nearestOwnCityDistance(view, targetHex) <= 2;
  }

  bool _isRecentHostile(String targetOwner) {
    return view.recentHostilePlayerIds.contains(targetOwner);
  }

  bool get _hasNoHumanPressure => humanPressureAnchors.isEmpty;

  bool _blocksHumanFrontline(HexCoordinate targetHex) {
    return _nearestDistance(targetHex, humanPressureAnchors) <=
        _frontlineBlockerDistance;
  }
}

bool _hasPressureContact(GameView view, List<HexCoordinate> pressureAnchors) {
  if (pressureAnchors.isEmpty) return false;
  for (final unit in view.ownUnits) {
    if (!_isMilitaryUnit(unit, view.ruleset.combat)) continue;
    final distance = _nearestDistance(_unitHex(unit), pressureAnchors);
    if (distance <= 1) return true;
    final stats = UnitCombatStats.derive(unit, ruleset: view.ruleset.combat);
    if (stats.attack > 0 && distance <= stats.range) return true;
  }
  return false;
}

int _nearestOwnCityDistance(GameView view, HexCoordinate target) {
  var nearest = 1 << 30;
  for (final city in view.ownCities) {
    nearest = math.min(
      nearest,
      HexDistance.between(target, city.center.toCoordinate()),
    );
  }
  return nearest;
}

GameUnit? _visibleEnemyUnitAt(GameView view, int col, int row) {
  for (final unit in view.visibleEnemyUnits) {
    if (_unitOccupies(unit, col, row)) return unit;
  }
  return null;
}

String? _ownerAt(GameView view, int col, int row) {
  for (final unit in view.visibleEnemyUnits) {
    if (_unitOccupies(unit, col, row)) return unit.ownerPlayerId;
  }
  for (final city in view.rememberedEnemyCities) {
    if (city.center.col == col && city.center.row == row) {
      return city.ownerPlayerId;
    }
  }
  return null;
}
