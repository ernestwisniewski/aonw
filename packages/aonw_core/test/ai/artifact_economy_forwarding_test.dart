import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AI artifact economy forwarding', () {
    test('empire assessment includes stored artifact gold', () {
      final baselineView = _view();
      final artifactView = _view(artifacts: const [_merchantsSeal]);

      final baseline = AiEmpireAssessment.fromView(
        baselineView,
        _context(baselineView),
      );
      final withArtifact = AiEmpireAssessment.fromView(
        artifactView,
        _context(artifactView),
      );

      expect(withArtifact.netGoldPerTurn, baseline.netGoldPerTurn + 2);
    });

    test('technology pressure includes artifact gold and science', () {
      final lowScienceRuleset = _ruleset.copyWith(
        technology: TechnologyRuleset(
          science: const ScienceBalance(
            baseSciencePerCity: 1,
            maxSciencePerCity: 0,
            secondScienceBuildingMultiplier: 0.70,
            thirdScienceBuildingMultiplier: 0.35,
          ),
          costs: _ruleset.technology.costs,
          technologies: _ruleset.technology.technologies,
        ),
      );
      final baseline = AiTechnologyScoreSnapshot.from(
        _view(ruleset: lowScienceRuleset),
      );
      final withGold = AiTechnologyScoreSnapshot.from(
        _view(artifacts: const [_merchantsSeal], ruleset: lowScienceRuleset),
      );
      final withScience = AiTechnologyScoreSnapshot.from(
        _view(
          artifacts: const [_astronomersTablets],
          ruleset: lowScienceRuleset,
        ),
      );

      expect(withGold.goldPressure, lessThan(baseline.goldPressure));
      expect(withScience.sciencePressure, lessThan(baseline.sciencePressure));
    });

    test('strategic economy health includes artifact science', () {
      final baselineView = _view();
      final artifactView = _view(artifacts: const [_astronomersTablets]);
      final baselineAssessment = AiEmpireAssessment.fromView(
        baselineView,
        _context(baselineView),
      );
      final artifactAssessment = AiEmpireAssessment.fromView(
        artifactView,
        _context(artifactView),
      );
      const expectations = EconomyExpectations(
        expectedCityCount: 1,
        expectedWorkerCount: 0,
        expectedMilitaryCount: 0,
        goldReserveTarget: 0,
        minimumSciencePerTurn: 4,
      );

      final baseline = EconomyHealth.fromView(
        view: baselineView,
        assessment: baselineAssessment,
        expectations: expectations,
      );
      final withArtifact = EconomyHealth.fromView(
        view: artifactView,
        assessment: artifactAssessment,
        expectations: expectations,
      );

      expect(withArtifact.sciencePerTurn, baseline.sciencePerTurn + 1);
      expect(withArtifact.scienceRatio, greaterThan(baseline.scienceRatio));
    });

    test('MCTS strategic score includes stored artifact yield', () {
      const scorer = MctsStrategicStateScorer();
      final baseline = scorer.score(
        SimulatedState.fromView(_view(), maxPlanningDepth: 1),
        PersonaWeights.identity,
      );
      final withArtifact = scorer.score(
        SimulatedState.fromView(
          _view(artifacts: const [_merchantsSeal]),
          maxPlanningDepth: 1,
        ),
        PersonaWeights.identity,
      );

      expect(withArtifact, greaterThan(baseline));
    });

    test('production scoring cache includes stored artifact yield', () {
      final baselineView = _view();
      final artifactView = _view(artifacts: const [_merchantsSeal]);
      final baseline = AiProductionScoringCache(
        view: baselineView,
        context: _context(baselineView),
      ).economyFor(_city);
      final withArtifact = AiProductionScoringCache(
        view: artifactView,
        context: _context(artifactView),
      ).economyFor(_city);

      expect(
        withArtifact.netYield.gold,
        baseline.netYield.gold + _merchantsSeal.type.cityYield.gold,
      );
    });
  });
}

GameView _view({
  List<WorldArtifact> artifacts = const [],
  GameRuleset? ruleset,
}) {
  return GameView(
    forPlayerId: 'player_1',
    turn: 1,
    ownUnits: const [],
    ownCities: const [_city],
    artifacts: artifacts,
    ownResearch: PlayerResearchState.empty,
    ownImprovements: const [],
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: _mapData,
    ruleset: ruleset ?? _ruleset,
  );
}

AiContext _context(GameView view) => AiContext(
  ruleset: view.ruleset,
  mapData: view.mapData,
  turn: view.turn,
  rng: AiRng(17),
);

const _city = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
  controlledHexes: [CityHex(col: 0, row: 0)],
  workedHexes: [CityHex(col: 0, row: 0)],
);

const _merchantsSeal = WorldArtifact(
  id: 'artifact.merchantsSeal',
  type: WorldArtifactType.merchantsSeal,
  location: WorldArtifactLocation.stored(cityId: 'city_1'),
);

const _astronomersTablets = WorldArtifact(
  id: 'artifact.astronomersTablets',
  type: WorldArtifactType.astronomersTablets,
  location: WorldArtifactLocation.stored(cityId: 'city_1'),
);

final _mapData = MapData(
  cols: 1,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);

final _ruleset = GameRuleset.standard();
