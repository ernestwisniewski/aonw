import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyFoundingPlanner', () {
    test('founds the opening city on a valid visible site', () {
      final mapData = _map(cols: 3, rows: 3);
      final view = _view(
        mapData: mapData,
        units: [
          GameUnit.startingCommander(
            ownerPlayerId: 'player_1',
            col: 1,
            row: 1,
            army: const [ArmyTroop(type: TroopType.settler, count: 1)],
          ),
        ],
      );
      final context = _context(view);

      final commands = const BasicStrategyFoundingPlanner().plan(
        view,
        context,
        AiEmpireAssessment.fromView(view, context),
      );

      final foundings = commands.whereType<FoundCityCommand>().toList();
      expect(foundings, hasLength(1));
      expect(foundings.single.founderId, 'commander_player_1');
      expect(
        foundings.single.controlledHexes,
        hasLength(CityFoundingDraft.requiredControlledHexes),
      );
      expect(foundings.single.controlledHexes, isNot(contains(viewCenter)));
    });

    test('moves an assigned settler toward the strategic site', () {
      final mapData = _map(cols: 8, rows: 8);
      const assignment = CityHex(col: 3, row: 2);
      final view = _view(
        mapData: mapData,
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 2,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 0, row: 1)],
          ),
        ],
      );
      final context = _context(
        view,
        strategicPlan: StrategicPlan(
          computedAtTurn: view.turn,
          mode: StrategicMode.expand,
          expectations: const EconomyExpectations(
            expectedCityCount: 2,
            expectedWorkerCount: 1,
            expectedMilitaryCount: 1,
            goldReserveTarget: 8,
            minimumSciencePerTurn: 2,
          ),
          settlerAssignments: {'settler_1': assignment},
        ),
      );

      final commands = const BasicStrategyFoundingPlanner().plan(
        view,
        context,
        AiEmpireAssessment.fromView(view, context),
      );

      expect(commands.whereType<FoundCityCommand>(), isEmpty);
      expect(commands, contains(const MoveUnitCommand('settler_1', 3, 2)));
    });

    test('moves a threatened opening settler instead of founding', () {
      final mapData = _map(cols: 8, rows: 8);
      final view = _view(
        mapData: mapData,
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 3,
          ),
          GameUnit.produced(
            id: 'enemy_warrior',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 1,
            row: 3,
          ),
        ],
      );
      final context = _context(view);

      final commands = const BasicStrategyFoundingPlanner().plan(
        view,
        context,
        AiEmpireAssessment.fromView(view, context),
      );

      expect(commands.whereType<FoundCityCommand>(), isEmpty);
      final move = commands.whereType<MoveUnitCommand>().single;
      expect(move.unitId, 'settler_1');
      expect(
        HexDistance.between(
          HexCoordinate(col: move.targetCol, row: move.targetRow),
          const HexCoordinate(col: 1, row: 3),
        ),
        greaterThan(1),
      );
    });
  });
}

const viewCenter = CityHex(col: 1, row: 1);

GameView _view({
  required MapData mapData,
  required List<GameUnit> units,
  List<GameCity> cities = const [],
}) {
  return GameView.fromPersistentState(
    PersistentGameState(
      units: units,
      cities: cities,
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

AiContext _context(GameView view, {StrategicPlan? strategicPlan}) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 1001,
    ),
    strategicPlan: strategicPlan,
  );
}

MapData _map({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

Set<HexCoordinate> _allHexesIn(MapData mapData) {
  return {
    for (var col = 0; col < mapData.cols; col++)
      for (var row = 0; row < mapData.rows; row++)
        HexCoordinate(col: col, row: row),
  };
}
