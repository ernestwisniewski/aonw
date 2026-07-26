import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('combat command adapter parity', () {
    test('instant result matches kernel at both state boundaries', () {
      final states = _states();
      final results = _resolveAll(
        states,
        const AttackHexCommand('attacker', 1, 0),
      );

      _expectAcceptedParity(results);
      expect(
        results.persistent.state.runtimeState.submittedPlayerIds,
        states.persistent.runtimeState.submittedPlayerIds,
      );
      expect(
        results.persistent.state.runtimeState.turnStartedAt,
        states.persistent.runtimeState.turnStartedAt,
      );
      expect(
        results.domain.state.playerWarWeariness,
        same(states.domain.playerWarWeariness),
      );
      expect(
        results.domain.state.mapObjectiveHoldStatesByObjectiveId,
        same(states.domain.mapObjectiveHoldStatesByObjectiveId),
      );
    });

    test('rejection preserves complete state and kernel slice identities', () {
      final states = _states();
      final results = _resolveAll(
        states,
        const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_2',
      );

      expect(results.kernel.reason, 'attacker_not_controlled');
      expect(results.persistent.reason, 'attacker_not_controlled');
      expect(results.domain.reason, 'attacker_not_controlled');
      expect(results.persistent.state, same(states.persistent));
      expect(results.domain.state, same(states.domain));
      expect(results.kernel.units, same(states.domain.units));
      expect(results.kernel.cities, same(states.domain.cities));
      expect(results.kernel.artifacts, same(states.domain.artifacts));
      expect(results.kernel.fogOfWar, same(states.domain.fogOfWar));
      expect(
        results.kernel.intendedAttacks,
        same(states.domain.intendedAttacks),
      );
      expect(results.kernel.diplomacy, same(states.domain.diplomacy));
      expect(
        results.kernel.resourceTradeAgreements,
        same(states.domain.resourceTradeAgreements),
      );
    });

    test('both adapters preserve city-center self-occupancy semantics', () {
      final states = _states(attackerOnEnemyCityCenter: true);
      final results = _resolveAll(
        states,
        const AttackHexCommand('attacker', 1, 0),
      );

      _expectAcceptedParity(results);
      expect(
        results.kernel.events.whereType<CityAttackedEvent>(),
        hasLength(1),
      );
      expect(
        results.persistent.events.whereType<CityAttackedEvent>(),
        hasLength(1),
      );
      expect(
        results.domain.events.whereType<CityAttackedEvent>(),
        hasLength(1),
      );
      expect(results.persistent.state.cities.single.ownerPlayerId, 'player_1');
      expect(results.domain.state.cities.single.ownerPlayerId, 'player_1');
    });
  });
}

typedef _CombatStates = ({PersistentGameState persistent, DomainState domain});

typedef _CombatResults = ({
  CombatCommandResult kernel,
  PersistentCombatCommandResult persistent,
  DomainCombatCommandResult domain,
});

_CombatStates _states({bool attackerOnEnemyCityCenter = false}) {
  final units = attackerOnEnemyCityCenter
      ? [_unit('attacker', 'player_1', 1)]
      : [
          _unit('attacker', 'player_1', 0),
          _unit('defender', 'player_2', 1, type: GameUnitType.settler),
        ];
  final cities = attackerOnEnemyCityCenter
      ? const [
          GameCity(
            id: 'city',
            ownerPlayerId: 'player_2',
            name: 'City',
            center: CityHex(col: 1, row: 0),
            hitPoints: 1,
          ),
        ]
      : const <GameCity>[];
  const artifacts = [
    WorldArtifact(
      id: 'sentinel_artifact',
      type: WorldArtifactType.astronomersTablets,
      location: WorldArtifactLocation.map(col: 2, row: 0),
    ),
  ];
  const attacks = [
    IntendedAttack(
      attackerUnitId: 'prior',
      defenderCol: 2,
      defenderRow: 0,
      declaredAtTick: 1,
      declaringPlayerId: 'player_1',
    ),
  ];
  final fog = _visibleFog();
  final runtime = GameRuntimeState.snapshot(
    submittedPlayerIds: const {'player_2'},
    timeoutStreaksByPlayerId: const {'player_2': 2},
    intendedAttacks: attacks,
    diplomacy: DiplomacyState.empty,
    dominationHoldTurnsByPlayerId: const {'player_2': 3},
    culturalVictoryHoldTurnsByPlayerId: const {'player_2': 4},
    mapObjectiveHoldStatesByObjectiveId: const {
      'sentinel': MapObjectiveHoldState(
        objectiveId: 'sentinel',
        playerId: 'player_2',
        holdTurns: 2,
      ),
    },
    turnStartedAt: DateTime.utc(2026, 7, 20),
  );
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {'player_1': 1, 'player_2': 2},
      playerCountries: const {
        'player_1': PlayerCountry.poland,
        'player_2': PlayerCountry.japan,
      },
      playerGold: const {'player_1': 10, 'player_2': 20},
      playerWarWeariness: const {'player_2': 3},
      playerStabilityNet: const {'player_2': 4},
      units: units,
      cities: cities,
      artifacts: artifacts,
      fogOfWar: fog,
      runtimeState: runtime,
    ),
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: 'player_1', name: 'One', colorValue: 1),
        Player(
          id: 'player_2',
          name: 'Two',
          colorValue: 2,
          country: PlayerCountry.japan,
        ),
      ],
      playerGold: const {'player_1': 10, 'player_2': 20},
      playerWarWeariness: const {'player_2': 3},
      playerStabilityNet: const {'player_2': 4},
      units: units,
      cities: cities,
      artifacts: artifacts,
      fogOfWar: fog,
      intendedAttacks: attacks,
      dominationHoldTurnsByPlayerId: const {'player_2': 3},
      culturalVictoryHoldTurnsByPlayerId: const {'player_2': 4},
      mapObjectiveHoldStatesByObjectiveId: const {
        'sentinel': MapObjectiveHoldState(
          objectiveId: 'sentinel',
          playerId: 'player_2',
          holdTurns: 2,
        ),
      },
    ),
  );
}

