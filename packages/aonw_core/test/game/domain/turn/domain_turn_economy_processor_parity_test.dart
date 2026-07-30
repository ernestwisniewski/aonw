import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:test/test.dart';

import 'domain_turn_economy_golden.dart';

void main() {
  group('DomainTurnEconomyProcessor projection', () {
    test('matches the persistent wrapper and canonical rich-turn golden', () {
      final state = _richState();
      expect(state.fogOfWar.playerIds, isNot(contains('base_only')));
      final ordered = _advanceBoth(state: state, playerIds: const ['p1', 'p2']);
      final reversedNoisy = _advanceBoth(
        state: state,
        playerIds: const ['p2', '', 'p1', 'p2', '', 'p1'],
      );

      _expectDomainStateParity(
        reversedNoisy.domain.state,
        ordered.domain.state,
      );
      expect(
        _eventJson(reversedNoisy.domain.events),
        _eventJson(ordered.domain.events),
      );
      expect(
        _scienceJson(reversedNoisy.domain.scienceGained),
        _scienceJson(ordered.domain.scienceGained),
      );

      expect(_eventJson(ordered.domain.events), richEconomyEventGolden);
      expect(
        _scienceJson(ordered.domain.scienceGained),
        richEconomyScienceGolden,
      );
      expect(
        ordered.domain.state.cities
            .singleWhere((city) => city.id == 'city_p1_5_3')
            .name,
        'Kyoto',
      );
      expect(
        ordered.domain.state.fogOfWar.playerIds,
        containsAll(<String>['p1', 'p2', 'base_only', 'fog_only']),
      );
      expect(
        ordered.domain.state.fogOfWar.fogForPlayer('base_only').playerId,
        'base_only',
      );
      expect(
        ordered.domain.state.fogOfWar.fogForPlayer('fog_only').playerId,
        'fog_only',
      );
    });

    test('rejects advancing players outside canonical participants', () {
      final domain = _adapter
          .toCanonical(save: _save, state: _richState())
          .domain;

      expect(
        () => DomainTurnEconomyProcessor.advanceForPlayers(
          state: domain,
          playerIds: const ['outsider'],
          mapData: _mapData,
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'playerIds')
              .having((error) => error.invalidValue, 'invalidValue', const [
                'outsider',
              ]),
        ),
      );
    });
  });
}

_ParityResult _advanceBoth({
  required PersistentGameState state,
  required Iterable<String> playerIds,
}) {
  final domainInput = _adapter.toCanonical(save: _save, state: state).domain;
  final persistent = PersistentTurnEconomyProcessor.advanceForPlayers(
    state: state,
    playerIds: playerIds,
    mapData: _mapData,
    priorEvents: _priorEvents,
    mapObjectives: _mapObjectives,
    turn: _save.turn,
  );
  final domain = DomainTurnEconomyProcessor.advanceForPlayers(
    state: domainInput,
    playerIds: playerIds,
    mapData: _mapData,
    priorEvents: _priorEvents,
    mapObjectives: _mapObjectives,
  );
  final persistentProjection = _adapter
      .toCanonical(save: _save, state: persistent.state)
      .domain;

  _expectDomainStateParity(domain.state, persistentProjection);
  expect(_eventJson(domain.events), _eventJson(persistent.events));
  expect(
    _scienceJson(domain.scienceGained),
    _scienceJson(persistent.scienceGained),
  );

  return _ParityResult(domain);
}

void _expectDomainStateParity(DomainState actual, DomainState expected) {
  expect(actual.turn, expected.turn, reason: 'turn');
  expect(actual.matchRules, expected.matchRules, reason: 'match rules');
  expect(actual.participants, expected.participants, reason: 'participants');
  expect(actual.playerColors, expected.playerColors, reason: 'player colors');
  expect(
    actual.playerCountries,
    expected.playerCountries,
    reason: 'player countries',
  );
  expect(actual.playerGold, expected.playerGold, reason: 'player gold');
  expect(
    actual.playerWarWeariness,
    expected.playerWarWeariness,
    reason: 'war weariness',
  );
  expect(
    actual.playerStabilityNet,
    expected.playerStabilityNet,
    reason: 'stability',
  );
  expect(actual.units, expected.units, reason: 'units');
  expect(actual.cities, expected.cities, reason: 'cities');
  expect(actual.artifacts, expected.artifacts, reason: 'artifacts');
  expect(
    actual.fieldImprovements,
    expected.fieldImprovements,
    reason: 'field improvements',
  );
  expect(actual.fogOfWar, expected.fogOfWar, reason: 'fog of war');
  expect(actual.research, expected.research, reason: 'research');
  expect(
    actual.wonderRegistry,
    expected.wonderRegistry,
    reason: 'wonder registry',
  );
  expect(
    actual.intendedAttacks,
    expected.intendedAttacks,
    reason: 'intended attacks',
  );
  expect(actual.diplomacy, expected.diplomacy, reason: 'diplomacy');
  expect(
    actual.resourceTradeAgreements,
    expected.resourceTradeAgreements,
    reason: 'resource trade agreements',
  );
  expect(
    actual.dominationHoldTurnsByPlayerId,
    expected.dominationHoldTurnsByPlayerId,
    reason: 'domination holds',
  );
  expect(
    actual.culturalVictoryHoldTurnsByPlayerId,
    expected.culturalVictoryHoldTurnsByPlayerId,
    reason: 'cultural holds',
  );
  expect(
    actual.mapObjectiveHoldStatesByObjectiveId,
    expected.mapObjectiveHoldStatesByObjectiveId,
    reason: 'map objective holds',
  );
  expect(actual, expected);
}

