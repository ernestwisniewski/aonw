part of '../mcts_action_generator_test.dart';

const _playerId = 'player_1';
const _enemyId = 'player_2';

class _StaticStrategy implements AiStrategy {
  final List<DomainCommand> commands;

  const _StaticStrategy({required this.commands});

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    return AiTurnPlan(commands: commands);
  }
}

class _CountingStrategy implements AiStrategy {
  final List<DomainCommand> commands;
  int calls = 0;

  _CountingStrategy({required this.commands});

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    calls += 1;
    return AiTurnPlan(commands: commands);
  }
}

class _StaticActionGenerator implements MctsActionGenerator {
  final List<MctsAction> actions;

  const _StaticActionGenerator({required this.actions});

  @override
  List<MctsAction> candidatesFor(SimulatedState state, AiContext context) {
    return actions;
  }
}

List<DomainCommand> _commands(List<MctsAction> actions) {
  return actions
      .map((action) => action.toCommand())
      .whereType<DomainCommand>()
      .toList();
}

AiContext _context({
  WorldMap? mapData,
  StrategicPlan? strategicPlan,
  CivilizationProfile civProfile = CivilizationProfiles.poland,
}) {
  final actualMapData = mapData ?? _mapData();
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: actualMapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: _playerId, baseSeed: 7),
    strategicPlan: strategicPlan,
    persona: civProfile.defaultPersona,
    civProfile: civProfile,
  );
}

StrategicPlan _strategicPlan({
  StrategicMode mode = StrategicMode.consolidate,
  List<WarGoal> warGoals = const [],
  Map<String, CityHex> settlerAssignments = const {},
  Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments =
      const {},
  Map<String, StrategicDefenseAssignment> defenses = const {},
}) {
  return StrategicPlan(
    computedAtTurn: 1,
    mode: mode,
    expectations: const EconomyExpectations(
      expectedCityCount: 1,
      expectedWorkerCount: 1,
      expectedMilitaryCount: 1,
      goldReserveTarget: 8,
      minimumSciencePerTurn: 2,
    ),
    warGoals: warGoals,
    settlerAssignments: settlerAssignments,
    frontierClearingAssignments: frontierClearingAssignments,
    defenses: defenses,
  );
}

GameView _view({
  WorldMap? mapData,
  PlayerResearchState? research,
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  List<FieldImprovement> fieldImprovements = const [],
  DiplomacyState diplomacy = DiplomacyState.empty,
  FogOfWarState? fogOfWar,
  bool ignoreFogOfWar = false,
}) {
  final actualMapData = mapData ?? _mapData();
  final researchState = research == null
      ? ResearchState.empty
      : ResearchState(players: {_playerId: research});
  return MctsSimulatorParityFixtures.viewFromPersistentState(
    DomainState.snapshot(
      units: units,
      cities: cities,
      fieldImprovements: fieldImprovements,
      research: researchState,
      diplomacy: diplomacy,
      fogOfWar: fogOfWar ?? _visibleFog(actualMapData),
    ),
    forPlayerId: _playerId,
    turn: 1,
    mapData: actualMapData,
    ruleset: GameRuleset.defaults,
    ignoreFogOfWar: ignoreFogOfWar,
  );
}

WorldMap _mapData() => _squareMap(cols: 3, rows: 2);

WorldMap _lineMap(int cols) => _squareMap(cols: cols, rows: 1);

WorldMap _highCostLineMap() {
  return WorldMap(
    cols: 3,
    rows: 1,
    tiles: [
      WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 1,
        row: 0,
        terrains: [TerrainType.snow, TerrainType.forest, TerrainType.tundra],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 2,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

WorldMap _squareMap({required int cols, required int rows}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

FogOfWarState _visibleFog(WorldMap mapData) {
  return _fogForHexes(_playerId, {
    for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
  });
}

FogOfWarState _fogForHexes(String playerId, Set<HexCoordinate> visibleHexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(playerId: playerId, visibleHexes: visibleHexes),
    },
  );
}
