import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

import 'support/server_command_reducer_test_driver.dart';

const _actorPlayerId = 'player_1';
const _opponentPlayerId = 'player_2';
const _scoutId = 'scout_1';
const _mapName = 'server_auto_explore_map';

void main() {
  group('ServerCommandReducer auto-explore', () {
    test(
      'direct no-target rejection preserves exact snapshot identity',
      () async {
        final state = _state(units: [_scout()]);
        final snapshot = _snapshot(state);

        final reduction = await _reduce(
          snapshot: snapshot,
          mapData: _map(cols: 1),
        );

        expect(reduction.accepted, isFalse);
        expect(reduction.reason, 'auto_explore_no_target');
        expect(reduction.wireSnapshot, same(snapshot));
        expect(reduction.nextSnapshot, isNull);
        expect(reduction.events, isEmpty);
      },
    );

    test(
      'forwards movement and contact while clearing only owned interaction',
      _forwardsMovementAndContact,
    );
  });
}

Future<void> _forwardsMovementAndContact() async {
  final reduction = await _reduce(
    snapshot: _snapshot(_contactState()),
    mapData: _map(cols: 4),
  );
  final before = reduction.previousSnapshot;
  final after = reduction.nextSnapshot!;

  _expectMovementAndContact(reduction, after);
  _expectUnrelatedStateShared(before, after);
}

PersistentGameState _contactState() {
  final unrelatedDraft = CityFoundingDraft(
    unitId: 'other_unit',
    ownerPlayerId: _actorPlayerId,
    center: const CityHex(col: 7, row: 7),
    controlledHexes: const [CityHex(col: 8, row: 7)],
  );
  return _state(
    units: [
      _scout(movementPoints: 1),
      GameUnit(
        id: 'opponent_unit',
        ownerPlayerId: _opponentPlayerId,
        type: GameUnitType.warrior,
        name: 'Opponent',
        col: 3,
        row: 0,
        movementPoints: 1,
      ),
    ],
    runtimeState: GameRuntimeState.snapshot(
      cityFoundingDraft: unrelatedDraft,
      pendingAction: const PendingUnitTurnSkip(
        ownerPlayerId: _actorPlayerId,
        unitId: _scoutId,
        restoreMovementPoints: 1,
      ),
      submittedPlayerIds: const {_opponentPlayerId},
      timeoutStreaksByPlayerId: const {_opponentPlayerId: 2},
      afkPlayerIds: const {_opponentPlayerId},
      kickedPlayerIds: const {'removed_player'},
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'sentinel_attacker',
          defenderCol: 6,
          defenderRow: 6,
          declaredAtTick: 17,
          declaringPlayerId: _opponentPlayerId,
        ),
      ],
      dominationHoldTurnsByPlayerId: const {_opponentPlayerId: 3},
      culturalVictoryHoldTurnsByPlayerId: const {_opponentPlayerId: 4},
      turnStartedAt: DateTime.utc(2026, 7, 22, 11),
    ),
  );
}

void _expectMovementAndContact(
  ServerCommandTestReduction reduction,
  CanonicalGameSnapshot after,
) {
  final moved = after.domain.units.byId(_scoutId)!;
  expect(reduction.accepted, isTrue);
  expect(reduction.reason, isNull);
  expect((moved.col, moved.row), (1, 0));
  expect(moved.posture, UnitPosture.autoExploring);
  expect(reduction.events, hasLength(1));
  final event = reduction.events.single as UnitMovedEvent;
  expect(
    (event.unitId, event.fromCol, event.fromRow, event.toCol, event.toRow),
    (_scoutId, 0, 0, 1, 0),
  );
  final execution = reduction.movementExecutions.single;
  expect(
    (execution.unitId, execution.fromCol, execution.fromRow),
    (_scoutId, 0, 0),
  );
  expect(
    execution.steps.map(
      (step) => (step.col, step.row, step.enterCost, step.cumulativeCost),
    ),
    [(1, 0, 1, 1)],
  );
  expect(
    after.domain.diplomacy.hasContact(_actorPlayerId, _opponentPlayerId),
    isTrue,
  );
  expect(after.interaction.pendingAction, isNull);
}

