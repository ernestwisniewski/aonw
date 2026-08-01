import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _actorId = 'player_1';
const _opponentId = 'player_2';

void main() {
  group('combat engine goldens', () {
    test('unit combat preserves exact event order and animation facts', () {
      final snapshot = _snapshot(
        units: [
          GameUnit(
            id: 'attacker',
            ownerPlayerId: _actorId,
            type: GameUnitType.warrior,
            name: 'Attacker',
            col: 0,
            row: 0,
          ),
          GameUnit(
            id: 'defender',
            ownerPlayerId: _opponentId,
            type: GameUnitType.warrior,
            name: 'Defender',
            col: 1,
            row: 0,
          ),
        ],
      );

      final accepted = _expectAccepted(
        _apply(snapshot, const AttackHexCommand('attacker', 1, 0)),
      );

      expect(accepted.events.map((event) => event.runtimeType), [
        UnitAttackedEvent,
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        UnitGainedExperienceEvent,
      ]);
      expect(accepted.combatAnimations, [
        const CombatAnimationFact(
          eventIndex: 1,
          attackerUnitId: 'attacker',
          defenderId: 'defender',
          attackerFromCol: 0,
          attackerFromRow: 0,
          attackerToCol: 1,
          attackerToRow: 0,
        ),
      ]);
      expect(() => accepted.combatAnimations.clear(), throwsUnsupportedError);
    });

    test('city combat identifies the city target without UI types', () {
      final snapshot = _snapshot(
        units: [
          GameUnit(
            id: 'attacker',
            ownerPlayerId: _actorId,
            type: GameUnitType.warrior,
            name: 'Attacker',
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'target_city',
            ownerPlayerId: _opponentId,
            name: 'Target',
            center: CityHex(col: 1, row: 0),
          ),
        ],
      );

      final accepted = _expectAccepted(
        _apply(snapshot, const AttackHexCommand('attacker', 1, 0)),
      );

      expect(accepted.events.take(2).map((event) => event.runtimeType), [
        CityAttackedEvent,
        CombatResolvedEvent,
      ]);
      expect(
        accepted.combatAnimations.single,
        const CombatAnimationFact(
          eventIndex: 1,
          attackerUnitId: 'attacker',
          defenderId: 'target_city',
          attackerFromCol: 0,
          attackerFromRow: 0,
          attackerToCol: 1,
          attackerToRow: 0,
        ),
      );
    });

    test('lethal city combat preserves conquest and exact event order', () {
      final snapshot = _snapshot(
        units: [
          GameUnit(
            id: 'attacker',
            ownerPlayerId: _actorId,
            type: GameUnitType.warrior,
            name: 'Attacker',
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'target_city',
            ownerPlayerId: _opponentId,
            name: 'Target',
            center: CityHex(col: 1, row: 0),
            hitPoints: 1,
          ),
        ],
      );
      final ruleset = GameRuleset.defaults.copyWith(
        combat: GameRuleset.defaults.combat.copyWith(
          varianceRange: 0,
          cityBaseStats: const CombatStats(
            attack: 0,
            defense: 0,
            hp: 1,
            range: 1,
            mobility: 0,
          ),
          unitBaseStats: const {
            GameUnitType.warrior: CombatStats(
              attack: 20,
              defense: 10,
              hp: 10,
              range: 1,
              mobility: 1,
            ),
          },
        ),
      );

      final accepted = _expectAccepted(
        _apply(
          snapshot,
          const AttackHexCommand(
            'attacker',
            1,
            0,
            cityConquestAction: CityConquestAction.capture,
          ),
          ruleset: ruleset,
        ),
      );

      expect(accepted.events.map((event) => event.runtimeType), [
        CityAttackedEvent,
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        CityCapturedEvent,
      ]);
      expect(accepted.snapshot.domain.cities.single.ownerPlayerId, _actorId);
    });

    test('rejection retains snapshot identity and exposes no animation', () {
      final snapshot = _snapshot(
        units: [
          GameUnit(
            id: 'attacker',
            ownerPlayerId: _actorId,
            type: GameUnitType.warrior,
            name: 'Attacker',
            col: 0,
            row: 0,
          ),
        ],
      );

      final result = _apply(snapshot, const AttackHexCommand('attacker', 1, 0));

      expect(result, isA<GameEngineRejected>());
      final rejected = result as GameEngineRejected;
      expect(rejected.snapshot, same(snapshot));
      expect(rejected.reason, 'attack_target_not_found');
      expect(rejected.events, isEmpty);
      expect(rejected.combatAnimations, isEmpty);
    });

    test('combat visibility policy is explicit at the engine boundary', () {
      final snapshot = _snapshot(
        units: [
          GameUnit(
            id: 'attacker',
            ownerPlayerId: _actorId,
            type: GameUnitType.warrior,
            name: 'Attacker',
            col: 0,
            row: 0,
          ),
          GameUnit(
            id: 'defender',
            ownerPlayerId: _opponentId,
            type: GameUnitType.warrior,
            name: 'Defender',
            col: 1,
            row: 0,
          ),
        ],
        fogOfWar: FogOfWarState(
          players: {
            _actorId: PlayerFogOfWar(
              playerId: _actorId,
              discoveredHexes: {const HexCoordinate(col: 0, row: 0)},
              visibleHexes: {const HexCoordinate(col: 0, row: 0)},
            ),
          },
        ),
      );

      final authoritative = _apply(
        snapshot,
        const AttackHexCommand('attacker', 1, 0),
      );
      final unrestricted = _apply(
        snapshot,
        const AttackHexCommand('attacker', 1, 0),
        combatVisibilityMode: CombatCommandVisibilityMode.unrestricted,
      );

      expect(authoritative, isA<GameEngineRejected>());
      expect(
        (authoritative as GameEngineRejected).reason,
        'attack_target_not_visible',
      );
      expect(unrestricted, isA<GameEngineAccepted>());
    });

    test(
      'seed comes from canonical turn and tick records simultaneous intent',
      () {
        final instantSnapshot = _snapshot(
          units: [
            GameUnit(
              id: 'attacker',
              ownerPlayerId: _actorId,
              type: GameUnitType.warrior,
              name: 'Attacker',
              col: 0,
              row: 0,
            ),
            GameUnit(
              id: 'defender',
              ownerPlayerId: _opponentId,
              type: GameUnitType.warrior,
              name: 'Defender',
              col: 1,
              row: 0,
            ),
          ],
        );

        final instant = _expectAccepted(
          _apply(instantSnapshot, const AttackHexCommand('attacker', 1, 0)),
        );
        final outcome = instant.events
            .whereType<CombatResolvedEvent>()
            .single
            .outcome;
        expect(outcome.steps.whereType<RollStep>().map((step) => step.seed), [
          2280806018,
          2280806018,
        ]);
        expect(outcome.steps.whereType<RollStep>().map((step) => step.value), [
          0,
          1,
        ]);

        final simultaneousRules = GameRuleset.defaults.copyWith(
          combat: GameRuleset.defaults.combat.copyWith(
            resolutionMode: CombatResolutionMode.simultaneous,
          ),
        );
        final simultaneous = _expectAccepted(
          _apply(
            instantSnapshot,
            const AttackHexCommand('attacker', 1, 0),
            ruleset: simultaneousRules,
            commandTick: 71,
          ),
        );
        expect(simultaneous.events, isEmpty);
        expect(simultaneous.combatAnimations, isEmpty);
        expect(
          simultaneous.snapshot.domain.intendedAttacks.single.declaredAtTick,
          71,
        );
        expect(simultaneous.snapshot.domain.turn, 7);
      },
    );
  });
}

