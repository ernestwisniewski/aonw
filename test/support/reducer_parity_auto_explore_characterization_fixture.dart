part of 'reducer_parity_auto_explore_characterization.dart';

const _autoExploreActorId = 'player_1';
const _autoExploreOpponentId = 'player_2';
const _autoExploreUnitId = 'auto_explore_scout';
const _autoExploreSentinelCityId = 'auto_explore_sentinel_city';

final _autoExploreSentinelUnit = GameUnit(
  id: 'auto_explore_sentinel_unit',
  ownerPlayerId: _autoExploreOpponentId,
  type: GameUnitType.scout,
  name: 'Auto-explore sentinel',
  col: 40,
  row: 40,
  movementPoints: 1,
);

const _autoExploreSentinelCity = GameCity(
  id: _autoExploreSentinelCityId,
  ownerPlayerId: _autoExploreOpponentId,
  name: 'Auto-explore sentinel city',
  center: CityHex(col: 41, row: 41),
);

const _autoExploreSentinelArtifact = WorldArtifact(
  id: 'auto_explore_sentinel_artifact',
  type: WorldArtifactType.astronomersTablets,
  location: WorldArtifactLocation.map(col: 42, row: 42),
);

const _autoExploreSentinelFieldImprovement = FieldImprovement(
  hex: CityHex(col: 43, row: 43),
  type: FieldImprovementType.mine,
  builtByCityId: _autoExploreSentinelCityId,
);

final _autoExploreSentinelResearch = ResearchState(
  players: {
    _autoExploreOpponentId: PlayerResearchState(
      unlockedTechnologyIds: const {TechnologyId.writing},
      scienceOverflow: 13,
    ),
  },
);

final _autoExploreSentinelWonderRegistry = WonderRegistry(
  completedBy: const {WonderType.greatLibrary: _autoExploreOpponentId},
);

final _autoExploreSentinelDiplomacy = DiplomacyState(
  contactKeys: const {'player_2|player_3'},
);

GameUnit _autoExploreUnit({
  String id = _autoExploreUnitId,
  String ownerPlayerId = _autoExploreActorId,
  GameUnitType type = GameUnitType.scout,
  int col = 0,
  int row = 0,
  int? movementPoints = 2,
  UnitPosture posture = UnitPosture.active,
  QueuedMovePath? queuedPath,
  String? excavatingArtifactId,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: 'Auto-explore unit',
    col: col,
    row: row,
    movementPoints: movementPoints,
    posture: posture,
    queuedPath: queuedPath,
    excavatingArtifactId: excavatingArtifactId,
  );
}

DomainState _autoExploreState(
  DomainState source, {
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  FogOfWarState? fogOfWar,
  String interactionUnitId = _autoExploreUnitId,
}) {
  return source.copyWith(
    units: [...units, _autoExploreSentinelUnit],
    cities: [...cities, _autoExploreSentinelCity],
    artifacts: const [_autoExploreSentinelArtifact],
    fieldImprovements: const [_autoExploreSentinelFieldImprovement],
    fogOfWar:
        fogOfWar ??
        _autoExploreFog(
          discovered: {const HexCoordinate(col: 0, row: 0)},
          visible: {const HexCoordinate(col: 0, row: 0)},
        ),
    research: _autoExploreSentinelResearch,

    actions: DomainActionState(
      cityFoundingDraft: CityFoundingDraft(
        unitId: interactionUnitId,
        ownerPlayerId: _autoExploreActorId,
        center: const CityHex(col: 44, row: 44),
        controlledHexes: const [CityHex(col: 45, row: 44)],
      ),
      pendingAction: PendingUnitTurnSkip(
        ownerPlayerId: _autoExploreActorId,
        unitId: interactionUnitId,
        restoreMovementPoints: 2,
      ),
    ),
    submittedPlayerIds: const {_autoExploreOpponentId},
    timeoutStreaksByPlayerId: const {_autoExploreOpponentId: 2},
    afkPlayerIds: const {_autoExploreOpponentId},
    kickedPlayerIds: const {_autoExploreOpponentId},
    intendedAttacks: const [
      IntendedAttack(
        attackerUnitId: 'sentinel_attacker',
        defenderCol: 30,
        defenderRow: 30,
        declaredAtTick: 43,
        declaringPlayerId: _autoExploreOpponentId,
      ),
    ],
    diplomacy: _autoExploreSentinelDiplomacy,
    dominationHoldTurnsByPlayerId: const {_autoExploreOpponentId: 3},
    culturalVictoryHoldTurnsByPlayerId: const {_autoExploreOpponentId: 4},
    mapObjectiveHoldStatesByObjectiveId: const {
      'sentinel_objective': MapObjectiveHoldState(
        objectiveId: 'sentinel_objective',
        playerId: _autoExploreOpponentId,
        holdTurns: 2,
      ),
    },
    resourceTradeAgreements: const [
      ResourceTradeAgreement(
        id: 'auto_explore_sentinel_trade',
        exporterPlayerId: _autoExploreOpponentId,
        importerPlayerId: _autoExploreActorId,
        resource: ResourceType.coal,
        goldPerTurn: 7,
        remainingTurns: 9,
      ),
    ],
    turnStartedAt: DateTime.utc(2026, 7, 1, 12),

    wonderRegistry: _autoExploreSentinelWonderRegistry,
  );
}

WorldMap _autoExploreMap(
  ReducerParityFixture template, {
  required int cols,
  Map<int, List<TerrainType>> terrainOverrides = const {},
}) {
  return WorldMap(
    cols: cols,
    rows: 1,
    mapName: template.save.mapName,
    tiles: [
      for (var col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: terrainOverrides[col] ?? const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

FogOfWarState _autoExploreFog({
  required Set<HexCoordinate> discovered,
  required Set<HexCoordinate> visible,
}) {
  return FogOfWarState(
    players: {
      _autoExploreActorId: PlayerFogOfWar(
        playerId: _autoExploreActorId,
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}

QueuedMovePath _autoExploreQueuedPath({required int targetCol}) {
  return QueuedMovePath(
    targetCol: targetCol,
    targetRow: 0,
    steps: [
      for (var col = 0; col <= targetCol; col++)
        UnitMovementStep(
          col: col,
          row: 0,
          enterCost: col == 0 ? 0 : 1,
          cumulativeCost: col,
        ),
    ],
  );
}

ReducerParityFixture _autoExploreFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required WorldMap mapData,
  required DomainState state,
  required AutoExploreUnitCommand command,
}) {
  final required = _requiredAutoExploreCharacterization[id]!;
  return ReducerParityFixture(
    id: id,
    family: 'auto-explore',
    now: template.now,
    actorPlayerId: _autoExploreActorId,
    tick: template.tick + tickOffset,
    mapData: mapData,
    match: template.match,
    save: template.save,
    state: state,
    command: command,
    expectedAccepted: required.accepted,
    expectedReason: required.reason,
    expectedSave: reducerParitySave(template.save),
    expectedState: CanonicalGameSnapshotCodec.encodeDomainState(
      _autoExploreExpectedState(id, state),
    ),
    expectedEvents: reducerParityEvents(_autoExploreExpectedEvents(id)),
  );
}
