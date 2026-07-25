import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CanonicalTurnPipeline', () {
    test(
      'finalizes canonical session in stable player order',
      _preservesCanonicalBoundaries,
    );
    test(
      'keeps city combat ordered and suppresses same-turn recovery',
      _characterizesCityCombatPrefix,
    );
    test(
      'captures the exact post-economy movement boundary',
      _characterizesMovementDelta,
    );
  });
}

void _preservesCanonicalBoundaries() {
  final input = _canonicalInput();

  final result = CanonicalTurnPipeline.simultaneousFinalize(
    _canonicalRequest(input),
  );
  final snapshot = result.snapshot;

  expect(snapshot.eventLogOffset, input.eventLogOffset);
  expect(snapshot.domain.turn, 2);
  expect(snapshot.domain.intendedAttacks, isEmpty);
  expect(snapshot.session.gameMode, GameMode.multiplayer);
  expect(snapshot.session.turnStatesByPlayerId, {
    'p1': PlayerTurnState.active,
    'p2': PlayerTurnState.active,
    'p3': PlayerTurnState.finished,
  });
  expect(snapshot.session.submittedPlayerIds, isEmpty);
  expect(snapshot.session.timeoutStreaksByPlayerId, {'p2': 3});
  expect(snapshot.session.afkPlayerIds, {'p2'});
  expect(snapshot.session.kickedPlayerIds, {'p3'});
  expect(snapshot.session.turnStartedAt, _finalizedAt);
  expect(snapshot.interaction, input.interaction);
  expect(snapshot.metadata.id, input.metadata.id);
  expect(snapshot.metadata.schemaVersion, input.metadata.schemaVersion);
  expect(snapshot.metadata.name, input.metadata.name);
  expect(snapshot.metadata.world, input.metadata.world);
  expect(snapshot.metadata.camera, input.metadata.camera);
  expect(snapshot.metadata.savedAtUtc, _finalizedAt);
  expect(
    result.events.whereType<PlayerTimedOutEvent>().map(
      (event) => event.playerId,
    ),
    ['p2'],
  );
  expect(result.events.whereType<AllPlayersSubmittedEvent>().single.playerIds, [
    'p2',
    'p1',
  ]);
  expect(
    result.events.whereType<TurnEndedEvent>().map((event) => event.playerId),
    ['p2', 'p1'],
  );
  final TurnMovementDelta? delta = result.movementDelta;
  expect(delta, isNotNull);
  expect(delta!.beforeUnits, hasLength(1));
  expect(delta.afterUnits, hasLength(1));
}

void _characterizesCityCombatPrefix() {
  final input = _combatInput();
  final result = CanonicalTurnPipeline.simultaneousFinalize(
    CanonicalTurnPipelineRequest.simultaneousFinalize(
      snapshot: input,
      playerIds: const ['p1', 'p2'],
      savedAt: _finalizedAt,
      mapView: _mapData(),
      ruleset: _deterministicCombatRuleset,
    ),
  );

  expect(result.events.take(4).map((event) => event.runtimeType), [
    AllPlayersSubmittedEvent,
    CityAttackedEvent,
    CombatResolvedEvent,
    UnitGainedExperienceEvent,
  ]);
  expect(
    result.events
        .skip(result.events.length - 2)
        .map((event) => event.runtimeType),
    [TurnEndedEvent, TurnEndedEvent],
  );
  expect(
    result.events.whereType<TurnEndedEvent>().map((event) => event.playerId),
    ['p1', 'p2'],
  );

  final combat = result.events.whereType<CombatResolvedEvent>().single;
  expect(combat.outcome.defenderKilled, isFalse);
  expect(combat.outcome.defenderHpAfter, 8);
  expect(
    result.snapshot.domain.cities.single.hitPoints,
    combat.outcome.defenderHpAfter,
    reason: 'combat events must remain prior events for same-turn economy',
  );
}

void _characterizesMovementDelta() {
  final input = _movementInput();

  final result = CanonicalTurnPipeline.simultaneousFinalize(
    CanonicalTurnPipelineRequest.simultaneousFinalize(
      snapshot: input,
      playerIds: const ['p1', 'p2'],
      savedAt: _finalizedAt,
      mapView: _mapData(),
    ),
  );

  final delta = result.movementDelta!;
  expect(delta.beforeUnits, hasLength(1));
  expect(delta.beforeUnits.single.occupies(0, 0), isTrue);
  expect(delta.beforeUnits.single.movementPoints, 0);
  expect(delta.beforeUnits.single.queuedPath?.targetCol, 2);
  expect(delta.afterUnits, hasLength(1));
  expect(delta.afterUnits.single.occupies(2, 0), isTrue);
  expect(delta.afterUnits.single.movementPoints, 3);
  expect(delta.afterUnits.single.queuedPath, isNull);
  expect(delta.executions, hasLength(1));
  expect(delta.executions.single.unitId, 'commander_p1');
  expect(delta.executions.single.steps.map((step) => (step.col, step.row)), [
    (1, 0),
    (2, 0),
  ]);
  expect(() => delta.executions.clear(), throwsUnsupportedError);
  expect(result.events.map((event) => event.runtimeType), [
    AllPlayersSubmittedEvent,
    TurnEndedEvent,
    TurnEndedEvent,
  ]);
}

