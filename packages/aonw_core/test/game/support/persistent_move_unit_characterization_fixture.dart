part of '../persistent_move_unit_resolver_characterization_test.dart';

const _moveActorId = 'player_1';
const _moveOpponentId = 'player_2';
const _moveSentinelId = 'sentinel';
const _moverId = 'mover';

final _sentinelUnit = GameUnit(
  id: 'sentinel_unit',
  ownerPlayerId: _moveSentinelId,
  type: GameUnitType.scout,
  name: 'Sentinel',
  col: 40,
  row: 40,
  movementPoints: 1,
);

const _sentinelArtifact = WorldArtifact(
  id: 'sentinel_artifact',
  type: WorldArtifactType.astronomersTablets,
  location: WorldArtifactLocation.map(col: 42, row: 42),
);

const _sentinelFieldImprovement = FieldImprovement(
  hex: CityHex(col: 43, row: 43),
  type: FieldImprovementType.mine,
  builtByCityId: 'sentinel_city',
);

final _sentinelResearch = ResearchState(
  players: {
    _moveSentinelId: PlayerResearchState(
      unlockedTechnologyIds: const {TechnologyId.writing},
      scienceOverflow: 11,
    ),
  },
);

final _sentinelWonderRegistry = WonderRegistry(
  completedBy: const {WonderType.greatLibrary: _moveSentinelId},
);

final _sentinelCityFoundingDraft = CityFoundingDraft(
  unitId: _sentinelUnit.id,
  ownerPlayerId: _moveSentinelId,
  center: const CityHex(col: 44, row: 44),
  controlledHexes: const [CityHex(col: 45, row: 44)],
);

const _sentinelPendingAction = PendingCityExpansionSelection(
  ownerPlayerId: _moveSentinelId,
  cityId: 'sentinel_city',
);

final _sentinelDiplomacy = DiplomacyState(
  contactKeys: const {'player_1|sentinel'},
  relations: {
    'player_1|sentinel': DiplomaticRelation.between(
      playerAId: _moveActorId,
      playerBId: _moveSentinelId,
      status: DiplomaticRelationStatus.friendly,
      relationScore: 51,
      lastChangedTurn: 7,
      lastChangeReason: DiplomaticRelationChangeReason.manual,
    ),
  },
);

final _sentinelPlayerFog = PlayerFogOfWar(
  playerId: _moveSentinelId,
  discoveredHexes: {const HexCoordinate(col: 40, row: 40)},
  visibleHexes: {const HexCoordinate(col: 40, row: 40)},
);

GameUnit _moveUnit({
  String id = _moverId,
  String ownerPlayerId = _moveActorId,
  GameUnitType type = GameUnitType.commander,
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
    name: 'Mover',
    col: col,
    row: row,
    movementPoints: movementPoints,
    posture: posture,
    carriedArtifactId: carriedArtifactId,
    excavatingArtifactId: excavatingArtifactId,
    queuedPath: queuedPath,
  );
}

