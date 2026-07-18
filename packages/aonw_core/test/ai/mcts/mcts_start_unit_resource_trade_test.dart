import 'package:aonw_core/ai/mcts/mcts_simulated_economy_command_applier.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('lightweight MCTS imported unit production', () {
    test('collector and applier match Persistent with imported iron', () {
      final scenario = _scenario(resourceTradeAgreements: const [_ironTrade]);
      final commands = const MctsProductionCandidateCollector()
          .commandsFor(scenario.view)
          .toList();
      final persistent = _applyPersistent(scenario.state);

      expect(commands, contains(_command));
      expect(persistent.accepted, isTrue);

      final result = scenario.applier.applyStartUnitProduction(_command);

      expect(result, persistent.state.cities);
      expect(result, isNot(same(scenario.view.ownCities)));
      expect(
        result.single.productionQueue?.target,
        const UnitProductionTarget(GameUnitType.warship),
      );
    });

    test('collector and applier reject without the import', () {
      final scenario = _scenario();
      final commands = const MctsProductionCandidateCollector()
          .commandsFor(scenario.view)
          .toList();
      final persistent = _applyPersistent(scenario.state);

      expect(commands, isNot(contains(_command)));
      expect(persistent.accepted, isFalse);
      expect(persistent.reason, 'unit_production_requires_resource');
      expect(persistent.state, same(scenario.state));

      final result = scenario.applier.applyStartUnitProduction(_command);

      expect(result, same(scenario.view.ownCities));
      expect(result.single, same(scenario.view.ownCities.single));
    });
  });
}

({
  PersistentGameState state,
  GameView view,
  MctsSimulatedEconomyCommandApplier applier,
})
_scenario({List<ResourceTradeAgreement> resourceTradeAgreements = const []}) {
  final state = PersistentGameState(
    cities: const [_port],
    research: ResearchState(
      players: {
        _playerId: PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.navalDoctrine},
        ),
      },
    ),
    runtimeState: GameRuntimeState(
      resourceTradeAgreements: resourceTradeAgreements,
    ),
  );
  final view = GameView.fromPersistentState(
    state,
    forPlayerId: _playerId,
    turn: 1,
    mapData: _coastalMapWithoutIron,
    ruleset: GameRuleset.defaults,
  );
  return (
    state: state,
    view: view,
    applier: MctsSimulatedEconomyCommandApplier(
      view: view,
      ownUnits: view.ownUnits,
      visibleEnemyUnits: view.visibleEnemyUnits,
      ownCities: view.ownCities,
      rememberedEnemyCities: view.rememberedEnemyCities,
      ownResearch: view.ownResearch,
    ),
  );
}

PersistentCityProductionResult _applyPersistent(PersistentGameState state) {
  return const PersistentCityProductionResolver().startUnitProduction(
    state: state,
    command: _command,
    actorPlayerId: _playerId,
    mapView: _coastalMapWithoutIron,
  );
}

const _playerId = 'player_1';
const _command = StartUnitProductionCommand('port', GameUnitType.warship);

const _port = GameCity(
  id: 'port',
  ownerPlayerId: _playerId,
  name: 'Port',
  population: 6,
  center: CityHex(col: 0, row: 0),
  controlledHexes: [CityHex(col: 0, row: 0)],
);

const _ironTrade = ResourceTradeAgreement(
  id: 'iron_import',
  exporterPlayerId: 'player_2',
  importerPlayerId: _playerId,
  resource: ResourceType.iron,
  goldPerTurn: 3,
  remainingTurns: 5,
);

final _coastalMapWithoutIron = MapData(
  cols: 2,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.coast],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 0,
      terrains: [TerrainType.ocean],
      resources: [],
      height: 0,
    ),
  ],
);
