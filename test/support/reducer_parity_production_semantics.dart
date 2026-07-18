import 'package:aonw_core/domain.dart';

import 'reducer_parity_contract.dart';

bool tryRequireProduction(
  String fixtureId,
  GameCommand command,
  String actorPlayerId,
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
    case final StartCityProjectCommand command:
      _requireAcceptedCityProject(fixtureId, command, before, after, events);
    case final SetCitySpecializationCommand command:
      _requireAcceptedCitySpecialization(
        fixtureId,
        command,
        actorPlayerId,
        before,
        after,
        events,
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

void _requireAcceptedCitySpecialization(
  String fixtureId,
  SetCitySpecializationCommand command,
  String actorPlayerId,
  PersistentGameState before,
  PersistentGameState after,
  List<GameEvent> events,
) {
  final cityIndex = before.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (cityIndex < 0 ||
      before.cities.length < 2 ||
      before.runtimeState.turnStartedAt == null ||
      events.isNotEmpty) {
    throw FormatException(
      '$fixtureId must target an existing city beside an unrelated sentinel, '
      'preserve runtime state, and emit no events.',
    );
  }

  final beforeCity = before.cities[cityIndex];
  final specializationUnlocked = before.research
      .forPlayer(beforeCity.ownerPlayerId)
      .hasUnlocked(TechnologyId.specialization);
  if (beforeCity.ownerPlayerId != actorPlayerId ||
      !specializationUnlocked ||
      beforeCity.specialization == command.specialization ||
      !CitySpecializationRules.hasRequiredBuilding(
        beforeCity.buildings,
        command.specialization,
      )) {
    throw FormatException(
      '$fixtureId must characterize a controlled, unlocked, changed '
      'specialization with its required building.',
    );
  }

  final expectedCities = [...before.cities]
    ..[cityIndex] = beforeCity.copyWith(specialization: command.specialization);
  final expectedState = before.copyWith(cities: expectedCities);
  if (after != expectedState) {
    throw FormatException(
      '$fixtureId must only replace the target city specialization while '
      'preserving city order, sentinels, production, and unrelated state.',
    );
  }
}

void _requireAcceptedCityProject(
  String fixtureId,
  StartCityProjectCommand command,
  PersistentGameState before,
  PersistentGameState after,
  List<GameEvent> events,
) {
  final cityIndex = before.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (cityIndex < 0 || before.cities.length < 2 || events.isNotEmpty) {
    throw FormatException(
      '$fixtureId must target an existing city beside an unrelated sentinel '
      'without emitting events.',
    );
  }

  final beforeCity = before.cities[cityIndex];
  final activeInvestment = beforeCity.productionQueue?.investedProduction;
  final expectedCity = beforeCity.copyWith(
    productionQueue: CityProductionQueue.target(
      target: ProjectProductionTarget(command.projectType),
      investedProduction: activeInvestment ?? 0,
    ),
    productionOverflow: activeInvestment == null
        ? 0
        : beforeCity.productionOverflow,
  );
  final expectedCities = [...before.cities]..[cityIndex] = expectedCity;
  final expectedState = before.copyWith(cities: expectedCities);
  if (after != expectedState) {
    throw FormatException(
      '$fixtureId must only replace the target city queue while preserving '
      'investment, overflow, city order, sentinels, and unrelated state.',
    );
  }
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
