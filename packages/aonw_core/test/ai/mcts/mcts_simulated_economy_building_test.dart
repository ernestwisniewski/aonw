import 'package:aonw_core/ai/mcts/mcts_simulated_economy_command_applier.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsSimulatedEconomyCommandApplier building production', () {
    test('preserves ownCities identity when the building is unavailable', () {
      final (:applier, :view) = _applierFor(
        const PersistentGameState(cities: [_city]),
      );

      final result = applier.applyStartBuilding(
        const StartBuildingCommand('city_1', CityBuildingType.workshop),
      );

      expect(result, same(view.ownCities));
      expect(result.single, same(view.ownCities.single));
    });

    test(
      'same target is accepted with new list, city, and queue identities',
      () {
        final queue = CityProductionQueue.building(
          buildingType: CityBuildingType.workshop,
          investedProduction: 5,
        );
        final city = _city.copyWith(
          productionQueue: queue,
          productionOverflow: 6,
        );
        final state = PersistentGameState(
          cities: [city],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {TechnologyId.craftsmanship},
              ),
            },
          ),
        );
        final (:applier, :view) = _applierFor(state);

        final result = applier.applyStartBuilding(
          const StartBuildingCommand('city_1', CityBuildingType.workshop),
        );

        expect(result, isNot(same(view.ownCities)));
        expect(result.single, city);
        expect(result.single, isNot(same(view.ownCities.single)));
        expect(result.single.productionQueue, queue);
        expect(
          result.single.productionQueue,
          isNot(same(view.ownCities.single.productionQueue)),
        );
      },
    );

    test('forwards non-default pace and map requirements to the kernel', () {
      final state = PersistentGameState(
        cities: [_city.copyWith(productionOverflow: 1000)],
        research: _factoryResearch,
      );
      final mapData = _mapDataWithResource(ResourceType.oil);
      final ruleset = GameRuleset.defaults.copyWith(
        paceBalance: PaceBalance.standard60,
      );
      const command = StartBuildingCommand('city_1', CityBuildingType.factory);
      final expected = const PersistentCityProductionResolver().startBuilding(
        state: state,
        command: command,
        actorPlayerId: 'player_1',
        mapTiles: mapData,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
        paceBalance: ruleset.paceBalance,
      );
      final (:applier, :view) = _applierFor(
        state,
        mapData: mapData,
        ruleset: ruleset,
      );

      final result = applier.applyStartBuilding(command);

      expect(expected.accepted, isTrue);
      expect(result, expected.state.cities);
      expect(result, isNot(same(view.ownCities)));
      expect(result.single.productionQueue?.investedProduction, 13);
      expect(
        result.single.productionQueue?.target,
        const BuildingProductionTarget(CityBuildingType.factory),
      );
    });

    test('preserves identity when the required map resource is absent', () {
      final state = PersistentGameState(
        cities: [_city.copyWith(productionOverflow: 1000)],
        research: _factoryResearch,
      );
      final ruleset = GameRuleset.defaults.copyWith(
        paceBalance: PaceBalance.standard60,
      );
      const command = StartBuildingCommand('city_1', CityBuildingType.factory);
      final (:applier, :view) = _applierFor(state, ruleset: ruleset);

      final result = applier.applyStartBuilding(command);

      expect(result, same(view.ownCities));
      expect(result.single, same(view.ownCities.single));
    });
  });
}

({MctsSimulatedEconomyCommandApplier applier, GameView view}) _applierFor(
  PersistentGameState state, {
  MapData? mapData,
  GameRuleset ruleset = GameRuleset.defaults,
}) {
  final view = GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData ?? _mapData,
    ruleset: ruleset,
  );
  return (
    applier: MctsSimulatedEconomyCommandApplier(
      view: view,
      ownUnits: view.ownUnits,
      visibleEnemyUnits: view.visibleEnemyUnits,
      ownCities: view.ownCities,
      rememberedEnemyCities: view.rememberedEnemyCities,
      ownResearch: view.ownResearch,
    ),
    view: view,
  );
}

const _city = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Own City',
  center: CityHex(col: 0, row: 0),
  controlledHexes: [],
);

final _factoryResearch = ResearchState(
  players: {
    'player_1': PlayerResearchState(
      unlockedTechnologyIds: {TechnologyId.machinery, TechnologyId.combustion},
    ),
  },
);

final _mapData = _mapDataWithResource(null);

MapData _mapDataWithResource(ResourceType? resource) => MapData(
  cols: 1,
  rows: 1,
  tiles: [
    TileData(
      col: 0,
      row: 0,
      terrains: const [TerrainType.plains],
      resources: resource == null ? const [] : [resource],
      height: 0,
    ),
  ],
);
