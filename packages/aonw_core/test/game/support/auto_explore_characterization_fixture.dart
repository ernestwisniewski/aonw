part of '../persistent_auto_explore_characterization_test.dart';

const _autoExploreActorId = 'player_1';
const _autoExploreOpponentId = 'player_2';
const _autoExploreSentinelId = 'sentinel';
const _autoExploreUnitId = 'scout_1';

final _autoExploreSentinelUnit = GameUnit(
  id: 'sentinel_unit',
  ownerPlayerId: _autoExploreSentinelId,
  type: GameUnitType.scout,
  name: 'Sentinel scout',
  col: 40,
  row: 40,
  movementPoints: 1,
);

const _autoExploreSentinelCity = GameCity(
  id: 'sentinel_city',
  ownerPlayerId: _autoExploreSentinelId,
  name: 'Sentinel city',
  center: CityHex(col: 41, row: 41),
  controlledHexes: [CityHex(col: 42, row: 41)],
);

const _autoExploreSentinelArtifact = WorldArtifact(
  id: 'sentinel_artifact',
  type: WorldArtifactType.astronomersTablets,
  location: WorldArtifactLocation.map(col: 42, row: 42),
);

const _autoExploreSentinelImprovement = FieldImprovement(
  hex: CityHex(col: 43, row: 43),
  type: FieldImprovementType.mine,
  builtByCityId: 'sentinel_city',
);

final _autoExploreSentinelResearch = ResearchState(
  players: {
    _autoExploreSentinelId: PlayerResearchState(
      unlockedTechnologyIds: const {TechnologyId.writing},
      scienceOverflow: 11,
    ),
  },
);

final _autoExploreSentinelWonders = WonderRegistry(
  completedBy: const {WonderType.greatLibrary: _autoExploreSentinelId},
);

final _autoExploreSentinelDraft = CityFoundingDraft(
  unitId: _autoExploreSentinelUnit.id,
  ownerPlayerId: _autoExploreSentinelId,
  center: const CityHex(col: 44, row: 44),
  controlledHexes: const [CityHex(col: 45, row: 44)],
);

const _autoExploreSentinelPendingAction = PendingCityExpansionSelection(
  ownerPlayerId: _autoExploreSentinelId,
  cityId: 'sentinel_city',
);

final _autoExploreSentinelDiplomacy = DiplomacyState(
  contactKeys: const {'player_1|sentinel'},
  relations: {
    'player_1|sentinel': DiplomaticRelation.between(
      playerAId: _autoExploreActorId,
      playerBId: _autoExploreSentinelId,
      status: DiplomaticRelationStatus.friendly,
      relationScore: 51,
      lastChangedTurn: 7,
      lastChangeReason: DiplomaticRelationChangeReason.manual,
    ),
  },
);

final _autoExploreSentinelFog = PlayerFogOfWar(
  playerId: _autoExploreSentinelId,
  discoveredHexes: {const HexCoordinate(col: 40, row: 40)},
  visibleHexes: {const HexCoordinate(col: 40, row: 40)},
);

GameUnit _autoExploreScout({
  String id = _autoExploreUnitId,
  String ownerPlayerId = _autoExploreActorId,
  GameUnitType type = GameUnitType.scout,
  int col = 0,
  int row = 0,
  int? movementPoints,
  UnitPosture posture = UnitPosture.active,
  String? carriedArtifactId,
  String? excavatingArtifactId,
  QueuedMovePath? queuedPath,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: 'Characterized unit',
    col: col,
    row: row,
    movementPoints: movementPoints,
    posture: posture,
    carriedArtifactId: carriedArtifactId,
    excavatingArtifactId: excavatingArtifactId,
    queuedPath: queuedPath,
  );
}

PersistentGameState _autoExploreState({
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  FogOfWarState? fogOfWar,
  DiplomacyState? diplomacy,
}) {
  return PersistentGameState.snapshot(
    playerColors: const {
      _autoExploreActorId: 0xFF112233,
      _autoExploreOpponentId: 0xFF445566,
      _autoExploreSentinelId: 0xFF778899,
    },
    playerCountries: const {
      _autoExploreActorId: PlayerCountry.poland,
      _autoExploreOpponentId: PlayerCountry.japan,
      _autoExploreSentinelId: PlayerCountry.egypt,
    },
    playerGold: const {
      _autoExploreActorId: 17,
      _autoExploreOpponentId: 23,
      _autoExploreSentinelId: 97,
    },
    playerWarWeariness: const {_autoExploreSentinelId: 5},
    playerStabilityNet: const {_autoExploreSentinelId: 8},
    units: [...units, _autoExploreSentinelUnit],
    cities: [...cities, _autoExploreSentinelCity],
    artifacts: const [_autoExploreSentinelArtifact],
    fieldImprovements: const [_autoExploreSentinelImprovement],
    fogOfWar: _withAutoExploreSentinelFog(
      fogOfWar ?? _autoExploreActorFog(visible: const {}),
    ),
    research: _autoExploreSentinelResearch,
    runtimeState: GameRuntimeState.snapshot(
      cityFoundingDraft: _autoExploreSentinelDraft,
      pendingAction: _autoExploreSentinelPendingAction,
      submittedPlayerIds: const {_autoExploreSentinelId},
      timeoutStreaksByPlayerId: const {_autoExploreSentinelId: 2},
      afkPlayerIds: const {_autoExploreSentinelId},
      kickedPlayerIds: const {'removed_player'},
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'sentinel_attacker',
          defenderCol: 30,
          defenderRow: 30,
          declaredAtTick: 41,
          declaringPlayerId: _autoExploreSentinelId,
        ),
      ],
      diplomacy: diplomacy ?? _autoExploreSentinelDiplomacy,
      dominationHoldTurnsByPlayerId: const {_autoExploreSentinelId: 3},
      culturalVictoryHoldTurnsByPlayerId: const {_autoExploreSentinelId: 4},
      mapObjectiveHoldStatesByObjectiveId: const {
        'sentinel_objective': MapObjectiveHoldState(
          objectiveId: 'sentinel_objective',
          playerId: _autoExploreSentinelId,
          holdTurns: 2,
        ),
      },
      resourceTradeAgreements: const [
        ResourceTradeAgreement(
          id: 'sentinel_trade',
          exporterPlayerId: _autoExploreSentinelId,
          importerPlayerId: _autoExploreOpponentId,
          resource: ResourceType.coal,
          goldPerTurn: 7,
          remainingTurns: 9,
        ),
      ],
      turnStartedAt: DateTime.utc(2026, 7, 1, 12),
    ),
    wonderRegistry: _autoExploreSentinelWonders,
  );
}

MapTraversalView _autoExploreMap({
  required int cols,
  int rows = 1,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return WorldMapReadView(
    WorldMap(
      cols: cols,
      rows: rows,
      tiles: [
        for (var row = 0; row < rows; row++)
          for (var col = 0; col < cols; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains:
                  terrainOverrides[(col: col, row: row)] ??
                  const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}

FogOfWarState _autoExploreActorFog({
  required Set<HexCoordinate> visible,
  Set<HexCoordinate> discovered = const {},
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

FogOfWarState _withAutoExploreSentinelFog(FogOfWarState fogOfWar) {
  return FogOfWarState(
    players: {
      ...fogOfWar.players,
      _autoExploreSentinelId: _autoExploreSentinelFog,
    },
  );
}

QueuedMovePath _autoExploreQueuedPath({int targetCol = 2}) {
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
