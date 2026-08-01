part of 'reducer_parity_fixture.dart';

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
  if (_validateStartWonderNotFound(fixture, city)) return;
  if (city == null) {
    ReducerParityCorpus._fail(fixture, 'must target one existing city');
  }

  final status = _reviewedStartWonderStatus(fixture, command, city);
  if (_validateStartWonderWrongActor(fixture, command, city, status)) return;
  if (city.ownerPlayerId != fixture.actorPlayerId) {
    ReducerParityCorpus._fail(fixture, 'must target an actor-controlled city');
  }

  if (_validateStartWonderUnavailable(fixture, command, city, status)) return;
  _validateAcceptedStartWonder(fixture, command, city, status);
}

bool _validateStartWonderNotFound(
  ReducerParityFixture fixture,
  GameCity? city,
) {
  if (fixture.id != 'city-production-wonder-not-found-rejected') return false;
  if (city != null ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'city_not_found') {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize city_not_found before later wonder checks',
    );
  }
  return true;
}

bool _validateStartWonderWrongActor(
  ReducerParityFixture fixture,
  StartWonderCommand command,
  GameCity city,
  _StartWonderStatus status,
) {
  switch (fixture.id) {
    case 'city-production-wonder-wrong-actor-rejected':
      _validateAvailableStartWonderWrongActor(fixture, city, status);
      return true;
    case 'city-production-wonder-wrong-actor-unavailable-rejected':
      _validateUnavailableStartWonderWrongActor(fixture, command, city, status);
      return true;
    default:
      return false;
  }
}

void _validateAvailableStartWonderWrongActor(
  ReducerParityFixture fixture,
  GameCity city,
  _StartWonderStatus status,
) {
  if (city.ownerPlayerId == fixture.actorPlayerId ||
      status != _StartWonderStatus.available ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'city_not_controlled') {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize an otherwise available wrong-actor wonder',
    );
  }
}

void _validateUnavailableStartWonderWrongActor(
  ReducerParityFixture fixture,
  StartWonderCommand command,
  GameCity city,
  _StartWonderStatus status,
) {
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
}

bool _validateStartWonderUnavailable(
  ReducerParityFixture fixture,
  StartWonderCommand command,
  GameCity city,
  _StartWonderStatus status,
) {
  final unavailableStatus = _startWonderUnavailableStatus(fixture);
  if (unavailableStatus == null) return false;
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
  return true;
}

void _validateAcceptedStartWonder(
  ReducerParityFixture fixture,
  StartWonderCommand command,
  GameCity city,
  _StartWonderStatus status,
) {
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
      fixture.state.turnStartedAt == null ||
      fixture.state.submittedPlayerIds.isEmpty ||
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