List<Map<String, dynamic>> _eventJson(Iterable<GameEvent> events) {
  return events.map(GameEventSerializer.toJson).toList(growable: false);
}

Map<String, Object> _scienceJson(ScienceYieldBreakdown science) {
  return {
    'total': science.total,
    'byCityId': {...science.byCityId},
    'sources': [
      for (final source in science.sources)
        {
          'cityId': source.cityId,
          'amount': source.amount,
          'label': source.label,
        },
    ],
  };
}

PersistentGameState _richState() {
  return PersistentGameState.snapshot(
    playerColors: const {
      'p1': 0xFF000001,
      'p2': 0xFF000002,
      'base_only': 0xFF000003,
    },
    playerCountries: const {
      'p1': PlayerCountry.japan,
      'p2': PlayerCountry.france,
      'base_only': PlayerCountry.canada,
    },
    playerGold: const {'p1': 12, 'p2': 7, 'base_only': 3},
    playerWarWeariness: const {'p1': 3, 'p2': 1, 'base_only': 6},
    playerStabilityNet: const {'p1': -4, 'p2': 2, 'base_only': -1},
    units: _richUnits(),
    cities: _richCities(),
    artifacts: _richArtifacts,
    fieldImprovements: _richFieldImprovements,
    fogOfWar: _richFog(),
    research: _richResearch(),
    wonderRegistry: WonderRegistry(
      completedBy: const {WonderType.grandCathedral: 'base_only'},
    ),
    runtimeState: _richRuntime(),
  );
}

List<GameUnit> _richUnits() {
  return [
    GameUnit(
      id: 'settler_p1',
      ownerPlayerId: 'p1',
      type: GameUnitType.settler,
      name: GameUnitType.settler.defaultNameToken,
      col: 5,
      row: 3,
      cityFoundingJob: CityFoundingJob(
        center: const CityHex(col: 5, row: 3),
        controlledHexes: const [
          CityHex(col: 6, row: 3),
          CityHex(col: 5, row: 4),
        ],
        remainingTurns: 1,
        totalTurns: 1,
      ),
    ),
    GameUnit(
      id: 'worker_p2',
      ownerPlayerId: 'p2',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 6,
      row: 0,
      workerJob: const WorkerJob(
        targetHex: CityHex(col: 6, row: 0),
        improvementType: FieldImprovementType.farm,
        remainingTurns: 1,
        totalTurns: 1,
      ),
    ),
    GameUnit(
      id: 'scout_p1',
      ownerPlayerId: 'p1',
      type: GameUnitType.scout,
      name: GameUnitType.scout.defaultNameToken,
      col: 2,
      row: 2,
      excavatingArtifactId: 'artifact_excavated',
    ),
    GameUnit.startingWarrior(ownerPlayerId: 'p1', col: 1, row: 0),
  ];
}

List<GameCity> _richCities() {
  return [
    GameCity(
      id: 'city_p1',
      ownerPlayerId: 'p1',
      name: 'Origin',
      center: const CityHex(col: 0, row: 0),
      controlledHexes: const [CityHex(col: 1, row: 0)],
      productionQueue: CityProductionQueue.project(
        projectType: CityProjectType.research,
      ),
      hitPoints: 10,
    ),
    GameCity(
      id: 'city_p2',
      ownerPlayerId: 'p2',
      name: 'Rival',
      center: const CityHex(col: 7, row: 0),
      controlledHexes: const [CityHex(col: 6, row: 0)],
      productionQueue: CityProductionQueue.unit(
        unitType: GameUnitType.warrior,
        investedProduction:
            CityProductionRules.unitProductionCost(GameUnitType.warrior) - 1,
      ),
    ),
  ];
}

