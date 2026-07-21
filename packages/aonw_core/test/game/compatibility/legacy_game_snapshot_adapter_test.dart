import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:test/test.dart';

void main() {
  group('LegacyGameSnapshotAdapter', () {
    test('round-trips a coherent full legacy snapshot', _roundTripsFullState);
    test('round-trips canonical state through legacy parts', _canonicalCycle);
    test('canonicalizes conflicting player identity', _identityPrecedence);
    test('falls back to save player identity', _identityFallback);
    test('appends orphan players deterministically', _orphanOrdering);
    test('keeps turn status and submission independent', _sessionSeparation);
    test(
      'includes a submitted-only player in canonical identity',
      _submittedOnly,
    );
    test('materializes multiplayer timeout origin once', _timeoutFallback);
    test('keeps a missing hot-seat timeout origin null', _hotSeatNullStart);
  });
}

void _roundTripsFullState() {
  final save = _save();
  final state = _fullState();

  final canonical = _adapter.toCanonical(
    save: save,
    state: state,
    eventLogOffset: 47,
  );
  final legacy = _adapter.toLegacy(canonical);

  expect(legacy.save, save);
  expect(legacy.state, state);
  expect(legacy.eventLogOffset, 47);
  expect(canonical.domain.intendedAttacks, state.runtimeState.intendedAttacks);
  expect(canonical.interaction.cityFoundingDraft, isNotNull);
  expect(canonical.interaction.pendingAction, isNotNull);
}

void _identityPrecedence() {
  final save = _save(
    players: const [
      Player(
        id: 'p1',
        name: 'Original name',
        colorValue: 0xFF010101,
        country: PlayerCountry.france,
      ),
    ],
    playerStates: const {'p1': PlayerTurnState.active},
  );
  final state = PersistentGameState.snapshot(
    playerColors: const {'p1': 0xFFABCDEF},
    playerCountries: const {'p1': PlayerCountry.japan},
  );

  final canonical = _adapter.toCanonical(save: save, state: state);
  final legacy = _adapter.toLegacy(canonical);

  expect(
    canonical.domain.participants.single,
    const Player(
      id: 'p1',
      name: 'Original name',
      colorValue: 0xFFABCDEF,
      country: PlayerCountry.japan,
    ),
  );
  expect(legacy.save.players.single, canonical.domain.participants.single);
  expect(legacy.state.playerColors, const {'p1': 0xFFABCDEF});
  expect(legacy.state.playerCountries, const {'p1': PlayerCountry.japan});
}

void _canonicalCycle() {
  final canonical = _adapter.toCanonical(
    save: _save(),
    state: _fullState(),
    eventLogOffset: 47,
  );
  final legacy = _adapter.toLegacy(canonical);
  final restored = _adapter.toCanonical(
    save: legacy.save,
    state: legacy.state,
    eventLogOffset: legacy.eventLogOffset,
  );

  expect(restored, canonical);
}

void _identityFallback() {
  const player = Player(
    id: 'p1',
    name: 'Fallback identity',
    colorValue: 0xFF123456,
    country: PlayerCountry.canada,
  );
  final canonical = _adapter.toCanonical(
    save: _save(
      players: [player],
      playerStates: const {'p1': PlayerTurnState.active},
    ),
    state: PersistentGameState.snapshot(),
  );
  final legacy = _adapter.toLegacy(canonical);

  expect(canonical.domain.participants.single, player);
  expect(legacy.state.playerColors, const {'p1': 0xFF123456});
  expect(legacy.state.playerCountries, const {'p1': PlayerCountry.canada});
}

void _orphanOrdering() {
  final save = _save(
    players: const [Player(id: 'p1', name: 'First', colorValue: 0xFF010101)],
    playerStates: const {'p1': PlayerTurnState.active},
  );
  final state = PersistentGameState.snapshot(
    playerColors: const {'z_orphan': 0xFF030303},
    playerGold: const {'a_orphan': 10},
    runtimeState: GameRuntimeState.snapshot(
      cityFoundingDraft: CityFoundingDraft(
        unitId: 'settler',
        ownerPlayerId: 'draft_orphan',
        center: const CityHex(col: 0, row: 0),
      ),
      pendingAction: const PendingResearchSelection(
        ownerPlayerId: 'pending_orphan',
      ),
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'unit',
          defenderCol: 1,
          defenderRow: 1,
          declaredAtTick: 1,
          declaringPlayerId: 'attack_orphan',
        ),
      ],
    ),
  );

  final canonical = _adapter.toCanonical(save: save, state: state);

  expect(canonical.domain.participants.map((player) => player.id), [
    'p1',
    'a_orphan',
    'attack_orphan',
    'draft_orphan',
    'pending_orphan',
    'z_orphan',
  ]);
  expect(canonical.domain.participants[1].name, 'a_orphan');
  expect(canonical.domain.participants[1].colorValue, Player.palette[1]);
  expect(
    canonical.domain.participants
        .singleWhere((player) => player.id == 'z_orphan')
        .colorValue,
    0xFF030303,
  );
  expect(
    canonical.domain.participants.skip(1).map((player) => player.country),
    everyElement(PlayerCountry.poland),
  );
}

