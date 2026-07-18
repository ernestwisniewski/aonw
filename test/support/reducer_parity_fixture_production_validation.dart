part of 'reducer_parity_fixture.dart';

const _requiredProductionAcceptanceModes = {
  'building',
  'unit',
  'project',
  'wonder',
  'specialization',
  'rush',
};

const _requiredSpecializationRejectionReasons = {
  'city_not_found',
  'city_not_controlled',
  'city_specialization_locked',
  'city_specialization_unchanged',
  'city_specialization_missing_building',
};

const _requiredStartBuildingFixtureIds = {
  'city-production-building-not-found-rejected',
  'city-production-wrong-actor-rejected',
  'city-production-building-wrong-actor-unavailable-rejected',
  'city-production-building-locked-rejected',
  'city-production-building-already-built-rejected',
  'city-production-building-map-requirement-rejected',
  'city-production-overflow-accepted',
  'city-production-building-map-requirement-replacement-accepted',
  'city-production-building-same-target-no-op-accepted',
};

enum _StartBuildingUnavailableCause {
  technologyLocked,
  alreadyBuilt,
  mapRequirementMissing,
}

const _requiredStartBuildingUnavailableCauses = {
  'technologyLocked',
  'alreadyBuilt',
  'mapRequirementMissing',
};

const _requiredStartWonderFixtureIds = {
  'city-production-wonder-not-found-rejected',
  'city-production-wonder-wrong-actor-rejected',
  'city-production-wonder-wrong-actor-unavailable-rejected',
  'city-production-wonder-completed-rejected',
  'city-production-wonder-locked-rejected',
  'city-production-wonder-map-requirement-rejected',
  'city-production-wonder-same-target-rejected',
  'city-production-wonder-other-city-active-rejected',
  'city-production-wonder-overflow-accepted',
  'city-production-wonder-map-requirement-replacement-accepted',
};

enum _StartWonderStatus {
  available,
  completed,
  technologyLocked,
  requirementsMissing,
  cityAlreadyBuildingWonder,
  playerAlreadyBuildingWonder,
}

const _requiredStartWonderUnavailableStatuses = {
  'completed',
  'technologyLocked',
  'requirementsMissing',
  'cityAlreadyBuildingWonder',
  'playerAlreadyBuildingWonder',
};

String _productionAcceptanceMode(ReducerParityFixture fixture) {
  return switch (fixture.command) {
    StartBuildingCommand() => 'building',
    StartUnitProductionCommand() => 'unit',
    StartCityProjectCommand() => 'project',
    StartWonderCommand() => 'wonder',
    SetCitySpecializationCommand() => 'specialization',
    RushProductionCommand() => 'rush',
    _ => throw StateError(
      '${fixture.id} uses an unreviewed city-production command.',
    ),
  };
}

void _requireProductionAcceptanceCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  final actual = summary.productionAcceptanceModes;
  if (actual.length != _requiredProductionAcceptanceModes.length ||
      !actual.containsAll(_requiredProductionAcceptanceModes)) {
    throw StateError(
      '$family acceptance modes must be exactly: '
      '${_requiredProductionAcceptanceModes.toList()..sort()}.',
    );
  }
  final specializationReasons = summary.specializationRejectionReasons;
  if (specializationReasons.length !=
          _requiredSpecializationRejectionReasons.length ||
      !specializationReasons.containsAll(
        _requiredSpecializationRejectionReasons,
      )) {
    throw StateError(
      '$family specialization rejection reasons must be exactly: '
      '${_requiredSpecializationRejectionReasons.toList()..sort()}.',
    );
  }
  final startBuildingFixtureIds = summary.startBuilding.fixtureIds;
  if (startBuildingFixtureIds.length !=
          _requiredStartBuildingFixtureIds.length ||
      !startBuildingFixtureIds.containsAll(_requiredStartBuildingFixtureIds)) {
    throw StateError(
      '$family StartBuilding fixture ids must be exactly: '
      '${_requiredStartBuildingFixtureIds.toList()..sort()}.',
    );
  }
  final unavailableCauses = summary.startBuilding.unavailableCauses;
  if (unavailableCauses.length !=
          _requiredStartBuildingUnavailableCauses.length ||
      !unavailableCauses.containsAll(_requiredStartBuildingUnavailableCauses)) {
    throw StateError(
      '$family StartBuilding building_not_available causes must be exactly: '
      '${_requiredStartBuildingUnavailableCauses.toList()..sort()}.',
    );
  }
  final startWonderFixtureIds = summary.startWonder.fixtureIds;
  if (startWonderFixtureIds.length != _requiredStartWonderFixtureIds.length ||
      !startWonderFixtureIds.containsAll(_requiredStartWonderFixtureIds)) {
    throw StateError(
      '$family StartWonder fixture ids must be exactly: '
      '${_requiredStartWonderFixtureIds.toList()..sort()}.',
    );
  }
  final unavailableStatuses = summary.startWonder.unavailableStatuses;
  if (unavailableStatuses.length !=
          _requiredStartWonderUnavailableStatuses.length ||
      !unavailableStatuses.containsAll(
        _requiredStartWonderUnavailableStatuses,
      )) {
    throw StateError(
      '$family StartWonder wonder_not_available statuses must be exactly: '
      '${_requiredStartWonderUnavailableStatuses.toList()..sort()}.',
    );
  }
}

