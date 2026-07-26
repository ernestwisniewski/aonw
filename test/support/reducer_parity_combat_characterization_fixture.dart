part of 'reducer_parity_combat_characterization.dart';

const _combatActorId = 'player_1';
const _combatOpponentId = 'player_2';
const _combatSentinelPlayerId = 'player_3';
const _combatSentinelUnitId = 'combat_sentinel_unit';
const _combatSentinelCityId = 'combat_sentinel_city';
const _combatCarriedArtifactId = 'combat_carried_artifact';
const _combatStoredArtifactId = 'combat_stored_artifact';

final _combatSentinelUnit = GameUnit(
  id: _combatSentinelUnitId,
  ownerPlayerId: _combatSentinelPlayerId,
  type: GameUnitType.scout,
  name: 'Combat sentinel',
  col: 2,
  row: 1,
  movementPoints: 1,
);

const _combatSentinelCity = GameCity(
  id: _combatSentinelCityId,
  ownerPlayerId: _combatOpponentId,
  name: 'Combat sentinel city',
  center: CityHex(col: 2, row: 0),
);

const _combatSentinelArtifact = WorldArtifact(
  id: 'combat_sentinel_artifact',
  type: WorldArtifactType.prophetMask,
  location: WorldArtifactLocation.map(col: 0, row: 1),
);

const _combatCarriedArtifact = WorldArtifact(
  id: _combatCarriedArtifactId,
  type: WorldArtifactType.queensMirror,
  location: WorldArtifactLocation.carried(unitId: 'defended_unit'),
);

const _combatSentinelFieldImprovement = FieldImprovement(
  hex: CityHex(col: 0, row: 1),
  type: FieldImprovementType.mine,
  builtByCityId: _combatSentinelCityId,
);

final _combatSentinelResearch = ResearchState(
  players: {
    _combatSentinelPlayerId: PlayerResearchState(
      unlockedTechnologyIds: const {TechnologyId.writing},
      scienceOverflow: 11,
    ),
  },
);

final _combatSentinelWonderRegistry = WonderRegistry(
  completedBy: const {WonderType.greatLibrary: _combatSentinelPlayerId},
);

const _combatPairTrade = ResourceTradeAgreement(
  id: 'combat_pair_trade',
  exporterPlayerId: _combatOpponentId,
  importerPlayerId: _combatActorId,
  resource: ResourceType.iron,
  goldPerTurn: 2,
  remainingTurns: 4,
);

const _combatUnrelatedTrade = ResourceTradeAgreement(
  id: 'combat_unrelated_trade',
  exporterPlayerId: _combatSentinelPlayerId,
  importerPlayerId: _combatActorId,
  resource: ResourceType.coal,
  goldPerTurn: 7,
  remainingTurns: 9,
);

final _combatBaseDiplomacy = DiplomacyState(
  contactKeys: const {'player_1|player_2'},
);

final _combatTruceDiplomacy = DiplomacyState(
  contactKeys: const {'player_1|player_2'},
  relations: const {
    'player_1|player_2': DiplomaticRelation(
      playerAId: _combatActorId,
      playerBId: _combatOpponentId,
      status: DiplomaticRelationStatus.truce,
      relationScore: 5,
      lastChangedTurn: 6,
      lastChangeReason: DiplomaticRelationChangeReason.manual,
    ),
  },
);

GameUnit _combatUnit({
  required String id,
  String ownerPlayerId = _combatActorId,
  GameUnitType type = GameUnitType.warrior,
  int col = 0,
  int row = 0,
  int? movementPoints,
  int? hitPoints,
  String? carriedArtifactId,
  String? excavatingArtifactId,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
    movementPoints: movementPoints,
    hitPoints: hitPoints,
    carriedArtifactId: carriedArtifactId,
    excavatingArtifactId: excavatingArtifactId,
  );
}

PersistentGameState _combatState(
  PersistentGameState source, {
  required List<GameUnit> units,
  required List<GameCity> cities,
  required FogOfWarState fogOfWar,
  List<WorldArtifact> artifacts = const [_combatSentinelArtifact],
  DiplomacyState? diplomacy,
}) {
  return source.copyWith(
    units: [...units, _combatSentinelUnit],
    cities: [...cities, _combatSentinelCity],
    artifacts: artifacts,
    fieldImprovements: const [_combatSentinelFieldImprovement],
    fogOfWar: fogOfWar,
    research: _combatSentinelResearch,
    runtimeState: GameRuntimeState.snapshot(
      submittedPlayerIds: const {_combatSentinelPlayerId},
      timeoutStreaksByPlayerId: const {_combatSentinelPlayerId: 2},
      afkPlayerIds: const {_combatSentinelPlayerId},
      kickedPlayerIds: const {_combatSentinelPlayerId},
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: _combatSentinelUnitId,
          defenderCol: 0,
          defenderRow: 1,
          declaredAtTick: 41,
          declaringPlayerId: _combatSentinelPlayerId,
        ),
      ],
      diplomacy: diplomacy ?? _combatBaseDiplomacy,
      dominationHoldTurnsByPlayerId: const {_combatSentinelPlayerId: 3},
      culturalVictoryHoldTurnsByPlayerId: const {_combatSentinelPlayerId: 4},
      mapObjectiveHoldStatesByObjectiveId: const {
        'combat_sentinel_objective': MapObjectiveHoldState(
          objectiveId: 'combat_sentinel_objective',
          playerId: _combatSentinelPlayerId,
          holdTurns: 2,
        ),
      },
      resourceTradeAgreements: const [_combatPairTrade, _combatUnrelatedTrade],
      turnStartedAt: DateTime.utc(2026, 7, 1, 12),
    ),
    wonderRegistry: _combatSentinelWonderRegistry,
  );
}

MapData _combatMap(
  ReducerParityFixture template, {
  required int cols,
  required int rows,
}) {
  return MapData(
    cols: cols,
    rows: rows,
    mapName: template.save.mapName,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

FogOfWarState _combatVisibleFog({required int cols, required int rows}) {
  return _combatFog(
    cols: cols,
    rows: rows,
    actorVisible: {
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++) HexCoordinate(col: col, row: row),
    },
  );
}

FogOfWarState _combatFog({
  required int cols,
  required int rows,
  required Set<HexCoordinate> actorVisible,
}) {
  final fullMap = {
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++) HexCoordinate(col: col, row: row),
  };
  return FogOfWarState(
    players: {
      _combatActorId: PlayerFogOfWar(
        playerId: _combatActorId,
        visibleHexes: actorVisible,
      ),
      _combatOpponentId: PlayerFogOfWar(
        playerId: _combatOpponentId,
        visibleHexes: fullMap,
      ),
      _combatSentinelPlayerId: PlayerFogOfWar(
        playerId: _combatSentinelPlayerId,
        visibleHexes: fullMap,
      ),
    },
  );
}

ReducerParityFixture _combatFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required MapData mapData,
  required PersistentGameState state,
  required AttackHexCommand command,
  String actorPlayerId = _combatActorId,
}) {
  final required = _requiredCombatCharacterization[id]!;
  return ReducerParityFixture(
    id: id,
    family: 'combat',
    now: template.now,
    actorPlayerId: actorPlayerId,
    tick: template.tick + tickOffset,
    mapData: mapData,
    match: template.match,
    save: template.save,
    state: state,
    command: command,
    expectedAccepted: required.accepted,
    expectedReason: required.reason,
    expectedSave: reducerParitySave(template.save),
    expectedState: _combatExpectedState(id, state).toJson(),
    expectedEvents: reducerParityEvents(_combatExpectedEvents(id)),
  );
}
