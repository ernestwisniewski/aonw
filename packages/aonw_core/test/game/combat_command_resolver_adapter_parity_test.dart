import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('combat command adapter parity', () {
    test('instant result matches kernel at both canonical boundaries', () {
      final domain = _domain();
      final results = _resolveAll(
        domain,
        const AttackHexCommand('attacker', 1, 0),
      );

      _expectAcceptedParity(results);
      expect(results.engine.snapshot.domain.submittedPlayerIds, const {
        'player_2',
      });
      expect(
        results.engine.snapshot.domain.turnStartedAt,
        DateTime.utc(2026, 7, 20),
      );
      expect(
        results.domain.state.playerWarWeariness,
        same(domain.playerWarWeariness),
      );
      expect(
        results.domain.state.mapObjectiveHoldStatesByObjectiveId,
        same(domain.mapObjectiveHoldStatesByObjectiveId),
      );
    });

    test('rejection preserves complete state and kernel slice identities', () {
      final domain = _domain();
      final results = _resolveAll(
        domain,
        const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_2',
      );

      expect(results.kernel.reason, 'attacker_not_controlled');
      expect(
        (results.engine as GameEngineRejected).reason,
        'attacker_not_controlled',
      );
      expect(results.domain.reason, 'attacker_not_controlled');
      expect(results.engine.snapshot, same(results.engineInput));
      expect(results.domain.state, same(domain));
      expect(results.kernel.units, same(domain.units));
      expect(results.kernel.cities, same(domain.cities));
      expect(results.kernel.artifacts, same(domain.artifacts));
      expect(results.kernel.fogOfWar, same(domain.fogOfWar));
      expect(results.kernel.intendedAttacks, same(domain.intendedAttacks));
      expect(results.kernel.diplomacy, same(domain.diplomacy));
      expect(
        results.kernel.resourceTradeAgreements,
        same(domain.resourceTradeAgreements),
      );
    });

    test('both adapters preserve city-center self-occupancy semantics', () {
      final domain = _domain(attackerOnEnemyCityCenter: true);
      final results = _resolveAll(
        domain,
        const AttackHexCommand('attacker', 1, 0),
      );

      _expectAcceptedParity(results);
      expect(
        results.kernel.events.whereType<CityAttackedEvent>(),
        hasLength(1),
      );
      expect(
        results.engine.events.whereType<CityAttackedEvent>(),
        hasLength(1),
      );
      expect(
        results.domain.events.whereType<CityAttackedEvent>(),
        hasLength(1),
      );
      expect(
        results.engine.snapshot.domain.cities.single.ownerPlayerId,
        'player_1',
      );
      expect(results.domain.state.cities.single.ownerPlayerId, 'player_1');
    });
  });
}

typedef _CombatResults = ({
  CombatCommandResult kernel,
  CanonicalGameSnapshot engineInput,
  GameEngineResult engine,
  DomainCombatCommandResult domain,
});

DomainState _domain({bool attackerOnEnemyCityCenter = false}) {
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
  return DomainState.snapshot(
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
  );
}

_CombatResults _resolveAll(
  DomainState domain,
  AttackHexCommand command, {
  String actorPlayerId = 'player_1',
}) {
  final map = _map();
  final engineInput = _snapshot(domain);
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
    engineInput: engineInput,
    engine: const GameEngine().apply(
      snapshot: engineInput,
      command: command,
      context: GameEngineContext(
        actorPlayerId: actorPlayerId,
        commandTick: 13,
        mapView: map,
        ruleset: GameRuleset.defaults,
      ),
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
  expect(results.engine, isA<GameEngineAccepted>());
  expect(results.domain.accepted, isTrue);
  expect(results.kernel.reason, isNull);
  expect(results.domain.reason, isNull);
  expect(results.engine.snapshot.domain.units, results.kernel.units);
  expect(results.domain.state.units, results.kernel.units);
  expect(results.engine.snapshot.domain.cities, results.kernel.cities);
  expect(results.domain.state.cities, results.kernel.cities);
  expect(results.engine.snapshot.domain.artifacts, results.kernel.artifacts);
  expect(results.domain.state.artifacts, results.kernel.artifacts);
  expect(results.engine.snapshot.domain.fogOfWar, results.kernel.fogOfWar);
  expect(results.domain.state.fogOfWar, results.kernel.fogOfWar);
  expect(
    results.engine.snapshot.domain.intendedAttacks,
    results.kernel.intendedAttacks,
  );
  expect(results.domain.state.intendedAttacks, results.kernel.intendedAttacks);
  expect(results.engine.snapshot.domain.diplomacy, results.kernel.diplomacy);
  expect(results.domain.state.diplomacy, results.kernel.diplomacy);
  expect(
    results.engine.events.map(GameEventSerializer.toJson),
    results.kernel.events.map(GameEventSerializer.toJson),
  );
  expect(
    results.domain.events.map(GameEventSerializer.toJson),
    results.kernel.events.map(GameEventSerializer.toJson),
  );
}

CanonicalGameSnapshot _snapshot(DomainState domain) {
  return CanonicalGameSnapshot.snapshot(
    domain: (domain).copyWith(
      gameMode: GameMode.hotSeat,
      submittedPlayerIds: const {'player_2'},
      timeoutStreaksByPlayerId: const {'player_2': 2},
      turnStartedAt: DateTime.utc(2026, 7, 20),
    ),

    metadata: GameSnapshotMetadata(
      id: 'combat-parity',
      schemaVersion: 3,
      name: 'Combat parity',
      world: const WorldReference(name: 'combat', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 20),
      camera: GameSnapshotCamera.zero,
    ),
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

MapReadView _map() {
  return WorldMap(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        WorldTile.at(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