void _sessionSeparation() {
  final save = _save(
    playerStates: const {
      'p1': PlayerTurnState.finished,
      'p2': PlayerTurnState.active,
    },
  );
  final state = PersistentGameState.snapshot(
    playerColors: _colors,
    playerCountries: _countries,
    runtimeState: GameRuntimeState.snapshot(
      submittedPlayerIds: {'p2'},
      kickedPlayerIds: {'p1'},
      turnStartedAt: _turnStartedAt,
    ),
  );

  final canonical = _adapter.toCanonical(save: save, state: state);
  final legacy = _adapter.toLegacy(canonical);

  expect(
    canonical.session.turnStatesByPlayerId['p1'],
    PlayerTurnState.finished,
  );
  expect(canonical.session.isKicked('p1'), isTrue);
  expect(canonical.session.hasSubmitted('p1'), isFalse);
  expect(canonical.session.turnStatesByPlayerId['p2'], PlayerTurnState.active);
  expect(canonical.session.hasSubmitted('p2'), isTrue);
  expect(legacy.save.playerStates, save.playerStates);
  expect(legacy.state.runtimeState.submittedPlayerIds, {'p2'});
  expect(legacy.state.runtimeState.kickedPlayerIds, {'p1'});
}

void _submittedOnly() {
  final canonical = _adapter.toCanonical(
    save: _save(),
    state: PersistentGameState.snapshot(
      playerColors: _colors,
      playerCountries: _countries,
      runtimeState: GameRuntimeState.snapshot(
        submittedPlayerIds: {'submitted-only'},
      ),
    ),
  );
  final legacy = _adapter.toLegacy(canonical);

  expect(canonical.domain.participants.map((player) => player.id), [
    'p1',
    'p2',
    'submitted-only',
  ]);
  expect(canonical.session.submittedPlayerIds, {'submitted-only'});
  expect(
    canonical.domain.participants.last,
    Player(
      id: 'submitted-only',
      name: 'submitted-only',
      colorValue: Player.palette[2],
    ),
  );
  expect(legacy.state.runtimeState.submittedPlayerIds, {'submitted-only'});
}

void _timeoutFallback() {
  final canonical = _adapter.toCanonical(
    save: _save(savedAt: _savedAt),
    state: PersistentGameState.snapshot(
      playerColors: _colors,
      playerCountries: _countries,
    ),
  );
  final laterSavedAt = _savedAt.add(const Duration(hours: 3));
  final updated = CanonicalGameSnapshot.snapshot(
    domain: canonical.domain,
    session: canonical.session,
    metadata: canonical.metadata.copyWith(savedAtUtc: laterSavedAt),
    interaction: canonical.interaction,
    eventLogOffset: canonical.eventLogOffset,
  );

  final legacy = _adapter.toLegacy(updated);

  expect(canonical.session.turnStartedAt, _savedAt);
  expect(legacy.save.savedAt, laterSavedAt);
  expect(legacy.state.runtimeState.turnStartedAt, _savedAt);
}

void _hotSeatNullStart() {
  final canonical = _adapter.toCanonical(
    save: _save(gameMode: GameMode.hotSeat),
    state: PersistentGameState.snapshot(
      playerColors: _colors,
      playerCountries: _countries,
    ),
  );
  final legacy = _adapter.toLegacy(canonical);

  expect(canonical.session.turnStartedAt, isNull);
  expect(legacy.state.runtimeState.turnStartedAt, isNull);
}