FogOfWarState _richFog() {
  return FogOfWarState(
    players: {
      'p1': PlayerFogOfWar(
        playerId: 'p1',
        discoveredHexes: {const HexCoordinate(col: 0, row: 0)},
      ),
      'p2': PlayerFogOfWar(
        playerId: 'p2',
        discoveredHexes: {const HexCoordinate(col: 7, row: 0)},
      ),
      'fog_only': PlayerFogOfWar(
        playerId: 'fog_only',
        discoveredHexes: {const HexCoordinate(col: 3, row: 2)},
      ),
    },
  );
}

ResearchState _richResearch() {
  return ResearchState(
    players: {
      'p1': PlayerResearchState(
        activeTechnologyId: TechnologyId.agriculture,
        progressByTechnologyId: const {TechnologyId.agriculture: 4},
      ),
      'p2': PlayerResearchState(activeTechnologyId: TechnologyId.mining),
    },
  );
}

GameRuntimeState _richRuntime() {
  var diplomacy = DiplomacyState.empty.setStatus(
    'p1',
    'p2',
    DiplomaticRelationStatus.friendly,
  );
  diplomacy = diplomacy.setStatus(
    'p2',
    'base_only',
    DiplomaticRelationStatus.truce,
    turn: _save.turn,
  );

  return GameRuntimeState.snapshot(
    submittedPlayerIds: const {'p1', 'p2'},
    intendedAttacks: const [
      IntendedAttack(
        attackerUnitId: 'warrior_p1',
        defenderCol: 7,
        defenderRow: 0,
        declaredAtTick: 42,
        declaringPlayerId: 'p1',
      ),
    ],
    diplomacy: diplomacy,
    dominationHoldTurnsByPlayerId: const {'p1': 1},
    culturalVictoryHoldTurnsByPlayerId: const {'p2': 2},
    mapObjectiveHoldStatesByObjectiveId: const {
      'pass_1': MapObjectiveHoldState(
        objectiveId: 'pass_1',
        playerId: 'p1',
        holdTurns: 1,
      ),
    },
    resourceTradeAgreements: const [
      ResourceTradeAgreement(
        id: 'trade_1',
        exporterPlayerId: 'p2',
        importerPlayerId: 'p1',
        resource: ResourceType.horses,
        goldPerTurn: 2,
        remainingTurns: 2,
      ),
    ],
    turnStartedAt: DateTime.utc(2026, 7, 18, 8),
  );
}

const _richArtifacts = <WorldArtifact>[
  WorldArtifact(
    id: 'artifact_excavated',
    type: WorldArtifactType.heroSword,
    location: WorldArtifactLocation.excavation(
      unitId: 'scout_p1',
      col: 2,
      row: 2,
      remainingTurns: 1,
    ),
  ),
  WorldArtifact(
    id: 'artifact_stored',
    type: WorldArtifactType.astronomersTablets,
    location: WorldArtifactLocation.stored(cityId: 'city_p2'),
  ),
];

const _richFieldImprovements = <FieldImprovement>[
  FieldImprovement(
    hex: CityHex(col: 1, row: 0),
    type: FieldImprovementType.farm,
    builtByCityId: 'city_p1',
  ),
];

final class _ParityResult {
  const _ParityResult(this.domain);

  final DomainTurnEconomyResult domain;
}

const _adapter = LegacyGameSnapshotAdapter();
final _save = GameSave(
  id: 'economy_parity',
  name: 'Economy parity',
  mapName: 'economy_map',
  turn: 11,
  playerStates: const {
    'p1': PlayerTurnState.finished,
    'p2': PlayerTurnState.finished,
  },
  savedAt: DateTime.utc(2026, 7, 18, 9),
  camera: CameraState.zero,
  players: const [
    Player(id: 'p1', name: 'Player one', colorValue: 0xFF110001),
    Player(id: 'p2', name: 'Player two', colorValue: 0xFF110002),
  ],
);

final _mapData = MapData(
  cols: 8,
  rows: 5,
  tiles: [
    for (var row = 0; row < 5; row++)
      for (var col = 0; col < 8; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

const _priorEvents = <GameEvent>[
  CityAttackedEvent(
    attackerUnitId: 'warrior_p1',
    attackerOwnerPlayerId: 'p1',
    cityId: 'city_p2',
    cityOwnerPlayerId: 'p2',
  ),
];

const _mapObjectives = <MapObjectiveDefinition>[
  MapObjectiveDefinition(
    id: 'pass_1',
    type: MapObjectiveType.strategicPass,
    hex: HexCoord(col: 1, row: 0),
    requiredHoldTurns: 2,
    victoryPoints: 3,
    goldPerTurn: 4,
  ),
];
