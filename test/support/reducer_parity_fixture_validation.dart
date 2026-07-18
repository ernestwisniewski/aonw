part of 'reducer_parity_fixture.dart';

void _validateReducerParityCorpus(List<ReducerParityFixture> fixtures) {
  final summary = _ReducerParityCorpusSummary();
  for (final fixture in fixtures) {
    summary.record(fixture);
  }
  _requireExactReducerParityFamilies(summary.coverage.keys.toSet());
  for (final family in reducerParityRequiredFamilies) {
    _requireReducerParityFamilyCoverage(summary, family);
  }
}

final class _ReducerParityCorpusSummary {
  final ids = <String>{};
  final coverage = <String, Set<bool>>{};
  final acceptedCountByFamily = <String, int>{};
  final rejectionReasonsByFamily = <String, Set<String>>{};
  final resourceTradeAcceptanceModes = <String>{};
  final cityWorkedHexAcceptanceModes = <String>{};
  final turnAcceptanceModes = <String>{};

  void record(ReducerParityFixture fixture) {
    if (!ids.add(fixture.id)) {
      throw StateError('Duplicate reducer parity fixture id: ${fixture.id}.');
    }
    coverage
        .putIfAbsent(fixture.family, () => <bool>{})
        .add(fixture.expectedAccepted);
    if (fixture.expectedAccepted) {
      _recordAcceptance(fixture);
    } else {
      rejectionReasonsByFamily
          .putIfAbsent(fixture.family, () => <String>{})
          .add(fixture.expectedReason!);
    }
  }

  void _recordAcceptance(ReducerParityFixture fixture) {
    acceptedCountByFamily.update(
      fixture.family,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    switch (fixture.family) {
      case 'turn-finalization':
        turnAcceptanceModes.add(
          fixture.expectedSave['turn'] == fixture.save.turn
              ? 'waiting'
              : 'finalizing',
        );
      case 'resource-trade':
        resourceTradeAcceptanceModes.add(switch (fixture.command) {
          OpenResourceTradeCommand() => 'gold',
          OpenResourceExchangeCommand() => 'exchange',
          _ => 'unexpected',
        });
      case 'city-worked-hex':
        final command = fixture.command as ToggleWorkedHexCommand;
        final city = fixture.state.cities.singleWhere(
          (candidate) => candidate.id == command.cityId,
        );
        final target = CityHex(col: command.col, row: command.row);
        cityWorkedHexAcceptanceModes.add(
          city.workedHexes.contains(target) ? 'remove' : 'add',
        );
    }
  }
}

void _requireExactReducerParityFamilies(Set<String> actualFamilies) {
  final unexpected = actualFamilies.difference(reducerParityRequiredFamilies);
  final missing = reducerParityRequiredFamilies.difference(actualFamilies);
  if (unexpected.isNotEmpty || missing.isNotEmpty) {
    throw StateError(
      'Reducer parity families must be exactly: '
      '${reducerParityRequiredFamilies.toList()..sort()}.',
    );
  }
}

void _requireReducerParityFamilyCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  if (summary.coverage[family]?.containsAll(const {true, false}) != true) {
    throw StateError('$family needs accepted and rejected parity fixtures.');
  }
  switch (family) {
    case 'turn-finalization':
      _requireTurnFinalizationAcceptanceCoverage(summary, family);
    case 'resource-trade':
      _requireResourceTradeAcceptanceCoverage(summary, family);
    case 'city-worked-hex':
      _requireCityWorkedHexAcceptanceCoverage(summary, family);
  }
  _requireRejectionCoverage(summary, family);
}

void _requireCityWorkedHexAcceptanceCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  if (!summary.cityWorkedHexAcceptanceModes.containsAll(const {
    'add',
    'remove',
  })) {
    throw StateError('$family needs accepted add and remove parity fixtures.');
  }
}

void _requireTurnFinalizationAcceptanceCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  if ((summary.acceptedCountByFamily[family] ?? 0) < 2 ||
      !summary.turnAcceptanceModes.containsAll(const {
        'waiting',
        'finalizing',
      })) {
    throw StateError(
      '$family needs waiting/finalizing accepts and actor/semantic rejects.',
    );
  }
}

void _requireResourceTradeAcceptanceCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  if (!summary.resourceTradeAcceptanceModes.containsAll(const {
    'gold',
    'exchange',
  })) {
    throw StateError(
      '$family needs accepted gold and exchange parity fixtures.',
    );
  }
}

void _requireRejectionCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  final requiredReasons = reducerParityRequiredRejectionReasons[family]!;
  if (summary.rejectionReasonsByFamily[family]?.containsAll(requiredReasons) !=
      true) {
    throw StateError(
      '$family needs rejection reasons: ${requiredReasons.toList()..sort()}.',
    );
  }
}

void _validateReducerParityAcceptedSemantics(ReducerParityFixture fixture) {
  final state = PersistentGameState.fromJson(fixture.expectedState);
  final events = fixture.expectedEvents
      .map(GameEventSerializer.fromJson)
      .toList(growable: false);
  if (tryRequireProduction(
    fixture.id,
    fixture.command,
    fixture.state,
    state,
    events,
  )) {
    return;
  }
  _validateReducerParityAcceptedCommand(fixture, state, events);
}

