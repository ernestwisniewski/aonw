import 'package:aonw_core/ai/mcts/mcts_opponent_view_index.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AI wonder context forwarding', () {
    test('empire assessment includes empire-wide wonder gold', () {
      final baselineView = _view(wonderCompleted: false);
      final wonderView = _view(wonderCompleted: true);
      final baseline = AiEmpireAssessment.fromView(
        baselineView,
        _context(baselineView),
      );
      final withWonder = AiEmpireAssessment.fromView(
        wonderView,
        _context(wonderView),
      );

      expect(withWonder.netGoldPerTurn, baseline.netGoldPerTurn + 14);
    });

    test('technology snapshot includes wonder gold and science', () {
      final baseline = AiTechnologyScoreSnapshot.from(
        _view(wonderCompleted: false, ruleset: _technologyRuleset),
      );
      final withWonder = AiTechnologyScoreSnapshot.from(
        _view(wonderCompleted: true, ruleset: _technologyRuleset),
      );

      expect(
        baseline.goldPressure - withWonder.goldPressure,
        closeTo(1 / 3, 1e-9),
      );
      expect(
        baseline.sciencePressure - withWonder.sciencePressure,
        closeTo(0.25, 1e-9),
      );
    });

    test('strategic economy health includes empire-wide wonder science', () {
      final baselineView = _view(wonderCompleted: false);
      final wonderView = _view(wonderCompleted: true);
      final baseline = EconomyHealth.fromView(
        view: baselineView,
        assessment: AiEmpireAssessment.fromView(
          baselineView,
          _context(baselineView),
        ),
        expectations: _expectations,
      );
      final withWonder = EconomyHealth.fromView(
        view: wonderView,
        assessment: AiEmpireAssessment.fromView(
          wonderView,
          _context(wonderView),
        ),
        expectations: _expectations,
      );

      expect(withWonder.sciencePerTurn, baseline.sciencePerTurn + 14);
      expect(withWonder.scienceRatio, greaterThan(baseline.scienceRatio));
    });

    test('MCTS strategic score includes empire-wide wonder yield', () {
      const scorer = MctsStrategicStateScorer();
      final hostOnly = scorer.score(
        SimulatedState.fromView(
          _view(wonderCompleted: true, ruleset: _hostOnlyRuleset),
          maxPlanningDepth: 1,
        ),
        PersonaWeights.identity,
      );
      final withWonder = scorer.score(
        SimulatedState.fromView(
          _view(wonderCompleted: true),
          maxPlanningDepth: 1,
        ),
        PersonaWeights.identity,
      );

      expect(withWonder, greaterThan(hostOnly));
    });

    test('economy telemetry includes empire-wide wonder gold and science', () {
      final baseline = _telemetryRow(wonderCompleted: false);
      final withWonder = _telemetryRow(wonderCompleted: true);

      expect(withWonder.cityGoldIncome, baseline.cityGoldIncome + 14);
      expect(withWonder.netGoldPerTurn, baseline.netGoldPerTurn + 14);
      expect(withWonder.sciencePerTurn, baseline.sciencePerTurn + 14);
    });

    test('opponent view preserves the source wonder registry', () {
      const opponentCity = GameCity(
        id: 'opponent_city',
        ownerPlayerId: _opponentId,
        name: 'Opponent City',
        center: CityHex(col: 0, row: 0),
      );
      final state = PersistentGameState(
        cities: const [opponentCity],
        wonderRegistry: _completedWonderRegistry,
      );
      final view = MctsOpponentViewIndex.fromState(state).viewFor(
        state: state,
        opponentId: _opponentId,
        turn: 1,
        mapData: _mapData,
        ruleset: _ruleset,
      );

      expect(view.ownCities, [opponentCity]);
      expect(view.wonderRegistry, same(_completedWonderRegistry));
    });
  });
}

GameView _view({required bool wonderCompleted, GameRuleset? ruleset}) {
  return GameView(
    forPlayerId: _playerId,
    turn: 1,
    ownUnits: const [],
    ownCities: _cities,
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
    wonderRegistry: _registry(wonderCompleted),
  );
}

AiContext _context(GameView view) => AiContext(
  ruleset: view.ruleset,
  mapData: view.mapData,
  turn: view.turn,
  rng: AiRng(17),
);

