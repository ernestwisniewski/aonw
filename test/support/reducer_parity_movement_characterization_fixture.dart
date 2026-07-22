part of 'reducer_parity_movement_characterization.dart';

const _movementActorId = 'player_1';
const _movementOpponentId = 'player_2';
const _movementUnitId = 'movement_mover';
const _movementSentinelCityId = 'movement_sentinel_city';

final _movementSentinelUnit = GameUnit(
  id: 'movement_sentinel',
  ownerPlayerId: _movementOpponentId,
  type: GameUnitType.scout,
  name: 'Movement sentinel',
  col: 40,
  row: 40,
  movementPoints: 1,
);

const _movementSentinelCity = GameCity(
  id: _movementSentinelCityId,
  ownerPlayerId: _movementOpponentId,
  name: 'Movement sentinel city',
  center: CityHex(col: 41, row: 41),
);

const _movementSentinelArtifact = WorldArtifact(
  id: 'movement_sentinel_artifact',
  type: WorldArtifactType.astronomersTablets,
  location: WorldArtifactLocation.map(col: 42, row: 42),
);

const _movementSentinelFieldImprovement = FieldImprovement(
  hex: CityHex(col: 43, row: 43),
  type: FieldImprovementType.mine,
  builtByCityId: _movementSentinelCityId,
);

final _movementSentinelResearch = ResearchState(
  players: {
    _movementOpponentId: PlayerResearchState(
      unlockedTechnologyIds: const {TechnologyId.writing},
      scienceOverflow: 11,
    ),
  },
);

final _movementSentinelWonderRegistry = WonderRegistry(
  completedBy: const {WonderType.greatLibrary: _movementOpponentId},
);

final _movementSentinelCityFoundingDraft = CityFoundingDraft(
  unitId: _movementSentinelUnit.id,
  ownerPlayerId: _movementOpponentId,
  center: const CityHex(col: 44, row: 44),
  controlledHexes: const [CityHex(col: 45, row: 44)],
);

const _movementSentinelPendingAction = PendingCityExpansionSelection(
  ownerPlayerId: _movementOpponentId,
  cityId: _movementSentinelCityId,
);

GameUnit _movementUnit({
  String id = _movementUnitId,
  String ownerPlayerId = _movementActorId,
  GameUnitType type = GameUnitType.commander,
  int col = 0,
  int row = 0,
  int? movementPoints,
  UnitPosture posture = UnitPosture.active,
  String? excavatingArtifactId,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: 'Movement mover',
    col: col,
    row: row,
    movementPoints: movementPoints,
    posture: posture,
    excavatingArtifactId: excavatingArtifactId,
  );
}

PersistentGameState _movementState(
  PersistentGameState source, {
  required int mapCols,
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  FogOfWarState? fogOfWar,
  DiplomacyState? diplomacy,
}) {
  return source.copyWith(
    units: [...units, _movementSentinelUnit],
    cities: [...cities, _movementSentinelCity],
    artifacts: const [_movementSentinelArtifact],
    fieldImprovements: const [_movementSentinelFieldImprovement],
    fogOfWar: fogOfWar ?? _movementVisibleFog(mapCols),
    research: _movementSentinelResearch,
    runtimeState: GameRuntimeState.snapshot(
      cityFoundingDraft: _movementSentinelCityFoundingDraft,
      pendingAction: _movementSentinelPendingAction,
      submittedPlayerIds: const {'sentinel_submitted'},
      timeoutStreaksByPlayerId: const {'sentinel_timeout': 2},
      afkPlayerIds: const {'sentinel_afk'},
      kickedPlayerIds: const {'sentinel_kicked'},
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'sentinel_attacker',
          defenderCol: 30,
          defenderRow: 30,
          declaredAtTick: 41,
          declaringPlayerId: 'sentinel_player',
        ),
      ],
      diplomacy: diplomacy ?? _movementContactDiplomacy,
      dominationHoldTurnsByPlayerId: const {'sentinel_player': 3},
      culturalVictoryHoldTurnsByPlayerId: const {'sentinel_player': 4},
      mapObjectiveHoldStatesByObjectiveId: const {
        'sentinel_objective': MapObjectiveHoldState(
          objectiveId: 'sentinel_objective',
          playerId: 'sentinel_player',
          holdTurns: 2,
        ),
      },
      resourceTradeAgreements: const [
        ResourceTradeAgreement(
          id: 'movement_sentinel_trade',
          exporterPlayerId: _movementOpponentId,
          importerPlayerId: _movementActorId,
          resource: ResourceType.coal,
          goldPerTurn: 7,
          remainingTurns: 9,
        ),
      ],
      turnStartedAt: DateTime.utc(2026, 7, 1, 12),
    ),
    wonderRegistry: _movementSentinelWonderRegistry,
  );
}

final _movementContactDiplomacy = DiplomacyState(
  contactKeys: {'player_1|player_2'},
);

MapData _movementMap(
  ReducerParityFixture template, {
  required int cols,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return MapData(
    cols: cols,
    rows: 1,
    mapName: template.save.mapName,
    tiles: [
      for (var col = 0; col < cols; col++)
        TileData(
          col: col,
          row: 0,
          terrains:
              terrainOverrides[(col: col, row: 0)] ??
              const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

FogOfWarState _movementVisibleFog(int cols) {
  final coordinates = {
    for (var col = 0; col < cols; col++) HexCoordinate(col: col, row: 0),
  };
  return _movementFog(visible: coordinates);
}

FogOfWarState _movementFog({
  required Set<HexCoordinate> visible,
  Set<HexCoordinate> discovered = const {},
}) {
  return FogOfWarState(
    players: {
      _movementActorId: PlayerFogOfWar(
        playerId: _movementActorId,
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}

ReducerParityFixture _movementFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required MapData mapData,
  required PersistentGameState state,
  required MoveUnitCommand command,
}) {
  final required = _requiredMovementCharacterization[id]!;
  return ReducerParityFixture(
    id: id,
    family: 'movement',
    now: template.now,
    actorPlayerId: _movementActorId,
    tick: template.tick + tickOffset,
    mapData: mapData,
    match: template.match,
    save: template.save,
    state: state,
    command: command,
    expectedAccepted: required.accepted,
    expectedReason: required.reason,
    expectedSave: reducerParitySave(template.save),
    expectedState: _movementExpectedState(id, state).toJson(),
    expectedEvents: reducerParityEvents(_movementExpectedEvents(id)),
  );
}
