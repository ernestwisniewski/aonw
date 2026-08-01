part of '../server_command_reducer_test.dart';

void _registerServerCommandReducerOutcomeTests() {
  group('ServerCommandReducer outcome authority', () {
    test(
      'excludes a kicked high-score domination leader from the outcome',
      () async {
        final players = [..._wirePlayers(), _outcomeWirePlayer('player_3')];
        final reduction = await _reduceOutcomeCommand(
          match: _runningMatch(players: players),
          state: _outcomeState(
            kickedPlayerIds: const {'player_3'},
            playerGold: const {'player_1': 50, 'player_3': 100000},
            dominationHoldTurnsByPlayerId: const {'player_3': 10},
            extraCities: [_dominantOutcomeCity('player_3')],
          ),
          savePlayers: [..._domainPlayers(), _outcomeDomainPlayer('player_3')],
        );

        expect(reduction.accepted, isTrue);
        expect(
          reduction.outcome,
          GameOutcome.score(
            winnerPlayerId: 'player_1',
            scoreByPlayerId: const {'player_1': 16, 'player_2': 15},
          ),
        );
        expect(reduction.outcome!.scoreByPlayerId, isNot(contains('player_3')));
      },
    );

    test(
      'excludes a phantom save and state player outside WireMatch players',
      () async {
        final reduction = await _reduceOutcomeCommand(
          match: _runningMatch(),
          state: _outcomeState(
            playerGold: const {'phantom': 100000},
            dominationHoldTurnsByPlayerId: const {'phantom': 10},
            extraCities: [_dominantOutcomeCity('phantom')],
          ),
          savePlayers: [..._domainPlayers(), _outcomeDomainPlayer('phantom')],
        );

        expect(reduction.accepted, isTrue);
        expect(
          reduction.outcome,
          GameOutcome.draw(
            scoreByPlayerId: const {'player_1': 15, 'player_2': 15},
          ),
        );
        expect(reduction.outcome!.scoreByPlayerId, isNot(contains('phantom')));
      },
    );

    test(
      'retains a WireMatch player missing from save and state in score roster',
      () async {
        final reduction = await _reduceOutcomeCommand(
          match: _runningMatch(
            players: [..._wirePlayers(), _outcomeWirePlayer('player_3')],
          ),
          state: _outcomeState(),
          savePlayers: _domainPlayers(),
        );

        expect(reduction.accepted, isTrue);
        expect(
          reduction.outcome,
          GameOutcome.draw(
            scoreByPlayerId: const {
              'player_1': 15,
              'player_2': 15,
              'player_3': 0,
            },
          ),
        );
      },
    );
  });
}

Future<ServerCommandTestReduction> _reduceOutcomeCommand({
  required WireMatch match,
  required DomainState state,
  required List<Player> savePlayers,
}) {
  const turn = GameLengthConfig.standard60TurnLimit;
  return const ServerCommandReducerTestDriver().reduce(
    reducer: ServerCommandReducer(
      mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
    ),
    match: match.copyWith(turn: turn),
    wireSnapshot: _snapshot(
      state,
      save: _save(players: savePlayers).copyWith(
        turn: turn,
        matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
      ),
    ),
    wireCommand: _wireCommand(
      const SkipUnitTurnCommand('unit_1'),
    ).copyWith(turn: turn),
    actorPlayerId: 'player_1',
    now: DateTime.utc(2026, 6, 30, 12),
  );
}

DomainState _outcomeState({
  Set<String> kickedPlayerIds = const {},
  Map<String, int> playerGold = const {},
  Map<String, int> dominationHoldTurnsByPlayerId = const {},
  List<GameCity> extraCities = const [],
}) {
  return DomainState.snapshot(
    playerGold: playerGold,
    units: [
      GameUnit(
        id: 'unit_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Unit 1',
        col: 0,
        row: 0,
      ),
      GameUnit(
        id: 'unit_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Unit 2',
        col: 1,
        row: 0,
      ),
    ],
    cities: extraCities,

    kickedPlayerIds: kickedPlayerIds,
    dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
  );
}

GameCity _dominantOutcomeCity(String playerId) {
  return GameCity(
    id: 'city_$playerId',
    ownerPlayerId: playerId,
    name: 'Dominant city',
    center: const CityHex(col: 0, row: 0),
    controlledHexes: const [
      CityHex(col: 1, row: 0),
      CityHex(col: 2, row: 0),
      CityHex(col: 0, row: 1),
      CityHex(col: 1, row: 1),
      CityHex(col: 2, row: 1),
      CityHex(col: 0, row: 2),
      CityHex(col: 1, row: 2),
      CityHex(col: 2, row: 2),
    ],
  );
}

WirePlayer _outcomeWirePlayer(String playerId) {
  return WirePlayer(
    id: playerId,
    userId: 'user_$playerId',
    name: playerId,
    colorValue: 0xFF715C36,
    country: PlayerCountry.japan,
    kind: WirePlayerKind.human,
    connectionState: WirePlayerConnectionState.connected,
  );
}

Player _outcomeDomainPlayer(String playerId) {
  return Player(
    id: playerId,
    name: playerId,
    colorValue: 0xFF715C36,
    country: PlayerCountry.japan,
  );
}
