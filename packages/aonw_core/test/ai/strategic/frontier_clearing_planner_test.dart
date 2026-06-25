import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('FrontierClearingPlanner', () {
    test('assigns a spare military unit to clear a blocker near a settler', () {
      final mapData = _openMap(cols: 8, rows: 6);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 4,
            row: 4,
          ),
          _unit(
            id: 'clearer',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 3,
            row: 3,
          ),
          _unit(
            id: 'reserve',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          _unit(
            id: 'blocker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 4,
            row: 3,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'second',
            ownerPlayerId: 'player_1',
            name: 'Second',
            center: CityHex(col: 7, row: 0),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const FrontierClearingPlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        citySitePlan: CitySitePlan.empty,
      );

      expect(plan.assignments.keys, {'clearer'});
      final assignment = plan.assignments['clearer']!;
      expect(assignment.founderId, 'settler_1');
      expect(assignment.targetPlayerId, 'player_2');
      expect(assignment.targetHex, const HexCoordinate(col: 4, row: 3));
      expect(assignment.priority, greaterThan(0));
    });

    test('skips units already reserved by higher priority plans', () {
      final mapData = _openMap(cols: 8, rows: 6);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 4,
            row: 4,
          ),
          _unit(
            id: 'reserved_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 4,
            row: 2,
          ),
          _unit(
            id: 'free_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 2,
            row: 3,
          ),
          _unit(
            id: 'spare_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          _unit(
            id: 'blocker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 4,
            row: 3,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'second',
            ownerPlayerId: 'player_1',
            name: 'Second',
            center: CityHex(col: 7, row: 0),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const FrontierClearingPlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        citySitePlan: CitySitePlan.empty,
        reservedUnitIds: const {'reserved_guard'},
      );

      expect(plan.assignments.keys, {'free_guard'});
      expect(plan.assignments, isNot(contains('reserved_guard')));
    });

    test('can use one surplus unit after city defenses are reserved', () {
      final mapData = _openMap(cols: 8, rows: 6);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 4,
            row: 4,
          ),
          _unit(
            id: 'capital_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          _unit(
            id: 'second_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 7,
            row: 0,
          ),
          _unit(
            id: 'surplus_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 3,
            row: 3,
          ),
          _unit(
            id: 'blocker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 4,
            row: 3,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'second',
            ownerPlayerId: 'player_1',
            name: 'Second',
            center: CityHex(col: 7, row: 0),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const FrontierClearingPlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        citySitePlan: CitySitePlan.empty,
        reservedUnitIds: const {'capital_guard', 'second_guard'},
      );

      expect(plan.assignments.keys, {'surplus_guard'});
    });

    test(
      'protects an assigned one-city settler when the target is pressured',
      () {
        final mapData = _openMap(cols: 8, rows: 6);
        final state = PersistentGameState(
          units: [
            _unit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              col: 4,
              row: 2,
            ),
            _unit(
              id: 'capital_guard',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
            _unit(
              id: 'surplus_guard',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 3,
              row: 2,
            ),
            _unit(
              id: 'blocker',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 5,
              row: 2,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
          ],
          fogOfWar: _fog(mapData),
        );
        final view = _view(state, mapData);
        final context = _context(mapData);
        final assessment = AiEmpireAssessment.fromView(view, context);

        final plan = const FrontierClearingPlanner().compute(
          view: view,
          context: context,
          assessment: assessment,
          citySitePlan: CitySitePlan(
            candidates: const [],
            settlerAssignments: const {'settler_1': CityHex(col: 5, row: 2)},
          ),
          reservedUnitIds: const {'capital_guard'},
        );

        expect(plan.assignments.keys, {'surplus_guard'});
        final assignment = plan.assignments['surplus_guard']!;
        expect(assignment.founderId, 'settler_1');
        expect(assignment.targetHex, const HexCoordinate(col: 5, row: 2));
      },
    );
  });
}

GameView _view(PersistentGameState state, MapData mapData) {
  return GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

AiContext _context(MapData mapData) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
  );
}

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required GameUnitType type,
  required int col,
  required int row,
}) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    col: col,
    row: row,
  );
}

FogOfWarState _fog(MapData mapData) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: {
          for (final tile in mapData.tiles)
            HexCoordinate(col: tile.col, row: tile.row),
        },
      ),
    },
  );
}

MapData _openMap({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
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
