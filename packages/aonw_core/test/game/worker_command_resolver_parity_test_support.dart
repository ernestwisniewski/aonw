part of 'worker_command_resolver_parity_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';
const _workerId = 'worker_1';

typedef _WorkerStates = ({
  PersistentGameState persistent,
  DomainState domain,
  PersistedInteractionState interaction,
});

typedef _WorkerAdapterResults = ({
  PersistentWorkerCommandResult persistent,
  DomainWorkerCommandResult domain,
});

_WorkerStates _workerStates({
  List<GameUnit>? units,
  List<FieldImprovement> fieldImprovements = const [],
  PersistedInteractionState interaction = PersistedInteractionState.empty,
}) {
  final sharedUnits = units ?? [_worker(), _guard()];
  final cities = [_city()];
  final research = _agricultureResearch();
  final runtimeState = GameRuntimeState.snapshot(
    cityFoundingDraft: interaction.cityFoundingDraft,
    pendingAction: interaction.pendingAction,
    submittedPlayerIds: const {_otherPlayerId},
    timeoutStreaksByPlayerId: const {_otherPlayerId: 2},
    afkPlayerIds: const {_otherPlayerId},
    dominationHoldTurnsByPlayerId: const {_playerId: 2},
    culturalVictoryHoldTurnsByPlayerId: const {_otherPlayerId: 1},
    mapObjectiveHoldStatesByObjectiveId: _mapObjectiveHoldStates,
    resourceTradeAgreements: _resourceTradeAgreements,
    turnStartedAt: DateTime.utc(2026, 7, 18),
  );
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {_playerId: 1, _otherPlayerId: 2},
      playerCountries: const {
        _playerId: PlayerCountry.poland,
        _otherPlayerId: PlayerCountry.france,
      },
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      playerWarWeariness: const {_otherPlayerId: 3},
      playerStabilityNet: const {_playerId: 4},
      units: sharedUnits,
      cities: cities,
      artifacts: const [_artifact],
      fieldImprovements: fieldImprovements,
      research: research,
      runtimeState: runtimeState,
    ),
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(
          id: _playerId,
          name: 'One',
          colorValue: 1,
          country: PlayerCountry.poland,
        ),
        Player(
          id: _otherPlayerId,
          name: 'Two',
          colorValue: 2,
          country: PlayerCountry.france,
        ),
      ],
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      playerWarWeariness: const {_otherPlayerId: 3},
      playerStabilityNet: const {_playerId: 4},
      units: sharedUnits,
      cities: cities,
      artifacts: const [_artifact],
      fieldImprovements: fieldImprovements,
      research: research,
      resourceTradeAgreements: runtimeState.resourceTradeAgreements,
      dominationHoldTurnsByPlayerId: runtimeState.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          runtimeState.culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId:
          runtimeState.mapObjectiveHoldStatesByObjectiveId,
    ),
    interaction: interaction,
  );
}

_WorkerAdapterResults _selectBoth(_WorkerStates states) {
  const command = SelectWorkerImprovementCommand(
    _workerId,
    FieldImprovementType.farm,
  );
  final mapTiles = _mapTiles();
  return (
    persistent: const PersistentWorkerCommandResolver().selectWorkerImprovement(
      state: states.persistent,
      command: command,
      actorPlayerId: _playerId,
      mapTiles: mapTiles,
      paceBalance: PaceBalance.standard60,
    ),
    domain: const DomainWorkerCommandResolver().selectWorkerImprovement(
      state: states.domain,
      interaction: states.interaction,
      command: command,
      actorPlayerId: _playerId,
      mapTiles: mapTiles,
      paceBalance: PaceBalance.standard60,
    ),
  );
}

_WorkerAdapterResults _confirmBoth(
  _WorkerStates states, {
  required ConfirmWorkerImprovementCommand command,
}) {
  final mapTiles = _mapTiles();
  return (
    persistent: const PersistentWorkerCommandResolver()
        .confirmWorkerImprovement(
          state: states.persistent,
          command: command,
          actorPlayerId: _playerId,
          mapTiles: mapTiles,
          paceBalance: PaceBalance.standard60,
        ),
    domain: const DomainWorkerCommandResolver().confirmWorkerImprovement(
      state: states.domain,
      interaction: states.interaction,
      command: command,
      actorPlayerId: _playerId,
      mapTiles: mapTiles,
      paceBalance: PaceBalance.standard60,
    ),
  );
}

_WorkerAdapterResults _cancelJobBoth(_WorkerStates states) {
  const command = CancelWorkerJobCommand(_workerId);
  return (
    persistent: const PersistentWorkerCommandResolver().cancelWorkerJob(
      state: states.persistent,
      command: command,
      actorPlayerId: _playerId,
    ),
    domain: const DomainWorkerCommandResolver().cancelWorkerJob(
      state: states.domain,
      interaction: states.interaction,
      command: command,
      actorPlayerId: _playerId,
    ),
  );
}

