import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_ranking_queries.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';

CommandRanking? rankMapObjectiveCommand(
  GameCommand command,
  GameView view,
  AiContext context,
) {
  if (command is! MoveUnitCommand) return null;
  final unit = ownUnitById(view, command.unitId);
  if (unit == null || !_canClaimMapObjective(unit)) return null;

  final target = _bestObjectiveForMove(command, unit, view);
  if (target == null) return null;

  final objective = target.objective;
  final reward = _objectiveReward(objective);
  final afterDistance = HexDistance.between(
    HexCoordinate(col: command.targetCol, row: command.targetRow),
    objective.hex.toCoordinate(),
  );
  final directClaimBonus = afterDistance == 0 ? 135.0 : 0.0;
  final coreDistance = nearestOwnCityDistance(
    view,
    objective.hex.col,
    objective.hex.row,
  ).clamp(0, 12);

  return CommandRanking(
    CandidatePriority.defense,
    690 +
        reward * 9 +
        target.improvement * 24 +
        directClaimBonus -
        coreDistance.toDouble() * 2,
  );
}

({MapObjectiveDefinition objective, int improvement})? _bestObjectiveForMove(
  MoveUnitCommand command,
  GameUnit unit,
  GameView view,
) {
  MapObjectiveDefinition? best;
  var bestImprovement = 0;
  var bestScore = double.negativeInfinity;

  for (final objective in view.mapData.objectives) {
    if (_objectiveReward(objective) <= 0) continue;
    if (_isCompletedByPlayer(objective, view)) continue;
    if (_isAlreadyControlledByOwnCity(objective, view)) continue;
    if (!_isRememberedObjective(objective, view)) continue;

    final improvement = distanceImprovement(
      fromCol: unit.col,
      fromRow: unit.row,
      toCol: command.targetCol,
      toRow: command.targetRow,
      target: objective.hex.toCoordinate(),
    );
    final afterDistance = HexDistance.between(
      HexCoordinate(col: command.targetCol, row: command.targetRow),
      objective.hex.toCoordinate(),
    );
    if (improvement <= 0 && afterDistance != 0) continue;

    final score =
        (_objectiveReward(objective) * 10 +
                improvement * 30 -
                afterDistance * 4)
            .toDouble();
    if (best == null ||
        score > bestScore ||
        (score == bestScore && objective.id.compareTo(best.id) < 0)) {
      best = objective;
      bestImprovement = improvement;
      bestScore = score;
    }
  }

  return best == null ? null : (objective: best, improvement: bestImprovement);
}

bool _canClaimMapObjective(GameUnit unit) {
  if (unit.isWorking || unit.movementPoints <= 0) return false;
  if (unit.hasSettlers ||
      unit.type == GameUnitType.worker ||
      unit.type == GameUnitType.settler) {
    return false;
  }
  return true;
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
