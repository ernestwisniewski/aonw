import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

void main() {
  group('ServerCommandReducer resource trade', () {
    test('opens gold-for-resource trade authoritatively', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: _snapshot(
          PersistentGameState(
            playerGold: const {'player_1': 8},
            cities: _tradeCities(),
            research: _researchWithMany({
              'player_2': {TechnologyId.animalHusbandry},
            }),
          ),
        ),
        wireCommand: _wireCommand(
          const OpenResourceTradeCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            durationTurns: 5,
            agreementId: 'server_trade_1',
          ),
        ),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 12),
      );

      final nextState = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(nextState.runtimeState.resourceTradeAgreements, [
        const ResourceTradeAgreement(
          id: 'server_trade_1',
          exporterPlayerId: 'player_2',
          importerPlayerId: 'player_1',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          remainingTurns: 5,
        ),
      ]);
    });

    test('opens resource exchange authoritatively', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: _snapshot(
          PersistentGameState(
            cities: _tradeCities(),
            research: _researchWithMany({
              'player_1': {TechnologyId.ironWorking},
              'player_2': {TechnologyId.animalHusbandry},
            }),
          ),
        ),
        wireCommand: _wireCommand(
          const OpenResourceExchangeCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            offeredResource: ResourceType.iron,
            requestedResource: ResourceType.horses,
            durationTurns: 6,
            agreementId: 'server_exchange_1',
          ),
        ),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 12),
      );

      final nextState = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(
        nextState.runtimeState.resourceTradeAgreements
            .map((agreement) => agreement.toJson())
            .toList(),
        [
          {
            'id': 'server_exchange_1_offered',
            'exporterPlayerId': 'player_1',
            'importerPlayerId': 'player_2',
            'resource': ResourceType.iron.name,
            'remainingTurns': 6,
          },
          {
            'id': 'server_exchange_1_requested',
            'exporterPlayerId': 'player_2',
            'importerPlayerId': 'player_1',
            'resource': ResourceType.horses.name,
            'remainingTurns': 6,
          },
        ],
      );
    });

    test('rejects resource trade issued for another player', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );
      final snapshot = _snapshot(
        PersistentGameState(
          playerGold: const {'player_2': 8},
          cities: _tradeCities(),
          research: _researchWithMany({
            'player_1': {TechnologyId.ironWorking},
          }),
        ),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: snapshot,
        wireCommand: _wireCommand(
          const OpenResourceTradeCommand(
            playerId: 'player_2',
            targetPlayerId: 'player_1',
            resource: ResourceType.iron,
            goldPerTurn: 3,
            durationTurns: 5,
          ),
          actorPlayerId: 'player_1',
        ),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 12),
      );

      expect(reduction.accepted, isFalse);
      expect(reduction.reason, 'resource_trade_player_not_controlled');
      expect(reduction.snapshot.toJson(), snapshot.toJson());
    });
  });
}

WireMatch _runningMatch() {
  return WireMatch(
    id: 'match_1',
    ownerUserId: 'user_1',
    name: 'Server reducer trade',
    mapName: 'test_map',
    players: _wirePlayers(),
    turn: 1,
    state: 'running',
    createdAt: DateTime.utc(2026, 6, 30, 11),
  );
}

WireSnapshot _snapshot(PersistentGameState state) {
  return WireSnapshot(
    matchId: 'match_1',
    offset: 0,
    save: _save().toJson(),
    state: state.toJson(),
  );
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Server reducer trade',
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
}

WireCommand _wireCommand(
  GameCommand command, {
  String actorPlayerId = 'player_1',
}) {
  return WireCommand(
    matchId: 'match_1',
    tick: 1,
    turn: 1,
    actorPlayerId: actorPlayerId,
    command: GameCommandSerializer.toJson(command),
  );
}

List<WirePlayer> _wirePlayers() {
  return const [
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
  ];
}

List<GameCity> _tradeCities() {
  return const [
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
}

ResearchState _researchWithMany(Map<String, Set<TechnologyId>> technologies) {
  return ResearchState(
    players: {
      for (final entry in technologies.entries)
        entry.key: PlayerResearchState(unlockedTechnologyIds: entry.value),
    },
  );
}

MapData _resourceTradeMap() {
  return MapData(
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
}

class _FakeMapCatalog implements MultiplayerMapCatalog {
  const _FakeMapCatalog(this.mapData);

  final MapData mapData;

  @override
  Future<MapData> loadAssetMap(String mapName) async => mapData;
}