void _validateReducerParityAcceptedCommand(
  ReducerParityFixture fixture,
  PersistentGameState state,
  List<GameEvent> events,
) {
  switch (fixture.family) {
    case 'auto-explore':
    case 'movement':
    case 'merchant-routing':
      requireAcceptedUnitAction(
        fixtureId: fixture.id,
        command: fixture.command,
        before: fixture.state,
        after: state,
        events: events,
      );
    case 'combat':
      _requireAcceptedParityCombat(fixture, state, events);
    case 'city-worked-hex':
      _requireAcceptedParityCityWorkedHex(fixture, state, events);
    case 'detachment':
      _requireAcceptedParityDetachment(fixture, state, events);
    case 'research':
      _requireAcceptedParityResearch(fixture, state);
    case 'resource-trade':
      _requireAcceptedParityResourceTrade(fixture, state, events);
    case 'worker':
      _requireAcceptedParityWorker(fixture, state);
    case 'turn-finalization':
      _requireAcceptedParityTurn(fixture, state, events);
    default:
      ReducerParityCorpus._fail(
        fixture,
        'uses a command outside the reviewed parity corpus',
      );
  }
}

void _requireAcceptedParityCityWorkedHex(
  ReducerParityFixture fixture,
  PersistentGameState state,
  List<GameEvent> events,
) {
  final command = fixture.command as ToggleWorkedHexCommand;
  final beforeIndex = fixture.state.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (beforeIndex < 0 || events.isNotEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must update an existing city without emitting events',
    );
  }
  if (!_jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save))) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve save metadata for worked-hex selection',
    );
  }

  final beforeCity = fixture.state.cities[beforeIndex];
  final target = CityHex(col: command.col, row: command.row);
  final expectedWorkedHexes = beforeCity.workedHexes.contains(target)
      ? [
          for (final hex in beforeCity.workedHexes)
            if (hex != target) hex,
        ]
      : [...beforeCity.workedHexes, target];
  final expectedCities = [...fixture.state.cities]
    ..[beforeIndex] = beforeCity.copyWith(workedHexes: expectedWorkedHexes);
  final expectedState = fixture.state.copyWith(cities: expectedCities);
  if (!_jsonDeepEquals(state.toJson(), expectedState.toJson())) {
    ReducerParityCorpus._fail(
      fixture,
      'must only toggle the reviewed city worked hex',
    );
  }
}

void _requireAcceptedParityCombat(
  ReducerParityFixture fixture,
  PersistentGameState state,
  List<GameEvent> events,
) {
  final command = fixture.command as AttackHexCommand;
  requireAcceptedCombat(fixture.id, command.attackerUnitId, state, events);
}

void _requireAcceptedParityDetachment(
  ReducerParityFixture fixture,
  PersistentGameState state,
  List<GameEvent> events,
) {
  final failure = validateAcceptedDetachment(
    command: fixture.command as DetachTroopCommand,
    before: fixture.state,
    after: state,
    actorPlayerId: fixture.actorPlayerId,
    events: events,
  );
  if (failure != null) ReducerParityCorpus._fail(fixture, failure);
}

void _requireAcceptedParityResearch(
  ReducerParityFixture fixture,
  PersistentGameState state,
) {
  final command = fixture.command as SelectTechnologyCommand;
  if (state.research.forPlayer(command.playerId).activeTechnologyId !=
      command.technologyId) {
    ReducerParityCorpus._fail(
      fixture,
      'must commit the reviewed research selection',
    );
  }
}

void _requireAcceptedParityResourceTrade(
  ReducerParityFixture fixture,
  PersistentGameState state,
  List<GameEvent> events,
) {
  if (!_jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save))) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve save metadata for resource trade',
    );
  }
  requireAcceptedResourceTrade(
    fixtureId: fixture.id,
    command: fixture.command,
    before: fixture.state,
    after: state,
    events: events,
  );
}

void _requireAcceptedParityWorker(
  ReducerParityFixture fixture,
  PersistentGameState state,
) {
  final command = fixture.command as ConfirmWorkerImprovementCommand;
  final worker = state.units.byId(command.unitId);
  if (command.improvementType == null ||
      worker?.workerJob?.improvementType != command.improvementType ||
      worker?.movementPoints != 0) {
    ReducerParityCorpus._fail(fixture, 'must commit the reviewed worker job');
  }
}

void _requireAcceptedParityTurn(
  ReducerParityFixture fixture,
  PersistentGameState state,
  List<GameEvent> events,
) {
  requireAcceptedTurnSubmission(
    fixtureId: fixture.id,
    command: fixture.command as SubmitTurnCommand,
    inputTurn: fixture.save.turn,
    playerIds: fixture.save.players.map((player) => player.id),
    expectedTurn: fixture.expectedSave['turn'],
    expectedPlayerStates: _asMap(
      fixture.expectedSave['playerStates'],
      '${fixture.id}.expected.save.playerStates',
    ),
    before: fixture.state,
    after: state,
    now: fixture.now,
    events: events,
  );
}
