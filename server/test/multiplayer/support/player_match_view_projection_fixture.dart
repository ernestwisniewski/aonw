import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

final _playerMatchViewSave = GameSave(
  id: 'match-1',
  name: 'Projected match',
  mapName: 'test-map',
  turn: 3,
  playerStates: const {
    'player-owner': PlayerTurnState.active,
    'player-guest': PlayerTurnState.finished,
    'player-ai': PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 7, 10),
  camera: const CameraState(x: 9, y: 8, zoom: 7),
  players: const [
    Player(
      id: 'player-owner',
      name: 'Owner',
      colorValue: 101,
      country: PlayerCountry.greece,
    ),
    Player(
      id: 'player-guest',
      name: 'Guest',
      colorValue: 102,
      country: PlayerCountry.spain,
    ),
    Player(
      id: 'player-ai',
      name: 'AI',
      colorValue: 103,
      country: PlayerCountry.japan,
      kind: PlayerKind.ai,
      ai: AiPlayer(strategyId: AiStrategyId.random, seed: 424242),
    ),
  ],
  gameMode: GameMode.multiplayer,
);

final _playerMatchViewOwnerFog = PlayerFogOfWar(
  playerId: 'player-owner',
  discoveredHexes: {
    const HexCoordinate(col: 1, row: 1),
    const HexCoordinate(col: 2, row: 2),
    const HexCoordinate(col: 2, row: 3),
    const HexCoordinate(col: 4, row: 4),
  },
  visibleHexes: {
    const HexCoordinate(col: 1, row: 1),
    const HexCoordinate(col: 2, row: 2),
    const HexCoordinate(col: 2, row: 3),
    const HexCoordinate(col: 4, row: 4),
  },
);

