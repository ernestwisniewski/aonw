part of 'worker_command_resolver_test.dart';

WorkerCommandResult _select({
  List<GameUnit>? units,
  ResearchState? research,
  DomainActionState interaction = DomainActionState.empty,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  return WorkerCommandResolver.selectWorkerImprovement(
    units: units ?? [_worker()],
    cities: [_city()],
    fieldImprovements: const [],
    research: research ?? _researchWithAgriculture(),
    interaction: interaction,
    command: const SelectWorkerImprovementCommand(
      _workerId,
      FieldImprovementType.farm,
    ),
    actorPlayerId: _playerId,
    mapTiles: _mapTiles(),
    cityRuleset: CityRulesets.standard,
    technologyRuleset: TechnologyRulesets.standard,
    paceBalance: paceBalance,
  );
}

WorkerCommandResult _confirm({
  List<GameUnit>? units,
  ResearchState? research,
  DomainActionState interaction = DomainActionState.empty,
  ConfirmWorkerImprovementCommand command =
      const ConfirmWorkerImprovementCommand(_workerId),
}) {
  return WorkerCommandResolver.confirmWorkerImprovement(
    units: units ?? [_worker()],
    cities: [_city()],
    fieldImprovements: const [],
    research: research ?? _researchWithAgriculture(),
    interaction: interaction,
    command: command,
    actorPlayerId: _playerId,
    mapTiles: _mapTiles(),
    cityRuleset: CityRulesets.standard,
    technologyRuleset: TechnologyRulesets.standard,
    paceBalance: PaceBalance.unlimited,
  );
}

WorkerCommandResult _assign({
  List<GameUnit>? units,
  List<FieldImprovement>? fieldImprovements,
  DomainActionState interaction = DomainActionState.empty,
}) {
  return WorkerCommandResolver.assignWorkerToHex(
    units: units ?? [_worker()],
    cities: [_city()],
    fieldImprovements:
        fieldImprovements ??
        const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
    interaction: interaction,
    command: const AssignWorkerToHexCommand(_workerId),
    actorPlayerId: _playerId,
    mapTiles: _mapTiles(),
  );
}

void _expectRejected(
  WorkerCommandResult result, {
  required List<GameUnit> units,
  required DomainActionState interaction,
  required String reason,
}) {
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.units, units), isTrue);
  expect(identical(result.interaction, interaction), isTrue);
}

DomainActionState _workerInteraction() {
  return DomainActionState(
    cityFoundingDraft: CityFoundingDraft(
      unitId: 'settler',
      ownerPlayerId: _playerId,
      center: const CityHex(col: 3, row: 3),
    ),
    pendingAction: const PendingWorkerActionSelection(
      ownerPlayerId: _playerId,
      unitId: _workerId,
      improvementType: FieldImprovementType.farm,
    ),
  );
}

GameUnit _worker({String ownerPlayerId = _playerId}) {
  return GameUnit(
    id: _workerId,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.worker,
    name: 'Worker',
    col: 1,
    row: 0,
  );
}

GameUnit _unit({required String id}) {
  return GameUnit(
    id: id,
    ownerPlayerId: _playerId,
    type: GameUnitType.warrior,
    name: 'Guard',
    col: 2,
    row: 0,
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

ResearchState _researchWithAgriculture() {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.agriculture},
      ),
    },
  );
}

MapTileLookup _mapTiles() => WorldMap(
  cols: 4,
  rows: 4,
  mapName: 'duel',
  tiles: [
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        WorldTile.at(
          coordinate: HexCoord(col: col, row: row),
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';
const _workerId = 'worker_1';
