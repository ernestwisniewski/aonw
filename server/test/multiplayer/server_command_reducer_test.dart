import 'dart:async';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

import 'support/server_command_reducer_test_driver.dart';

part 'support/server_command_reducer_fixture.dart';
part 'support/server_command_reducer_contract_cases.dart';
part 'support/server_command_reducer_combat_cases.dart';
part 'support/server_command_reducer_map_cache_cases.dart';
part 'support/server_command_reducer_outcome_cases.dart';
part 'support/server_command_reducer_snapshot_cases.dart';
part 'support/server_command_reducer_turn_timeout_cases.dart';
part 'support/server_command_reducer_resource_trade_cases.dart';

const _serverCommandTestDriver = ServerCommandReducerTestDriver();

void main() {
  _registerServerCommandReductionContractTests();
  _registerServerCommandReducerMapCacheTests();
  _registerServerCommandReducerOutcomeTests();
  _registerServerCommandReducerSnapshotTests();
  _registerServerCommandReducerTurnTimeoutTests();
  _registerServerCommandReducerCombatTests();

  group('ServerCommandReducer diplomacy commands', () {
    test(
      'routes proposals through the shared state-neutral diplomacy resolver',
      () async {
        final reduction = await _reduceDiplomacyCommand(
          state: _diplomacyState(),
          command: const SendDiplomaticProposalCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            kind: DiplomaticProposalKind.friendship,
            proposalId: 'proposal_1',
          ),
        );
        final nextDomain = reduction.nextSnapshot!.domain;

        expect(reduction.accepted, isTrue);
        expect(nextDomain.turn, 1);
        expect(reduction.previousSnapshot.domain, isNot(same(nextDomain)));
        expect(reduction.movementExecutions, isEmpty);
        expect(nextDomain.diplomacy.pendingProposals, contains('proposal_1'));
      },
    );

    test(
      'routes proposal responses through the shared state-neutral resolver',
      () async {
        final reduction = await _reduceDiplomacyCommand(
          state: _diplomacyState(
            diplomacy: DiplomacyState.empty.addProposal(
              const DiplomaticProposal(
                id: 'proposal_1',
                fromPlayerId: 'player_1',
                toPlayerId: 'player_2',
                kind: DiplomaticProposalKind.friendship,
                createdTurn: 1,
                expiresOnTurn: 6,
              ),
            ),
          ),
          command: const RespondDiplomaticProposalCommand(
            playerId: 'player_2',
            proposalId: 'proposal_1',
            accepted: true,
          ),
          actorPlayerId: 'player_2',
        );
        final nextDomain = reduction.nextSnapshot!.domain;

        expect(reduction.accepted, isTrue);
        expect(
          nextDomain.diplomacy.statusBetween('player_1', 'player_2'),
          DiplomaticRelationStatus.friendly,
        );
      },
    );

    test(
      'routes war declarations through the shared state-neutral resolver',
      () async {
        final reduction = await _reduceDiplomacyCommand(
          state: _diplomacyState(),
          command: const DeclareWarCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
          ),
        );
        final nextDomain = reduction.nextSnapshot!.domain;

        expect(reduction.accepted, isTrue);
        expect(
          nextDomain.diplomacy.statusBetween('player_1', 'player_2'),
          DiplomaticRelationStatus.war,
        );
      },
    );

    test(
      'routes gold gifts through the shared state-neutral diplomacy resolver',
      () async {
        final reduction = await _reduceDiplomacyCommand(
          state: _diplomacyState(playerGold: const {'player_1': 5}),
          command: const SendGoldGiftCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            amount: 5,
          ),
        );
        final nextDomain = reduction.nextSnapshot!.domain;

        expect(reduction.accepted, isTrue);
        expect(nextDomain.playerGold['player_1'], 0);
        expect(nextDomain.playerGold['player_2'], 5);
      },
    );

    test(
      'routes diplomatic messages through the shared state-neutral resolver',
      () async {
        final reduction = await _reduceDiplomacyCommand(
          state: _diplomacyState(),
          command: const SendDiplomaticMessageCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            topic: DiplomaticMessageTopic.blockedRoutes,
            messageId: 'message_1',
          ),
        );
        final nextDomain = reduction.nextSnapshot!.domain;

        expect(reduction.accepted, isTrue);
        expect(nextDomain.diplomacy.messages, contains('message_1'));
      },
    );

    test(
      'routes diplomatic message responses through the shared neutral resolver',
      () async {
        final reduction = await _reduceDiplomacyCommand(
          state: _diplomacyState(
            diplomacy: DiplomacyState.empty.addMessage(
              DiplomaticMessage.create(
                id: 'message_1',
                fromPlayerId: 'player_1',
                toPlayerId: 'player_2',
                topic: DiplomaticMessageTopic.troopsNearCities,
                createdTurn: 1,
                expiresOnTurn: 6,
              ),
            ),
          ),
          command: const RespondDiplomaticMessageCommand(
            playerId: 'player_2',
            messageId: 'message_1',
            response: DiplomaticMessageResponse.conciliatory,
          ),
          actorPlayerId: 'player_2',
        );
        final message =
            reduction.nextSnapshot!.domain.diplomacy.messages['message_1'];

        expect(reduction.accepted, isTrue);
        expect(message?.response, DiplomaticMessageResponse.conciliatory);
      },
    );

    test('rejects diplomacy commands issued for another player', () async {
      final snapshot = _snapshot(_diplomacyState());
      final reduction = await _serverCommandTestDriver.reduce(
        reducer: ServerCommandReducer(
          mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        ),
        match: _runningMatch(),
        wireSnapshot: snapshot,
        wireCommand: _wireCommand(
          const SendGoldGiftCommand(
            playerId: 'player_2',
            targetPlayerId: 'player_1',
            amount: 5,
          ),
          actorPlayerId: 'player_1',
        ),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 12),
      );

      expect(reduction.accepted, isFalse);
      expect(reduction.reason, 'diplomacy_player_not_controlled');
      expect(reduction.nextSnapshot, isNull);
      expect(reduction.wireSnapshot, same(snapshot));
    });
  });

  _registerServerCommandReducerResourceTradeTests();
}

