import 'package:aonw_core/ai/mcts/mcts_simulated_economy_command_applier.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsSimulatedEconomyCommandApplier city project', () {
    test('preserves active investment and overflow like persistent state', () {
      final ownCity = _ownCity.copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 7,
        ),
        productionOverflow: 12,
      );
      const enemyCity = _enemyCity;
      final state = PersistentGameState(
        cities: [ownCity, enemyCity],
        fogOfWar: _visibleFog,
      );
      const command = StartCityProjectCommand(
        'city_1',
        CityProjectType.research,
      );
      final persistent = const PersistentCityProductionResolver()
          .startCityProject(
            state: state,
            command: command,
            actorPlayerId: 'player_1',
          );
      final (:applier, :view) = _applierFor(state);

      final result = applier.applyStartCityProject(command);

      expect(persistent.accepted, isTrue);
      expect(result.single, persistent.state.cities.first);
      expect(result.single.productionQueue?.investedProduction, 7);
      expect(result.single.productionOverflow, 12);
      expect(applier.rememberedEnemyCities, same(view.rememberedEnemyCities));
      expect(applier.rememberedEnemyCities.single, same(enemyCity));
    });

    test('keeps a same-project application as an identity no-op', () {
      final state = PersistentGameState(
        cities: [
          _ownCity.copyWith(
            productionQueue: CityProductionQueue.project(
              projectType: CityProjectType.wealth,
              investedProduction: 5,
            ),
          ),
          _enemyCity,
        ],
        fogOfWar: _visibleFog,
      );
      final (:applier, :view) = _applierFor(state);

      final result = applier.applyStartCityProject(
        const StartCityProjectCommand('city_1', CityProjectType.wealth),
      );

      expect(result, same(view.ownCities));
      expect(applier.rememberedEnemyCities, same(view.rememberedEnemyCities));
    });

    test('cannot apply a project to a remembered enemy city', () {
      final state = PersistentGameState(
        cities: const [_ownCity, _enemyCity],
        fogOfWar: _visibleFog,
      );
      final (:applier, :view) = _applierFor(state);

      final result = applier.applyStartCityProject(
        const StartCityProjectCommand('city_2', CityProjectType.wealth),
      );

      expect(result, same(view.ownCities));
      expect(applier.rememberedEnemyCities, same(view.rememberedEnemyCities));
      expect(applier.rememberedEnemyCities.single, same(_enemyCity));
    });
  });
}

({MctsSimulatedEconomyCommandApplier applier, GameView view}) _applierFor(
  PersistentGameState state,
) {
  final view = GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData,
    ruleset: GameRuleset.defaults,
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

const _ownCity = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Own City',
  center: CityHex(col: 0, row: 0),
  controlledHexes: [],
);

const _enemyCity = GameCity(
  id: 'city_2',
  ownerPlayerId: 'player_2',
  name: 'Enemy City',
  center: CityHex(col: 1, row: 0),
  controlledHexes: [],
);

final _visibleFog = FogOfWarState(
  players: {
    'player_1': PlayerFogOfWar(
      playerId: 'player_1',
      visibleHexes: {
        const HexCoordinate(col: 0, row: 0),
        const HexCoordinate(col: 1, row: 0),
      },
    ),
  },
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