PersistentGameState _moveState({
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  FogOfWarState? fogOfWar,
  DiplomacyState? diplomacy,
}) {
  return PersistentGameState.snapshot(
    playerColors: const {
      _moveActorId: 0xFF112233,
      _moveOpponentId: 0xFF445566,
      _moveSentinelId: 0xFF778899,
    },
    playerCountries: const {
      _moveActorId: PlayerCountry.poland,
      _moveOpponentId: PlayerCountry.japan,
      _moveSentinelId: PlayerCountry.egypt,
    },
    playerGold: const {
      _moveActorId: 17,
      _moveOpponentId: 23,
      _moveSentinelId: 97,
    },
    playerWarWeariness: const {_moveSentinelId: 5},
    playerStabilityNet: const {_moveSentinelId: 8},
    units: [...units, _sentinelUnit],
    cities: cities,
    artifacts: const [_sentinelArtifact],
    fieldImprovements: const [_sentinelFieldImprovement],
    fogOfWar: _withSentinelFog(fogOfWar ?? FogOfWarState.empty),
    research: _sentinelResearch,
    runtimeState: GameRuntimeState.snapshot(
      cityFoundingDraft: _sentinelCityFoundingDraft,
      pendingAction: _sentinelPendingAction,
      submittedPlayerIds: const {_moveSentinelId},
      timeoutStreaksByPlayerId: const {_moveSentinelId: 2},
      afkPlayerIds: const {_moveSentinelId},
      kickedPlayerIds: const {'removed_player'},
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'sentinel_attacker',
          defenderCol: 30,
          defenderRow: 30,
          declaredAtTick: 41,
          declaringPlayerId: _moveSentinelId,
        ),
      ],
      diplomacy: diplomacy ?? _sentinelDiplomacy,
      dominationHoldTurnsByPlayerId: const {_moveSentinelId: 3},
      culturalVictoryHoldTurnsByPlayerId: const {_moveSentinelId: 4},
      mapObjectiveHoldStatesByObjectiveId: const {
        'sentinel_objective': MapObjectiveHoldState(
          objectiveId: 'sentinel_objective',
          playerId: _moveSentinelId,
          holdTurns: 2,
        ),
      },
      resourceTradeAgreements: const [
        ResourceTradeAgreement(
          id: 'sentinel_trade',
          exporterPlayerId: _moveSentinelId,
          importerPlayerId: _moveOpponentId,
          resource: ResourceType.coal,
          goldPerTurn: 7,
          remainingTurns: 9,
        ),
      ],
      turnStartedAt: DateTime.utc(2026, 7, 1, 12),
    ),
    wonderRegistry: _sentinelWonderRegistry,
  );
}

