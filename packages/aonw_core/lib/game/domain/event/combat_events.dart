part of 'game_event.dart';

final class UnitAttackedEvent extends GameEvent {
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

final class CombatResolvedEvent extends GameEvent {
  const CombatResolvedEvent({
    required this.attackerUnitId,
    required this.defenderUnitId,
    required this.outcome,
  });

  final String attackerUnitId;
  final String defenderUnitId;
  final CombatOutcome outcome;
}

final class UnitKilledEvent extends GameEvent {
  const UnitKilledEvent({
    required this.unitId,
    required this.ownerPlayerId,
    this.attackerUnitId,
  });

  final String unitId;
  final String ownerPlayerId;
  final String? attackerUnitId;
}

final class UnitRetreatedEvent extends GameEvent {
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

final class CityCapturedEvent extends GameEvent {
  const CityCapturedEvent({
    required this.cityId,
    required this.previousOwnerPlayerId,
    required this.newOwnerPlayerId,
  });

  final String cityId;
  final String previousOwnerPlayerId;
  final String newOwnerPlayerId;
}

final class CityDestroyedEvent extends GameEvent {
  const CityDestroyedEvent({
    required this.cityId,
    required this.previousOwnerPlayerId,
    required this.attackerOwnerPlayerId,
  });

  final String cityId;
  final String previousOwnerPlayerId;
  final String attackerOwnerPlayerId;
}
