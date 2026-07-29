part of 'game_event.dart';

final class TurnEndedEvent extends DomainEvent {
  const TurnEndedEvent({required this.playerId});
  final String playerId;
}

final class WorkerCompletedJobEvent extends DomainEvent {
  const WorkerCompletedJobEvent({required this.unitId});
  final String unitId;
}

final class DominationThresholdReachedEvent extends DomainEvent {
  const DominationThresholdReachedEvent({
    required this.playerId,
    required this.controlPercent,
    required this.requiredControlPercent,
    required this.holdTurns,
    required this.requiredHoldTurns,
  });

  final String playerId;
  final double controlPercent;
  final double requiredControlPercent;
  final int holdTurns;
  final int requiredHoldTurns;
}
