import 'package:aonw_core/domain.dart';

import 'reducer_parity_contract.dart';

bool tryRequireProduction(
  String fixtureId,
  GameCommand command,
  PersistentGameState before,
  PersistentGameState after,
  List<GameEvent> events,
) {
  if (!reducerParityCommandMatchesFamily('city-production', command)) {
    return false;
  }
  switch (command) {
    case final RushProductionCommand command:
      _requireAcceptedRushProduction(fixtureId, command, before, after, events);
    case StartBuildingCommand(:final cityId, :final buildingType):
      _requireAcceptedProductionQueue(
        fixtureId: fixtureId,
        cityId: cityId,
        target: BuildingProductionTarget(buildingType),
        after: after,
        events: events,
        eventsMustBeEmpty: false,
        failure: 'must commit the reviewed building queue',
      );
    case StartUnitProductionCommand(:final cityId, :final unitType):
      _requireAcceptedProductionQueue(
        fixtureId: fixtureId,
        cityId: cityId,
        target: UnitProductionTarget(unitType),
        after: after,
        events: events,
        eventsMustBeEmpty: true,
        failure: 'must commit the reviewed unit queue without events',
      );
    case StartWonderCommand(:final cityId, :final wonderType):
      _requireAcceptedProductionQueue(
        fixtureId: fixtureId,
        cityId: cityId,
        target: WonderProductionTarget(wonderType),
        after: after,
        events: events,
        eventsMustBeEmpty: true,
        failure: 'must commit the reviewed wonder queue without events',
      );
    default:
      throw StateError('Expected a production command.');
  }
  return true;
}

void _requireAcceptedRushProduction(
  String fixtureId,
  RushProductionCommand command,
  PersistentGameState before,
  PersistentGameState after,
  List<GameEvent> events,
) {
  final beforeQueue = before.cities.byId(command.cityId)?.productionQueue;
  final afterQueue = after.cities.byId(command.cityId)?.productionQueue;
  final progressed =
      beforeQueue != null &&
      afterQueue?.target == beforeQueue.target &&
      afterQueue!.investedProduction > beforeQueue.investedProduction;
  final completed =
      beforeQueue != null && afterQueue == null && events.isNotEmpty;
  if (!progressed && !completed) {
    throw FormatException(
      '$fixtureId must advance or complete the reviewed rush queue.',
    );
  }
}

void _requireAcceptedProductionQueue({
  required String fixtureId,
  required String cityId,
  required CityProductionTarget target,
  required PersistentGameState after,
  required List<GameEvent> events,
  required bool eventsMustBeEmpty,
  required String failure,
}) {
  if (after.cities.byId(cityId)?.productionQueue?.target != target ||
      eventsMustBeEmpty && events.isNotEmpty) {
    throw FormatException('$fixtureId $failure.');
  }
}
