import 'dart:async';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

part 'support/server_command_reducer_map_cache_cases.dart';
part 'support/server_command_reducer_resource_trade_cases.dart';

void main() {
  _registerServerCommandReducerMapCacheTests();

  group('ServerCommandReducer diplomacy commands', () {
    test(
      'routes proposals through the persistent diplomacy resolver',
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
        final nextState = PersistentGameState.fromJson(
          reduction.snapshot.state,
        );

        expect(reduction.accepted, isTrue);
        expect(reduction.turn, 1);
        expect(reduction.previousState, isNotNull);
        expect(reduction.state, nextState);
        expect(
          nextState.runtimeState.diplomacy.pendingProposals,
          contains('proposal_1'),
        );
      },
    );

    test(
      'routes proposal responses through the persistent diplomacy resolver',
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
        final nextState = PersistentGameState.fromJson(
          reduction.snapshot.state,
        );

        expect(reduction.accepted, isTrue);
        expect(
          nextState.runtimeState.diplomacy.statusBetween(
            'player_1',
            'player_2',
          ),
          DiplomaticRelationStatus.friendly,
        );
      },
    );

    test(
      'routes war declarations through the persistent diplomacy resolver',
      () async {
        final reduction = await _reduceDiplomacyCommand(
          state: _diplomacyState(),
          command: const DeclareWarCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
          ),
        );
        final nextState = PersistentGameState.fromJson(
          reduction.snapshot.state,
        );

        expect(reduction.accepted, isTrue);
        expect(
          nextState.runtimeState.diplomacy.statusBetween(
            'player_1',
            'player_2',
          ),
          DiplomaticRelationStatus.war,
        );
      },
    );

    test(
      'routes gold gifts through the persistent diplomacy resolver',
      () async {
        final reduction = await _reduceDiplomacyCommand(
          state: _diplomacyState(playerGold: const {'player_1': 5}),
          command: const SendGoldGiftCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            amount: 5,
          ),
        );
        final nextState = PersistentGameState.fromJson(
          reduction.snapshot.state,
        );

        expect(reduction.accepted, isTrue);
        expect(nextState.playerGold['player_1'], 0);
        expect(nextState.playerGold['player_2'], 5);
      },
    );

    test(
      'routes diplomatic messages through the persistent diplomacy resolver',
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
        final nextState = PersistentGameState.fromJson(
          reduction.snapshot.state,
        );

        expect(reduction.accepted, isTrue);
        expect(
          nextState.runtimeState.diplomacy.messages,
          contains('message_1'),
        );
      },
    );

    test(
      'routes diplomatic message responses through the persistent resolver',
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
        final nextState = PersistentGameState.fromJson(
          reduction.snapshot.state,
        );
        final message = nextState.runtimeState.diplomacy.messages['message_1'];

        expect(reduction.accepted, isTrue);
        expect(message?.response, DiplomaticMessageResponse.conciliatory);
      },
    );

    test('rejects diplomacy commands issued for another player', () async {
      final snapshot = _snapshot(_diplomacyState());
      final reduction =
          await ServerCommandReducer(
            mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
          ).reduce(
            match: _runningMatch(),
            snapshot: snapshot,
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
      expect(reduction.snapshot.toJson(), snapshot.toJson());
    });
  });

  _registerServerCommandReducerResourceTradeTests();

  group('ServerCommandReducer combat commands', () {
    test('resolves a unit attack instead of rejecting the command', () async {
      final reduction =
          await ServerCommandReducer(
            mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
          ).reduce(
            match: _runningMatch(),
            snapshot: _snapshot(
              _combatState(
                units: [
                  _combatUnit('attacker', 'player_1', 0, 0),
                  _combatUnit(
                    'defender',
                    'player_2',
                    1,
                    0,
                    type: GameUnitType.settler,
                  ),
                ],
              ),
            ),
            wireCommand: _wireCommand(const AttackHexCommand('attacker', 1, 0)),
            actorPlayerId: 'player_1',
            now: DateTime.utc(2026, 6, 30, 12),
          );
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(reduction.reason, isNull);
      expect(reduction.events.whereType<UnitAttackedEvent>(), hasLength(1));
      expect(reduction.events.whereType<CombatResolvedEvent>(), hasLength(1));
      expect(state.units.byId('attacker')?.movementPoints, 0);
    });

    test('honors city destruction in an authoritative attack', () async {
      final reduction =
          await ServerCommandReducer(
            mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
          ).reduce(
            match: _runningMatch(),
            snapshot: _snapshot(
              _combatState(
                units: [_combatUnit('attacker', 'player_1', 0, 0)],
                cities: const [
                  GameCity(
                    id: 'city_2',
                    ownerPlayerId: 'player_2',
                    name: 'City 2',
                    center: CityHex(col: 1, row: 0),
                    hitPoints: 1,
                  ),
                ],
              ),
            ),
            wireCommand: _wireCommand(
              const AttackHexCommand(
                'attacker',
                1,
                0,
                cityConquestAction: CityConquestAction.destroy,
              ),
            ),
            actorPlayerId: 'player_1',
            now: DateTime.utc(2026, 6, 30, 12),
          );
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(state.cities, isEmpty);
      expect(reduction.events.whereType<CityAttackedEvent>(), hasLength(1));
      expect(reduction.events.whereType<CityDestroyedEvent>(), hasLength(1));
    });
  });

  group('ServerCommandReducer turn timeouts', () {
    test(
      'finalizes when the remaining unsubmitted player is offline',
      () async {
        final players = _wirePlayers();
        final reducer = ServerCommandReducer(
          mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        );

        final reduction = await reducer.reduce(
          match: _runningMatch(
            players: [
              players[0],
              players[1].copyWith(
                connectionState: WirePlayerConnectionState.offline,
              ),
            ],
          ),
          snapshot: _snapshot(_diplomacyState()),
          wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
          actorPlayerId: 'player_1',
          now: DateTime.utc(2026, 6, 30, 11, 1),
        );
        final save = GameSave.fromJson(reduction.snapshot.save);
        final state = PersistentGameState.fromJson(reduction.snapshot.state);

        expect(reduction.accepted, isTrue);
        expect(save.turn, 2);
        expect(state.runtimeState.timeoutStreaksByPlayerId, {'player_2': 1});
        expect(
          reduction.events.whereType<PlayerTimedOutEvent>().single.playerId,
          'player_2',
        );
      },
    );

    test('keeps waiting for connected players before the deadline', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: _snapshot(_diplomacyState()),
        wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 11, 1),
      );
      final save = GameSave.fromJson(reduction.snapshot.save);
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(save.turn, 1);
      expect(save.playerStates['player_1'], PlayerTurnState.finished);
      expect(state.runtimeState.submittedPlayerIds, {'player_1'});
      expect(reduction.events, isEmpty);
    });

    test('finalizes an already submitted turn after the deadline', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        turnTimeout: const Duration(seconds: 10),
      );
      final snapshot = _snapshot(
        _diplomacyState(
          runtimeState: GameRuntimeState(
            submittedPlayerIds: const {'player_1'},
            turnStartedAt: DateTime.utc(2026, 6, 30, 11),
          ),
        ),
        save: _save(
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        ),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: snapshot,
        wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 11, 0, 11),
      );
      final save = GameSave.fromJson(reduction.snapshot.save);
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(save.turn, 2);
      expect(state.runtimeState.timeoutStreaksByPlayerId, {'player_2': 1});
      expect(
        reduction.events.whereType<PlayerTimedOutEvent>().single.playerId,
        'player_2',
      );
    });

    test('does not wait for AI players in multiplayer snapshots', () async {
      final players = _wirePlayers();
      final aiPlayer = players[1].copyWith(
        kind: WirePlayerKind.ai,
        ai: const WireAiPlayer(
          strategyId: AiStrategyId.basic,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
        ),
      );
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(players: [players[0], aiPlayer]),
        snapshot: _snapshot(
          _diplomacyState(),
          save: _save(
            players: [
              _domainPlayers()[0],
              _domainPlayers()[1].copyWith(
                kind: PlayerKind.ai,
                ai: const AiPlayer(
                  strategyId: AiStrategyId.basic,
                  difficulty: AiDifficulty.normal,
                  persona: AiPersona.balanced,
                  seed: 1,
                ),
              ),
            ],
          ),
        ),
        wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 11, 1),
      );
      final save = GameSave.fromJson(reduction.snapshot.save);

      expect(reduction.accepted, isTrue);
      expect(save.turn, 2);
    });

    test('advances artifact excavation once during finalization', () async {
      final unit = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 1,
        row: 1,
      ).copyWithExcavatingArtifact('artifact_1');
      const artifact = WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.excavation(
          unitId: 'scout_1',
          col: 1,
          row: 1,
          remainingTurns: 2,
        ),
      );
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: _snapshot(
          PersistentGameState(
            units: [unit],
            artifacts: const [artifact],
            runtimeState: const GameRuntimeState(
              submittedPlayerIds: {'player_1'},
            ),
          ),
          save: _save(
            playerStates: const {
              'player_1': PlayerTurnState.finished,
              'player_2': PlayerTurnState.active,
            },
          ),
        ),
        wireCommand: _wireCommand(
          const SubmitTurnCommand('player_2'),
          actorPlayerId: 'player_2',
        ),
        actorPlayerId: 'player_2',
        now: DateTime.utc(2026, 6, 30, 11, 1),
      );
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(state.units.single.excavatingArtifactId, 'artifact_1');
      expect(state.units.single.carriedArtifactId, isNull);
      expect(state.artifacts.single.location.remainingTurns, 1);
    });
  });
}

Future<ServerCommandReduction> _reduceDiplomacyCommand({
  required PersistentGameState state,
  required DiplomaticCommand command,
  String actorPlayerId = 'player_1',
}) {
  return ServerCommandReducer(
    mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
  ).reduce(
    match: _runningMatch(),
    snapshot: _snapshot(state),
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

WireSnapshot _snapshot(PersistentGameState state, {GameSave? save}) {
  return WireSnapshot(
    matchId: 'match_1',
    offset: 0,
    save: (save ?? _save()).toJson(),
    state: state.toJson(),
  );
}

GameSave _save({
  Map<String, PlayerTurnState>? playerStates,
  List<Player>? players,
  String mapName = 'test_map',
}) {
  return GameSave(
    id: 'save_1',
    name: 'Server reducer trade',
    mapName: mapName,
    turn: 1,
    playerStates:
        playerStates ??
        const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
    savedAt: DateTime.utc(2026, 6, 30, 11),
    camera: CameraState.zero,
    players: players ?? _domainPlayers(),
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