_WorkerAdapterResults _assignBoth(_WorkerStates states) {
  const command = AssignWorkerToHexCommand(_workerId);
  final mapTiles = _mapTiles();
  return (
    persistent: const PersistentWorkerCommandResolver().assignWorkerToHex(
      state: states.persistent,
      command: command,
      actorPlayerId: _playerId,
      mapTiles: mapTiles,
    ),
    domain: const DomainWorkerCommandResolver().assignWorkerToHex(
      state: states.domain,
      interaction: states.interaction,
      command: command,
      actorPlayerId: _playerId,
      mapTiles: mapTiles,
    ),
  );
}

_WorkerAdapterResults _cancelAssignmentBoth(_WorkerStates states) {
  const command = CancelWorkerAssignmentCommand(_workerId);
  return (
    persistent: const PersistentWorkerCommandResolver().cancelWorkerAssignment(
      state: states.persistent,
      command: command,
      actorPlayerId: _playerId,
    ),
    domain: const DomainWorkerCommandResolver().cancelWorkerAssignment(
      state: states.domain,
      interaction: states.interaction,
      command: command,
      actorPlayerId: _playerId,
    ),
  );
}

void _expectAcceptedParity(
  _WorkerStates before,
  _WorkerAdapterResults results,
) {
  _expectResultParity(results, accepted: true);
  expect(
    results.persistent.state,
    before.persistent.copyWith(
      units: results.persistent.state.units,
      runtimeState: before.persistent.runtimeState.copyWith(
        cityFoundingDraft: results.domain.interaction.cityFoundingDraft,
        pendingAction: results.domain.interaction.pendingAction,
      ),
    ),
  );
  expect(
    results.domain.state,
    before.domain.copyWith(units: results.domain.state.units),
  );
  expect(identical(results.persistent.state, before.persistent), isFalse);
  expect(identical(results.domain.state, before.domain), isFalse);
  expect(
    identical(
      results.persistent.state.units.last,
      before.persistent.units.last,
    ),
    isTrue,
  );
  expect(
    identical(results.domain.state.units.last, before.domain.units.last),
    isTrue,
  );
  _expectUnrelatedStatePreserved(before, results);
}

void _expectRejectedIdentity(
  _WorkerStates before,
  _WorkerAdapterResults results, {
  required String reason,
}) {
  _expectResultParity(results, accepted: false, reason: reason);
  expect(identical(results.persistent.state, before.persistent), isTrue);
  expect(identical(results.domain.state, before.domain), isTrue);
  expect(identical(results.domain.interaction, before.interaction), isTrue);
}

void _expectResultParity(
  _WorkerAdapterResults results, {
  required bool accepted,
  String? reason,
}) {
  expect(results.persistent.accepted, accepted);
  expect(results.domain.accepted, accepted);
  expect(results.persistent.reason, reason);
  expect(results.domain.reason, reason);
  expect(results.persistent.state.units, results.domain.state.units);
  expect(
    results.persistent.state.runtimeState.cityFoundingDraft,
    results.domain.interaction.cityFoundingDraft,
  );
  expect(
    results.persistent.state.runtimeState.pendingAction,
    results.domain.interaction.pendingAction,
  );
}

void _expectMatchingPendingCleared(
  _WorkerStates before,
  _WorkerAdapterResults results,
) {
  expect(results.domain.interaction.pendingAction, isNull);
  expect(results.persistent.state.runtimeState.pendingAction, isNull);
  expect(
    results.domain.interaction.cityFoundingDraft,
    before.interaction.cityFoundingDraft,
  );
  expect(
    results.persistent.state.runtimeState.cityFoundingDraft,
    before.persistent.runtimeState.cityFoundingDraft,
  );
  expect(before.interaction.pendingAction, isA<PendingWorkerActionSelection>());
  expect(
    before.persistent.runtimeState.pendingAction,
    isA<PendingWorkerActionSelection>(),
  );
}

void _expectInteractionIdentityPreserved(
  _WorkerStates before,
  _WorkerAdapterResults results,
) {
  expect(identical(results.domain.interaction, before.interaction), isTrue);
  expect(
    identical(
      results.persistent.state.runtimeState,
      before.persistent.runtimeState,
    ),
    isTrue,
  );
}

