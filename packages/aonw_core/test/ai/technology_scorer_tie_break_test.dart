import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AiTechnologyScorer deterministic edge cases', () {
    test('orders equal scores by technology tree position', () {
      final ruleset = _tieBreakRuleset();
      final view = _view(ruleset);
      final context = _context(view);
      final assessment = _assessment();
      const scorer = AiTechnologyScorer();

      expect(
        scorer.scoreTechnology(
          view: view,
          id: TechnologyId.irrigation,
          context: context,
          assessment: assessment,
        ),
        scorer.scoreTechnology(
          view: view,
          id: TechnologyId.construction,
          context: context,
          assessment: assessment,
        ),
      );
      expect(
        scorer.rankTechnologies(
          view: view,
          context: context,
          assessment: assessment,
        ),
        [TechnologyId.construction, TechnologyId.irrigation],
      );
    });

    test('values army strength more when the military is undersized', () {
      final view = _view(GameRuleset.defaults);
      final context = _context(view);
      const definition = TechnologyDefinition(
        id: TechnologyId.irrigation,
        name: 'Army strength fixture',
        description: 'Isolates the army-strength state score.',
        era: TechnologyEra.foundation,
        baseCost: 1,
        effects: [ArmyStrengthMultiplier(0.10)],
        treePosition: TechnologyTreePosition(column: 0, row: 0),
      );
      const scorer = AiTechnologyStateScorer();

      final adequateScore = scorer.score(
        view: view,
        definition: definition,
        context: context,
        assessment: _assessment(),
        snapshot: _snapshot,
      );
      final undersizedScore = scorer.score(
        view: view,
        definition: definition,
        context: context,
        assessment: _assessment(undersizedMilitary: true),
        snapshot: _snapshot,
      );

      expect(undersizedScore - adequateScore, closeTo(0.22, 1e-12));
    });
  });
}

GameRuleset _tieBreakRuleset() {
  return GameRuleset.defaults.copyWith(
    technology: TechnologyRuleset(
      science: TechnologyRulesets.standard.science,
      costs: TechnologyRulesets.standard.costs,
      technologies: {
        TechnologyId.agriculture: _technology(
          TechnologyId.agriculture,
          column: 0,
        ),
        TechnologyId.irrigation: _technology(
          TechnologyId.irrigation,
          column: 3,
        ),
        TechnologyId.construction: _technology(
          TechnologyId.construction,
          column: 2,
        ),
      },
    ),
  );
}

TechnologyDefinition _technology(TechnologyId id, {required int column}) {
  return TechnologyDefinition(
    id: id,
    name: id.name,
    description: 'Tie-break fixture.',
    era: TechnologyEra.foundation,
    baseCost: 1,
    treePosition: TechnologyTreePosition(column: column, row: 0),
  );
}

GameView _view(GameRuleset ruleset) {
  return GameView(
    forPlayerId: 'player_1',
    turn: 2,
    ownUnits: const [],
    ownCities: const [],
    ownResearch: PlayerResearchState(
      unlockedTechnologyIds: {TechnologyId.agriculture},
    ),
    ownImprovements: const [],
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: _map,
    ruleset: ruleset,
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
      baseSeed: 1001,
    ),
  );
}

AiEmpireAssessment _assessment({bool undersizedMilitary = false}) {
  return AiEmpireAssessment(
    playerId: 'player_1',
    cityCount: 1,
    workerCount: 1,
    settlerCount: 0,
    militaryCount: undersizedMilitary ? 0 : 1,
    visibleEnemyMilitaryCount: 0,
    goldReserve: 24,
    netGoldPerTurn: 1,
    desiredCityCount: 1,
    desiredWorkerCount: 1,
    desiredMilitaryCount: 1,
  );
}

const _snapshot = AiTechnologyScoreSnapshot(
  visibleTiles: [],
  visibleResources: {},
  controlledResources: {},
  productionPressure: 0,
  growthPressure: 0,
  goldPressure: 0,
  sciencePressure: 0,
  militaryPressure: 0.4,
  hasRiverTile: false,
  hasCoastalOpportunity: false,
);

final _map = WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
