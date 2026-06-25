import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyMapObjectivePlanner {
  const BasicStrategyMapObjectivePlanner({this.maxMovesPerTurn = 2});

  final int maxMovesPerTurn;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    if (maxMovesPerTurn <= 0 || view.mapData.objectives.isEmpty) {
      return const [];
    }

    final objectives = _claimableObjectives(view);
    if (objectives.isEmpty) return const [];

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
        if (_canClaimObjective(unit, usedUnitIds)) unit,
    ]..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in units) {
      if (commands.length >= maxMovesPerTurn) break;
      final move = _bestMoveFor(
        unit: unit,
        objectives: objectives,
        view: view,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (move == null) continue;

      commands.add(move.command);
      usedUnitIds.add(unit.id);
      occupied
        ..remove(_key(unit.col, unit.row))
        ..addAll(move.reservedHexes.map((hex) => _key(hex.col, hex.row)));
      reservedHexes.addAll(move.reservedHexes);
    }

    return List.unmodifiable(commands);
  }

  List<MapObjectiveDefinition> _claimableObjectives(GameView view) {
    final objectives =
        [
          for (final objective in view.mapData.objectives)
            if (_objectiveReward(objective) > 0 &&
                !_isCompletedByPlayer(objective, view) &&
                !_isAlreadyControlledByOwnCity(objective, view) &&
                _isRememberedObjective(objective, view))
              objective,
        ]..sort((a, b) {
          final reward = _objectiveReward(b).compareTo(_objectiveReward(a));
          if (reward != 0) return reward;
          return a.id.compareTo(b.id);
        });
    return objectives;
  }

  _ObjectiveMove? _bestMoveFor({
    required GameUnit unit,
    required List<MapObjectiveDefinition> objectives,
    required GameView view,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    _ObjectiveMove? best;
    for (final objective in objectives) {
      final target = objective.hex;
      if (unit.occupies(target.col, target.row)) continue;
      if (occupied.contains(_key(target.col, target.row))) continue;
      final tile = view.mapData.tileAt(target.col, target.row);
      if (tile == null ||
          !view.visibility.canSeeDynamicAt(tile.col, tile.row)) {
        continue;
      }
      final plan = pathfinder.plan(unit: unit, targetTile: tile);
      final step = plan?.furthestReachableStep;
      if (plan == null || step == null || unit.occupies(step.col, step.row)) {
        continue;
      }
      if (!UnitMovementFeasibility.canEventuallyTraverse(
        unit: unit,
        plan: plan,
      )) {
        continue;
      }
      final candidate = _ObjectiveMove(
        command: MoveUnitCommand(unit.id, step.col, step.row),
        reservedHexes: _reservedHexesFor(plan),
        score: _moveScore(unit, objective, plan),
      );
      if (best == null ||
          candidate.score > best.score ||
          (candidate.score == best.score &&
              candidate.command.unitId.compareTo(best.command.unitId) < 0)) {
        best = candidate;
      }
    }
    return best;
  }

  bool _canClaimObjective(GameUnit unit, Set<String> usedUnitIds) {
    if (usedUnitIds.contains(unit.id) ||
        unit.isWorking ||
        unit.queuedPath != null ||
        unit.movementPoints <= 0 ||
        unit.isCarryingArtifact) {
      return false;
    }
    if (unit.hasSettlers ||
        unit.type == GameUnitType.worker ||
        unit.type == GameUnitType.settler) {
      return false;
    }
    return AiUnitRoles.isMilitaryUnit(unit);
  }

  double _moveScore(
    GameUnit unit,
    MapObjectiveDefinition objective,
    UnitMovementPlan plan,
  ) {
    final reward = _objectiveReward(objective);
    final distance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      objective.hex.toCoordinate(),
    );
    return (reward * 100 - distance * 6 - plan.totalCost).toDouble();
  }

  bool _isCompletedByPlayer(MapObjectiveDefinition objective, GameView view) {
    final hold = view.mapObjectiveHoldStatesByObjectiveId[objective.id];
    return hold != null &&
        hold.playerId == view.forPlayerId &&
        hold.holdTurns >= objective.requiredHoldTurns;
  }

  bool _isAlreadyControlledByOwnCity(
    MapObjectiveDefinition objective,
    GameView view,
  ) {
    for (final city in view.ownCities) {
      if (city.controlsHex(objective.hex)) return true;
    }
    return false;
  }

  bool _isRememberedObjective(MapObjectiveDefinition objective, GameView view) {
    final visibility = view.visibility;
    return !visibility.isEnabled ||
        visibility.canRememberStaticAt(objective.hex.col, objective.hex.row);
  }

  int _objectiveReward(MapObjectiveDefinition objective) {
    return objective.victoryPoints + objective.goldPerTurn;
  }

  Set<HexCoordinate> _reservedHexesFor(UnitMovementPlan plan) {
    return {
      for (final step in plan.reachableSteps.skip(1))
        HexCoordinate(col: step.col, row: step.row),
    };
  }

  String _key(int col, int row) => '$col:$row';
}

final class _ObjectiveMove {
  const _ObjectiveMove({
    required this.command,
    required this.reservedHexes,
    required this.score,
  });

  final MoveUnitCommand command;
  final Set<HexCoordinate> reservedHexes;
  final double score;
}
