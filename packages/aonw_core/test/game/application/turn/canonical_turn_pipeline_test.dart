import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:test/test.dart';

void main() {
  group('CanonicalTurnPipeline', () {
    test('matches the temporary persistent kernel', _matchesLegacyKernel);
    test(
      'preserves canonical session, interaction, metadata, and offset',
      _preservesCanonicalBoundaries,
    );
    test(
      'keeps city combat ordered and suppresses same-turn recovery',
      _characterizesCityCombatPrefix,
    );
  });
}

void _matchesLegacyKernel() {
  final input = _canonicalInput();
  final legacyInput = _adapter.toLegacy(input);
  final legacyResult = PersistentTurnPipeline.simultaneousFinalize(
    _legacyRequest(legacyInput),
  );

  final result = CanonicalTurnPipeline.simultaneousFinalize(
    _canonicalRequest(input),
  );
  final expectedSnapshot = _adapter.toCanonical(
    save: legacyResult.save,
    state: legacyResult.state,
    eventLogOffset: input.eventLogOffset,
  );

  expect(result.snapshot, expectedSnapshot);
  expect(_eventJson(result.events), _eventJson(legacyResult.events));
  expect(
    result.movementDelta?.beforeUnits,
    legacyResult.movementDelta?.beforeUnits,
  );
  expect(
    result.movementDelta?.afterUnits,
    legacyResult.movementDelta?.afterUnits,
  );
}

void _preservesCanonicalBoundaries() {
  final input = _canonicalInput();

  final result = CanonicalTurnPipeline.simultaneousFinalize(
    _canonicalRequest(input),
  );
  final snapshot = result.snapshot;

  expect(snapshot.eventLogOffset, input.eventLogOffset);
  expect(snapshot.domain.turn, 2);
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
  final TurnMovementDelta? delta = result.movementDelta;
  expect(delta, isNotNull);
  expect(delta!.beforeUnits, hasLength(1));
  expect(delta.afterUnits, hasLength(1));
}

void _characterizesCityCombatPrefix() {
  final input = _combatInput();
  final legacyInput = _adapter.toLegacy(input);
  final legacyResult = PersistentTurnPipeline.simultaneousFinalize(
    PersistentTurnPipelineRequest.simultaneousFinalize(
      save: legacyInput.save,
      state: legacyInput.state,
      playerIds: const ['p1', 'p2'],
      savedAt: _finalizedAt,
      mapView: _mapData(),
      ruleset: _deterministicCombatRuleset,
    ),
  );

  final result = CanonicalTurnPipeline.simultaneousFinalize(
    CanonicalTurnPipelineRequest.simultaneousFinalize(
      snapshot: input,
      playerIds: const ['p1', 'p2'],
      savedAt: _finalizedAt,
      mapView: _mapData(),
      ruleset: _deterministicCombatRuleset,
    ),
  );
  final expectedSnapshot = _adapter.toCanonical(
    save: legacyResult.save,
    state: legacyResult.state,
    eventLogOffset: input.eventLogOffset,
  );

  expect(result.snapshot, expectedSnapshot);
  expect(_eventJson(result.events), _eventJson(legacyResult.events));
  expect(
    result.movementDelta?.beforeUnits,
    legacyResult.movementDelta?.beforeUnits,
  );
  expect(
    result.movementDelta?.afterUnits,
    legacyResult.movementDelta?.afterUnits,
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

PersistentTurnPipelineRequest _legacyRequest(LegacyGameSnapshotParts input) {
  return PersistentTurnPipelineRequest.simultaneousFinalize(
    save: input.save,
    state: input.state,
    playerIds: const ['p2', 'p1', 'p1'],
    skippedPlayerIds: const ['p2'],
    savedAt: _finalizedAt,
    mapView: _mapData(),
    preserveNonParticipantPlayerStates: true,
    trackTimeoutStreaks: true,
  );
}

CanonicalGameSnapshot _canonicalInput() {
  return _adapter.toCanonical(
    save: _save(),
    state: _state(),
    eventLogOffset: 41,
  );
}

CanonicalGameSnapshot _combatInput() {
  return _adapter.toCanonical(
    save: _save(),
    state: PersistentGameState(
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
      runtimeState: const GameRuntimeState(
        intendedAttacks: [
          IntendedAttack(
            attackerUnitId: 'warrior_p1',
            defenderCol: 1,
            defenderRow: 0,
            declaredAtTick: 7,
            declaringPlayerId: 'p1',
          ),
        ],
      ),
    ),
    eventLogOffset: 73,
  );
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    schemaVersion: gameSaveCurrentSchemaVersion,
    name: 'Canonical turn fixture',
    mapName: 'turn_map',
    mapSource: MapSource.saved,
    turn: 1,
    playerStates: const {
      'p1': PlayerTurnState.finished,
      'p2': PlayerTurnState.finished,
      'p3': PlayerTurnState.finished,
    },
    savedAt: _startedAt,
    camera: const CameraState(x: 2, y: 3, zoom: 0.75),
    players: _players,
    gameMode: GameMode.multiplayer,
  );
}

PersistentGameState _state() {
  return PersistentGameState.snapshot(
    playerColors: const {'p1': 0xFF000001, 'p2': 0xFF000002, 'p3': 0xFF000003},
    playerCountries: const {
      'p1': PlayerCountry.poland,
      'p2': PlayerCountry.france,
      'p3': PlayerCountry.japan,
    },
    units: [
      GameUnit.startingWarrior(
        ownerPlayerId: 'p1',
        col: 1,
        row: 1,
      ).copyWith(movementPoints: 0),
    ],
    runtimeState: GameRuntimeState.snapshot(
      cityFoundingDraft: CityFoundingDraft(
        unitId: 'warrior_p1',
        ownerPlayerId: 'p1',
        center: const CityHex(col: 1, row: 1),
      ),
      pendingAction: const PendingResearchSelection(ownerPlayerId: 'p1'),
      submittedPlayerIds: {'p1', 'p2'},
      timeoutStreaksByPlayerId: {'p2': 2},
      afkPlayerIds: {'p2'},
      kickedPlayerIds: {'p3'},
      turnStartedAt: _startedAt,
    ),
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

List<Map<String, dynamic>> _eventJson(Iterable<GameEvent> events) {
  return events.map(GameEventSerializer.toJson).toList();
}

const _adapter = LegacyGameSnapshotAdapter();
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
