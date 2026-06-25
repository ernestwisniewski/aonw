import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategic/economy_expectations.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_defensive_stance_planner.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyDefensiveStancePlanner', () {
    test('returns no commands when the strategic plan has no defenses', () {
      final view = _view(
        units: [
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [_capital],
      );

      final commands = const BasicStrategyDefensiveStancePlanner().plan(
        view,
        _context(view, defenses: const {}),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, isEmpty);
    });

    test('fortifies assigned garrison in a threatened defense area', () {
      final guard = GameUnit.produced(
        id: 'guard_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).copyWith(hitPoints: 6);
      final usedUnitIds = <String>{};
      final view = _view(units: [guard], cities: const [_capital]);

      final commands = const BasicStrategyDefensiveStancePlanner().plan(
        view,
        _context(
          view,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 10,
              assignedUnitIds: ['guard_1'],
              primaryThreatPlayerId: 'player_2',
            ),
          },
        ),
        usedUnitIds,
        <HexCoordinate>{},
      );

      expect(commands, const [FortifyUnitCommand('guard_1')]);
      expect(usedUnitIds, {'guard_1'});
    });

    test('moves assigned garrison toward defended city and reserves path', () {
      final guard = GameUnit.produced(
        id: 'guard_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 4,
        row: 0,
      );
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};
      final view = _view(units: [guard], cities: const [_capital]);

      final commands = const BasicStrategyDefensiveStancePlanner().plan(
        view,
        _context(
          view,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 0,
              assignedUnitIds: ['guard_1'],
            ),
          },
        ),
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, hasLength(1));
      final move = commands.single as MoveUnitCommand;
      expect(move.unitId, 'guard_1');
      expect(
        HexDistance.between(
          HexCoordinate(col: move.targetCol, row: move.targetRow),
          _capital.center.toCoordinate(),
        ),
        lessThan(
          HexDistance.between(
            const HexCoordinate(col: 4, row: 0),
            _capital.center.toCoordinate(),
          ),
        ),
      );
      expect(usedUnitIds, {'guard_1'});
      expect(
        reservedHexes,
        contains(HexCoordinate(col: move.targetCol, row: move.targetRow)),
      );
    });
  });
}

GameView _view({
  required List<GameUnit> units,
  required List<GameCity> cities,
}) {
  return GameView(
    forPlayerId: 'player_1',
    turn: 1,
    ownUnits: units,
    ownCities: cities,
    ownResearch: PlayerResearchState.empty,
    ownImprovements: const [],
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: _mapData,
    ruleset: _ruleset,
  );
}

AiContext _context(
  GameView view, {
  required Map<String, StrategicDefenseAssignment> defenses,
}) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 17,
    ),
    strategicPlan: StrategicPlan(
      computedAtTurn: view.turn,
      mode: StrategicMode.consolidate,
      expectations: const EconomyExpectations(
        expectedCityCount: 1,
        expectedWorkerCount: 0,
        expectedMilitaryCount: 1,
        goldReserveTarget: 8,
        minimumSciencePerTurn: 2,
      ),
      defenses: defenses,
    ),
  );
}

const _capital = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
);

final _mapData = MapData(
  cols: 5,
  rows: 1,
  tiles: [
    for (var col = 0; col < 5; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
  ],
);

const _ruleset = GameRuleset.defaults;
