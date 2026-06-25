part of 'game_event.dart';

final class UnitMovedEvent extends GameEvent {
  const UnitMovedEvent({
    required this.unitId,
    required this.fromCol,
    required this.fromRow,
    required this.toCol,
    required this.toRow,
  });
  final String unitId;
  final int fromCol;
  final int fromRow;
  final int toCol;
  final int toRow;
}

final class UnitGainedExperienceEvent extends GameEvent {
  const UnitGainedExperienceEvent({
    required this.unitId,
    required this.ownerPlayerId,
    required this.amount,
    required this.totalExperience,
    required this.rank,
    required this.promoted,
  });

  final String unitId;
  final String ownerPlayerId;
  final int amount;
  final int totalExperience;
  final UnitVeterancyRank rank;
  final bool promoted;
}