MapTraversalView _movementMap({
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

FogOfWarState _actorFog({
  required Set<HexCoordinate> visible,
  Set<HexCoordinate> discovered = const {},
}) {
  return FogOfWarState(
    players: {
      _moveActorId: PlayerFogOfWar(
        playerId: _moveActorId,
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}

FogOfWarState _withSentinelFog(FogOfWarState fogOfWar) {
  return FogOfWarState(
    players: {...fogOfWar.players, _moveSentinelId: _sentinelPlayerFog},
  );
}

FogOfWarState _expectedActorFog(Iterable<({int col, int row})> coordinates) {
  final hexes = {
    for (final coordinate in coordinates)
      HexCoordinate(col: coordinate.col, row: coordinate.row),
  };
  return FogOfWarState(
    players: {
      _moveActorId: PlayerFogOfWar(
        playerId: _moveActorId,
        discoveredHexes: hexes,
        visibleHexes: hexes,
      ),
      _moveSentinelId: _sentinelPlayerFog,
    },
  );
}

void _expectRejectedMove(
  PersistentMoveUnitResult result,
  PersistentGameState input,
  String reason,
) {
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(result.events, isEmpty);
  expect(result.state, same(input));
  expect(result.state.units, same(input.units));
  expect(result.state.cities, same(input.cities));
  expect(result.state.fogOfWar, same(input.fogOfWar));
  expect(result.state.runtimeState, same(input.runtimeState));
  _expectOuterMovementSentinelsShared(input, result.state);
  _expectRuntimeMovementSentinelsShared(input, result.state);
  _expectMovementStateIsImmutable(result.state);
}

void _expectAcceptedNoOp(
  PersistentMoveUnitResult result,
  PersistentGameState input,
) {
  expect(result.accepted, isTrue);
  expect(result.reason, isNull);
  expect(result.events, isEmpty);
  expect(result.state, same(input));
  expect(result.state.units, same(input.units));
  expect(result.state.fogOfWar, same(input.fogOfWar));
  expect(result.state.runtimeState, same(input.runtimeState));
  _expectOuterMovementSentinelsShared(input, result.state);
  _expectRuntimeMovementSentinelsShared(input, result.state);
  _expectMovementStateIsImmutable(result.state);
}

void _expectMovedStateSharing(
  PersistentGameState input,
  PersistentMoveUnitResult result, {
  required bool diplomacyChanged,
}) {
  final actual = result.state;
  expect(actual, isNot(same(input)));
  expect(actual.units, isNot(same(input.units)));
  expect(actual.units.first, isNot(same(input.units.first)));
  for (var index = 1; index < input.units.length; index++) {
    expect(actual.units[index], same(input.units[index]));
  }
  expect(actual.fogOfWar, isNot(same(input.fogOfWar)));
  expect(actual.runtimeState, isNot(same(input.runtimeState)));
  if (diplomacyChanged) {
    expect(
      actual.runtimeState.diplomacy,
      isNot(same(input.runtimeState.diplomacy)),
    );
  } else {
    expect(actual.runtimeState.diplomacy, same(input.runtimeState.diplomacy));
  }
  _expectOuterMovementSentinelsShared(input, actual);
  _expectRuntimeMovementSentinelsShared(input, actual);
  _expectMovementStateIsImmutable(actual);
}

void _expectMovementStateIsImmutable(PersistentGameState state) {
  expect(() => state.units.add(_sentinelUnit), throwsUnsupportedError);
  expect(
    () => state.cities.add(
      const GameCity(
        id: 'mutation_probe',
        ownerPlayerId: _moveActorId,
        name: 'Mutation probe',
        center: CityHex(col: 0, row: 0),
      ),
    ),
    throwsUnsupportedError,
  );
  expect(() => state.playerGold['mutation_probe'] = 1, throwsUnsupportedError);
  expect(
    () => state.runtimeState.submittedPlayerIds.add('mutation_probe'),
    throwsUnsupportedError,
  );
}

void _expectOuterMovementSentinelsShared(
  PersistentGameState input,
  PersistentGameState actual,
) {
  expect(input.artifacts, isNotEmpty);
  expect(input.fieldImprovements, isNotEmpty);
  expect(input.research.players, isNotEmpty);
  expect(input.wonderRegistry.completedBy, isNotEmpty);
  expect(actual.playerColors, same(input.playerColors));
  expect(actual.playerCountries, same(input.playerCountries));
  expect(actual.playerGold, same(input.playerGold));
  expect(actual.playerWarWeariness, same(input.playerWarWeariness));
  expect(actual.playerStabilityNet, same(input.playerStabilityNet));
  expect(actual.cities, same(input.cities));
  expect(actual.artifacts, same(input.artifacts));
  expect(actual.fieldImprovements, same(input.fieldImprovements));
  expect(actual.research, same(input.research));
  expect(actual.wonderRegistry, same(input.wonderRegistry));
}

void _expectRuntimeMovementSentinelsShared(
  PersistentGameState input,
  PersistentGameState actual,
) {
  final before = input.runtimeState;
  final after = actual.runtimeState;
  expect(before.cityFoundingDraft, isNotNull);
  expect(before.pendingAction, isNotNull);
  expect(after.cityFoundingDraft, same(before.cityFoundingDraft));
  expect(after.pendingAction, same(before.pendingAction));
  expect(after.submittedPlayerIds, same(before.submittedPlayerIds));
  expect(after.timeoutStreaksByPlayerId, same(before.timeoutStreaksByPlayerId));
  expect(after.afkPlayerIds, same(before.afkPlayerIds));
  expect(after.kickedPlayerIds, same(before.kickedPlayerIds));
  expect(after.intendedAttacks, same(before.intendedAttacks));
  expect(
    after.dominationHoldTurnsByPlayerId,
    same(before.dominationHoldTurnsByPlayerId),
  );
  expect(
    after.culturalVictoryHoldTurnsByPlayerId,
    same(before.culturalVictoryHoldTurnsByPlayerId),
  );
  expect(
    after.mapObjectiveHoldStatesByObjectiveId,
    same(before.mapObjectiveHoldStatesByObjectiveId),
  );
  expect(after.resourceTradeAgreements, same(before.resourceTradeAgreements));
  expect(after.turnStartedAt, before.turnStartedAt);
}

void _expectMoveEvent(
  PersistentMoveUnitResult result, {
  required int fromCol,
  required int toCol,
}) {
  expect(result.events, hasLength(1));
  final event = result.events.single;
  expect(event, isA<UnitMovedEvent>());
  final moved = event as UnitMovedEvent;
  expect(moved.unitId, _moverId);
  expect(moved.fromCol, fromCol);
  expect(moved.fromRow, 0);
  expect(moved.toCol, toCol);
  expect(moved.toRow, 0);
}
