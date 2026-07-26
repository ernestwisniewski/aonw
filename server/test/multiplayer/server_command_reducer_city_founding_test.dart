import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

import 'support/server_command_reducer_test_driver.dart';

void main() {
  test('clears the founding draft when a settler founds a city', () async {
    final reduction = await const ServerCommandReducerTestDriver().reduce(
      reducer: ServerCommandReducer(
        mapCatalog: _FoundingMapCatalog(_grasslandMap()),
      ),
      match: _runningMatch(),
      wireSnapshot: _snapshot(
        PersistentGameState(
          units: [_settler()],
          runtimeState: GameRuntimeState(
            cityFoundingDraft: CityFoundingDraft(
              unitId: 'settler_1',
              ownerPlayerId: 'player_1',
              center: const CityHex(col: 1, row: 1),
            ),
          ),
        ),
      ),
      wireCommand: _wireCommand(
        FoundCityCommand(
          'settler_1',
          controlledHexes: const [
            CityHex(col: 2, row: 1),
            CityHex(col: 1, row: 2),
          ],
        ),
      ),
      actorPlayerId: 'player_1',
      now: DateTime.utc(2026, 6, 30, 12),
    );
    final nextSnapshot = reduction.nextSnapshot!;

    expect(reduction.accepted, isTrue);
    expect(nextSnapshot.interaction.cityFoundingDraft, isNull);
    expect(nextSnapshot.domain.units.single.cityFoundingJob, isNotNull);
  });
}

GameUnit _settler() {
  return GameUnit(
    id: 'settler_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.settler,
    name: 'Settler',
    col: 1,
    row: 1,
    movementPoints: 2,
  );
}

WireMatch _runningMatch() => WireMatch(
  id: 'match_1',
  ownerUserId: 'user_1',
  name: 'Server reducer founding',
  mapName: 'test_map',
  players: const [
    WirePlayer(
      id: 'player_1',
      userId: 'user_1',
      name: 'Player 1',
      colorValue: 0xFF3D5FA8,
      country: PlayerCountry.poland,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.connected,
    ),
    WirePlayer(
      id: 'player_2',
      userId: 'user_2',
      name: 'Player 2',
      colorValue: 0xFFB83A3A,
      country: PlayerCountry.france,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.connected,
    ),
  ],
  turn: 1,
  state: 'running',
  createdAt: DateTime.utc(2026, 6, 30, 11),
);

WireSnapshot _snapshot(PersistentGameState state) => WireSnapshot(
  matchId: 'match_1',
  offset: 0,
  save: _save().toJson(),
  state: state.toJson(),
);

GameSave _save() => GameSave(
  id: 'save_1',
  name: 'Server reducer founding',
  mapName: 'test_map',
  turn: 1,
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 6, 30, 11),
  camera: CameraState.zero,
  players: const [
    Player(
      id: 'player_1',
      name: 'Player 1',
      colorValue: 0xFF3D5FA8,
      country: PlayerCountry.poland,
    ),
    Player(
      id: 'player_2',
      name: 'Player 2',
      colorValue: 0xFFB83A3A,
      country: PlayerCountry.france,
    ),
  ],
  gameMode: GameMode.multiplayer,
);

WireCommand _wireCommand(GameCommand command) => WireCommand(
  matchId: 'match_1',
  tick: 1,
  turn: 1,
  actorPlayerId: 'player_1',
  command: GameCommandSerializer.toJson(command),
);

MapData _grasslandMap() => MapData(
  cols: 4,
  rows: 4,
  tiles: [
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

final class _FoundingMapCatalog implements MultiplayerMapCatalog {
  const _FoundingMapCatalog(this.mapData);

  final MapData mapData;

  @override
  Future<MapData> loadAssetMap(String mapName) async => mapData;
}