final class _StartBuildingCorpusSummary {
  final fixtureIds = <String>{};
  final unavailableCauses = <String>{};

  void record(ReducerParityFixture fixture) {
    if (fixture.command is! StartBuildingCommand) return;
    fixtureIds.add(fixture.id);
    final cause = _startBuildingUnavailableCause(fixture);
    if (cause != null) unavailableCauses.add(cause.name);
  }
}

final class _StartWonderCorpusSummary {
  final fixtureIds = <String>{};
  final unavailableStatuses = <String>{};

  void record(ReducerParityFixture fixture) {
    if (fixture.command is! StartWonderCommand) return;
    fixtureIds.add(fixture.id);
    final status = _startWonderUnavailableStatus(fixture);
    if (status != null) unavailableStatuses.add(status.name);
  }
}

bool _permitsReviewedStartBuildingValueNoOp(ReducerParityFixture fixture) {
  return fixture.id == 'city-production-building-same-target-no-op-accepted' &&
      fixture.command is StartBuildingCommand &&
      fixture.expectedAccepted &&
      fixture.expectedReason == null;
}

bool _acceptedFixtureLacksRequiredChange(
  ReducerParityFixture fixture,
  bool changed,
) {
  return !changed && !_permitsReviewedStartBuildingValueNoOp(fixture);
}

_StartBuildingUnavailableCause? _startBuildingUnavailableCause(
  ReducerParityFixture fixture,
) {
  if (fixture.command is! StartBuildingCommand ||
      fixture.expectedReason != 'building_not_available') {
    return null;
  }
  return switch (fixture.id) {
    'city-production-building-locked-rejected' =>
      _StartBuildingUnavailableCause.technologyLocked,
    'city-production-building-already-built-rejected' =>
      _StartBuildingUnavailableCause.alreadyBuilt,
    'city-production-building-map-requirement-rejected' =>
      _StartBuildingUnavailableCause.mapRequirementMissing,
    _ => throw StateError(
      '${fixture.id} uses building_not_available without an explicit '
      'StartBuilding cause classification.',
    ),
  };
}

typedef _StartBuildingAvailability = ({
  bool technologyUnlocked,
  bool alreadyBuilt,
  bool requirementsMet,
});

void _validateStartBuildingCharacterizationFixture(
  ReducerParityFixture fixture,
) {
  final command = fixture.command;
  if (command is! StartBuildingCommand) return;
  _requireReviewedStartBuildingFixtureShape(fixture);

  final city = fixture.state.cities.byId(command.cityId);
  if (fixture.id == 'city-production-building-not-found-rejected') {
    _validateStartBuildingNotFound(fixture, city);
    return;
  }
  if (city == null) {
    ReducerParityCorpus._fail(fixture, 'must target one existing city');
  }
  final availability = _startBuildingAvailability(fixture, command, city);
  if (fixture.id == 'city-production-wrong-actor-rejected' ||
      fixture.id ==
          'city-production-building-wrong-actor-unavailable-rejected') {
    _validateStartBuildingWrongActor(fixture, city, availability);
    return;
  }
  if (city.ownerPlayerId != fixture.actorPlayerId) {
    ReducerParityCorpus._fail(fixture, 'must target an actor-controlled city');
  }

  final unavailableCause = _startBuildingUnavailableCause(fixture);
  if (unavailableCause != null) {
    _validateStartBuildingUnavailableCause(
      fixture,
      unavailableCause,
      availability,
    );
    return;
  }
  _validateAcceptedStartBuildingMode(fixture, command, city, availability);
}