EconomySimulationTurnRow _telemetryRow({required bool wonderCompleted}) {
  return EconomySimulationTurnRowProjector.project(
    turn: 1,
    state: _state(wonderCompleted: wonderCompleted),
    playerId: _playerId,
    mapData: _mapData,
    ruleset: _ruleset,
  );
}

PersistentGameState _state({required bool wonderCompleted}) {
  return PersistentGameState(
    playerGold: const {_playerId: 0},
    cities: _cities,
    wonderRegistry: _registry(wonderCompleted),
  );
}

WonderRegistry _registry(bool wonderCompleted) {
  return wonderCompleted ? _completedWonderRegistry : WonderRegistry.empty;
}

const _playerId = 'player_1';
const _opponentId = 'player_2';

const _expectations = EconomyExpectations(
  expectedCityCount: 2,
  expectedWorkerCount: 0,
  expectedMilitaryCount: 0,
  goldReserveTarget: 0,
  minimumSciencePerTurn: 100,
);

const _cities = [
  GameCity(
    id: 'capital',
    ownerPlayerId: _playerId,
    name: 'Capital',
    center: CityHex(col: 0, row: 0),
    controlledHexes: [CityHex(col: 0, row: 0)],
    workedHexes: [CityHex(col: 0, row: 0)],
  ),
  GameCity(
    id: 'wonder_city',
    ownerPlayerId: _playerId,
    name: 'Wonder City',
    center: CityHex(col: 1, row: 0),
    controlledHexes: [CityHex(col: 1, row: 0)],
    workedHexes: [CityHex(col: 1, row: 0)],
    wonders: {WonderType.greatWall},
  ),
];

final _completedWonderRegistry = WonderRegistry(
  completedBy: {WonderType.greatWall: _playerId},
);

final _ruleset = GameRuleset.defaults.copyWith(
  technology: TechnologyRuleset(
    science: const ScienceBalance(
      baseSciencePerCity: 1,
      maxSciencePerCity: 0,
      secondScienceBuildingMultiplier: 0.70,
      thirdScienceBuildingMultiplier: 0.35,
    ),
    costs: GameRuleset.defaults.technology.costs,
    technologies: GameRuleset.defaults.technology.technologies,
  ),
  wonders: const WonderRuleset(
    wonders: {
      WonderType.greatWall: WonderDefinition(
        type: WonderType.greatWall,
        productionCost: 140,
        unlockTech: TechnologyId.militaryOrganization,
        standingEffects: [
          EmpireFlatYieldEffect(
            TileYield(food: 0, production: 0, gold: 7, defense: 0),
          ),
          EmpireScienceEffect(7),
        ],
      ),
    },
  ),
);

final _technologyRuleset = GameRuleset.defaults.copyWith(
  technology: TechnologyRuleset(
    science: const ScienceBalance(
      baseSciencePerCity: 1,
      maxSciencePerCity: 0,
      secondScienceBuildingMultiplier: 0.70,
      thirdScienceBuildingMultiplier: 0.35,
    ),
    costs: GameRuleset.defaults.technology.costs,
    technologies: GameRuleset.defaults.technology.technologies,
  ),
  wonders: const WonderRuleset(
    wonders: {
      WonderType.greatWall: WonderDefinition(
        type: WonderType.greatWall,
        productionCost: 140,
        unlockTech: TechnologyId.militaryOrganization,
        standingEffects: [
          EmpireFlatYieldEffect(
            TileYield(food: 0, production: 0, gold: 1, defense: 0),
          ),
          EmpireScienceEffect(1),
        ],
      ),
    },
  ),
);

final _hostOnlyRuleset = GameRuleset.defaults.copyWith(
  wonders: const WonderRuleset(
    wonders: {
      WonderType.greatWall: WonderDefinition(
        type: WonderType.greatWall,
        productionCost: 140,
        unlockTech: TechnologyId.militaryOrganization,
        standingEffects: [
          HostCityFlatYieldEffect(
            TileYield(food: 0, production: 0, gold: 7, defense: 0),
          ),
        ],
      ),
    },
  ),
);

final _mapData = MapData(
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
      resources: [],
      height: 0,
    ),
  ],
);
