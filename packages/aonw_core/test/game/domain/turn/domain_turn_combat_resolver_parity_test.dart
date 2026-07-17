import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:test/test.dart';

void main() {
  group('DomainTurnCombatResolver parity', () {
    test('matches active unit combat', () {
      final result = _resolveBoth(_unitCombatState());

      expect(result.domain.events.map((event) => event.runtimeType), [
        UnitAttackedEvent,
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        UnitKilledEvent,
      ]);
      expect(result.domain.state.units, hasLength(1));
      expect(result.domain.state.artifacts.single.location.isOnMap, isTrue);
    });

    test('matches active city combat', () {
      final result = _resolveBoth(_cityCombatState());

      expect(result.domain.events.map((event) => event.runtimeType), [
        CityAttackedEvent,
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
      ]);
      expect(result.domain.state.cities.single.hitPoints, 8);
      expect(result.domain.state.resourceTradeAgreements, isEmpty);
    });

    test('short-circuits city lookup when the attacker tile is missing', () {
      final input = _adapter
          .toCanonical(save: _save(), state: _cityCombatState())
          .domain;
      final lookup = _MissingAttackerTileLookup();

      final result = DomainTurnCombatResolver.resolve(
        state: input,
        mapTiles: lookup,
        ruleset: _ruleset,
      );

      expect(result.state, input);
      expect(result.events, isEmpty);
      expect(lookup.calls, 1);
    });
  });
}

({DomainTurnCombatResult domain, PersistentTurnCombatResult persistent})
_resolveBoth(PersistentGameState persistentInput) {
  final domainInput = _adapter
      .toCanonical(save: _save(), state: persistentInput)
      .domain;
  final persistent = PersistentTurnCombatResolver.resolve(
    turn: _turn,
    state: persistentInput,
    mapTiles: _mapTiles,
    ruleset: _ruleset,
  );
  final domain = DomainTurnCombatResolver.resolve(
    state: domainInput,
    mapTiles: _mapTiles,
    ruleset: _ruleset,
  );

  expect(
    domain.state,
    domainInput.copyWith(
      units: persistent.state.units,
      cities: persistent.state.cities,
      artifacts: persistent.state.artifacts,
      diplomacy: persistent.state.runtimeState.diplomacy,
      resourceTradeAgreements:
          persistent.state.runtimeState.resourceTradeAgreements,
    ),
  );
  expect(domain.state.units, persistent.state.units);
  expect(domain.state.cities, persistent.state.cities);
  expect(domain.state.artifacts, persistent.state.artifacts);
  expect(domain.state.diplomacy, persistent.state.runtimeState.diplomacy);
  expect(
    domain.state.resourceTradeAgreements,
    persistent.state.runtimeState.resourceTradeAgreements,
  );
  expect(_eventJson(domain.events), _eventJson(persistent.events));

  return (domain: domain, persistent: persistent);
}

PersistentGameState _unitCombatState() {
  return PersistentGameState(
    units: [
      _unit('warrior_p1', 'p1', GameUnitType.warrior, 0, 0),
      _unit(
        'settler_p2',
        'p2',
        GameUnitType.settler,
        1,
        0,
        carriedArtifactId: 'artifact_1',
      ),
    ],
    cities: const [
      GameCity(
        id: 'city_p2',
        ownerPlayerId: 'p2',
        name: 'City two',
        center: CityHex(col: 1, row: 0),
      ),
    ],
    artifacts: const [
      WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.carried(unitId: 'settler_p2'),
      ),
    ],
    runtimeState: const GameRuntimeState(
      intendedAttacks: [
        IntendedAttack(
          attackerUnitId: 'warrior_p1',
          defenderCol: 1,
          defenderRow: 0,
          declaredAtTick: 3,
          declaringPlayerId: 'p1',
        ),
      ],
      resourceTradeAgreements: [_tradeAgreement],
    ),
  );
}

PersistentGameState _cityCombatState() {
  return PersistentGameState(
    units: [_unit('warrior_p1', 'p1', GameUnitType.warrior, 0, 0)],
    cities: const [
      GameCity(
        id: 'city_p2',
        ownerPlayerId: 'p2',
        name: 'City two',
        center: CityHex(col: 1, row: 0),
        hitPoints: 10,
      ),
    ],
    artifacts: const [
      WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.stored(cityId: 'city_p2'),
      ),
    ],
    runtimeState: const GameRuntimeState(
      intendedAttacks: [
        IntendedAttack(
          attackerUnitId: 'warrior_p1',
          defenderCol: 1,
          defenderRow: 0,
          declaredAtTick: 7,
          declaringPlayerId: 'p1',
        ),
      ],
      resourceTradeAgreements: [_tradeAgreement],
    ),
  );
}

GameUnit _unit(
  String id,
  String ownerPlayerId,
  GameUnitType type,
  int col,
  int row, {
  String? carriedArtifactId,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
    carriedArtifactId: carriedArtifactId,
  );
}

GameSave _save() {
  return GameSave(
    id: 'combat_parity',
    name: 'Combat parity',
    mapName: 'combat_map',
    turn: _turn,
    playerStates: const {
      'p1': PlayerTurnState.finished,
      'p2': PlayerTurnState.finished,
    },
    savedAt: DateTime.utc(2026, 7, 17),
    camera: CameraState.zero,
    players: _players,
  );
}

List<Map<String, dynamic>> _eventJson(Iterable<GameEvent> events) {
  return events.map(GameEventSerializer.toJson).toList();
}

const _turn = 4;
const _adapter = LegacyGameSnapshotAdapter();
const _players = [
  Player(id: 'p1', name: 'Player one', colorValue: 0xFF000001),
  Player(id: 'p2', name: 'Player two', colorValue: 0xFF000002),
];
const _tradeAgreement = ResourceTradeAgreement(
  id: 'trade_1',
  exporterPlayerId: 'p1',
  importerPlayerId: 'p2',
  resource: ResourceType.iron,
  goldPerTurn: 2,
  remainingTurns: 3,
);
const _ruleset = GameRuleset(
  city: CityRulesets.standard,
  combat: CombatRuleset(
    varianceRange: 0,
    cityBaseStats: CombatStats(
      attack: 0,
      defense: 2,
      hp: 16,
      range: 1,
      mobility: 0,
    ),
    unitBaseStats: {
      GameUnitType.warrior: CombatStats(
        attack: 4,
        defense: 3,
        hp: 10,
        range: 1,
        mobility: 1,
      ),
      GameUnitType.settler: CombatStats(
        attack: 0,
        defense: 1,
        hp: 2,
        range: 1,
        mobility: 1,
      ),
    },
  ),
  technology: TechnologyRulesets.standard,
);
final _mapTiles = MapData(
  cols: 2,
  rows: 1,
  tiles: [
    for (var col = 0; col < 2; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);

final class _MissingAttackerTileLookup implements MapTileLookup {
  int calls = 0;

  @override
  MapTileView? tileAt(int col, int row) {
    calls++;
    if (calls == 1) return null;
    throw StateError('City tile must not be read after a missing attacker.');
  }
}
