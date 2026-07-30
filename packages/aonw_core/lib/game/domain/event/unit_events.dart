part of 'game_event.dart';

final class UnitMovedEvent extends DomainEvent {
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

final class FortifiedUnitThreatTarget {
  const FortifiedUnitThreatTarget({
    required this.unitId,
    required this.col,
    required this.row,
  });

  final String unitId;
  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is FortifiedUnitThreatTarget &&
      other.unitId == unitId &&
      other.col == col &&
      other.row == row;

  @override
  int get hashCode => Object.hash(unitId, col, row);
}

final class FortifiedUnitThreatenedEvent extends DomainEvent {
  FortifiedUnitThreatenedEvent({
    required this.unitId,
    required this.ownerPlayerId,
    required Iterable<FortifiedUnitThreatTarget> targets,
  }) : targets = List.unmodifiable(targets);

  final String unitId;
  final String ownerPlayerId;
  final List<FortifiedUnitThreatTarget> targets;
}

final class UnitGainedExperienceEvent extends DomainEvent {
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
