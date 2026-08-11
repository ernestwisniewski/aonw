part of 'reducer_parity_fixture.dart';

void _validateReducerParityInteractionScope(ReducerParityFixture fixture) {
  final runtime = fixture.state;
  final pendingAction = runtime.actions.pendingAction;
  final command = fixture.command;
  if ((fixture.family == 'artifacts' ||
          fixture.family == 'city-expansion' ||
          fixture.family == 'unit-actions') &&
      runtime.turnStartedAt == null) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve a non-empty runtime sentinel for reviewed commands',
    );
  }
  final permitsReviewedResearchPendingAction =
      fixture.family == 'research' &&
      fixture.expectedAccepted &&
      command is SelectTechnologyCommand &&
      pendingAction is PendingResearchSelection &&
      pendingAction.ownerPlayerId == command.playerId;
  final permitsUnitAction = _permitsReviewedUnitActionPendingAction(fixture);
  final permitsWorker = _permitsReviewedWorkerInteraction(fixture);
  if ((runtime.actions.cityFoundingDraft != null && !permitsWorker) ||
      (pendingAction != null &&
          !permitsReviewedResearchPendingAction &&
          !permitsUnitAction &&
          !permitsWorker)) {
    ReducerParityCorpus._fail(
      fixture,
      'uses client interaction fields outside parity scope',
    );
  }
}

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
  final artifactAcceptanceModes = <String>{};
  final unitActionAcceptanceModes = <String>{};
  final resourceTradeAcceptanceModes = <String>{};
  final cityWorkedHexAcceptanceModes = <String>{};
  final cityFoundingAcceptanceModes = <String>{};
  final productionAcceptanceModes = <String>{};
  final specializationRejectionReasons = <String>{};
  final startBuilding = _StartBuildingCorpusSummary();
  final startUnit = _StartUnitCorpusSummary();
  final startWonder = _StartWonderCorpusSummary();
  final rush = _RushCorpusSummary();
  final workerAcceptanceModes = <String>{};
  final workerInteractionModes = <String>{};
  final turnAcceptanceModes = <String>{};
  void record(ReducerParityFixture fixture) {
    if (!ids.add(fixture.id)) {
      throw StateError('Duplicate reducer parity fixture id: ${fixture.id}.');
    }
    coverage
        .putIfAbsent(fixture.family, () => <bool>{})
        .add(fixture.expectedAccepted);
    startBuilding.record(fixture);
    startUnit.record(fixture);
    startWonder.record(fixture);
    rush.record(fixture);
    if (fixture.expectedAccepted) {
      _recordAcceptance(fixture);
    } else {
      rejectionReasonsByFamily
          .putIfAbsent(fixture.family, () => <String>{})
          .add(fixture.expectedReason!);
      if (fixture.command is SetCitySpecializationCommand) {
        specializationRejectionReasons.add(fixture.expectedReason!);
      }
    }
  }

  void _recordAcceptance(ReducerParityFixture fixture) {
    acceptedCountByFamily.update(
      fixture.family,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    switch (fixture.family) {
      case 'artifacts':
        artifactAcceptanceModes.add(artifactAcceptanceMode(fixture.command));
      case 'unit-actions':
        unitActionAcceptanceModes.add(_unitActionAcceptanceMode(fixture));
      case 'turn-finalization':
        turnAcceptanceModes.add(
          fixture.expectedSave['turn'] == fixture.save.turn
              ? 'waiting'
              : 'finalizing',
        );
      case 'resource-trade':
        resourceTradeAcceptanceModes.add(
          resourceTradeAcceptanceMode(fixture.command),
        );
      case 'city-worked-hex':
        final command = fixture.command as ToggleWorkedHexCommand;
        final city = fixture.state.cities.singleWhere(
          (candidate) => candidate.id == command.cityId,
        );
        final target = CityHex(col: command.col, row: command.row);
        cityWorkedHexAcceptanceModes.add(
          city.workedHexes.contains(target) ? 'remove' : 'add',
        );
      case 'city-founding':
        cityFoundingAcceptanceModes.add(_cityFoundingAcceptanceMode(fixture));
      case 'city-production':
        productionAcceptanceModes.add(_productionAcceptanceMode(fixture));
      case 'worker':
        workerAcceptanceModes.add(_workerAcceptanceMode(fixture));
        workerInteractionModes.add(_workerInteractionMode(fixture));
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
    case 'artifacts':
      _requireArtifactAcceptanceCoverage(summary, family);
    case 'unit-actions':
      _requireUnitActionAcceptanceCoverage(summary, family);
    case 'turn-finalization':
      _requireTurnFinalizationAcceptanceCoverage(summary, family);
    case 'resource-trade':
      _requireResourceTradeAcceptanceCoverage(summary, family);
    case 'city-worked-hex':
      _requireCityWorkedHexAcceptanceCoverage(summary, family);
    case 'city-founding':
      _requireCityFoundingAcceptanceCoverage(summary, family);
    case 'city-production':
      _requireProductionAcceptanceCoverage(summary, family);
    case 'worker':
      _requireWorkerAcceptanceCoverage(summary, family);
  }
  _requireRejectionCoverage(summary, family);
}

void _requireArtifactAcceptanceCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  if (!summary.artifactAcceptanceModes.containsAll(const {
    'excavation',
    'store',
    'trade',
  })) {
    throw StateError(
      '$family needs accepted excavation, store, and trade fixtures.',
    );
  }
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
  final actualReasons = summary.rejectionReasonsByFamily[family];
  if (actualReasons?.containsAll(requiredReasons) != true) {
    throw StateError(
      '$family needs rejection reasons: ${requiredReasons.toList()..sort()}.',
    );
  }
}