GameSave _save({
  List<Player> players = _players,
  Map<String, PlayerTurnState> playerStates = _playerStates,
  DateTime? savedAt,
  GameMode gameMode = GameMode.multiplayer,
}) {
  return GameSave(
    id: 'save_1',
    schemaVersion: gameSaveCurrentSchemaVersion,
    name: 'Adapter fixture',
    mapName: 'world_1',
    mapSource: MapSource.saved,
    turn: 9,
    playerStates: playerStates,
    savedAt: savedAt ?? _savedAt,
    camera: const CameraState(x: 1.5, y: -2.0, zoom: 0.75),
    players: players,
    gameMode: gameMode,
  );
}

PersistentGameState _fullState() {
  return PersistentGameState.snapshot(
    playerColors: _colors,
    playerCountries: _countries,
    playerGold: const {'p1': 12, 'p2': 7},
    playerWarWeariness: const {'p1': 2},
    playerStabilityNet: const {'p2': -1},
    units: [GameUnit.startingCommander(ownerPlayerId: 'p1', col: 2, row: 3)],
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'p1',
        name: 'Capital',
        center: CityHex(col: 2, row: 3),
      ),
    ],
    artifacts: const [
      WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.ancientImperialCrown,
        location: WorldArtifactLocation.map(col: 4, row: 5),
      ),
    ],
    fieldImprovements: const [
      FieldImprovement(
        hex: CityHex(col: 3, row: 3),
        type: FieldImprovementType.farm,
        builtByCityId: 'city_1',
      ),
    ],
    fogOfWar: FogOfWarState(
      players: {
        'p1': PlayerFogOfWar(
          playerId: 'p1',
          visibleHexes: <HexCoordinate>{const HexCoordinate(col: 2, row: 3)},
        ),
      },
    ),
    research: ResearchState(
      players: {'p1': PlayerResearchState(scienceOverflow: 4)},
    ),
    runtimeState: _fullRuntimeState(),
    wonderRegistry: WonderRegistry.empty.complete(
      type: WonderType.greatLibrary,
      playerId: 'p1',
    ),
  );
}

GameRuntimeState _fullRuntimeState() {
  return GameRuntimeState.snapshot(
    cityFoundingDraft: CityFoundingDraft(
      unitId: 'commander_p1',
      ownerPlayerId: 'p1',
      center: const CityHex(col: 2, row: 3),
    ),
    pendingAction: const PendingResearchSelection(ownerPlayerId: 'p1'),
    submittedPlayerIds: {'p2'},
    timeoutStreaksByPlayerId: {'p2': 2},
    afkPlayerIds: {'p2'},
    kickedPlayerIds: {'p2'},
    intendedAttacks: const [
      IntendedAttack(
        attackerUnitId: 'commander_p1',
        defenderCol: 5,
        defenderRow: 6,
        declaredAtTick: 7,
        declaringPlayerId: 'p1',
      ),
    ],
    diplomacy: DiplomacyState.empty.registerUnitAttack(
      attackerPlayerId: 'p1',
      defenderPlayerId: 'p2',
      turn: 9,
    ),
    dominationHoldTurnsByPlayerId: {'p1': 2},
    culturalVictoryHoldTurnsByPlayerId: {'p2': 3},
    mapObjectiveHoldStatesByObjectiveId: const {
      'pass_1': MapObjectiveHoldState(
        objectiveId: 'pass_1',
        playerId: 'p1',
        holdTurns: 4,
      ),
    },
    resourceTradeAgreements: const [
      ResourceTradeAgreement(
        id: 'trade_1',
        exporterPlayerId: 'p1',
        importerPlayerId: 'p2',
        resource: ResourceType.iron,
        goldPerTurn: 2,
        remainingTurns: 3,
      ),
    ],
    turnStartedAt: _turnStartedAt,
  );
}

const _adapter = LegacyGameSnapshotAdapter();
final _savedAt = DateTime.utc(2026, 7, 17, 10);
final _turnStartedAt = DateTime.utc(2026, 7, 17, 9);
const _colors = {'p1': 0xFF101010, 'p2': 0xFF202020};
const _countries = {'p1': PlayerCountry.poland, 'p2': PlayerCountry.japan};
const _players = [
  Player(
    id: 'p1',
    name: 'Player one',
    colorValue: 0xFF101010,
    country: PlayerCountry.poland,
  ),
  Player(
    id: 'p2',
    name: 'Player two',
    colorValue: 0xFF202020,
    country: PlayerCountry.japan,
  ),
];
const _playerStates = {
  'p1': PlayerTurnState.finished,
  'p2': PlayerTurnState.active,
};
