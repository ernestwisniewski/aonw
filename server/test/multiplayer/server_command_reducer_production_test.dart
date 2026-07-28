import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

import 'support/server_command_reducer_test_driver.dart';

void main() {
  test('routes unit production through the canonical world map', () async {
    final reduction = await const ServerCommandReducerTestDriver().reduce(
      reducer: ServerCommandReducer(
        mapCatalog: _ProductionMapCatalog(_resourceTradeMap()),
      ),
      match: _runningMatch(),
      wireSnapshot: _snapshot(PersistentGameState(cities: _tradeCities())),
      wireCommand: _wireCommand(
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
      ),
      actorPlayerId: 'player_1',
      now: DateTime.utc(2026, 6, 30, 12),
    );
    final domain = reduction.nextSnapshot!.domain;

    expect(reduction.accepted, isTrue);
    expect(
      domain.cities
          .firstWhere((city) => city.id == 'city_1')
          .productionQueue
          ?.target,
      const UnitProductionTarget(GameUnitType.warrior),
    );
  });

  test('routes city projects through the production boundary', () async {
    final reduction = await _reduceCommand(
      const StartCityProjectCommand('city_1', CityProjectType.wealth),
      state: PersistentGameState(cities: _tradeCities()),
    );
    final domain = reduction.nextSnapshot!.domain;

    expect(reduction.accepted, isTrue);
    expect(
      domain.cities
          .firstWhere((city) => city.id == 'city_1')
          .productionQueue
          ?.target,
      const ProjectProductionTarget(CityProjectType.wealth),
    );
  });

  test('rush preserves unchanged server state slices', () async {
    final productionCost = CityProductionRules.buildingProductionCost(
      CityBuildingType.granary,
    );
    final reduction = await _reduceCommand(
      const RushProductionCommand('city_1'),
      state: PersistentGameState.snapshot(
        playerGold: const {'player_1': 2},
        units: [
          GameUnit.produced(
            id: 'sentinel_unit',
            ownerPlayerId: 'player_2',
            type: GameUnitType.worker,
            col: 2,
            row: 2,
          ),
        ],
        cities: [
          GameCity.snapshot(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Rush City',
            center: const CityHex(col: 0, row: 0),
            productionQueue: CityProductionQueue.building(
              buildingType: CityBuildingType.granary,
              investedProduction: productionCost - 1,
            ),
          ),
        ],
      ),
    );

    expect(reduction.accepted, isTrue);
    expect(
      reduction.nextSnapshot!.domain.units,
      same(reduction.previousSnapshot.domain.units),
    );
  });

  test(
    'routes the end-turn alias through authoritative turn handling',
    () async {
      final reduction = await _reduceCommand(
        const EndTurnCommand('player_1'),
        state: const PersistentGameState(),
      );

      expect(reduction.accepted, isTrue);
      expect(reduction.nextSnapshot!.domain.turn, 2);
    },
  );

  test('routes map-backed commands through the loaded server map', () async {
    final scenarios = <({GameCommand command, String reason})>[
      (
        command: FoundCityCommand('missing_settler', controlledHexes: const []),
        reason: 'city_founder_not_found',
      ),
      (
        command: const RushProductionCommand('missing_city'),
        reason: 'city_not_found',
      ),
      (
        command: const SelectCityExpansionHexCommand('missing_city', 1, 1),
        reason: 'city_not_found',
      ),
      (
        command: const SelectWorkerImprovementCommand(
          'missing_worker',
          FieldImprovementType.farm,
        ),
        reason: 'worker_not_found',
      ),
      (
        command: const AssignWorkerToHexCommand('missing_worker'),
        reason: 'worker_not_found',
      ),
    ];

    for (final scenario in scenarios) {
      final reduction = await _reduceCommand(
        scenario.command,
        state: const PersistentGameState(),
      );

      expect(
        reduction.accepted,
        isFalse,
        reason: '${scenario.command.runtimeType} must be rejected',
      );
      expect(reduction.reason, scenario.reason);
    }
  });
}

Future<ServerCommandTestReduction> _reduceCommand(
  GameCommand command, {
  required PersistentGameState state,
}) {
  return const ServerCommandReducerTestDriver().reduce(
    reducer: ServerCommandReducer(
      mapCatalog: _ProductionMapCatalog(_resourceTradeMap()),
    ),
    match: _runningMatch(),
    wireSnapshot: _snapshot(state),
    wireCommand: _wireCommand(command),
    actorPlayerId: 'player_1',
    now: DateTime.utc(2026, 6, 30, 12),
  );
}

WireMatch _runningMatch() => WireMatch(
  id: 'match_1',
  ownerUserId: 'user_1',
  name: 'Server reducer production',
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
  name: 'Server reducer production',
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

List<GameCity> _tradeCities() => const [
  GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'Iron City',
    center: CityHex(col: 0, row: 0),
  ),
  GameCity(
    id: 'city_2',
    ownerPlayerId: 'player_2',
    name: 'Horse City',
    center: CityHex(col: 2, row: 2),
  ),
];

MapData _resourceTradeMap() => MapData(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: switch ((col, row)) {
            (0, 0) => const [ResourceType.iron],
            (2, 2) => const [ResourceType.horses],
            _ => const [],
          },
          height: 0,
        ),
  ],
);

final class _ProductionMapCatalog implements MultiplayerMapCatalog {
  const _ProductionMapCatalog(this.mapData);

  final MapData mapData;

  @override
  Future<MapData> loadAssetMap(String mapName) async => mapData;
}