void _expectUnrelatedStatePreserved(
  _WorkerStates before,
  _WorkerAdapterResults results,
) {
  final persistent = results.persistent.state;
  final domain = results.domain.state;
  expect(
    identical(persistent.playerColors, before.persistent.playerColors),
    isTrue,
  );
  expect(
    identical(persistent.playerCountries, before.persistent.playerCountries),
    isTrue,
  );
  expect(
    identical(persistent.playerGold, before.persistent.playerGold),
    isTrue,
  );
  expect(identical(persistent.cities, before.persistent.cities), isTrue);
  expect(identical(persistent.artifacts, before.persistent.artifacts), isTrue);
  expect(
    identical(
      persistent.fieldImprovements,
      before.persistent.fieldImprovements,
    ),
    isTrue,
  );
  expect(identical(persistent.research, before.persistent.research), isTrue);
  expect(identical(domain.participants, before.domain.participants), isTrue);
  expect(identical(domain.playerGold, before.domain.playerGold), isTrue);
  expect(identical(domain.cities, before.domain.cities), isTrue);
  expect(identical(domain.artifacts, before.domain.artifacts), isTrue);
  expect(
    identical(domain.fieldImprovements, before.domain.fieldImprovements),
    isTrue,
  );
  expect(identical(domain.research, before.domain.research), isTrue);
  expect(
    identical(
      domain.resourceTradeAgreements,
      before.domain.resourceTradeAgreements,
    ),
    isTrue,
  );
  final runtime = persistent.runtimeState;
  final beforeRuntime = before.persistent.runtimeState;
  expect(
    identical(runtime.submittedPlayerIds, beforeRuntime.submittedPlayerIds),
    isTrue,
  );
  expect(
    identical(
      runtime.mapObjectiveHoldStatesByObjectiveId,
      beforeRuntime.mapObjectiveHoldStatesByObjectiveId,
    ),
    isTrue,
  );
  expect(
    identical(
      runtime.resourceTradeAgreements,
      beforeRuntime.resourceTradeAgreements,
    ),
    isTrue,
  );
}

PersistedInteractionState _matchingInteraction() {
  return PersistedInteractionState(
    cityFoundingDraft: _cityDraft(),
    pendingAction: const PendingWorkerActionSelection(
      ownerPlayerId: _playerId,
      unitId: _workerId,
      improvementType: FieldImprovementType.farm,
    ),
  );
}

PersistedInteractionState _unrelatedInteraction() {
  return PersistedInteractionState(
    cityFoundingDraft: _cityDraft(),
    pendingAction: const PendingWorkerActionSelection(
      ownerPlayerId: _playerId,
      unitId: 'other_worker',
      improvementType: FieldImprovementType.farm,
    ),
  );
}

CityFoundingDraft _cityDraft() {
  return CityFoundingDraft(
    unitId: 'settler_1',
    ownerPlayerId: _playerId,
    center: const CityHex(col: 3, row: 3),
  );
}

GameUnit _worker({
  QueuedMovePath? queuedPath,
  WorkerJob? workerJob,
  WorkerAssignment? workerAssignment,
}) {
  return GameUnit(
    id: _workerId,
    ownerPlayerId: _playerId,
    type: GameUnitType.worker,
    name: 'Worker',
    col: 1,
    row: 0,
    queuedPath: queuedPath,
    workerJob: workerJob,
    workerAssignment: workerAssignment,
  );
}

GameUnit _guard() {
  return GameUnit(
    id: 'guard_1',
    ownerPlayerId: _playerId,
    type: GameUnitType.warrior,
    name: 'Guard',
    col: 2,
    row: 0,
  );
}

QueuedMovePath _queuedPath() {
  return QueuedMovePath(
    targetCol: 2,
    targetRow: 0,
    steps: const [
      UnitMovementStep(col: 1, row: 0, enterCost: 0, cumulativeCost: 0),
    ],
  );
}

GameCity _city() {
  return const GameCity(
    id: 'city_1',
    ownerPlayerId: _playerId,
    name: 'City',
    center: CityHex(col: 0, row: 0),
    controlledHexes: [CityHex(col: 1, row: 0)],
  );
}

ResearchState _agricultureResearch() {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.agriculture},
      ),
    },
  );
}

MapTileLookup _mapTiles() => WorldMapReadView(
  WorldMap(
    cols: 4,
    rows: 4,
    mapName: 'duel',
    tiles: [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  ),
);

const _farm = FieldImprovement(
  hex: CityHex(col: 1, row: 0),
  type: FieldImprovementType.farm,
  builtByCityId: 'city_1',
);

const _artifact = WorldArtifact(
  id: 'artifact_1',
  type: WorldArtifactType.heroSword,
  location: WorldArtifactLocation.map(col: 3, row: 0),
);

const _mapObjectiveHoldStates = <String, MapObjectiveHoldState>{
  'objective_1': MapObjectiveHoldState(
    objectiveId: 'objective_1',
    playerId: _playerId,
    holdTurns: 2,
  ),
};

const _resourceTradeAgreements = <ResourceTradeAgreement>[
  ResourceTradeAgreement(
    id: 'trade_1',
    exporterPlayerId: _otherPlayerId,
    importerPlayerId: _playerId,
    resource: ResourceType.horses,
    goldPerTurn: 2,
    remainingTurns: 3,
  ),
];
