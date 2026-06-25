import 'package:aonw_core/game/domain/objective/map_objective.dart';

enum MapObjectivePressureKind { secureOwnHold, breakOpponentHold }

class MapObjectivePressure {
  final MapObjectivePressureKind kind;
  final int currentHoldTurns;
  final int requiredHoldTurns;

  const MapObjectivePressure({
    required this.kind,
    required this.currentHoldTurns,
    required this.requiredHoldTurns,
  });
}

abstract final class MapObjectivePressureRules {
  static MapObjectivePressure? pressureForPlayer({
    required String playerId,
    required Iterable<MapObjectiveProgress> progress,
  }) {
    MapObjectiveProgress? ownHold;
    MapObjectiveProgress? opponentHold;
    for (final entry in progress) {
      final controller = entry.controllingPlayerId;
      if (controller == null || entry.completed || entry.holdTurns <= 0) {
        continue;
      }
      if (controller == playerId) {
        ownHold = _strongerHold(ownHold, entry);
      } else {
        opponentHold = _strongerHold(opponentHold, entry);
      }
    }

    if (opponentHold != null &&
        (ownHold == null || opponentHold.holdTurns >= ownHold.holdTurns)) {
      return _pressure(
        MapObjectivePressureKind.breakOpponentHold,
        opponentHold,
      );
    }
    if (ownHold != null) {
      return _pressure(MapObjectivePressureKind.secureOwnHold, ownHold);
    }
    return null;
  }

  static MapObjectiveProgress _strongerHold(
    MapObjectiveProgress? current,
    MapObjectiveProgress candidate,
  ) {
    if (current == null) return candidate;
    final currentScore = _pressureScore(current);
    final candidateScore = _pressureScore(candidate);
    return candidateScore > currentScore ? candidate : current;
  }

  static int _pressureScore(MapObjectiveProgress progress) {
    return progress.holdTurns * 100 +
        progress.definition.victoryPoints * 10 +
        progress.definition.goldPerTurn;
  }

  static MapObjectivePressure _pressure(
    MapObjectivePressureKind kind,
    MapObjectiveProgress progress,
  ) {
    return MapObjectivePressure(
      kind: kind,
      currentHoldTurns: progress.holdTurns,
      requiredHoldTurns: progress.definition.requiredHoldTurns,
    );
  }
}
