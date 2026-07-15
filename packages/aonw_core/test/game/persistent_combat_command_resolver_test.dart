import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentCombatCommandResolver', () {
    test('resolves a controlled visible unit attack immediately', () {
      final state = _state(
        units: [
          _unit('attacker', 'player_1', 0, 0),
          _unit('defender', 'player_2', 1, 0, type: GameUnitType.settler),
        ],
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'queued_attacker',
              defenderCol: 2,
              defenderRow: 0,
              declaredAtTick: 1,
              declaringPlayerId: 'player_1',
            ),
          ],
        ),
      );

      final result = const PersistentCombatCommandResolver().resolve(
        state: state,
        command: const AttackHexCommand('attacker', 1, 0),
        actorPlayerId: 'player_1',
        turn: 3,
        commandTick: 7,
        worldMap: _worldMap(),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.events.whereType<UnitAttackedEvent>(), hasLength(1));
      expect(result.events.whereType<CombatResolvedEvent>(), hasLength(1));
      expect(
        result.state.runtimeState.intendedAttacks,
        state.runtimeState.intendedAttacks,
      );
      expect(result.state.units.byId('attacker')?.movementPoints, 0);
    });

    test('captures and destroys cities according to the command action', () {
      for (final action in CityConquestAction.values) {
        final state = _state(
          units: [_unit('attacker', 'player_1', 0, 0)],
          cities: [
            const GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_2',
              name: 'City 2',
              center: CityHex(col: 1, row: 0),
              hitPoints: 1,
            ),
          ],
        );

        final result = const PersistentCombatCommandResolver().resolve(
          state: state,
          command: AttackHexCommand(
            'attacker',
            1,
            0,
            cityConquestAction: action,
          ),
          actorPlayerId: 'player_1',
          turn: 3,
          commandTick: 7,
          worldMap: _worldMap(),
        );

        expect(result.accepted, isTrue, reason: action.name);
        expect(result.events.whereType<CityAttackedEvent>(), hasLength(1));
        expect(result.events.whereType<CombatResolvedEvent>(), hasLength(1));
        if (action == CityConquestAction.destroy) {
          expect(result.state.cities, isEmpty);
          expect(result.events.whereType<CityDestroyedEvent>(), hasLength(1));
        } else {
          expect(result.state.cities.single.ownerPlayerId, 'player_1');
          expect(result.events.whereType<CityCapturedEvent>(), hasLength(1));
        }
      }
    });

    test('rejects forged, hidden, ranged, and treaty-protected attacks', () {
      final visibleState = _state(
        units: [
          _unit('attacker', 'player_1', 0, 0),
          _unit('defender', 'player_2', 1, 0),
        ],
      );
      const resolver = PersistentCombatCommandResolver();

      expect(
        resolver
            .resolve(
              state: visibleState,
              command: const AttackHexCommand('attacker', 1, 0),
              actorPlayerId: 'player_2',
              turn: 3,
              commandTick: 7,
              worldMap: _worldMap(),
            )
            .reason,
        'attacker_not_controlled',
      );
      expect(
        resolver
            .resolve(
              state: visibleState.copyWith(fogOfWar: FogOfWarState.empty),
              command: const AttackHexCommand('attacker', 1, 0),
              actorPlayerId: 'player_1',
              turn: 3,
              commandTick: 7,
              worldMap: _worldMap(),
            )
            .reason,
        'attack_target_not_visible',
      );

      final rangedState = _state(
        units: [
          _unit('attacker', 'player_1', 0, 0),
          _unit('defender', 'player_2', 2, 0),
        ],
      );
      expect(
        resolver
            .resolve(
              state: rangedState,
              command: const AttackHexCommand('attacker', 2, 0),
              actorPlayerId: 'player_1',
              turn: 3,
              commandTick: 7,
              worldMap: _worldMap(),
            )
            .reason,
        'attack_target_out_of_range',
      );

      final treatyState = visibleState.copyWith(
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.truce,
            turn: 2,
          ),
        ),
      );
      expect(
        resolver
            .resolve(
              state: treatyState,
              command: const AttackHexCommand('attacker', 1, 0),
              actorPlayerId: 'player_1',
              turn: 3,
              commandTick: 7,
              worldMap: _worldMap(),
            )
            .reason,
        'attack_target_protected_by_treaty',
      );
    });
  });
}

PersistentGameState _state({
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  GameRuntimeState runtimeState = GameRuntimeState.empty,
}) {
  final visible = {
    const HexCoordinate(col: 0, row: 0),
    const HexCoordinate(col: 1, row: 0),
    const HexCoordinate(col: 2, row: 0),
  };
  return PersistentGameState(
    playerColors: const {'player_1': 1, 'player_2': 2},
    units: units,
    cities: cities,
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(playerId: 'player_1', visibleHexes: visible),
        'player_2': PlayerFogOfWar(playerId: 'player_2', visibleHexes: visible),
      },
    ),
    runtimeState: runtimeState,
  );
}

GameUnit _unit(
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

WorldMap _worldMap() {
  return WorldMap(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        WorldTile(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
