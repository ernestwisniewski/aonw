part of 'game_event.dart';

final class UnitAttackedEvent extends DomainEvent {
  const UnitAttackedEvent({
    required this.attackerUnitId,
    required this.attackerOwnerPlayerId,
    required this.defenderUnitId,
    required this.defenderOwnerPlayerId,
  });

  final String attackerUnitId;
  final String attackerOwnerPlayerId;
  final String defenderUnitId;
  final String defenderOwnerPlayerId;
}

final class CombatResolvedEvent extends DomainEvent {
  const CombatResolvedEvent({
    required this.attackerUnitId,
    required this.defenderUnitId,
    required this.outcome,
  });

  final String attackerUnitId;
  final String defenderUnitId;
  final CombatOutcome outcome;
}

final class UnitKilledEvent extends DomainEvent {
  const UnitKilledEvent({
    required this.unitId,
    required this.ownerPlayerId,
    this.attackerUnitId,
  });

  final String unitId;
  final String ownerPlayerId;
  final String? attackerUnitId;
}

final class UnitRetreatedEvent extends DomainEvent {
  const UnitRetreatedEvent({
    required this.unitId,
    required this.ownerPlayerId,
    required this.fromCol,
    required this.fromRow,
    required this.toCol,
    required this.toRow,
  });

  final String unitId;
  final String ownerPlayerId;
  final int fromCol;
  final int fromRow;
  final int toCol;
  final int toRow;
}

final class CityAttackedEvent extends DomainEvent {
  const CityAttackedEvent({
    required this.attackerUnitId,
    required this.attackerOwnerPlayerId,
    required this.cityId,
    required this.cityOwnerPlayerId,
  });

  final String attackerUnitId;
  final String attackerOwnerPlayerId;
  final String cityId;
  final String cityOwnerPlayerId;
}

final class CityCapturedEvent extends DomainEvent {
  const CityCapturedEvent({
    required this.cityId,
    required this.previousOwnerPlayerId,
    required this.newOwnerPlayerId,
  });

  final String cityId;
  final String previousOwnerPlayerId;
  final String newOwnerPlayerId;
}

final class CityDestroyedEvent extends DomainEvent {
  const CityDestroyedEvent({
    required this.cityId,
    required this.previousOwnerPlayerId,
    required this.attackerOwnerPlayerId,
  });

  final String cityId;
  final String previousOwnerPlayerId;
  final String attackerOwnerPlayerId;
}