_CombatResults _resolveAll(
  _CombatStates states,
  AttackHexCommand command, {
  String actorPlayerId = 'player_1',
}) {
  final domain = states.domain;
  final map = _map();
  return (
    kernel: const CombatCommandResolver().resolve(
      state: CombatCommandState(
        units: domain.units,
        cities: domain.cities,
        artifacts: domain.artifacts,
        fogOfWar: domain.fogOfWar,
        research: domain.research,
        intendedAttacks: domain.intendedAttacks,
        diplomacy: domain.diplomacy,
        resourceTradeAgreements: domain.resourceTradeAgreements,
        playerIds: domain.participants.map((player) => player.id),
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      turn: domain.turn,
      commandTick: 13,
      mapTiles: map,
    ),
    persistent: const PersistentCombatCommandResolver().resolve(
      state: states.persistent,
      command: command,
      actorPlayerId: actorPlayerId,
      turn: domain.turn,
      commandTick: 13,
      mapTiles: map,
    ),
    domain: const DomainCombatCommandResolver().resolve(
      state: domain,
      command: command,
      actorPlayerId: actorPlayerId,
      commandTick: 13,
      mapTiles: map,
    ),
  );
}

void _expectAcceptedParity(_CombatResults results) {
  expect(results.kernel.accepted, isTrue);
  expect(results.persistent.accepted, isTrue);
  expect(results.domain.accepted, isTrue);
  expect(results.kernel.reason, isNull);
  expect(results.persistent.reason, isNull);
  expect(results.domain.reason, isNull);
  expect(results.persistent.state.units, results.kernel.units);
  expect(results.domain.state.units, results.kernel.units);
  expect(results.persistent.state.cities, results.kernel.cities);
  expect(results.domain.state.cities, results.kernel.cities);
  expect(results.persistent.state.artifacts, results.kernel.artifacts);
  expect(results.domain.state.artifacts, results.kernel.artifacts);
  expect(results.persistent.state.fogOfWar, results.kernel.fogOfWar);
  expect(results.domain.state.fogOfWar, results.kernel.fogOfWar);
  expect(
    results.persistent.state.runtimeState.intendedAttacks,
    results.kernel.intendedAttacks,
  );
  expect(results.domain.state.intendedAttacks, results.kernel.intendedAttacks);
  expect(
    results.persistent.state.runtimeState.diplomacy,
    results.kernel.diplomacy,
  );
  expect(results.domain.state.diplomacy, results.kernel.diplomacy);
  expect(
    results.persistent.events.map(GameEventSerializer.toJson),
    results.kernel.events.map(GameEventSerializer.toJson),
  );
  expect(
    results.domain.events.map(GameEventSerializer.toJson),
    results.kernel.events.map(GameEventSerializer.toJson),
  );
}

GameUnit _unit(
  String id,
  String ownerPlayerId,
  int col, {
  GameUnitType type = GameUnitType.warrior,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: 0,
  );
}

FogOfWarState _visibleFog() {
  final visible = {
    const HexCoordinate(col: 0, row: 0),
    const HexCoordinate(col: 1, row: 0),
    const HexCoordinate(col: 2, row: 0),
  };
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(playerId: 'player_1', visibleHexes: visible),
      'player_2': PlayerFogOfWar(playerId: 'player_2', visibleHexes: visible),
    },
  );
}

MapTileLookup _map() {
  return WorldMapReadView(
    WorldMap(
      cols: 3,
      rows: 1,
      tiles: [
        for (var col = 0; col < 3; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: 0),
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
      ],
    ),
  );
}
