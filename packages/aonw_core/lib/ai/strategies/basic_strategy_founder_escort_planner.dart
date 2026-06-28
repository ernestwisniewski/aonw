import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_defense_movement.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_military_awareness.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyFounderEscortPlanner {
  const BasicStrategyFounderEscortPlanner({
    this.defenseMovement = const BasicStrategyDefenseMovement(),
    this.militaryAwareness = const BasicStrategyMilitaryAwareness(),
  });

  final BasicStrategyDefenseMovement defenseMovement;
  final BasicStrategyMilitaryAwareness militaryAwareness;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    AiEmpireAssessment assessment,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    if (view.ownCities.length < 2 || assessment.settlerCount <= 0) {
      return const [];
    }

    final militaryUnits = [
      for (final unit in view.ownUnits)
        if (defenseMovement.canHold(unit, context.ruleset.combat)) unit,
    ];
    final requiredDefenders =
        view.ownCities.length + (assessment.enemyMilitaryPressure ? 1 : 0);
    if (militaryUnits.length <= requiredDefenders) return const [];

    final needs = _founderEscortNeeds(view, context);
    if (needs.isEmpty) return const [];

    final defenseByUnitId = militaryAwareness.defenseByUnitId(context);
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

    final commands = <GameCommand>[];
    for (final need in needs) {
      if (militaryAwareness.ownMilitaryNear(need.focus, view, 2)) continue;

      _FounderEscortMoveCandidate? best;
      for (final unit in militaryUnits) {
        if (usedUnitIds.contains(unit.id)) continue;
        final defense = defenseByUnitId[unit.id];
        if (defense != null &&
            defense.threatLevel > 0 &&
            militaryUnits.length <= requiredDefenders + 1) {
          continue;
        }

        final candidate = _founderEscortMoveFor(
          unit: unit,
          need: need,
          defense: defense,
          view: view,
          occupied: occupied,
          pathfinder: pathfinder,
        );
        if (candidate == null) continue;
        if (best == null || candidate.score > best.score) {
          best = candidate;
        }
      }

      if (best == null) continue;
      commands.add(best.command);
      usedUnitIds.add(best.command.unitId);
      occupied
        ..remove(_key(best.origin.col, best.origin.row))
        ..addAll(best.reservedHexes.map((hex) => _key(hex.col, hex.row)));
      reservedHexes.addAll(best.reservedHexes);
    }

    return List.unmodifiable(commands);
  }

  List<_FounderEscortNeed> _founderEscortNeeds(
    GameView view,
    AiContext context,
  ) {
    final assignments =
        context.strategicPlan?.settlerAssignments ?? const <String, CityHex>{};
    if (assignments.isEmpty) return const [];

    final needs = <_FounderEscortNeed>[];
    final founders = [
      for (final unit in view.ownUnits)
        if (CityFoundingRules.canFoundCityWith(unit) &&
            !unit.isWorking &&
            unit.queuedPath == null)
          unit,
    ]..sort((a, b) => a.id.compareTo(b.id));

    for (final founder in founders) {
      final assignment = assignments[founder.id];
      if (assignment == null) continue;
      final focus = assignment.toCoordinate();
      if (militaryAwareness.ownMilitaryNear(focus, view, 2)) continue;
      if (!_founderEscortFocusHasPressure(
        founder: founder,
        focus: focus,
        view: view,
      )) {
        continue;
      }

      final current = HexCoordinate(col: founder.col, row: founder.row);
      final currentThreat = militaryAwareness
          .nearestVisibleEnemyMilitaryDistance(current, view);
      final focusThreat = militaryAwareness.nearestVisibleEnemyMilitaryDistance(
        focus,
        view,
      );
      final priority =
          100 -
          HexDistance.between(current, focus) * 4 +
          (currentThreat == null ? 0 : (4 - currentThreat).clamp(0, 4) * 12) +
          (focusThreat == null ? 0 : (4 - focusThreat).clamp(0, 4) * 10);
      needs.add(
        _FounderEscortNeed(
          founder: founder,
          focus: focus,
          priority: priority.toDouble(),
        ),
      );
    }

    needs.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.founder.id.compareTo(b.founder.id);
    });
    return needs;
  }

  bool _founderEscortFocusHasPressure({
    required GameUnit founder,
    required HexCoordinate focus,
    required GameView view,
  }) {
    final current = HexCoordinate(col: founder.col, row: founder.row);
    final currentEnemy = militaryAwareness.nearestVisibleEnemyMilitaryDistance(
      current,
      view,
    );
    if (currentEnemy != null && currentEnemy <= 3) return true;
    final focusEnemy = militaryAwareness.nearestVisibleEnemyMilitaryDistance(
      focus,
      view,
    );
    if (focusEnemy != null && focusEnemy <= 3) return true;

    final currentEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: current,
        );
    if (currentEnemyCity != null && currentEnemyCity <= 3) return true;
    final focusEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: focus,
        );
    return focusEnemyCity != null && focusEnemyCity <= 3;
  }

  _FounderEscortMoveCandidate? _founderEscortMoveFor({
    required GameUnit unit,
    required _FounderEscortNeed need,
    required StrategicDefenseAssignment? defense,
    required GameView view,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    final current = HexCoordinate(col: unit.col, row: unit.row);
    final currentDistance = HexDistance.between(current, need.focus);
    _FounderEscortMoveCandidate? best;

    for (final target in _founderEscortTargetHexes(need.focus, view)) {
      if (target == need.focus) continue;
      if (unit.occupies(target.col, target.row)) continue;
      if (occupied.contains(_key(target.col, target.row))) continue;
      final tile = view.mapData.tileAt(target.col, target.row);
      if (tile == null ||
          !view.visibility.canSeeDynamicAt(target.col, target.row)) {
        continue;
      }
      final plan = pathfinder.plan(unit: unit, targetTile: tile);
      final step = plan?.furthestReachableStep;
      if (plan == null ||
          !UnitMovementFeasibility.canEventuallyTraverse(
            unit: unit,
            plan: plan,
          ) ||
          step == null ||
          unit.occupies(step.col, step.row)) {
        continue;
      }

      final stepHex = HexCoordinate(col: step.col, row: step.row);
      final stepThreat = militaryAwareness.nearestVisibleEnemyMilitaryDistance(
        stepHex,
        view,
      );
      if (stepThreat != null && stepThreat <= 1) continue;
      final stepDistance = HexDistance.between(stepHex, need.focus);
      final improvement = currentDistance - stepDistance;
      if (improvement <= 0 && stepDistance > 2) continue;

      final founderDistance = HexDistance.between(
        stepHex,
        HexCoordinate(col: need.founder.col, row: need.founder.row),
      );
      final defensePenalty = defense == null
          ? 0.0
          : 14.0 + defense.threatLevel * 18.0;
      final score =
          need.priority +
          improvement * 24.0 +
          (stepDistance <= 2 ? 48.0 : 0.0) +
          (founderDistance <= 2 ? 24.0 : 0.0) -
          stepDistance * 7.0 -
          founderDistance * 3.0 -
          plan.totalCost * 0.4 -
          (stepThreat == null ? 0.0 : (4 - stepThreat).clamp(0, 4) * 5.0) -
          defensePenalty;
      final candidate = _FounderEscortMoveCandidate(
        command: MoveUnitCommand(unit.id, step.col, step.row),
        origin: current,
        reservedHexes: plan.reservedHexes,
        score: score,
      );
      if (best == null || candidate.score > best.score) best = candidate;
    }

    return best;
  }

  List<HexCoordinate> _founderEscortTargetHexes(
    HexCoordinate focus,
    GameView view,
  ) {
    final targets =
        [
          for (final tile in view.mapData.tiles)
            if (HexDistance.between(HexCoordinate.fromTile(tile), focus) <= 2)
              HexCoordinate.fromTile(tile),
        ]..sort((a, b) {
          final distanceCompare = HexDistance.between(
            a,
            focus,
          ).compareTo(HexDistance.between(b, focus));
          if (distanceCompare != 0) return distanceCompare;
          final colCompare = a.col.compareTo(b.col);
          if (colCompare != 0) return colCompare;
          return a.row.compareTo(b.row);
        });
    return targets;
  }

  String _key(int col, int row) => '$col:$row';
}

final class _FounderEscortNeed {
  const _FounderEscortNeed({
    required this.founder,
    required this.focus,
    required this.priority,
  });

  final GameUnit founder;
  final HexCoordinate focus;
  final double priority;
}

final class _FounderEscortMoveCandidate {
  const _FounderEscortMoveCandidate({
    required this.command,
    required this.origin,
    required this.reservedHexes,
    required this.score,
  });

  final MoveUnitCommand command;
  final HexCoordinate origin;
  final Set<HexCoordinate> reservedHexes;
  final double score;
}