GameEngineResult _apply(
  CanonicalGameSnapshot snapshot,
  AttackHexCommand command, {
  GameRuleset? ruleset,
  int commandTick = 13,
  CombatCommandVisibilityMode combatVisibilityMode =
      CombatCommandVisibilityMode.authoritative,
}) {
  return const GameEngine().apply(
    snapshot: snapshot,
    command: command,
    context: GameEngineContext(
      actorPlayerId: _actorId,
      mapView: _map,
      ruleset: ruleset ?? GameRuleset.defaults,
      commandTick: commandTick,
      combatVisibilityMode: combatVisibilityMode,
    ),
  );
}

GameEngineAccepted _expectAccepted(GameEngineResult result) {
  expect(result, isA<GameEngineAccepted>());
  return result as GameEngineAccepted;
}

CanonicalGameSnapshot _snapshot({
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  FogOfWarState? fogOfWar,
}) {
  return CanonicalGameSnapshot.snapshot(
    domain: (DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: _actorId, name: 'One', colorValue: 1),
        Player(id: _opponentId, name: 'Two', colorValue: 2),
      ],
      units: units,
      cities: cities,
      fogOfWar: fogOfWar ?? _visibleFog,
    )).copyWith(gameMode: GameMode.multiplayer),

    metadata: GameSnapshotMetadata(
      id: 'combat',
      schemaVersion: 3,
      name: 'Combat',
      world: const WorldReference(name: 'combat', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),
  );
}

final _visibleHexes = {
  const HexCoordinate(col: 0, row: 0),
  const HexCoordinate(col: 1, row: 0),
  const HexCoordinate(col: 2, row: 0),
};

final _visibleFog = FogOfWarState(
  players: {
    _actorId: PlayerFogOfWar(
      playerId: _actorId,
      discoveredHexes: _visibleHexes,
      visibleHexes: _visibleHexes,
    ),
    _opponentId: PlayerFogOfWar(
      playerId: _opponentId,
      discoveredHexes: _visibleHexes,
      visibleHexes: _visibleHexes,
    ),
  },
);

final _map = WorldMap(
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
