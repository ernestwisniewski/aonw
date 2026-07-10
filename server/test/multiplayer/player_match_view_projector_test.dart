import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart';
import 'package:test/test.dart';

void main() {
  const projector = PlayerMatchViewProjector();
  const owner = MatchRecipient(
    userIdentifier: 'owner-auth-id',
    playerId: 'player-owner',
  );

  test('redacts account identifiers and private invite codes from matches', () {
    final canonical = _match();

    final ownerView = projector.matchFor(
      canonical,
      userIdentifier: owner.userIdentifier,
    );
    final guestView = projector.matchFor(
      canonical,
      userIdentifier: 'guest-auth-id',
    );

    expect(ownerView.ownerUserId, owner.userIdentifier);
    expect(ownerView.inviteCode, 'SECRET-CODE');
    expect(ownerView.players.map((player) => player.userId), [
      owner.userIdentifier,
      'player-guest',
    ]);
    expect(guestView.ownerUserId, 'player-owner');
    expect(guestView.inviteCode, isNull);
    expect(guestView.players.map((player) => player.userId), [
      'player-owner',
      'guest-auth-id',
    ]);
    expect(guestView.toJson().toString(), isNot(contains('owner-auth-id')));
  });

  test('projects a fail-closed player-visible snapshot', () {
    final canonical = _snapshot();
    final canonicalJson = canonical.toJson().toString();

    final projected = projector.snapshotFor(canonical, owner);
    final save = GameSave.fromJson(projected.save);
    final state = PersistentGameState.fromJson(projected.state);

    expect(save.camera, CameraState.zero);
    expect(save.players.last.ai?.seed, 0);
    expect(
      state.playerColors.keys,
      containsAll(['player-owner', 'player-guest']),
    );
    expect(state.playerGold, {'player-owner': 111});
    expect(state.playerWarWeariness, {'player-owner': 3});
    expect(state.playerStabilityNet, {'player-owner': 4});
    expect(state.fogOfWar.playerIds, ['player-owner']);
    expect(state.research.players.keys, ['player-owner']);

    expect(state.units.map((unit) => unit.id), [
      'own-unit',
      'visible-enemy-unit',
    ]);
    final visibleEnemy = state.units.last;
    expect(visibleEnemy.movementPoints, 0);
    expect(visibleEnemy.army, isEmpty);
    expect(visibleEnemy.queuedPath, isNull);
    expect(visibleEnemy.experiencePoints, 0);

    expect(state.cities.map((city) => city.id), [
      'own-city',
      'visible-enemy-city',
    ]);
    final visibleEnemyCity = state.cities.last;
    expect(visibleEnemyCity.storedFood, GameCity.defaultStartStoredFood);
    expect(visibleEnemyCity.buildings, isEmpty);
    expect(visibleEnemyCity.productionQueue, isNull);
    expect(visibleEnemyCity.productionOverflow, 0);
    expect(visibleEnemyCity.controlledHexes, [const CityHex(col: 2, row: 3)]);

    expect(state.fieldImprovements, hasLength(2));
    expect(state.artifacts.map((artifact) => artifact.id), [
      'visible-artifact',
    ]);
    expect(state.runtimeState.cityFoundingDraft, isNull);
    expect(state.runtimeState.pendingAction, isNull);
    expect(state.runtimeState.timeoutStreaksByPlayerId, {'player-owner': 1});
    expect(state.runtimeState.intendedAttacks, hasLength(1));
    expect(
      state.runtimeState.intendedAttacks.single.declaringPlayerId,
      'player-owner',
    );
    expect(state.runtimeState.diplomacy.relations, hasLength(1));
    expect(state.runtimeState.dominationHoldTurnsByPlayerId, {
      'player-owner': 2,
    });
    expect(state.runtimeState.mapObjectiveHoldStatesByObjectiveId.keys, [
      'objective-own',
    ]);
    expect(state.runtimeState.resourceTradeAgreements, hasLength(1));
    expect(projected.state['reason'], 'owner_left');
    expect(projected.state, isNot(contains('leftUserIdentifier')));

    expect(canonical.toJson().toString(), canonicalJson);
    expect(canonical.state.toString(), contains('hidden-enemy-unit'));
    expect(projected.state.toString(), isNot(contains('hidden-enemy-unit')));
    expect(projected.state.toString(), isNot(contains('guest-secret')));
  });

  test('redacts event payloads and projects command acknowledgements', () {
    final snapshot = _snapshot();
    final ownEvent = WireEvent(
      matchId: snapshot.matchId,
      offset: 7,
      timestamp: DateTime.utc(2026, 7, 10),
      actorPlayerId: owner.playerId,
      tick: 3,
      command: const {'type': 'own-command', 'secret': 'actor-secret'},
      events: const [
        {'type': 'global-resolution', 'secret': 'other-player-secret'},
      ],
    );
    final otherEvent = ownEvent.copyWith(
      actorPlayerId: 'player-guest',
      command: const {'type': 'guest-secret-command'},
    );

    final projectedOwn = projector.eventFor(ownEvent, owner);
    final projectedOther = projector.eventFor(otherEvent, owner);
    final ack = projector.ackFor(
      WireCommandAck(
        matchId: snapshot.matchId,
        accepted: true,
        offset: 7,
        snapshot: snapshot,
        events: ownEvent.events,
      ),
      owner,
    );

    expect(projectedOwn.command?['type'], 'own-command');
    expect(projectedOwn.events, isEmpty);
    expect(projectedOther.actorPlayerId, isNull);
    expect(projectedOther.tick, isNull);
    expect(projectedOther.command, isNull);
    expect(projectedOther.events, isEmpty);
    expect(ack.events, isEmpty);
    expect(PersistentGameState.fromJson(ack.snapshot.state).playerGold, {
      'player-owner': 111,
    });
  });

  test('allows only explicit lifecycle fields in lobby snapshots', () {
    final projected = projector.snapshotFor(
      WireSnapshot(
        matchId: 'match-1',
        offset: 0,
        save: const {},
        state: const {
          'phase': 'lobby',
          'mapName': 'test-map',
          'leftUserIdentifier': 'raw-auth-id',
          'futureSecret': 'must-fail-closed',
        },
      ),
      owner,
    );

    expect(projected.state, {'phase': 'lobby', 'mapName': 'test-map'});
  });

  test(
    'malformed running snapshots fail instead of returning canonical data',
    () {
      final malformed = WireSnapshot(
        matchId: 'match-1',
        offset: 1,
        save: const {'id': 'incomplete'},
        state: const {'secret': 'must-not-pass-through'},
      );

      expect(() => projector.snapshotFor(malformed, owner), throwsA(anything));
    },
  );
}

