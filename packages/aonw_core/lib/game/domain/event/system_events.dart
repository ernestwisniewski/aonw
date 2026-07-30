part of 'game_event.dart';

final class CommandRejectedEvent extends GameEvent {
  const CommandRejectedEvent({required this.reason});

  final String reason;
}

final class AllPlayersSubmittedEvent extends DomainEvent {
  AllPlayersSubmittedEvent({
    required this.turn,
    required List<String> playerIds,
  }) : playerIds = List.unmodifiable(playerIds);

  final int turn;
  final List<String> playerIds;
}

final class PlayerTimedOutEvent extends DomainEvent {
  const PlayerTimedOutEvent({required this.turn, required this.playerId});

  final int turn;
  final String playerId;
}

final class TurnAutoResolvedEvent extends DomainEvent {
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

final class PlayerKickedEvent extends DomainEvent {
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

final class CivilizationMetEvent extends DomainEvent {
  const CivilizationMetEvent({
    required this.playerId,
    required this.metPlayerId,
  });

  final String playerId;
  final String metPlayerId;
}
