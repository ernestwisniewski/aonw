import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/util/wire_json.dart';

/// Wire codec for combat and conquest events.
abstract final class CombatEventSerializer {
  static Map<String, dynamic> toJson(GameEvent event) {
    return switch (event) {
      UnitAttackedEvent() => _unitAttackedToJson(event),
      CombatResolvedEvent() => _combatResolvedToJson(event),
      UnitKilledEvent() => _unitKilledToJson(event),
      UnitRetreatedEvent() => _unitRetreatedToJson(event),
      CityAttackedEvent() => _cityAttackedToJson(event),
      CityCapturedEvent() => _cityCapturedToJson(event),
      CityDestroyedEvent() => _cityDestroyedToJson(event),
      _ => throw ArgumentError.value(event, 'event', 'Not a combat event'),
    };
  }

  static GameEvent? tryFromJson(Map<String, dynamic> json, String type) {
    return switch (type) {
      'UnitAttacked' => _unitAttackedFromJson(json, type),
      'CombatResolved' => _combatResolvedFromJson(json, type),
      'UnitKilled' => _unitKilledFromJson(json, type),
      'UnitRetreated' => _unitRetreatedFromJson(json, type),
      'CityAttacked' => _cityAttackedFromJson(json, type),
      'CityCaptured' => _cityCapturedFromJson(json, type),
      'CityDestroyed' => _cityDestroyedFromJson(json, type),
      _ => null,
    };
  }
}

Map<String, dynamic> _unitAttackedToJson(UnitAttackedEvent event) => {
  'type': 'UnitAttacked',
  'attackerUnitId': event.attackerUnitId,
  'attackerOwnerPlayerId': event.attackerOwnerPlayerId,
  'defenderUnitId': event.defenderUnitId,
  'defenderOwnerPlayerId': event.defenderOwnerPlayerId,
};

Map<String, dynamic> _combatResolvedToJson(CombatResolvedEvent event) => {
  'type': 'CombatResolved',
  'attackerUnitId': event.attackerUnitId,
  'defenderUnitId': event.defenderUnitId,
  'outcome': CombatOutcomeSerializer.toJson(event.outcome),
};

Map<String, dynamic> _unitKilledToJson(UnitKilledEvent event) => {
  'type': 'UnitKilled',
  'unitId': event.unitId,
  'ownerPlayerId': event.ownerPlayerId,
  'attackerUnitId': ?event.attackerUnitId,
};

Map<String, dynamic> _unitRetreatedToJson(UnitRetreatedEvent event) => {
  'type': 'UnitRetreated',
  'unitId': event.unitId,
  'ownerPlayerId': event.ownerPlayerId,
  'fromCol': event.fromCol,
  'fromRow': event.fromRow,
  'toCol': event.toCol,
  'toRow': event.toRow,
};

Map<String, dynamic> _cityAttackedToJson(CityAttackedEvent event) => {
  'type': 'CityAttacked',
  'attackerUnitId': event.attackerUnitId,
  'attackerOwnerPlayerId': event.attackerOwnerPlayerId,
  'cityId': event.cityId,
  'cityOwnerPlayerId': event.cityOwnerPlayerId,
};

Map<String, dynamic> _cityCapturedToJson(CityCapturedEvent event) => {
  'type': 'CityCaptured',
  'cityId': event.cityId,
  'previousOwnerPlayerId': event.previousOwnerPlayerId,
  'newOwnerPlayerId': event.newOwnerPlayerId,
};

Map<String, dynamic> _cityDestroyedToJson(CityDestroyedEvent event) => {
  'type': 'CityDestroyed',
  'cityId': event.cityId,
  'previousOwnerPlayerId': event.previousOwnerPlayerId,
  'attackerOwnerPlayerId': event.attackerOwnerPlayerId,
};

UnitAttackedEvent _unitAttackedFromJson(
  Map<String, dynamic> json,
  String type,
) => UnitAttackedEvent(
  attackerUnitId: requiredStringField(json, type, 'attackerUnitId'),
  attackerOwnerPlayerId: requiredStringField(
    json,
    type,
    'attackerOwnerPlayerId',
  ),
  defenderUnitId: requiredStringField(json, type, 'defenderUnitId'),
  defenderOwnerPlayerId: requiredStringField(
    json,
    type,
    'defenderOwnerPlayerId',
  ),
);

CombatResolvedEvent _combatResolvedFromJson(
  Map<String, dynamic> json,
  String type,
) => CombatResolvedEvent(
  attackerUnitId: requiredStringField(json, type, 'attackerUnitId'),
  defenderUnitId: requiredStringField(json, type, 'defenderUnitId'),
  outcome: CombatOutcomeSerializer.fromJson(
    requiredMapValue(json['outcome'], '$type.outcome'),
  ),
);

UnitKilledEvent _unitKilledFromJson(Map<String, dynamic> json, String type) =>
    UnitKilledEvent(
      unitId: requiredStringField(json, type, 'unitId'),
      ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
      attackerUnitId: optionalStringField(json, type, 'attackerUnitId'),
    );

UnitRetreatedEvent _unitRetreatedFromJson(
  Map<String, dynamic> json,
  String type,
) => UnitRetreatedEvent(
  unitId: requiredStringField(json, type, 'unitId'),
  ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
  fromCol: requiredIntField(json, type, 'fromCol'),
  fromRow: requiredIntField(json, type, 'fromRow'),
  toCol: requiredIntField(json, type, 'toCol'),
  toRow: requiredIntField(json, type, 'toRow'),
);

CityAttackedEvent _cityAttackedFromJson(
  Map<String, dynamic> json,
  String type,
) => CityAttackedEvent(
  attackerUnitId: requiredStringField(json, type, 'attackerUnitId'),
  attackerOwnerPlayerId: requiredStringField(
    json,
    type,
    'attackerOwnerPlayerId',
  ),
  cityId: requiredStringField(json, type, 'cityId'),
  cityOwnerPlayerId: requiredStringField(json, type, 'cityOwnerPlayerId'),
);

CityCapturedEvent _cityCapturedFromJson(
  Map<String, dynamic> json,
  String type,
) => CityCapturedEvent(
  cityId: requiredStringField(json, type, 'cityId'),
  previousOwnerPlayerId: requiredStringField(
    json,
    type,
    'previousOwnerPlayerId',
  ),
  newOwnerPlayerId: requiredStringField(json, type, 'newOwnerPlayerId'),
);

CityDestroyedEvent _cityDestroyedFromJson(
  Map<String, dynamic> json,
  String type,
) => CityDestroyedEvent(
  cityId: requiredStringField(json, type, 'cityId'),
  previousOwnerPlayerId: requiredStringField(
    json,
    type,
    'previousOwnerPlayerId',
  ),
  attackerOwnerPlayerId: requiredStringField(
    json,
    type,
    'attackerOwnerPlayerId',
  ),
);
