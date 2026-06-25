part of 'game_event.dart';

final class ResearchPointsGainedEvent extends GameEvent {
  const ResearchPointsGainedEvent({
    required this.playerId,
    required this.points,
  });
  final String playerId;
  final int points;
}

final class TechnologyResearchedEvent extends GameEvent {
  const TechnologyResearchedEvent({
    required this.playerId,
    required this.technologyId,
  });
  final String playerId;
  final TechnologyId technologyId;
}
