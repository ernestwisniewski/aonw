import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_command_reconciliation_rules.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

const _defaultRules = MctsCommandReconciliationRules();

final class MctsBaselineMovementCommandPolicy {
  final MctsCommandReconciliationRules _rules;

  const MctsBaselineMovementCommandPolicy({
    MctsCommandReconciliationRules rules = _defaultRules,
  }) : _rules = rules;

  bool canAppendPressureMove(
    MoveUnitCommand command, {
    required GameUnit unit,
    required GameView view,
    required AiContext context,
    required Set<String> reservedMoveTargets,
  }) {
    if (!_rules.canServeAsMilitaryUnit(unit, context)) {
      return false;
    }
    if (!isBaselinePressureMove(command, unit: unit, view: view)) {
      return false;
    }
    return canAppendBaselineMove(
      command,
      unit: unit,
      view: view,
      context: context,
      reservedMoveTargets: reservedMoveTargets,
    );
  }

  bool canAppendBaselineMove(
    MoveUnitCommand command, {
    required GameUnit unit,
    required GameView view,
    required AiContext context,
    required Set<String> reservedMoveTargets,
  }) {
    if (unit.isWorking || unit.movementPoints <= 0) return false;
    if (unit.occupies(command.targetCol, command.targetRow)) {
      return false;
    }
    final targetTile = view.mapData.tileAt(
      command.targetCol,
      command.targetRow,
    );
    if (targetTile == null || !view.visibility.canInspectTile(targetTile)) {
      return false;
    }
    if (_rules.isRememberedEnemyCityHex(
      view,
      command.targetCol,
      command.targetRow,
    )) {
      return false;
    }
    if (_rules.isFounderUnit(unit) &&
        !_isBaselineFounderMoveSafe(
          command,
          unit: unit,
          view: view,
          context: context,
        )) {
      return false;
    }
    final targetKey = _rules.hexKey(command.targetCol, command.targetRow);
    if (reservedMoveTargets.contains(targetKey)) return false;
    for (final other in view.movementBlockingUnits) {
      if (other.id == unit.id) continue;
      if (other.occupies(command.targetCol, command.targetRow)) {
        return false;
      }
    }
    return true;
  }

  bool isBaselinePressureMove(
    MoveUnitCommand command, {
    required GameUnit unit,
    required GameView view,
  }) {
    final anchors = _pressureTargetAnchors(view);
    if (anchors.isEmpty) return false;

    final current = HexCoordinate(col: unit.col, row: unit.row);
    final target = HexCoordinate(
      col: command.targetCol,
      row: command.targetRow,
    );
    return _nearestDistanceToAny(target, anchors) <
        _nearestDistanceToAny(current, anchors);
  }

  List<HexCoordinate> _pressureTargetAnchors(GameView view) {
    final targetPlayerIds = {
      ...view.activeHostilePlayerIds,
      ...view.pressureTargetPlayerIds,
      ...view.recentHostilePlayerIds,
    };
    if (targetPlayerIds.isEmpty) return const [];

    final anchors = <HexCoordinate>[];
    for (final city in view.rememberedTargetableEnemyCities) {
      if (targetPlayerIds.contains(city.ownerPlayerId)) {
        anchors.add(city.center.toCoordinate());
      }
    }
    for (final unit in view.visibleTargetableEnemyUnits) {
      if (targetPlayerIds.contains(unit.ownerPlayerId)) {
        anchors.add(HexCoordinate(col: unit.col, row: unit.row));
      }
    }
    return anchors;
  }

  int _nearestDistanceToAny(
    HexCoordinate origin,
    Iterable<HexCoordinate> targets,
  ) {
    var best = 1 << 30;
    for (final target in targets) {
      final distance = HexDistance.between(origin, target);
      if (distance < best) best = distance;
    }
    return best;
  }

  bool _isBaselineFounderMoveSafe(
    MoveUnitCommand command, {
    required GameUnit unit,
    required GameView view,
    required AiContext context,
  }) {
    final target = HexCoordinate(
      col: command.targetCol,
      row: command.targetRow,
    );
    if (view.ownCities.isEmpty) {
      final nearestEnemy = _rules.nearestVisibleMilitaryDistance(
        view,
        target,
        context,
      );
      return nearestEnemy == null || nearestEnemy > 1;
    }

    if (AiCityFoundingSafety.isKnownEnemyCityHex(view: view, hex: target)) {
      return false;
    }

    final targetEscorted = _rules.ownMilitaryNear(
      view,
      target.col,
      target.row,
      2,
      context,
    );
    final targetEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: target,
        );
    if (targetEnemyCity != null) {
      if (targetEnemyCity <= 1) return false;
      if (targetEnemyCity <= 2) return false;
      if (targetEnemyCity <= 3 && !targetEscorted) return false;
    }

    final targetEnemy = _rules.nearestVisibleMilitaryDistance(
      view,
      target,
      context,
    );
    if (targetEnemy != null) {
      if (targetEnemy <= 1) return false;
      if (targetEnemy <= 2 && !targetEscorted) return false;
    }

    final current = HexCoordinate(col: unit.col, row: unit.row);
    final currentOwnCityDistance = _rules.nearestOwnCityDistance(view, current);
    final targetOwnCityDistance = _rules.nearestOwnCityDistance(view, target);
    final needsDestinationEscort =
        view.ownCities.length >= 2 &&
        targetOwnCityDistance >= currentOwnCityDistance &&
        !targetEscorted;
    if (!needsDestinationEscort) return true;

    final currentEnemy = _rules.nearestVisibleMilitaryDistance(
      view,
      current,
      context,
    );
    if ((currentEnemy != null && currentEnemy <= 3) ||
        (targetEnemy != null && targetEnemy <= 3)) {
      return _rules.isFounderThreatReducedByMove(
        currentEnemy: currentEnemy,
        targetEnemy: targetEnemy,
      );
    }

    final currentEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: current,
        );
    if ((currentEnemyCity != null && currentEnemyCity <= 3) ||
        (targetEnemyCity != null && targetEnemyCity <= 3)) {
      return _rules.isFounderThreatReducedByMove(
        currentEnemy: currentEnemyCity,
        targetEnemy: targetEnemyCity,
      );
    }

    return true;
  }
}
