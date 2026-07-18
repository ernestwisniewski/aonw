part of 'reducer_parity_fixture.dart';

const _cityFoundingSentinelUnitId = 'founding_unit_sentinel';
const _cityFoundingSentinelCityId = 'founding_city_sentinel';

String _cityFoundingAcceptanceMode(ReducerParityFixture fixture) {
  final command = fixture.command;
  if (command is FoundCityCommand &&
      command.controlledHexes.length ==
          CityFoundingDraft.requiredControlledHexes &&
      fixture.state.runtimeState.cityFoundingDraft == null &&
      fixture.state.runtimeState.pendingAction == null) {
    return 'self-contained';
  }
  return 'unexpected';
}

void _requireCityFoundingAcceptanceCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  if (summary.cityFoundingAcceptanceModes.length != 1 ||
      !summary.cityFoundingAcceptanceModes.contains('self-contained')) {
    throw StateError(
      '$family needs exactly the self-contained explicit-payload acceptance mode.',
    );
  }
}

void _requireAcceptedParityCityFounding(
  ReducerParityFixture fixture,
  PersistentGameState state,
  List<GameEvent> events,
) {
  final command = fixture.command as FoundCityCommand;
  _requireCityFoundingEnvelope(fixture, events);

  final founderIndex = _cityFoundingFounderIndex(fixture, command.founderId);
  final founder = fixture.state.units[founderIndex];
  _requireEligibleCityFounder(fixture, founder);
  _requireCityFoundingSentinels(fixture, command.founderId);

  final draft = CityFoundingDraft(
    unitId: founder.id,
    ownerPlayerId: founder.ownerPlayerId,
    center: CityHex(col: founder.col, row: founder.row),
    controlledHexes: command.controlledHexes,
  );
  _requireValidCityFoundingDraft(fixture, command, founder, draft);

  final expectedState = _expectedCityFoundingState(
    fixture,
    command,
    founder,
    founderIndex,
    draft,
  );
  if (!_jsonDeepEquals(fixture.expectedState, expectedState.toJson()) ||
      !_jsonDeepEquals(state.toJson(), expectedState.toJson())) {
    ReducerParityCorpus._fail(
      fixture,
      'must only schedule the independently derived founding job',
    );
  }
}

void _requireCityFoundingEnvelope(
  ReducerParityFixture fixture,
  List<GameEvent> events,
) {
  if (!_jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save)) ||
      events.isNotEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve save metadata without emitting events',
    );
  }
  if (_cityFoundingAcceptanceMode(fixture) != 'self-contained') {
    ReducerParityCorpus._fail(
      fixture,
      'must carry a complete payload without client interaction state',
    );
  }
}

int _cityFoundingFounderIndex(ReducerParityFixture fixture, String founderId) {
  final founderIndex = fixture.state.units.indexWhere(
    (unit) => unit.id == founderId,
  );
  final founderCount = fixture.state.units
      .where((unit) => unit.id == founderId)
      .length;
  if (founderIndex < 0 || founderCount != 1) {
    ReducerParityCorpus._fail(fixture, 'must target one existing founder');
  }
  return founderIndex;
}

void _requireEligibleCityFounder(
  ReducerParityFixture fixture,
  GameUnit founder,
) {
  if (founder.ownerPlayerId != fixture.actorPlayerId ||
      founder.isWorking ||
      founder.movementPoints <= 0 ||
      founder.queuedPath == null ||
      founder.cityFoundingJob != null) {
    ReducerParityCorpus._fail(
      fixture,
      'must target one mobile, queued, idle founder controlled by the actor',
    );
  }
}

void _requireValidCityFoundingDraft(
  ReducerParityFixture fixture,
  FoundCityCommand command,
  GameUnit founder,
  CityFoundingDraft draft,
) {
  final startFailure = CityFoundingRules.startFailure(
    unit: founder,
    centerTile: fixture.mapData.tileAt(founder.col, founder.row),
    cities: fixture.state.cities,
  );
  if (startFailure != null || CityFoundingRules.confirmFailure(draft) != null) {
    ReducerParityCorpus._fail(
      fixture,
      'must contain an independently valid explicit founding payload',
    );
  }
  if (command.controlledHexes.toSet().length !=
      command.controlledHexes.length) {
    ReducerParityCorpus._fail(fixture, 'must contain unique controlled hexes');
  }
  for (final hex in command.controlledHexes) {
    final tile = fixture.mapData.tileAt(hex.col, hex.row);
    if (tile == null ||
        !CityFoundingRules.isControlledHexCandidate(
          draft: draft,
          tile: tile,
          mapTiles: fixture.mapData,
          cities: fixture.state.cities,
        )) {
      ReducerParityCorpus._fail(
        fixture,
        'must contain valid controlled hex candidates',
      );
    }
  }
}

PersistentGameState _expectedCityFoundingState(
  ReducerParityFixture fixture,
  FoundCityCommand command,
  GameUnit founder,
  int founderIndex,
  CityFoundingDraft draft,
) {
  final updatedFounder = founder
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(null)
      .copyWithCityFoundingJob(
        CityFoundingJob(
          center: draft.center,
          controlledHexes: command.controlledHexes,
          remainingTurns: 1,
          totalTurns: 1,
        ),
      );
  final expectedUnits = [
    for (var index = 0; index < fixture.state.units.length; index++)
      if (index == founderIndex) updatedFounder else fixture.state.units[index],
  ];
  return fixture.state.copyWith(units: expectedUnits);
}

void _requireCityFoundingSentinels(
  ReducerParityFixture fixture,
  String founderId,
) {
  final units = fixture.state.units;
  final cities = fixture.state.cities;
  final founderIndex = units.indexWhere((unit) => unit.id == founderId);
  final sentinelUnitIndex = units.indexWhere(
    (unit) => unit.id == _cityFoundingSentinelUnitId,
  );
  final sentinelCityIndex = cities.indexWhere(
    (city) => city.id == _cityFoundingSentinelCityId,
  );
  final sentinelUnitCount = units
      .where((unit) => unit.id == _cityFoundingSentinelUnitId)
      .length;
  final sentinelCityCount = cities
      .where((city) => city.id == _cityFoundingSentinelCityId)
      .length;
  if (sentinelUnitIndex < 0 ||
      sentinelCityIndex < 0 ||
      sentinelUnitCount != 1 ||
      sentinelCityCount != 1 ||
      sentinelUnitIndex >= founderIndex ||
      units[sentinelUnitIndex].movementPoints <= 0 ||
      fixture.state.runtimeState.submittedPlayerIds.isEmpty ||
      fixture.state.runtimeState.turnStartedAt == null) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve unrelated unit, city, and runtime sentinels',
    );
  }
}
