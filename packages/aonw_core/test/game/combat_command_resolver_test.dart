import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CombatCommandResolver', () {
    test('post-counter zero rejects atomically before turn combat', () {
      final state = _state(
        units: [
          _unit('attacker', 'player_1', 0, type: GameUnitType.cavalry),
          _unit('defender', 'player_2', 1, type: GameUnitType.archer),
        ],
      );
      final result = const CombatCommandResolver().resolve(
        state: state,
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        turn: 7,
        commandTick: 13,
        mapTiles: _map(targetTerrains: const [TerrainType.forest]),
        ruleset: GameRuleset.defaults.copyWith(
          combat: CombatRuleset.standard.copyWith(
            varianceRange: 0,
            unitBaseStats: const {
              GameUnitType.cavalry: CombatStats(
                attack: 2,
                defense: 3,
                hp: 10,
                range: 1,
                mobility: 2,
              ),
            },
          ),
        ),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'attacker_cannot_attack');
      _expectRejectedSliceIdentity(state, result);
    });

    test('simultaneous mode replaces only the same attacker intent', () {
      const superseded = IntendedAttack(
        attackerUnitId: 'attacker',
        defenderCol: 2,
        defenderRow: 0,
        declaredAtTick: 2,
        declaringPlayerId: 'player_1',
      );
      const unrelated = IntendedAttack(
        attackerUnitId: 'other_attacker',
        defenderCol: 7,
        defenderRow: 7,
        declaredAtTick: 3,
        declaringPlayerId: 'player_2',
      );
      final state = _state(
        units: [
          _unit('attacker', 'player_1', 0),
          _unit('defender', 'player_2', 1, type: GameUnitType.settler),
        ],
        intendedAttacks: const [superseded, unrelated],
      );
      final result = const CombatCommandResolver().resolve(
        state: state,
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        turn: 7,
        commandTick: 13,
        mapTiles: _map(),
        ruleset: GameRuleset.defaults.copyWith(
          combat: CombatRuleset.standard.copyWith(
            resolutionMode: CombatResolutionMode.simultaneous,
          ),
        ),
      );

      expect(result.accepted, isTrue);
      expect(result.events, isEmpty);
      expect(result.units, same(state.units));
      expect(result.cities, same(state.cities));
      expect(result.artifacts, same(state.artifacts));
      expect(result.fogOfWar, same(state.fogOfWar));
      expect(result.diplomacy, same(state.diplomacy));
      expect(
        result.resourceTradeAgreements,
        same(state.resourceTradeAgreements),
      );
      expect(result.intendedAttacks, const [
        unrelated,
        IntendedAttack(
          attackerUnitId: 'attacker',
          defenderCol: 1,
          defenderRow: 0,
          declaredAtTick: 13,
          declaringPlayerId: 'player_1',
        ),
      ]);
      expect(
        () => result.intendedAttacks.add(unrelated),
        throwsUnsupportedError,
      );
    });

    test('instant combat uses turn-kernel opponent counter context', () {
      final state = _state(
        units: [
          _unit('attacker', 'player_1', 0, type: GameUnitType.cavalry),
          _unit('defender', 'player_2', 1, type: GameUnitType.archer),
        ],
        intendedAttacks: const [
          IntendedAttack(
            attackerUnitId: 'prior',
            defenderCol: 2,
            defenderRow: 0,
            declaredAtTick: 1,
            declaringPlayerId: 'player_1',
          ),
        ],
      );
      final result = const CombatCommandResolver().resolve(
        state: state,
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        turn: 7,
        commandTick: 13,
        mapTiles: _map(targetTerrains: const [TerrainType.forest]),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.intendedAttacks, same(state.intendedAttacks));
      final outcome = result.events
          .whereType<CombatResolvedEvent>()
          .single
          .outcome;
      expect(
        {
          for (final step in outcome.steps.whereType<ModifierAppliedStep>())
            if (step.modifier is CounterModifier) step.modifier.label,
        },
        {
          'counter.cavalryRoughAttack.attack',
          'counter.archerDefensiveTerrain.defense',
        },
      );
      expect(result.events.whereType<CombatResolvedEvent>(), hasLength(1));
      expect(
        () => result.units.add(_unit('forged', 'player_1', 2)),
        throwsUnsupportedError,
      );
      expect(
        () => result.events.add(
          const UnitKilledEvent(unitId: 'forged', ownerPlayerId: 'player_1'),
        ),
        throwsUnsupportedError,
      );
    });

    test('attacker on enemy city center attacks the city, not itself', () {
      final state = _state(
        units: [_unit('attacker', 'player_1', 1)],
        cities: const [
          GameCity(
            id: 'city',
            ownerPlayerId: 'player_2',
            name: 'City',
            center: CityHex(col: 1, row: 0),
            hitPoints: 1,
          ),
        ],
      );
      final result = const CombatCommandResolver().resolve(
        state: state,
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        turn: 7,
        commandTick: 13,
        mapTiles: _map(),
      );

      expect(result.accepted, isTrue);
      expect(result.events.whereType<CityAttackedEvent>(), hasLength(1));
      expect(result.events.whereType<UnitAttackedEvent>(), isEmpty);
      expect(result.cities.single.ownerPlayerId, 'player_1');
    });

    test('another unit on attacker tile wins over the city target', () {
      final state = _state(
        units: [
          _unit('attacker', 'player_1', 1),
          _unit('defender', 'player_2', 1, type: GameUnitType.settler),
        ],
        cities: const [
          GameCity(
            id: 'city',
            ownerPlayerId: 'player_2',
            name: 'City',
            center: CityHex(col: 1, row: 0),
          ),
        ],
      );
      final result = const CombatCommandResolver().resolve(
        state: state,
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        turn: 7,
        commandTick: 13,
        mapTiles: _map(),
      );

      expect(result.accepted, isTrue);
      expect(result.events.whereType<UnitAttackedEvent>(), hasLength(1));
      expect(result.events.whereType<CityAttackedEvent>(), isEmpty);
      expect(result.cities.single.ownerPlayerId, 'player_2');
    });

    test('ignoreFogOfWar bypasses only the visibility guard', () {
      final state = _state(
        units: [
          _unit('attacker', 'player_1', 0),
          _unit('defender', 'player_2', 1, type: GameUnitType.settler),
        ],
        fogOfWar: FogOfWarState.empty,
      );
      final hidden = const CombatCommandResolver().resolve(
        state: state,
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        turn: 7,
        commandTick: 13,
        mapTiles: _map(),
      );
      final ignored = const CombatCommandResolver().resolve(
        state: state,
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        turn: 7,
        commandTick: 13,
        mapTiles: _map(),
        ignoreFogOfWar: true,
      );

      expect(hidden.reason, 'attack_target_not_visible');
      expect(ignored.accepted, isTrue);
    });

    test('city health guard includes stored artifact combat stats', () {
      final state = _state(
        units: [_unit('attacker', 'player_1', 0)],
        cities: const [
          GameCity(
            id: 'city',
            ownerPlayerId: 'player_2',
            name: 'City',
            center: CityHex(col: 1, row: 0),
            hitPoints: 1,
          ),
        ],
        artifacts: const [
          WorldArtifact(
            id: 'crown',
            type: WorldArtifactType.ancientImperialCrown,
            location: WorldArtifactLocation.stored(cityId: 'city'),
          ),
        ],
      );
      final result = const CombatCommandResolver().resolve(
        state: state,
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        turn: 7,
        commandTick: 13,
        mapTiles: _map(),
        ruleset: GameRuleset.defaults.copyWith(
          combat: CombatRuleset.standard.copyWith(
            cityBaseStats: const CombatStats(),
          ),
        ),
      );

      expect(result.accepted, isTrue);
      expect(result.events.whereType<CombatResolvedEvent>(), hasLength(1));
    });
  });
}

