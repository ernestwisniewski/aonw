part of 'game_event.dart';

final class CommandRejectedEvent extends GameEvent {
  const CommandRejectedEvent({required this.reason});

  final String reason;
}

final class AllPlayersSubmittedEvent extends GameEvent {
  AllPlayersSubmittedEvent({
    required this.turn,
    required List<String> playerIds,
  }) : playerIds = List.unmodifiable(playerIds);

  final int turn;
  final List<String> playerIds;
}

final class PlayerTimedOutEvent extends GameEvent {
  const PlayerTimedOutEvent({required this.turn, required this.playerId});

  final int turn;
  final String playerId;
}

final class TurnAutoResolvedEvent extends GameEvent {
  const TurnAutoResolvedEvent({
    required this.turn,
    required this.playerId,
    required this.unitOrderCount,
    required this.cityProductionCount,
    required this.researchSelected,
  });

  final int turn;
  final String playerId;
  final int unitOrderCount;
  final int cityProductionCount;
  final bool researchSelected;
}

final class PlayerKickedEvent extends GameEvent {
  const PlayerKickedEvent({
    required this.turn,
    required this.playerId,
    required this.reason,
    required this.timeoutStreak,
  });

  final int turn;
  final String playerId;
  final String reason;
  final int timeoutStreak;
}

final class CivilizationMetEvent extends GameEvent {
  const CivilizationMetEvent({
    required this.playerId,
    required this.metPlayerId,
  });

  final String playerId;
  final String metPlayerId;
}