void _requireReviewedStartBuildingFixtureShape(ReducerParityFixture fixture) {
  if (!_requiredStartBuildingFixtureIds.contains(fixture.id)) {
    ReducerParityCorpus._fail(
      fixture,
      'uses an unreviewed StartBuilding characterization id',
    );
  }
  if (fixture.state.cities.length < 2 ||
      fixture.state.cities.first.id != 'city_sentinel' ||
      fixture.state.runtimeState.turnStartedAt == null ||
      fixture.state.runtimeState.submittedPlayerIds.isEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve an unrelated city and non-empty runtime sentinels',
    );
  }
}

void _validateStartBuildingNotFound(
  ReducerParityFixture fixture,
  GameCity? city,
) {
  if (city != null ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'city_not_found') {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize city_not_found before later building checks',
    );
  }
}

_StartBuildingAvailability _startBuildingAvailability(
  ReducerParityFixture fixture,
  StartBuildingCommand command,
  GameCity city,
) {
  return (
    technologyUnlocked: TechnologyUnlockQuery.hasBuildingUnlocked(
      playerId: city.ownerPlayerId,
      buildingType: command.buildingType,
      research: fixture.state.research,
      ruleset: TechnologyRulesets.standard,
    ),
    requirementsMet: CityBuildingRequirementRules.meetsRequirements(
      city: city,
      buildingType: command.buildingType,
      mapTiles: fixture.mapData,
      ruleset: CityRulesets.standard,
      research: fixture.state.research,
    ),
    alreadyBuilt: city.buildings.contains(command.buildingType),
  );
}

void _validateStartBuildingWrongActor(
  ReducerParityFixture fixture,
  GameCity city,
  _StartBuildingAvailability availability,
) {
  final expectedAvailability = switch (fixture.id) {
    'city-production-wrong-actor-rejected' => (
      technologyUnlocked: true,
      alreadyBuilt: false,
      requirementsMet: true,
    ),
    'city-production-building-wrong-actor-unavailable-rejected' => (
      technologyUnlocked: false,
      alreadyBuilt: false,
      requirementsMet: true,
    ),
    _ => throw StateError('${fixture.id} is not a wrong-actor fixture.'),
  };
  if (city.ownerPlayerId == fixture.actorPlayerId ||
      availability != expectedAvailability ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'city_not_controlled') {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize its reviewed city_not_controlled availability mode',
    );
  }
}

void _validateStartBuildingUnavailableCause(
  ReducerParityFixture fixture,
  _StartBuildingUnavailableCause cause,
  _StartBuildingAvailability actual,
) {
  final expected = switch (cause) {
    _StartBuildingUnavailableCause.technologyLocked => (
      technologyUnlocked: false,
      alreadyBuilt: false,
      requirementsMet: true,
    ),
    _StartBuildingUnavailableCause.alreadyBuilt => (
      technologyUnlocked: true,
      alreadyBuilt: true,
      requirementsMet: true,
    ),
    _StartBuildingUnavailableCause.mapRequirementMissing => (
      technologyUnlocked: true,
      alreadyBuilt: false,
      requirementsMet: false,
    ),
  };
  if (actual != expected || fixture.expectedAccepted) {
    ReducerParityCorpus._fail(
      fixture,
      'does not isolate its reviewed building_not_available cause',
    );
  }
}

void _validateAcceptedStartBuildingMode(
  ReducerParityFixture fixture,
  StartBuildingCommand command,
  GameCity city,
  _StartBuildingAvailability availability,
) {
  _requireAcceptedStartBuildingAvailability(fixture, availability);
  switch (fixture.id) {
    case 'city-production-overflow-accepted':
      _validateFreshStartBuildingQueue(fixture, command, city);
    case 'city-production-building-map-requirement-replacement-accepted':
      _validateStartBuildingQueueReplacement(fixture, command, city);
    case 'city-production-building-same-target-no-op-accepted':
      _validateSameTargetStartBuilding(fixture, command, city);
    default:
      ReducerParityCorpus._fail(
        fixture,
        'uses an unreviewed accepted StartBuilding mode',
      );
  }
}

void _requireAcceptedStartBuildingAvailability(
  ReducerParityFixture fixture,
  _StartBuildingAvailability availability,
) {
  if (!fixture.expectedAccepted ||
      fixture.expectedReason != null ||
      !availability.technologyUnlocked ||
      !availability.requirementsMet ||
      availability.alreadyBuilt) {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize an otherwise available accepted building',
    );
  }
}

