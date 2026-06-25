import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AiTechnologyScorer', () {
    test('prioritizes production tech when production is the bottleneck', () {
      final mapData = _productionMap();
      final view = _view(
        mapData: mapData,
        state: _state(
          mapData: mapData,
          playerGold: 24,
          city: const GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
          research: _researchWithUnlocked(TechnologyId.agriculture),
          units: [
            GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 0, row: 0),
          ],
        ),
      );
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final pick = const AiTechnologyScorer().pickTechnology(
        view: view,
        context: context,
        assessment: assessment,
      );

      expect(pick, TechnologyId.mining);
    });

    test('uses live gold pressure and matching resources for trade', () {
      final mapData = _ivoryMap();
      final view = _view(
        mapData: mapData,
        state: _state(
          mapData: mapData,
          playerGold: 0,
          city: const GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
          research: _researchWithUnlocked(TechnologyId.agriculture),
          units: [
            GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 0, row: 0),
          ],
        ),
      );
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final pick = const AiTechnologyScorer().pickTechnology(
        view: view,
        context: context,
        assessment: assessment,
      );

      expect(pick, TechnologyId.trade);
    });

    test('exposes persona and state score components', () {
      final mapData = _productionMap();
      final view = _view(
        mapData: mapData,
        state: _state(
          mapData: mapData,
          playerGold: 24,
          city: const GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
          research: _researchWithUnlocked(TechnologyId.agriculture),
          units: [
            GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 0, row: 0),
          ],
        ),
      );
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);
      const scorer = AiTechnologyScorer();

      final breakdown = scorer.scoreTechnologyBreakdown(
        view: view,
        id: TechnologyId.mining,
        context: context,
        assessment: assessment,
      );
      final interfaceBreakdown = scorer.score(
        TechnologyId.mining,
        AiTechnologyScoreInput(
          view: view,
          context: context,
          assessment: assessment,
        ),
      );

      expect(
        breakdown.total,
        scorer.scoreTechnology(
          view: view,
          id: TechnologyId.mining,
          context: context,
          assessment: assessment,
        ),
      );
      expect(interfaceBreakdown.total, breakdown.total);
      expect(breakdown.components.keys, containsAll(['persona', 'state']));
    });

    test('StrategicPlanner publishes the scored research path', () {
      final mapData = _pastureMap();
      final view = _view(
        mapData: mapData,
        state: _state(
          mapData: mapData,
          playerGold: 24,
          city: const GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
          research: _researchWithUnlocked(TechnologyId.agriculture),
          units: [
            GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 0, row: 0),
          ],
        ),
      );
      final context = _context(mapData);

      final plan = const StrategicPlanner().build(view: view, context: context);

      expect(plan.techPath.first, TechnologyId.animalHusbandry);
    });
  });
}

AiContext _context(MapData mapData) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: 2,
    rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
  );
}

GameView _view({required MapData mapData, required PersistentGameState state}) {
  return GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 2,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

PersistentGameState _state({
  required MapData mapData,
  required int playerGold,
  required GameCity city,
  required ResearchState research,
  List<GameUnit> units = const [],
}) {
  return PersistentGameState(
    units: units,
    cities: [city],
    playerGold: {'player_1': playerGold},
    research: research,
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: _allHexesIn(mapData),
        ),
      },
    ),
  );
}

ResearchState _researchWithUnlocked(TechnologyId technologyId) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(unlockedTechnologyIds: {technologyId}),
    },
  );
}

MapData _productionMap() {
  return MapData(
    cols: 2,
    rows: 1,
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
        terrains: [TerrainType.hills],
        resources: [],
        height: 1,
      ),
    ],
  );
}

MapData _ivoryMap() {
  return MapData(
    cols: 2,
    rows: 1,
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
        terrains: [TerrainType.plains],
        resources: [ResourceType.ivory],
        height: 0,
      ),
    ],
  );
}

MapData _pastureMap() {
  return MapData(
    cols: 2,
    rows: 1,
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