WireMatch _match() {
  return WireMatch(
    id: 'match-1',
    ownerUserId: 'owner-auth-id',
    name: 'Private match',
    mapName: 'test-map',
    players: [
      _wirePlayer(id: 'player-owner', userId: 'owner-auth-id', name: 'Owner'),
      _wirePlayer(id: 'player-guest', userId: 'guest-auth-id', name: 'Guest'),
    ],
    turn: 1,
    state: 'running',
    createdAt: DateTime.utc(2026, 7, 10),
    inviteCode: 'SECRET-CODE',
  );
}

WirePlayer _wirePlayer({
  required String id,
  required String userId,
  required String name,
}) {
  return WirePlayer(
    id: id,
    userId: userId,
    name: name,
    colorValue: 1,
    kind: WirePlayerKind.human,
    connectionState: WirePlayerConnectionState.connected,
  );
}

WireSnapshot _snapshot() {
  final save = GameSave(
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
      Player(id: 'player-owner', name: 'Owner', colorValue: 1),
      Player(id: 'player-guest', name: 'Guest', colorValue: 2),
      Player(
        id: 'player-ai',
        name: 'AI',
        colorValue: 3,
        kind: PlayerKind.ai,
        ai: AiPlayer(strategyId: AiStrategyId.random, seed: 424242),
      ),
    ],
    gameMode: GameMode.multiplayer,
  );
  final viewerFog = PlayerFogOfWar(
    playerId: 'player-owner',
    discoveredHexes: {
      HexCoordinate(col: 1, row: 1),
      HexCoordinate(col: 2, row: 2),
      HexCoordinate(col: 2, row: 3),
      HexCoordinate(col: 4, row: 4),
    },
    visibleHexes: {
      HexCoordinate(col: 1, row: 1),
      HexCoordinate(col: 2, row: 2),
      HexCoordinate(col: 2, row: 3),
      HexCoordinate(col: 4, row: 4),
    },
  );
  final state = PersistentGameState(
    playerColors: const {'player-owner': 1, 'player-guest': 2},
    playerCountries: const {
      'player-owner': PlayerCountry.poland,
      'player-guest': PlayerCountry.france,
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
      GameCity(
        id: 'own-city',
        ownerPlayerId: 'player-owner',
        name: 'Own City',
        center: const CityHex(col: 9, row: 8),
      ),
      GameCity(
        id: 'visible-enemy-city',
        ownerPlayerId: 'player-guest',
        name: 'Visible City',
        center: const CityHex(col: 2, row: 2),
        storedFood: 987,
        controlledHexes: const [
          CityHex(col: 2, row: 3),
          CityHex(col: 3, row: 3),
        ],
        buildings: const {CityBuildingType.factory},
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.reactor,
          investedProduction: 123,
        ),
        productionOverflow: 456,
      ),
      GameCity(
        id: 'hidden-enemy-city',
        ownerPlayerId: 'player-guest',
        name: 'guest-secret-city',
        center: const CityHex(col: 8, row: 7),
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
        'player-owner': viewerFog,
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
      ),
      dominationHoldTurnsByPlayerId: const {
        'player-owner': 2,
        'player-guest': 8,
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
  );

  return WireSnapshot(
    matchId: 'match-1',
    offset: 6,
    save: save.toJson(),
    state: {
      ...state.toJson(),
      'phase': 'abandoned',
      'reason': 'owner_left',
      'leftUserIdentifier': 'owner-auth-id',
      'futureSecret': 'guest-secret-future-field',
    },
  );
}