void _validateFreshStartBuildingQueue(
  ReducerParityFixture fixture,
  StartBuildingCommand command,
  GameCity city,
) {
  if (city.productionQueue != null ||
      command.buildingType != CityBuildingType.workshop ||
      city.productionOverflow != 9 ||
      fixture.save.matchRules.paceBalance.profile != PaceProfile.standard60) {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize a fresh pace-scaled queue with stored overflow',
    );
  }
}

void _validateStartBuildingQueueReplacement(
  ReducerParityFixture fixture,
  StartBuildingCommand command,
  GameCity city,
) {
  final definition = CityRulesets.standard.buildingDefinitionFor(
    command.buildingType,
  );
  final queue = city.productionQueue;
  if (queue == null ||
      queue.target == BuildingProductionTarget(command.buildingType) ||
      definition.requirements.isEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must replace an active queue with a met positive map requirement',
    );
  }
}

void _validateSameTargetStartBuilding(
  ReducerParityFixture fixture,
  StartBuildingCommand command,
  GameCity city,
) {
  if (city.productionQueue?.target !=
      BuildingProductionTarget(command.buildingType)) {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize the accepted same-target value no-op',
    );
  }
}

_StartWonderStatus? _startWonderUnavailableStatus(
  ReducerParityFixture fixture,
) {
  if (fixture.command is! StartWonderCommand ||
      fixture.expectedReason != 'wonder_not_available') {
    return null;
  }
  return switch (fixture.id) {
    'city-production-wonder-completed-rejected' => _StartWonderStatus.completed,
    'city-production-wonder-locked-rejected' =>
      _StartWonderStatus.technologyLocked,
    'city-production-wonder-map-requirement-rejected' =>
      _StartWonderStatus.requirementsMissing,
    'city-production-wonder-same-target-rejected' =>
      _StartWonderStatus.cityAlreadyBuildingWonder,
    'city-production-wonder-other-city-active-rejected' =>
      _StartWonderStatus.playerAlreadyBuildingWonder,
    _ => throw StateError(
      '${fixture.id} uses wonder_not_available without an explicit '
      'StartWonder status classification.',
    ),
  };
}

void _validateStartWonderCharacterizationFixture(ReducerParityFixture fixture) {
  final command = fixture.command;
  if (command is! StartWonderCommand) return;
  _requireReviewedStartWonderFixtureShape(fixture);

  final city = fixture.state.cities.byId(command.cityId);
  if (fixture.id == 'city-production-wonder-not-found-rejected') {
    if (city != null ||
        fixture.expectedAccepted ||
        fixture.expectedReason != 'city_not_found') {
      ReducerParityCorpus._fail(
        fixture,
        'must characterize city_not_found before later wonder checks',
      );
    }
    return;
  }
  if (city == null) {
    ReducerParityCorpus._fail(fixture, 'must target one existing city');
  }

  final status = _reviewedStartWonderStatus(fixture, command, city);
  if (fixture.id == 'city-production-wonder-wrong-actor-rejected') {
    if (city.ownerPlayerId == fixture.actorPlayerId ||
        status != _StartWonderStatus.available ||
        fixture.expectedAccepted ||
        fixture.expectedReason != 'city_not_controlled') {
      ReducerParityCorpus._fail(
        fixture,
        'must characterize an otherwise available wrong-actor wonder',
      );
    }
    return;
  }
  if (fixture.id == 'city-production-wonder-wrong-actor-unavailable-rejected') {
    if (city.ownerPlayerId == fixture.actorPlayerId ||
        status != _StartWonderStatus.cityAlreadyBuildingWonder ||
        city.productionQueue?.target !=
            WonderProductionTarget(command.wonderType) ||
        fixture.expectedAccepted ||
        fixture.expectedReason != 'city_not_controlled') {
      ReducerParityCorpus._fail(
        fixture,
        'must characterize city_not_controlled before an unavailable '
        'same-target wonder',
      );
    }
    return;
  }
  if (city.ownerPlayerId != fixture.actorPlayerId) {
    ReducerParityCorpus._fail(fixture, 'must target an actor-controlled city');
  }

  final unavailableStatus = _startWonderUnavailableStatus(fixture);
  if (unavailableStatus != null) {
    if (status != unavailableStatus ||
        fixture.expectedAccepted ||
        fixture.expectedReason != 'wonder_not_available') {
      ReducerParityCorpus._fail(
        fixture,
        'does not isolate its reviewed wonder_not_available status',
      );
    }
    if (fixture.id == 'city-production-wonder-same-target-rejected' &&
        city.productionQueue?.target !=
            WonderProductionTarget(command.wonderType)) {
      ReducerParityCorpus._fail(
        fixture,
        'must isolate the exact requested wonder as the active target',
      );
    }
    return;
  }

  if (status != _StartWonderStatus.available ||
      !fixture.expectedAccepted ||
      fixture.expectedReason != null) {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize an otherwise available accepted wonder',
    );
  }
  switch (fixture.id) {
    case 'city-production-wonder-overflow-accepted':
      _validateFreshStartWonderQueue(fixture, command, city);
    case 'city-production-wonder-map-requirement-replacement-accepted':
      _validateStartWonderQueueReplacement(fixture, command, city);
    default:
      ReducerParityCorpus._fail(
        fixture,
        'uses an unreviewed accepted StartWonder mode',
      );
  }
}