void _validateReducerParityAcceptedSemantics(ReducerParityFixture fixture) {
  final state = CanonicalGameSnapshotCodec.decodeDomainState(
    fixture.expectedState,
  );
  const parseEvent = GameEventSerializer.fromJson;
  final events = fixture.expectedEvents.map(parseEvent).toList(growable: false);
  if (tryRequireProduction(
    fixture.id,
    fixture.command,
    fixture.actorPlayerId,
    fixture.state,
    state,
    events,
    fixture.mapData,
    fixture.save.matchRules.paceBalance,
  )) {
    return;
  }
  _validateReducerParityAcceptedCommand(fixture, state, events);
}

void _validateReducerParityAcceptedCommand(
  ReducerParityFixture fixture,
  DomainState state,
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
    case 'artifacts':
      _requireAcceptedParityArtifact(fixture, state, events);
    case 'combat':
      _requireAcceptedParityCombat(fixture, state, events);
    case 'city-expansion':
      _requireAcceptedParityCityExpansion(fixture, state, events);
    case 'city-worked-hex':
      _requireAcceptedParityCityWorkedHex(fixture, state, events);
    case 'city-founding':
      _requireAcceptedParityCityFounding(fixture, state, events);
    default:
      _validateReducerParityAcceptedCommandContinuation(fixture, state, events);
  }
}

void _validateReducerParityAcceptedCommandContinuation(
  ReducerParityFixture fixture,
  DomainState state,
  List<GameEvent> events,
) {
  switch (fixture.family) {
    case 'detachment':
      _requireAcceptedParityDetachment(fixture, state, events);
    case 'infrastructure':
      final command = fixture.command as BuildRoadCommand;
      _requireWorkerSentinel(fixture, command.unitId);
      final failure = validateAcceptedRoadInfrastructure(
        command: command,
        save: fixture.save,
        before: fixture.state,
        after: state,
        events: events,
        expectedSave: fixture.expectedSave,
        actualSave: reducerParitySave(fixture.save),
        expectedState: fixture.expectedState,
      );
      if (failure != null) ReducerParityCorpus._fail(fixture, failure);
    case 'research':
      _requireAcceptedParityResearch(fixture, state, events);
    case 'resource-trade':
      _requireAcceptedParityResourceTrade(fixture, state, events);
    case 'unit-actions':
      _requireAcceptedParityUnitAction(fixture, state, events);
    case 'worker':
      _requireAcceptedParityWorker(fixture, state, events);
    case 'turn-finalization':
      _requireAcceptedParityTurn(fixture, state, events);
    default:
      ReducerParityCorpus._fail(
        fixture,
        'uses a command outside the reviewed parity corpus',
      );
  }
}

void _requireAcceptedParityArtifact(
  ReducerParityFixture fixture,
  DomainState state,
  List<GameEvent> events,
) {
  if (!jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save))) {
    ReducerParityCorpus._fail(fixture, 'must preserve save metadata');
  }
  final failure = validateAcceptedArtifactCommand(
    command: fixture.command,
    before: fixture.state,
    after: state,
    events: events,
  );
  if (failure != null) {
    ReducerParityCorpus._fail(fixture, failure);
  }
}

void _requireAcceptedParityCityWorkedHex(
  ReducerParityFixture fixture,
  DomainState state,
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
  if (!jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save))) {
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
  if (!jsonDeepEquals(
    CanonicalGameSnapshotCodec.encodeDomainState(state),
    CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
  )) {
    ReducerParityCorpus._fail(
      fixture,
      'must only toggle the reviewed city worked hex',
    );
  }
}

void _requireAcceptedParityCombat(
  ReducerParityFixture fixture,
  DomainState state,
  List<GameEvent> events,
) {
  final command = fixture.command as AttackHexCommand;
  requireAcceptedCombat(fixture.id, command.attackerUnitId, state, events);
}

void _requireAcceptedParityDetachment(
  ReducerParityFixture fixture,
  DomainState state,
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
  DomainState state,
  List<GameEvent> events,
) {
  final command = fixture.command as SelectTechnologyCommand;
  final pendingAction = fixture.state.actions.pendingAction;
  if (pendingAction is! PendingResearchSelection ||
      pendingAction.ownerPlayerId != command.playerId) {
    ReducerParityCorpus._fail(
      fixture,
      'must start with the matching pending research selection',
    );
  }
  if (!jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save)) ||
      events.isNotEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve save metadata without emitting events',
    );
  }
  if (state.research.forPlayer(command.playerId).activeTechnologyId !=
      command.technologyId) {
    ReducerParityCorpus._fail(
      fixture,
      'must commit the reviewed research selection',
    );
  }
  if (state.actions.pendingAction != null) {
    ReducerParityCorpus._fail(
      fixture,
      'must clear the matching pending research selection',
    );
  }

  final expectedReviewedState = <String, dynamic>{
    ...CanonicalGameSnapshotCodec.encodeDomainState(fixture.state),
    // Research stays an independent fixture oracle; do not reproduce overflow.
    'research': fixture.expectedState['research'],
    'lifecycle': CanonicalGameSnapshotCodec.encodeDomainState(
      fixture.state.copyWith(
        actions: fixture.state.actions.copyWith(pendingAction: null),
      ),
    )['lifecycle'],
  };
  if (!jsonDeepEquals(fixture.expectedState, expectedReviewedState)) {
    ReducerParityCorpus._fail(
      fixture,
      'must only update research and clear its matching pending action',
    );
  }
}