void _expectRejectedSliceIdentity(
  CombatCommandState state,
  CombatCommandResult result,
) {
  expect(result.units, same(state.units));
  expect(result.cities, same(state.cities));
  expect(result.artifacts, same(state.artifacts));
  expect(result.fogOfWar, same(state.fogOfWar));
  expect(result.intendedAttacks, same(state.intendedAttacks));
  expect(result.diplomacy, same(state.diplomacy));
  expect(result.resourceTradeAgreements, same(state.resourceTradeAgreements));
  expect(result.events, isEmpty);
}

CombatCommandState _state({
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  List<WorldArtifact> artifacts = const [],
  FogOfWarState? fogOfWar,
  ResearchState research = ResearchState.empty,
  List<IntendedAttack> intendedAttacks = const [],
  DiplomacyState diplomacy = DiplomacyState.empty,
  List<ResourceTradeAgreement> resourceTradeAgreements = const [],
}) {
  return CombatCommandState(
    units: units,
    cities: cities,
    artifacts: artifacts,
    fogOfWar: fogOfWar ?? _visibleFog(),
    research: research,
    intendedAttacks: intendedAttacks,
    diplomacy: diplomacy,
    resourceTradeAgreements: resourceTradeAgreements,
    playerIds: const {'player_1', 'player_2'},
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

MapTileLookup _map({
  List<TerrainType> targetTerrains = const [TerrainType.grassland],
}) {
  return WorldMapReadView(
    WorldMap(
      cols: 3,
      rows: 1,
      tiles: [
        for (var col = 0; col < 3; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: 0),
            terrains: col == 1 ? targetTerrains : const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
      ],
    ),
  );
}
