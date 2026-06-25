import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WorkerAssignmentPlanner', () {
    test('assigns a worker to the nearest productive city', () {
      final mapData = _openMap(cols: 5, rows: 3);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 3,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'west',
            ownerPlayerId: 'player_1',
            name: 'West',
            center: CityHex(col: 0, row: 1),
            controlledHexes: [CityHex(col: 1, row: 1)],
          ),
          GameCity(
            id: 'east',
            ownerPlayerId: 'player_1',
            name: 'East',
            center: CityHex(col: 4, row: 1),
            controlledHexes: [CityHex(col: 3, row: 1)],
          ),
        ],
        research: _researchWith({
          TechnologyId.agriculture,
          TechnologyId.animalHusbandry,
        }),
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const WorkerAssignmentPlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        mode: StrategicMode.expand,
      );

      expect(plan.assignments['worker_1']?.cityId, 'east');
      expect(
        plan.assignments['worker_1']?.primaryTarget?.targetHex,
        const CityHex(col: 3, row: 1),
      );
    });

    test('ranks a legal resource specialist improvement first', () {
      final mapData = _resourceMap();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
          ),
        ],
        research: _researchWith({
          TechnologyId.agriculture,
          TechnologyId.animalHusbandry,
        }),
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const WorkerAssignmentPlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        mode: StrategicMode.expand,
      );

      final target = plan.assignments['worker_1']?.primaryTarget;
      expect(target?.targetHex, const CityHex(col: 1, row: 0));
      expect(target?.improvementType, FieldImprovementType.pasture);
      expect(target?.existingImprovement, isFalse);
    });

    test(
      'prefers a new build target before assigning an existing improvement',
      () {
        final mapData = _openMap(cols: 3, rows: 1);
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 1,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
              controlledHexes: [
                CityHex(col: 1, row: 0),
                CityHex(col: 2, row: 0),
              ],
            ),
          ],
          fieldImprovements: const [
            FieldImprovement(
              hex: CityHex(col: 1, row: 0),
              type: FieldImprovementType.farm,
              builtByCityId: 'city_1',
            ),
          ],
          research: _researchWith({TechnologyId.agriculture}),
          fogOfWar: _fog(mapData),
        );
        final view = _view(state, mapData);
        final context = _context(mapData);
        final assessment = AiEmpireAssessment.fromView(view, context);

        final plan = const WorkerAssignmentPlanner().compute(
          view: view,
          context: context,
          assessment: assessment,
          mode: StrategicMode.consolidate,
        );

        final target = plan.assignments['worker_1']?.primaryTarget;
        expect(target?.targetHex, const CityHex(col: 2, row: 0));
        expect(target?.improvementType, FieldImprovementType.farm);
        expect(target?.existingImprovement, isFalse);
      },
    );

    test('StrategicPlanner publishes worker assignments', () {
      final mapData = _resourceMap();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
        ],
        research: _researchWith({
          TechnologyId.agriculture,
          TechnologyId.animalHusbandry,
        }),
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);

      final plan = const StrategicPlanner().build(view: view, context: context);

      expect(plan.workerAssignments, contains('worker_1'));
      expect(
        plan.workerAssignments['worker_1']?.primaryTarget?.improvementType,
        FieldImprovementType.pasture,
      );
    });
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

ResearchState _researchWith(Set<TechnologyId> technologies) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(unlockedTechnologyIds: technologies),
    },
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

MapData _resourceMap() {
  return MapData(
    cols: 2,
    rows: 2,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [ResourceType.sheep],
        height: 0,
      ),
      TileData(
        col: 0,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}