Future<ServerCommandTestReduction> _reduceDiplomacyCommand({
  required PersistentGameState state,
  required DiplomaticCommand command,
  String actorPlayerId = 'player_1',
}) {
  return _serverCommandTestDriver.reduce(
    reducer: ServerCommandReducer(
      mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
    ),
    match: _runningMatch(),
    wireSnapshot: _snapshot(state),
    wireCommand: _wireCommand(command, actorPlayerId: actorPlayerId),
    actorPlayerId: actorPlayerId,
    now: DateTime.utc(2026, 6, 30, 12),
  );
}

PersistentGameState _diplomacyState({
  Map<String, int> playerGold = const {},
  DiplomacyState? diplomacy,
  GameRuntimeState? runtimeState,
}) {
  return PersistentGameState(
    playerColors: const {'player_1': 0xFF3D5FA8, 'player_2': 0xFFB83A3A},
    playerCountries: const {
      'player_1': PlayerCountry.poland,
      'player_2': PlayerCountry.france,
    },
    playerGold: playerGold,
    runtimeState:
        runtimeState ??
        GameRuntimeState(
          diplomacy:
              diplomacy ??
              DiplomacyState.empty.addContact('player_1', 'player_2'),
        ),
  );
}

WireMatch _runningMatch({
  List<WirePlayer>? players,
  String mapName = 'test_map',
}) {
  return WireMatch(
    id: 'match_1',
    ownerUserId: 'user_1',
    name: 'Server reducer trade',
    mapName: mapName,
    players: players ?? _wirePlayers(),
    turn: 1,
    state: 'running',
    createdAt: DateTime.utc(2026, 6, 30, 11),
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

List<Player> _domainPlayers() {
  return const [
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

PersistentGameState _combatState({
  required List<GameUnit> units,
  List<GameCity> cities = const [],
}) {
  final visible = {
    const HexCoordinate(col: 0, row: 0),
    const HexCoordinate(col: 1, row: 0),
    const HexCoordinate(col: 2, row: 0),
  };
  return PersistentGameState(
    playerColors: const {'player_1': 0xFF3D5FA8, 'player_2': 0xFFB83A3A},
    units: units,
    cities: cities,
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(playerId: 'player_1', visibleHexes: visible),
        'player_2': PlayerFogOfWar(playerId: 'player_2', visibleHexes: visible),
      },
    ),
  );
}

GameUnit _combatUnit(
  String id,
  String ownerPlayerId,
  int col,
  int row, {
  GameUnitType type = GameUnitType.warrior,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: id,
    col: col,
    row: row,
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
