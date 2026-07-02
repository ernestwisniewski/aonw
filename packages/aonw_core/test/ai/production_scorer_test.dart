import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/production_counter_pressure_scorer.dart';
import 'package:aonw_core/ai/production_scorer.dart';
import 'package:aonw_core/ai/production_scoring_cache.dart';
import 'package:aonw_core/ai/production_unit_scorer.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  group('AiProductionScorer', () {
    test('recommends a worker when the empire has uncovered worker demand', () {
      const scorer = AiProductionScorer();
      final city = _city();
      final view = _view(city);
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 1,
        workerCount: 0,
        settlerCount: 0,
        militaryCount: 1,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 8,
        netGoldPerTurn: 1,
        desiredCityCount: 1,
        desiredWorkerCount: 1,
        desiredMilitaryCount: 1,
      );
      const planState = AiProductionPlanState(
        hasPlannedResearch: true,
        workerCount: 0,
        settlerCount: 0,
        militaryCount: 1,
        reconCount: 0,
      );

      final recommendation = scorer.recommend(
        city: city,
        view: view,
        context: _context(view),
        assessment: assessment,
        planState: planState,
      );

      expect(
        recommendation.target,
        const UnitProductionTarget(GameUnitType.worker),
      );
    });

    test('prefers a safe second-city settler before first worker recovery', () {
      const scorer = AiProductionScorer();
      final city = _city();
      final view = _view(
        city,
        mapData: _expansionMapData,
        units: [
          _warrior('warrior_1', col: 0, row: 0),
          _warrior('warrior_2', col: 1, row: 0),
          _scout('scout_1', col: 2, row: 0),
        ],
      );
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 1,
        workerCount: 0,
        settlerCount: 0,
        militaryCount: 2,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 12,
        netGoldPerTurn: 2,
        desiredCityCount: 4,
        desiredWorkerCount: 1,
        desiredMilitaryCount: 1,
      );
      const planState = AiProductionPlanState(
        hasPlannedResearch: true,
        workerCount: 0,
        settlerCount: 0,
        militaryCount: 2,
        reconCount: 0,
      );

      final recommendation = scorer.recommend(
        city: city,
        view: view,
        context: _context(view),
        assessment: assessment,
        planState: planState,
      );

      expect(
        recommendation.target,
        const UnitProductionTarget(GameUnitType.settler),
      );
    });

    test('prefers a safe second-city settler over worker with one guard', () {
      const scorer = AiProductionScorer();
      final city = _city();
      final view = _view(
        city,
        mapData: _expansionMapData,
        units: [_warrior('warrior_1', col: 0, row: 0)],
      );
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 1,
        workerCount: 0,
        settlerCount: 0,
        militaryCount: 1,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 10,
        netGoldPerTurn: 1,
        desiredCityCount: 4,
        desiredWorkerCount: 1,
        desiredMilitaryCount: 1,
      );
      const planState = AiProductionPlanState(
        hasPlannedResearch: true,
        workerCount: 0,
        settlerCount: 0,
        militaryCount: 1,
        reconCount: 0,
      );

      final recommendation = scorer.recommend(
        city: city,
        view: view,
        context: _context(view),
        assessment: assessment,
        planState: planState,
      );

      expect(
        recommendation.target,
        const UnitProductionTarget(GameUnitType.settler),
      );
    });

    test('keeps worker recovery competitive after the second city', () {
      final capital = _city();
      final secondCity = _city(id: 'city_2', col: 3, row: 3);
      final view = _view(
        capital,
        cities: [capital, secondCity],
        mapData: _expansionMapData,
        units: [
          _warrior('warrior_1', col: 0, row: 0),
          _warrior('warrior_2', col: 1, row: 0),
        ],
      );
      final context = _context(view);
      final cache = AiProductionScoringCache(view: view, context: context);
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 2,
        workerCount: 0,
        settlerCount: 0,
        militaryCount: 2,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 14,
        netGoldPerTurn: 2,
        desiredCityCount: 4,
        desiredWorkerCount: 2,
        desiredMilitaryCount: 2,
      );
      const planState = AiProductionPlanState(
        hasPlannedResearch: true,
        workerCount: 0,
        settlerCount: 0,
        militaryCount: 2,
        reconCount: 0,
      );
      const unitScorer = AiUnitProductionScorer();

      final workerScore = unitScorer.score(
        GameUnitType.worker,
        city: capital,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
        cache: cache,
      );
      final settlerScore = unitScorer.score(
        GameUnitType.settler,
        city: capital,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
        cache: cache,
      );

      expect(workerScore, greaterThan(settlerScore));
    });

    test('adds counter pressure when visible cavalry threatens the empire', () {
      final city = _city();
      final enemyCavalry = GameUnit.produced(
        id: 'enemy_cavalry',
        ownerPlayerId: 'player_2',
        type: GameUnitType.cavalry,
        col: 1,
        row: 0,
      );
      final view = _view(
        city,
        visibleEnemyUnits: [enemyCavalry],
        ownResearch: PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.militaryOrganization},
        ),
      );
      final context = _context(view);
      final cache = AiProductionScoringCache(view: view, context: context);
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 1,
        workerCount: 1,
        settlerCount: 0,
        militaryCount: 1,
        visibleEnemyMilitaryCount: 4,
        goldReserve: 8,
        netGoldPerTurn: 1,
        desiredCityCount: 1,
        desiredWorkerCount: 1,
        desiredMilitaryCount: 2,
      );
      const planState = AiProductionPlanState(
        hasPlannedResearch: true,
        workerCount: 1,
        settlerCount: 0,
        militaryCount: 1,
        reconCount: 0,
      );
      const unitScorer = AiUnitProductionScorer();

      final spearmanScore = unitScorer.score(
        GameUnitType.spearman,
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
        cache: cache,
      );
      final warriorScore = unitScorer.score(
        GameUnitType.warrior,
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
        cache: cache,
      );
      final recommendation = const AiProductionScorer().recommend(
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
      );

      expect(
        const AiProductionCounterPressureScorer().score(
          GameUnitType.spearman,
          view,
        ),
        greaterThan(0),
      );
      expect(spearmanScore, greaterThan(warriorScore));
      expect(recommendation.target, isA<UnitProductionTarget>());
      expect(
        (recommendation.target as UnitProductionTarget).unitType,
        GameUnitType.spearman,
      );
    });

    test('opens a first core building before extending to a third city', () {
      const scorer = AiProductionScorer();
      final capital = _city();
      final secondCity = _city(id: 'city_2', col: 3, row: 3);
      final view = _view(
        capital,
        cities: [capital, secondCity],
        mapData: _expansionMapData,
        units: [
          _warrior('warrior_1', col: 0, row: 0),
          _warrior('warrior_2', col: 1, row: 0),
        ],
      );
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 2,
        workerCount: 2,
        settlerCount: 0,
        militaryCount: 2,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 16,
        netGoldPerTurn: 3,
        desiredCityCount: 4,
        desiredWorkerCount: 2,
        desiredMilitaryCount: 2,
      );
      const planState = AiProductionPlanState(
        hasPlannedResearch: true,
        workerCount: 2,
        settlerCount: 0,
        militaryCount: 2,
        reconCount: 0,
      );

      final recommendation = scorer.recommend(
        city: capital,
        view: view,
        context: _context(view),
        assessment: assessment,
        planState: planState,
      );

      expect(
        recommendation.target,
        const BuildingProductionTarget(CityBuildingType.granary),
      );
    });

    test('raises order-building priority when stability reaches unrest', () {
      const scorer = AiProductionScorer();
      final existingBuildings = CityBuildingType.values.toSet()
        ..remove(CityBuildingType.townHall);
      final city = _city().copyWith(buildings: existingBuildings);
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 1,
        workerCount: 1,
        settlerCount: 0,
        militaryCount: 1,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 20,
        netGoldPerTurn: 2,
        desiredCityCount: 1,
        desiredWorkerCount: 1,
        desiredMilitaryCount: 1,
      );
      const planState = AiProductionPlanState(
        hasPlannedResearch: true,
        workerCount: 1,
        settlerCount: 0,
        militaryCount: 1,
        reconCount: 0,
      );
      final research = PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.administration},
      );
      final stableView = _view(city, ownResearch: research);
      final unrestView = _view(
        city,
        ownResearch: research,
        ownStabilityNet: -4,
      );

      final stable = scorer.recommend(
        city: city,
        view: stableView,
        context: _context(stableView),
        assessment: assessment,
        planState: planState,
      );
      final unrest = scorer.recommend(
        city: city,
        view: unrestView,
        context: _context(unrestView),
        assessment: assessment,
        planState: planState,
      );

      expect(
        unrest.target,
        const BuildingProductionTarget(CityBuildingType.townHall),
      );
      expect(unrest.score, greaterThan(stable.score));
    });
  });
}

