part of '../server_command_reducer_test.dart';

const _combatReducerDriver = ServerCommandReducerTestDriver();

void _registerServerCommandReducerCombatTests() {
  _registerServerCommandReducerCombatCommandTests();
  _registerServerCommandReducerCombatPrivacyTests();
}

void _registerServerCommandReducerCombatCommandTests() {
  group('ServerCommandReducer combat commands', () {
    test('resolves a unit attack instead of rejecting the command', () async {
      final reduction = await _combatReducerDriver.reduce(
        reducer: ServerCommandReducer(
          mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        ),
        match: _runningMatch(),
        wireSnapshot: _snapshot(
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
      final domain = reduction.nextSnapshot!.domain;

      expect(reduction.accepted, isTrue);
      expect(reduction.reason, isNull);
      expect(reduction.events.whereType<UnitAttackedEvent>(), hasLength(1));
      expect(reduction.events.whereType<CombatResolvedEvent>(), hasLength(1));
      expect(domain.units.byId('attacker')?.movementPoints, 0);
    });

    test('honors city destruction in an authoritative attack', () async {
      final reduction = await _combatReducerDriver.reduce(
        reducer: ServerCommandReducer(
          mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
        ),
        match: _runningMatch(),
        wireSnapshot: _snapshot(
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
      final domain = reduction.nextSnapshot!.domain;

      expect(reduction.accepted, isTrue);
      expect(domain.cities, isEmpty);
      expect(reduction.events.whereType<CityAttackedEvent>(), hasLength(1));
      expect(reduction.events.whereType<CityDestroyedEvent>(), hasLength(1));
    });

    test('projects the authoritative combat sequence once to every visible '
        'recipient', () async {
      final projection = await _projectAuthoritativeCombatSequence();
      _expectAuthoritativeCombatProjection(projection);
    });
  });
}

Future<
  ({ServerCommandTestReduction reduction, Map<String, WireEvent> projected})
>
_projectAuthoritativeCombatSequence() async {
  const participantIds = ['player_1', 'player_2', 'observer', 'hidden'];
  final visible = {
    const HexCoordinate(col: 0, row: 0),
    const HexCoordinate(col: 1, row: 0),
  };
  final players = [
    for (var index = 0; index < participantIds.length; index++)
      Player(
        id: participantIds[index],
        name: participantIds[index],
        colorValue: index + 1,
      ),
  ];
  final wirePlayers = [
    for (var index = 0; index < participantIds.length; index++)
      WirePlayer(
        id: participantIds[index],
        userId: 'user_$index',
        name: participantIds[index],
        colorValue: index + 1,
        country: PlayerCountry.poland,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      ),
  ];
  final state = DomainState.snapshot(
    playerColors: {
      for (var index = 0; index < participantIds.length; index++)
        participantIds[index]: index + 1,
    },
    units: [
      _combatUnit('attacker', 'player_1', 0, 0),
      _combatUnit('defender', 'player_2', 1, 0, type: GameUnitType.settler),
    ],
    fogOfWar: FogOfWarState(
      players: {
        for (final playerId in const ['player_1', 'player_2', 'observer'])
          playerId: PlayerFogOfWar(playerId: playerId, visibleHexes: visible),
        'hidden': PlayerFogOfWar(playerId: 'hidden'),
      },
    ),
  );
  final match = _runningMatch(players: wirePlayers);
  final reduction = await _combatReducerDriver.reduce(
    reducer: ServerCommandReducer(
      mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
    ),
    match: match,
    wireSnapshot: _snapshot(
      state,
      save: _save(
        players: players,
        playerStates: {
          for (final playerId in participantIds)
            playerId: PlayerTurnState.active,
        },
      ),
    ),
    wireCommand: _wireCommand(const AttackHexCommand('attacker', 1, 0)),
    actorPlayerId: 'player_1',
    now: DateTime.utc(2026, 6, 30, 12),
  );
  final next = reduction.nextSnapshot!;
  final stored = PlayerMatchEventAudience.annotateForStorage(
    events: reduction.events,
    combatAnimations: reduction.reduction.combatAnimations,
    participantPlayerIds: participantIds,
    previous: GameEventOwnershipIndex.from(
      reduction.previousSnapshot.domain.units,
      reduction.previousSnapshot.domain.cities,
    ),
    next: GameEventOwnershipIndex.from(next.domain.units, next.domain.cities),
    previousFog: reduction.previousSnapshot.domain.fogOfWar,
    nextFog: next.domain.fogOfWar,
  );
  final wire = WireEvent(
    matchId: match.id,
    offset: 1,
    timestamp: DateTime.utc(2026, 6, 30, 12),
    actorPlayerId: 'player_1',
    tick: 1,
    turn: 1,
    events: stored,
    movementExecutions: WireMovementExecutionList(const []),
  );
  const projector = PlayerMatchViewProjector();
  final projected = {
    for (var index = 0; index < participantIds.length; index++)
      participantIds[index]: projector.eventFor(
        wire,
        MatchRecipient(
          userIdentifier: 'user_$index',
          playerId: participantIds[index],
        ),
      ),
  };
  return (reduction: reduction, projected: projected);
}

void _expectAuthoritativeCombatProjection(
  ({ServerCommandTestReduction reduction, Map<String, WireEvent> projected})
  projection,
) {
  final (:reduction, :projected) = projection;
  expect(
    projected['player_1']!.events.map((event) => event['type']),
    reduction.events.map((event) => GameEventSerializer.toJson(event)['type']),
  );
  expect(projected['player_2']!.events, projected['player_1']!.events);
  expect(projected['observer']!.events, projected['player_1']!.events);
  expect(
    CombatAnimationFactCodec.fromEventPayloads(projected['observer']!.events),
    reduction.reduction.combatAnimations,
  );
  expect(projected['hidden']!.events, isEmpty);
  expect(
    projected['hidden']!.toJson().toString(),
    allOf(
      isNot(contains('attacker')),
      isNot(contains('defender')),
      isNot(contains('attackerFromCol')),
    ),
  );
}

void _registerServerCommandReducerCombatPrivacyTests() {
  group('ServerCommandReducer combat privacy', () {
    final cases = <_CombatPrivacyCase>[
      const _CombatPrivacyCase(name: 'empty cell'),
      _CombatPrivacyCase(
        name: 'hidden hostile unit',
        units: [_combatUnit('target', 'player_2', 1, 0)],
        diplomacy: _combatPrivacyDiplomacy(DiplomaticRelationStatus.hostile),
      ),
      _CombatPrivacyCase(
        name: 'hidden friendly unit',
        units: [_combatUnit('target', 'player_1', 1, 0)],
      ),
      _CombatPrivacyCase(
        name: 'hidden truce unit',
        units: [_combatUnit('target', 'player_2', 1, 0)],
        diplomacy: _combatPrivacyDiplomacy(DiplomaticRelationStatus.truce),
      ),
      _CombatPrivacyCase(
        name: 'hidden hostile city',
        cities: const [
          GameCity(
            id: 'target_city',
            ownerPlayerId: 'player_2',
            name: 'Hidden city',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        diplomacy: _combatPrivacyDiplomacy(DiplomaticRelationStatus.hostile),
      ),
    ];

    for (final privacyCase in cases) {
      test(
        'does not disclose ${privacyCase.name} through a forged attack',
        () async {
          final state = _combatPrivacyState(privacyCase);
          final snapshot = _snapshot(state);
          final reduction = await _combatReducerDriver.reduce(
            reducer: ServerCommandReducer(
              mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
            ),
            match: _runningMatch(),
            wireSnapshot: snapshot,
            wireCommand: _wireCommand(const AttackHexCommand('attacker', 1, 0)),
            actorPlayerId: 'player_1',
            now: DateTime.utc(2026, 6, 30, 12),
          );

          expect(reduction.accepted, isFalse);
          expect(reduction.reason, 'attack_target_not_visible');
          expect(reduction.nextSnapshot, isNull);
          expect(reduction.wireSnapshot, same(snapshot));
          expect(reduction.wireSnapshot.toJson(), snapshot.toJson());
          expect(reduction.events, isEmpty);
          expect(reduction.movementExecutions, isEmpty);
        },
      );
    }
  });
}

final class _CombatPrivacyCase {
  const _CombatPrivacyCase({
    required this.name,
    this.units = const [],
    this.cities = const [],
    this.diplomacy = DiplomacyState.empty,
  });

  final String name;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final DiplomacyState diplomacy;
}

DomainState _combatPrivacyState(_CombatPrivacyCase privacyCase) {
  return DomainState.snapshot(
    playerColors: const {'player_1': 0xFF3D5FA8, 'player_2': 0xFFB83A3A},
    units: [_combatUnit('attacker', 'player_1', 0, 0), ...privacyCase.units],
    cities: privacyCase.cities,
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: {const HexCoordinate(col: 0, row: 0)},
        ),
        'player_2': PlayerFogOfWar(
          playerId: 'player_2',
          visibleHexes: {
            const HexCoordinate(col: 0, row: 0),
            const HexCoordinate(col: 1, row: 0),
          },
        ),
      },
    ),
    diplomacy: privacyCase.diplomacy,
  );
}

DiplomacyState _combatPrivacyDiplomacy(DiplomaticRelationStatus status) {
  const actorPlayerId = 'player_1';
  const opponentPlayerId = 'player_2';
  final relation = DiplomaticRelation.between(
    playerAId: actorPlayerId,
    playerBId: opponentPlayerId,
    status: status,
  );
  return DiplomacyState(
    relations: {relation.key: relation},
    contactKeys: {relation.key},
  );
}
