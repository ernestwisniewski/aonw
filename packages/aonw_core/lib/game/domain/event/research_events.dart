part of 'game_event.dart';

final class ResearchPointsGainedEvent extends DomainEvent {
  const ResearchPointsGainedEvent({
    required this.playerId,
    required this.points,
  });
  final String playerId;
  final int points;
}

final class TechnologyResearchedEvent extends DomainEvent {
  const TechnologyResearchedEvent({
    required this.playerId,
    required this.technologyId,
  });
  final String playerId;
  final TechnologyId technologyId;
}