final _playerMatchViewState = PersistentGameState(
  playerColors: const {'player-owner': 1, 'player-guest': 2, 'player-ai': 3},
  playerCountries: const {
    'player-owner': PlayerCountry.poland,
    'player-guest': PlayerCountry.france,
    'player-ai': PlayerCountry.germany,
  },
  playerGold: const {'player-owner': 111, 'player-guest': 999999},
  playerWarWeariness: const {'player-owner': 3, 'player-guest': 77},
  playerStabilityNet: const {'player-owner': 4, 'player-guest': -99},
  units: [
    GameUnit(
      id: 'own-unit',
      ownerPlayerId: 'player-owner',
      type: GameUnitType.warrior,
      name: 'Own unit',
      col: 9,
      row: 9,
    ),
    GameUnit(
      id: 'visible-enemy-unit',
      ownerPlayerId: 'player-guest',
      type: GameUnitType.warrior,
      name: 'Visible enemy',
      col: 1,
      row: 1,
      movementPoints: 9,
      experiencePoints: 88,
      queuedPath: QueuedMovePath(targetCol: 7, targetRow: 7, steps: const []),
    ),
    GameUnit(
      id: 'hidden-enemy-unit',
      ownerPlayerId: 'player-guest',
      type: GameUnitType.warrior,
      name: 'guest-secret-unit',
      col: 8,
      row: 8,
    ),
  ],
  cities: [
    const GameCity(
      id: 'own-city',
      ownerPlayerId: 'player-owner',
      name: 'Own City',
      center: CityHex(col: 9, row: 8),
    ),
    GameCity(
      id: 'visible-enemy-city',
      ownerPlayerId: 'player-guest',
      name: 'Visible City',
      center: const CityHex(col: 2, row: 2),
      storedFood: 987,
      controlledHexes: const [CityHex(col: 2, row: 3), CityHex(col: 3, row: 3)],
      buildings: const {CityBuildingType.factory},
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.reactor,
        investedProduction: 123,
      ),
      productionOverflow: 456,
    ),
    const GameCity(
      id: 'hidden-enemy-city',
      ownerPlayerId: 'player-guest',
      name: 'guest-secret-city',
      center: CityHex(col: 8, row: 7),
    ),
  ],
  artifacts: const [
    WorldArtifact(
      id: 'visible-artifact',
      type: WorldArtifactType.heroSword,
      location: WorldArtifactLocation.map(col: 4, row: 4),
    ),
    WorldArtifact(
      id: 'hidden-artifact',
      type: WorldArtifactType.queensMirror,
      location: WorldArtifactLocation.map(col: 7, row: 7),
    ),
    WorldArtifact(
      id: 'own-carried-artifact',
      type: WorldArtifactType.merchantsSeal,
      location: WorldArtifactLocation.carried(unitId: 'own-unit'),
    ),
    WorldArtifact(
      id: 'enemy-carried-artifact',
      type: WorldArtifactType.prophetMask,
      location: WorldArtifactLocation.carried(unitId: 'visible-enemy-unit'),
    ),
    WorldArtifact(
      id: 'enemy-excavation-artifact',
      type: WorldArtifactType.ancientImperialCrown,
      location: WorldArtifactLocation.excavation(
        unitId: 'visible-enemy-unit',
        col: 4,
        row: 4,
        remainingTurns: 9,
      ),
    ),
  ],
  fieldImprovements: const [
    FieldImprovement(
      hex: CityHex(col: 9, row: 8),
      type: FieldImprovementType.farm,
      builtByCityId: 'own-city',
    ),
    FieldImprovement(
      hex: CityHex(col: 4, row: 4),
      type: FieldImprovementType.mine,
      builtByCityId: 'visible-enemy-city',
    ),
    FieldImprovement(
      hex: CityHex(col: 6, row: 6),
      type: FieldImprovementType.oilWell,
      builtByCityId: 'hidden-enemy-city',
    ),
  ],
  fogOfWar: FogOfWarState(
    players: {
      'player-owner': _playerMatchViewOwnerFog,
      'player-guest': PlayerFogOfWar(
        playerId: 'player-guest',
        visibleHexes: {const HexCoordinate(col: 8, row: 8)},
      ),
    },
  ),
  research: ResearchState(
    players: {
      'player-owner': PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.agriculture},
      ),
      'player-guest': PlayerResearchState(
        activeTechnologyId: TechnologyId.nuclearPhysics,
        scienceOverflow: 999,
      ),
    },
  ),
  runtimeState: GameRuntimeState(
    cityFoundingDraft: CityFoundingDraft(
      unitId: 'hidden-enemy-unit',
      ownerPlayerId: 'player-guest',
      center: const CityHex(col: 8, row: 8),
    ),
    pendingAction: const PendingResearchSelection(
      ownerPlayerId: 'player-guest',
    ),
    submittedPlayerIds: const {'player-owner', 'player-guest'},
    timeoutStreaksByPlayerId: const {'player-owner': 1, 'player-guest': 9},
    afkPlayerIds: const {'player-guest'},
    kickedPlayerIds: const {'player-ai'},
    intendedAttacks: const [
      IntendedAttack(
        attackerUnitId: 'own-unit',
        defenderCol: 1,
        defenderRow: 1,
        declaredAtTick: 1,
        declaringPlayerId: 'player-owner',
      ),
      IntendedAttack(
        attackerUnitId: 'hidden-enemy-unit',
        defenderCol: 9,
        defenderRow: 9,
        declaredAtTick: 2,
        declaringPlayerId: 'player-guest',
      ),
    ],
    diplomacy: DiplomacyState(
      contactKeys: {
        DiplomacyState.relationKey('player-owner', 'player-guest'),
        DiplomacyState.relationKey('player-owner', 'player-ai'),
        DiplomacyState.relationKey('player-guest', 'player-ai'),
      },
      relations: {
        DiplomacyState.relationKey(
          'player-owner',
          'player-guest',
        ): DiplomaticRelation.between(
          playerAId: 'player-owner',
          playerBId: 'player-guest',
          relationScore: -10,
        ),
        DiplomacyState.relationKey(
          'player-guest',
          'player-ai',
        ): DiplomaticRelation.between(
          playerAId: 'player-guest',
          playerBId: 'player-ai',
          relationScore: 99,
        ),
      },
      pendingProposals: const {
        'owner-proposal': DiplomaticProposal(
          id: 'owner-proposal',
          fromPlayerId: 'player-owner',
          toPlayerId: 'player-ai',
          kind: DiplomaticProposalKind.friendship,
          createdTurn: 1,
          expiresOnTurn: 9,
        ),
        'guest-secret-proposal': DiplomaticProposal(
          id: 'guest-secret-proposal',
          fromPlayerId: 'player-guest',
          toPlayerId: 'player-ai',
          kind: DiplomaticProposalKind.truce,
          createdTurn: 2,
          expiresOnTurn: 10,
        ),
      },
      messages: const {
        'owner-message': DiplomaticMessage(
          id: 'owner-message',
          fromPlayerId: 'player-ai',
          toPlayerId: 'player-owner',
          topic: DiplomaticMessageTopic.peacefulPraise,
          category: DiplomaticMessageCategory.praise,
          createdTurn: 1,
          expiresOnTurn: 9,
        ),
        'guest-secret-message': DiplomaticMessage(
          id: 'guest-secret-message',
          fromPlayerId: 'player-ai',
          toPlayerId: 'player-guest',
          topic: DiplomaticMessageTopic.troopsNearCities,
          category: DiplomaticMessageCategory.warning,
          createdTurn: 2,
          expiresOnTurn: 10,
        ),
      },
      scoreHistory: {
        'corrupt-mixed-key': [
          DiplomaticScoreEntry.between(
            playerAId: 'player-owner',
            playerBId: 'player-guest',
            turn: 1,
            delta: 1,
            scoreAfter: 1,
            reason: DiplomaticScoreChangeReason.manual,
            sourceId: 'shared-score',
          ),
          DiplomaticScoreEntry.between(
            playerAId: 'player-owner',
            playerBId: 'player-ai',
            turn: 1,
            delta: 2,
            scoreAfter: 2,
            reason: DiplomaticScoreChangeReason.manual,
            sourceId: 'owner-secret-score',
          ),
          DiplomaticScoreEntry.between(
            playerAId: 'player-guest',
            playerBId: 'player-ai',
            turn: 1,
            delta: 99,
            scoreAfter: 99,
            reason: DiplomaticScoreChangeReason.manual,
            sourceId: 'guest-secret-score',
          ),
        ],
      },
    ),
    dominationHoldTurnsByPlayerId: const {'player-owner': 2, 'player-guest': 8},
    culturalVictoryHoldTurnsByPlayerId: const {
      'player-owner': 3,
      'player-guest': 7,
    },
    mapObjectiveHoldStatesByObjectiveId: const {
      'objective-own': MapObjectiveHoldState(
        objectiveId: 'objective-own',
        playerId: 'player-owner',
        holdTurns: 1,
      ),
      'objective-guest': MapObjectiveHoldState(
        objectiveId: 'objective-guest',
        playerId: 'player-guest',
        holdTurns: 9,
      ),
    },
    resourceTradeAgreements: const [
      ResourceTradeAgreement(
        id: 'own-trade',
        exporterPlayerId: 'player-owner',
        importerPlayerId: 'player-guest',
        resource: ResourceType.iron,
        goldPerTurn: 2,
        remainingTurns: 3,
      ),
      ResourceTradeAgreement(
        id: 'guest-secret-trade',
        exporterPlayerId: 'player-guest',
        importerPlayerId: 'player-ai',
        resource: ResourceType.uranium,
        goldPerTurn: 99,
        remainingTurns: 9,
      ),
    ],
    turnStartedAt: DateTime.utc(2026, 7, 10),
  ),
  wonderRegistry: WonderRegistry(
    completedBy: const {WonderType.greatLibrary: 'player-owner'},
  ),
);

final playerMatchViewProjectionFixture = WireSnapshot(
  matchId: 'match-1',
  offset: 6,
  save: _playerMatchViewSave.toJson(),
  state: {
    ..._playerMatchViewState.toJson(),
    'phase': 'abandoned',
    'reason': 'owner_left',
    'leftUserIdentifier': 'owner-auth-id',
  },
);