GameCity _city({String id = 'city_1', int col = 0, int row = 0}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: col, row: row),
    controlledHexes: [CityHex(col: col, row: row)],
    workedHexes: [CityHex(col: col, row: row)],
  );
}

GameView _view(
  GameCity city, {
  List<GameCity>? cities,
  List<GameUnit>? units,
  List<GameUnit> visibleEnemyUnits = const [],
  PlayerResearchState ownResearch = PlayerResearchState.empty,
  int ownStabilityNet = 0,
  MapData? mapData,
}) {
  final actualMapData = mapData ?? _mapData;
  return GameView(
    forPlayerId: 'player_1',
    turn: 1,
    ownUnits: units ?? [_warrior('warrior_1', col: 0, row: 0)],
    ownCities: cities ?? [city],
    ownResearch: ownResearch,
    ownStabilityNet: ownStabilityNet,
    ownImprovements: const [],
    visibleEnemyUnits: visibleEnemyUnits,
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: 'player_1',
      state: FogOfWarState.empty,
    ),
    mapData: actualMapData,
    ruleset: _ruleset,
  );
}

GameUnit _warrior(String id, {required int col, required int row}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    name: 'Warrior',
    col: col,
    row: row,
  );
}

GameUnit _scout(String id, {required int col, required int row}) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.scout,
    col: col,
    row: row,
  );
}

AiContext _context(GameView view) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 7,
    ),
  );
}

final _mapData = MapData(
  cols: 1,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.grassland],
      resources: [],
      height: 1,
    ),
  ],
);

final _expansionMapData = MapData(
  cols: 8,
  rows: 8,
  tiles: [
    for (var col = 0; col < 8; col++)
      for (var row = 0; row < 8; row++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 1,
        ),
  ],
);

final _ruleset = GameRuleset.standard();