void _expectUnrelatedStateShared(
  CanonicalGameSnapshot before,
  CanonicalGameSnapshot after,
) {
  expect(
    after.interaction.cityFoundingDraft,
    same(before.interaction.cityFoundingDraft),
  );
  expect(after.domain.playerColors, same(before.domain.playerColors));
  expect(after.domain.playerGold, same(before.domain.playerGold));
  expect(after.domain.cities, same(before.domain.cities));
  expect(after.domain.artifacts, same(before.domain.artifacts));
  expect(after.domain.fieldImprovements, same(before.domain.fieldImprovements));
  expect(after.domain.research, same(before.domain.research));
  expect(after.domain.wonderRegistry, same(before.domain.wonderRegistry));
  expect(
    after.session.submittedPlayerIds,
    same(before.session.submittedPlayerIds),
  );
  expect(
    after.session.timeoutStreaksByPlayerId,
    same(before.session.timeoutStreaksByPlayerId),
  );
  expect(after.session.afkPlayerIds, same(before.session.afkPlayerIds));
  expect(after.session.kickedPlayerIds, same(before.session.kickedPlayerIds));
  expect(after.domain.intendedAttacks, same(before.domain.intendedAttacks));
  expect(
    after.domain.dominationHoldTurnsByPlayerId,
    same(before.domain.dominationHoldTurnsByPlayerId),
  );
  expect(
    after.domain.culturalVictoryHoldTurnsByPlayerId,
    same(before.domain.culturalVictoryHoldTurnsByPlayerId),
  );
  expect(after.session.turnStartedAt, before.session.turnStartedAt);
}

PersistentGameState _state({
  required List<GameUnit> units,
  GameRuntimeState runtimeState = GameRuntimeState.empty,
}) {
  const origin = HexCoordinate(col: 0, row: 0);
  return PersistentGameState.snapshot(
    playerColors: const {
      _actorPlayerId: 0xFF112233,
      _opponentPlayerId: 0xFF445566,
    },
    playerGold: const {_actorPlayerId: 11, _opponentPlayerId: 13},
    units: units,
    fogOfWar: FogOfWarState(
      players: {
        _actorPlayerId: PlayerFogOfWar(
          playerId: _actorPlayerId,
          discoveredHexes: {origin},
          visibleHexes: {origin},
        ),
      },
    ),
    runtimeState: runtimeState,
  );
}

GameUnit _scout({int movementPoints = 2}) {
  return GameUnit(
    id: _scoutId,
    ownerPlayerId: _actorPlayerId,
    type: GameUnitType.scout,
    name: 'Scout',
    col: 0,
    row: 0,
    movementPoints: movementPoints,
  );
}

Future<ServerCommandTestReduction> _reduce({
  required WireSnapshot snapshot,
  required MapData mapData,
}) {
  return const ServerCommandReducerTestDriver().reduce(
    reducer: ServerCommandReducer(mapCatalog: _AutoExploreMapCatalog(mapData)),
    match: _runningMatch(),
    wireSnapshot: snapshot,
    wireCommand: WireCommand(
      matchId: 'match_1',
      tick: 1,
      turn: 1,
      actorPlayerId: _actorPlayerId,
      command: GameCommandSerializer.toJson(
        const AutoExploreUnitCommand(_scoutId),
      ),
    ),
    actorPlayerId: _actorPlayerId,
    now: DateTime.utc(2026, 7, 22, 12),
  );
}

WireSnapshot _snapshot(PersistentGameState state) => WireSnapshot(
  matchId: 'match_1',
  offset: 0,
  save: _save().toJson(),
  state: state.toJson(),
);

GameSave _save() => GameSave(
  id: 'save_1',
  name: 'Server auto-explore',
  mapName: _mapName,
  turn: 1,
  playerStates: const {
    _actorPlayerId: PlayerTurnState.active,
    _opponentPlayerId: PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 7, 22, 11),
  camera: CameraState.zero,
  players: const [
    Player(
      id: _actorPlayerId,
      name: 'Player 1',
      colorValue: 0xFF112233,
      country: PlayerCountry.poland,
    ),
    Player(
      id: _opponentPlayerId,
      name: 'Player 2',
      colorValue: 0xFF445566,
      country: PlayerCountry.france,
    ),
  ],
  gameMode: GameMode.multiplayer,
);

WireMatch _runningMatch() => WireMatch(
  id: 'match_1',
  ownerUserId: 'user_1',
  name: 'Server auto-explore',
  mapName: _mapName,
  players: const [
    WirePlayer(
      id: _actorPlayerId,
      userId: 'user_1',
      name: 'Player 1',
      colorValue: 0xFF112233,
      country: PlayerCountry.poland,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.connected,
    ),
    WirePlayer(
      id: _opponentPlayerId,
      userId: 'user_2',
      name: 'Player 2',
      colorValue: 0xFF445566,
      country: PlayerCountry.france,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.connected,
    ),
  ],
  turn: 1,
  state: 'running',
  createdAt: DateTime.utc(2026, 7, 22, 11),
);

MapData _map({required int cols}) => MapData(
  cols: cols,
  rows: 1,
  mapName: _mapName,
  tiles: [
    for (var col = 0; col < cols; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);

final class _AutoExploreMapCatalog implements MultiplayerMapCatalog {
  const _AutoExploreMapCatalog(this.mapData);

  final MapData mapData;

  @override
  Future<MapData> loadAssetMap(String mapName) async {
    if (mapName != _mapName) {
      throw StateError('Unexpected auto-explore map: $mapName.');
    }
    return mapData;
  }
}