CanonicalTurnPipelineRequest _canonicalRequest(CanonicalGameSnapshot snapshot) {
  return CanonicalTurnPipelineRequest.simultaneousFinalize(
    snapshot: snapshot,
    playerIds: const ['p2', 'p1', 'p1'],
    skippedPlayerIds: const ['p2'],
    savedAt: _finalizedAt,
    mapView: _mapData(),
    preserveNonParticipantPlayerStates: true,
    trackTimeoutStreaks: true,
  );
}

CanonicalGameSnapshot _canonicalInput() {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: _players,
      units: [
        GameUnit.startingWarrior(
          ownerPlayerId: 'p1',
          col: 1,
          row: 1,
        ).copyWith(movementPoints: 0),
      ],
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'missing_attacker',
          defenderCol: 2,
          defenderRow: 2,
          declaredAtTick: 1,
          declaringPlayerId: 'p1',
        ),
      ],
    ),
    session: MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: _finishedPlayerStates,
      submittedPlayerIds: const {'p1', 'p2'},
      timeoutStreaksByPlayerId: const {'p2': 2},
      afkPlayerIds: const {'p2'},
      kickedPlayerIds: const {'p3'},
      turnStartedAt: _startedAt,
    ),
    metadata: _metadata(),
    interaction: PersistedInteractionState(
      cityFoundingDraft: CityFoundingDraft(
        unitId: 'warrior_p1',
        ownerPlayerId: 'p1',
        center: const CityHex(col: 1, row: 1),
      ),
      pendingAction: const PendingResearchSelection(ownerPlayerId: 'p1'),
    ),
    eventLogOffset: 41,
  );
}

CanonicalGameSnapshot _combatInput() {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: _players,
      units: [
        GameUnit(
          id: 'warrior_p1',
          ownerPlayerId: 'p1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'city_p2',
          ownerPlayerId: 'p2',
          name: 'City two',
          center: CityHex(col: 1, row: 0),
          hitPoints: 10,
        ),
      ],
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'warrior_p1',
          defenderCol: 1,
          defenderRow: 0,
          declaredAtTick: 7,
          declaringPlayerId: 'p1',
        ),
      ],
    ),
    session: _baseSession(),
    metadata: _metadata(),
    eventLogOffset: 73,
  );
}

CanonicalGameSnapshot _movementInput() {
  final commander = GameUnit.startingCommander(ownerPlayerId: 'p1')
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 2,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          ],
        ),
      );
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: _players,
      units: [commander],
    ),
    session: _baseSession(),
    metadata: _metadata(),
    eventLogOffset: 91,
  );
}

MatchSessionState _baseSession() {
  return MatchSessionState.snapshot(
    gameMode: GameMode.multiplayer,
    turnStatesByPlayerId: _finishedPlayerStates,
    turnStartedAt: _startedAt,
  );
}

GameSnapshotMetadata _metadata() {
  return GameSnapshotMetadata(
    id: 'save_1',
    schemaVersion: gameSaveCurrentSchemaVersion,
    name: 'Canonical turn fixture',
    world: const WorldReference(name: 'turn_map', source: MapSource.saved),
    savedAtUtc: _startedAt,
    camera: const GameSnapshotCamera(x: 2, y: 3, zoom: 0.75),
  );
}

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var col = 0; col < 3; col++)
        for (var row = 0; row < 3; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 1,
          ),
    ],
  );
}

const _deterministicCombatRuleset = GameRuleset(
  city: CityRulesets.standard,
  combat: CombatRuleset(
    varianceRange: 0,
    cityBaseStats: CombatStats(
      attack: 0,
      defense: 2,
      hp: 16,
      range: 1,
      mobility: 0,
    ),
    unitBaseStats: {
      GameUnitType.warrior: CombatStats(
        attack: 4,
        defense: 3,
        hp: 10,
        range: 1,
        mobility: 1,
      ),
    },
  ),
  technology: TechnologyRulesets.standard,
);
final _startedAt = DateTime.utc(2026, 7, 17, 9);
final _finalizedAt = DateTime.utc(2026, 7, 17, 10);
const _finishedPlayerStates = {
  'p1': PlayerTurnState.finished,
  'p2': PlayerTurnState.finished,
  'p3': PlayerTurnState.finished,
};
const _players = [
  Player(id: 'p1', name: 'Player one', colorValue: 0xFF000001),
  Player(
    id: 'p2',
    name: 'Player two',
    colorValue: 0xFF000002,
    country: PlayerCountry.france,
  ),
  Player(
    id: 'p3',
    name: 'Player three',
    colorValue: 0xFF000003,
    country: PlayerCountry.japan,
  ),
];
