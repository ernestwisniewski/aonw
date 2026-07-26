import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentCombatCommandResolver rejection contract', () {
    final base = _state(
      units: [
        _unit('attacker', 'player_1', 0),
        _unit('defender', 'player_2', 1),
      ],
    );
    final defaultMap = WorldMapReadView(_map());
    final cases = <_RejectionCase>[
      (
        name: 'missing attacker wins over every target failure',
        reason: 'attacker_not_found',
        state: base.copyWith(units: const []),
        command: const AttackHexCommand('missing', 7, 7),
        actorPlayerId: 'player_2',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'wrong actor wins over unavailable and invalid target',
        reason: 'attacker_not_controlled',
        state: base.copyWith(
          units: [
            _unit(
              'attacker',
              'player_1',
              0,
              movementPoints: 0,
              excavatingArtifactId: 'busy',
            ),
          ],
        ),
        command: const AttackHexCommand('attacker', 7, 7),
        actorPlayerId: 'player_2',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'working attacker wins over exhaustion',
        reason: 'attacker_unavailable',
        state: base.copyWith(
          units: [
            _unit(
              'attacker',
              'player_1',
              0,
              movementPoints: 0,
              excavatingArtifactId: 'busy',
            ),
          ],
        ),
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'exhausted attacker wins over origin bounds',
        reason: 'attacker_exhausted',
        state: base.copyWith(
          units: [_unit('attacker', 'player_1', -1, movementPoints: 0)],
        ),
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'invalid attacker origin wins over invalid target',
        reason: 'attacker_out_of_bounds',
        state: base.copyWith(units: [_unit('attacker', 'player_1', -1)]),
        command: const AttackHexCommand('attacker', 7, 7),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'invalid target bounds wins over attacker capability',
        reason: 'attack_target_out_of_bounds',
        state: base.copyWith(
          units: [_unit('attacker', 'player_1', 0, type: GameUnitType.settler)],
        ),
        command: const AttackHexCommand('attacker', 7, 7),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'noncombat attacker wins over missing target',
        reason: 'attacker_cannot_attack',
        state: base.copyWith(
          units: [_unit('attacker', 'player_1', 0, type: GameUnitType.settler)],
        ),
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'missing target is distinguished from friendly target',
        reason: 'attack_target_not_found',
        state: base.copyWith(units: [_unit('attacker', 'player_1', 0)]),
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'friendly target wins over treaty and visibility',
        reason: 'attack_target_not_enemy',
        state: base.copyWith(
          units: [
            _unit('attacker', 'player_1', 0),
            _unit('defender', 'player_1', 1),
          ],
          fogOfWar: FogOfWarState.empty,
        ),
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'protected treaty wins over hidden target',
        reason: 'attack_target_protected_by_treaty',
        state: base.copyWith(
          fogOfWar: FogOfWarState.empty,
          runtimeState: GameRuntimeState(
            diplomacy: DiplomacyState.empty.setStatus(
              'player_1',
              'player_2',
              DiplomaticRelationStatus.truce,
              turn: 6,
            ),
          ),
        ),
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'hidden target wins over range',
        reason: 'attack_target_not_visible',
        state: _state(
          units: [
            _unit('attacker', 'player_1', 0),
            _unit('defender', 'player_2', 2),
          ],
          fogOfWar: FogOfWarState.empty,
        ),
        command: const AttackHexCommand('attacker', 2, 0),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'visible target outside effective range is rejected',
        reason: 'attack_target_out_of_range',
        state: _state(
          units: [
            _unit('attacker', 'player_1', 0),
            _unit('defender', 'player_2', 2),
          ],
        ),
        command: const AttackHexCommand('attacker', 2, 0),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults,
      ),
      (
        name: 'nonpositive city health is rejected before resolution',
        reason: 'attack_city_has_no_health',
        state: _state(
          units: [_unit('attacker', 'player_1', 0)],
          cities: const [
            GameCity(
              id: 'city',
              ownerPlayerId: 'player_2',
              name: 'City',
              center: CityHex(col: 1, row: 0),
            ),
          ],
        ),
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        mapTiles: defaultMap,
        ruleset: GameRuleset.defaults.copyWith(
          combat: CombatRuleset.standard.copyWith(
            cityBaseStats: const CombatStats(),
          ),
        ),
      ),
      (
        name: 'post-counter zero attack reports unresolved combat atomically',
        reason: 'attack_not_resolved',
        state: _state(
          units: [
            _unit('attacker', 'player_1', 0, type: GameUnitType.cavalry),
            _unit('defender', 'player_2', 1, type: GameUnitType.archer),
          ],
        ),
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        mapTiles: WorldMapReadView(
          _map(targetTerrains: const [TerrainType.forest]),
        ),
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
      ),
    ];

    for (final scenario in cases) {
      test(scenario.name, () {
        final result = const PersistentCombatCommandResolver().resolve(
          state: scenario.state,
          command: scenario.command,
          actorPlayerId: scenario.actorPlayerId,
          turn: 7,
          commandTick: 13,
          mapTiles: scenario.mapTiles,
          ruleset: scenario.ruleset,
        );

        expect(result.accepted, isFalse);
        expect(result.reason, scenario.reason);
        expect(result.state, same(scenario.state));
        expect(result.events, isEmpty);
      });
    }
  });
}

typedef _RejectionCase = ({
  String name,
  String reason,
  PersistentGameState state,
  AttackHexCommand command,
  String actorPlayerId,
  MapTileLookup mapTiles,
  GameRuleset ruleset,
});

PersistentGameState _state({
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  FogOfWarState? fogOfWar,
}) {
  return PersistentGameState(
    playerColors: const {'player_1': 1, 'player_2': 2},
    units: units,
    cities: cities,
    fogOfWar: fogOfWar ?? _visibleFog(),
  );
}

GameUnit _unit(
  String id,
  String ownerPlayerId,
  int col, {
  GameUnitType type = GameUnitType.warrior,
  int? movementPoints,
  String? excavatingArtifactId,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: 0,
    movementPoints: movementPoints,
    excavatingArtifactId: excavatingArtifactId,
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
    },
  );
}

WorldMap _map({
  List<TerrainType> targetTerrains = const [TerrainType.grassland],
}) {
  return WorldMap(
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
  );
}