void _requireReviewedStartWonderFixtureShape(ReducerParityFixture fixture) {
  if (!_requiredStartWonderFixtureIds.contains(fixture.id)) {
    ReducerParityCorpus._fail(
      fixture,
      'uses an unreviewed StartWonder characterization id',
    );
  }
  if (fixture.state.cities.length < 2) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve unrelated city, registry, runtime, and empty-event sentinels',
    );
  }
  final sentinel = fixture.state.cities.first;
  if (sentinel.id != 'city_sentinel' ||
      fixture.state.runtimeState.turnStartedAt == null ||
      fixture.state.runtimeState.submittedPlayerIds.isEmpty ||
      fixture.state.wonderRegistry.ownerOf(WonderType.centralBank) == null ||
      fixture.expectedEvents.isNotEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve unrelated city, registry, runtime, and empty-event sentinels',
    );
  }
}

_StartWonderStatus _reviewedStartWonderStatus(
  ReducerParityFixture fixture,
  StartWonderCommand command,
  GameCity city,
) {
  if (fixture.state.wonderRegistry.ownerOf(command.wonderType) != null) {
    return _StartWonderStatus.completed;
  }
  final definition = WonderRuleset.standard.definitionFor(command.wonderType);
  if (!fixture.state.research
      .forPlayer(city.ownerPlayerId)
      .hasUnlocked(definition.unlockTech)) {
    return _StartWonderStatus.technologyLocked;
  }
  final missingRequirements = WonderRequirementRules.missingRequirements(
    city: city,
    wonderType: command.wonderType,
    mapTiles: fixture.mapData,
    ruleset: WonderRuleset.standard,
    research: fixture.state.research,
  );
  if (missingRequirements.isNotEmpty) {
    return _StartWonderStatus.requirementsMissing;
  }
  if (city.productionQueue?.target is WonderProductionTarget) {
    return _StartWonderStatus.cityAlreadyBuildingWonder;
  }
  for (final otherCity in fixture.state.cities) {
    if (otherCity.id == city.id ||
        otherCity.ownerPlayerId != city.ownerPlayerId) {
      continue;
    }
    if (otherCity.productionQueue?.target is WonderProductionTarget) {
      return _StartWonderStatus.playerAlreadyBuildingWonder;
    }
  }
  return _StartWonderStatus.available;
}

void _validateFreshStartWonderQueue(
  ReducerParityFixture fixture,
  StartWonderCommand command,
  GameCity city,
) {
  final sentinel = fixture.state.cities.first;
  if (command.wonderType != WonderType.petra ||
      city.productionQueue != null ||
      city.productionOverflow != 1000 ||
      fixture.save.matchRules.paceBalance.profile != PaceProfile.standard60 ||
      sentinel.ownerPlayerId == city.ownerPlayerId ||
      sentinel.productionQueue?.target is! WonderProductionTarget) {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize standard60 wonder rollover while ignoring an enemy queue',
    );
  }
}

void _validateStartWonderQueueReplacement(
  ReducerParityFixture fixture,
  StartWonderCommand command,
  GameCity city,
) {
  final definition = WonderRuleset.standard.definitionFor(command.wonderType);
  final queue = city.productionQueue;
  if (command.wonderType != WonderType.petra ||
      queue == null ||
      queue.target is WonderProductionTarget ||
      queue.investedProduction != 7 ||
      city.productionOverflow != 13 ||
      definition.requirements.isEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must replace a non-wonder queue with a met positive map requirement',
    );
  }
}
