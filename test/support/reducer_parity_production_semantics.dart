import 'package:aonw_core/domain.dart';

import 'reducer_parity_contract.dart';

bool tryRequireProduction(
  String fixtureId,
  GameCommand command,
  PersistentGameState after,
  List<GameEvent> events,
) {
  if (!reducerParityCommandMatchesFamily('city-production', command)) {
    return false;
  }
  final (cityId, target, failure) = switch (command) {
    StartBuildingCommand(:final cityId, :final buildingType) => (
      cityId,
      BuildingProductionTarget(buildingType),
      'must commit the reviewed building queue',
    ),
    StartUnitProductionCommand(:final cityId, :final unitType) => (
      cityId,
      UnitProductionTarget(unitType),
      'must commit the reviewed unit queue without events',
    ),
    StartWonderCommand(:final cityId, :final wonderType) => (
      cityId,
      WonderProductionTarget(wonderType),
      'must commit the reviewed wonder queue without events',
    ),
    _ => throw StateError('Expected a production command.'),
  };
  if (after.cities.byId(cityId)?.productionQueue?.target != target ||
      (command is StartUnitProductionCommand ||
              command is StartWonderCommand) &&
          events.isNotEmpty) {
    throw FormatException('$fixtureId $failure.');
  }
  return true;
}
