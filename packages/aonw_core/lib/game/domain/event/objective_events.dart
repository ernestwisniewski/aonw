part of 'game_event.dart';

final class MapObjectiveSecuredEvent extends GameEvent {
  const MapObjectiveSecuredEvent({
    required this.playerId,
    required this.objectiveId,
    required this.objectiveType,
    required this.col,
    required this.row,
    required this.holdTurns,
    required this.requiredHoldTurns,
    required this.victoryPoints,
    required this.goldPerTurn,
  });

  final String playerId;
  final String objectiveId;
  final MapObjectiveType objectiveType;
  final int col;
  final int row;
  final int holdTurns;
  final int requiredHoldTurns;
  final int victoryPoints;
  final int goldPerTurn;
}
