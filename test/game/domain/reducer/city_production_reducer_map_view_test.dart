import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_worked_hex_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MapReadView mapView;
  late MapTileLookup mapTiles;

  setUp(() {
    mapView = WorldMapReadView(_worldMap());
    mapTiles = mapView;
  });

  test('queues city production through canonical map contracts', () {
    const city = _city;
    final selectedState = _stateWithSelectedCity(city);

    final building = CityProductionReducer.startBuilding(
      selectedState,
      const StartBuildingCommand('city_1', CityBuildingType.granary),
      mapTiles,
    );

    final cityWithBuildingQueue = building.state.cities.single;
    expect(
      cityWithBuildingQueue.productionQueue?.target,
      const BuildingProductionTarget(CityBuildingType.granary),
    );
    expect(building.state.selection?.city, same(cityWithBuildingQueue));

    final unit = CityProductionReducer.startUnitProduction(
      _stateWithSelectedCity(city),
      const StartUnitProductionCommand('city_1', GameUnitType.warrior),
      mapView,
    );

    final cityWithUnitQueue = unit.state.cities.single;
    expect(
      cityWithUnitQueue.productionQueue,
      CityProductionQueue.unit(
        unitType: GameUnitType.warrior,
        investedProduction: 0,
      ),
    );
    expect(unit.state.selection?.city, same(cityWithUnitQueue));
  });

  test(
    'rushes production and refreshes selection through canonical lookup',
    () {
      final city = _city.copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 5,
        ),
      );
      final state = _stateWithSelectedCity(
        city,
        playerGold: const {'player_1': 2},
      );

      final result = CityProductionReducer.rushProduction(
        state,
        const RushProductionCommand('city_1'),
        mapTiles,
        context: const GameCommandContext(paceBalance: PaceBalance.long120),
      );

      final updatedCity = result.state.cities.single;
      expect(updatedCity.buildings, contains(CityBuildingType.granary));
      expect(updatedCity.productionQueue, isNull);
      expect(result.state.playerGold['player_1'], 0);
      expect(result.state.selection?.city, same(updatedCity));
      expect(result.events.single, isA<CityBuiltBuildingEvent>());
    },
  );

  test('queues a map-dependent wonder through canonical lookup', () {
    final desertMapTiles = WorldMapReadView(
      _worldMap(centerTerrain: TerrainType.desert),
    );
    final state = _stateWithSelectedCity(
      _city,
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.stoneworking},
          ),
        },
      ),
    );

    final result = CityProductionReducer.startWonder(
      state,
      const StartWonderCommand('city_1', WonderType.petra),
      desertMapTiles,
    );

    final updatedCity = result.state.cities.single;
    expect(
      updatedCity.productionQueue?.target,
      const WonderProductionTarget(WonderType.petra),
    );
    expect(result.state.selection?.city, same(updatedCity));
  });

  test('updates worked hex and selection through canonical lookup', () {
    const city = _city;
    final state = _stateWithSelectedCity(city);

    final result = CityWorkedHexReducer.toggleWorkedHex(
      state,
      const ToggleWorkedHexCommand('city_1', 2, 1),
      mapTiles,
      context: const GameCommandContext(paceBalance: PaceBalance.long120),
    );

    final updatedCity = result.state.cities.single;
    expect(updatedCity.workedHexes, const [CityHex(col: 2, row: 1)]);
    expect(result.state.selection?.city, same(updatedCity));
    expect(result.state.selection?.cityTileYieldBreakdown, isNotNull);
    expect(
      result.state.selection?.cityEconomy?.growthCost,
      CityGrowthRules.growthCost(updatedCity, paceBalance: PaceBalance.long120),
    );
  });

  test('preserves local sandbox authorization around worked-hex kernel', () {
    final city = _city.copyWith(ownerPlayerId: 'player_2');
    final sandboxState = _stateWithSelectedCity(
      city,
    ).copyWith(activePlayerId: '');

    final accepted = CityWorkedHexReducer.toggleWorkedHex(
      sandboxState,
      const ToggleWorkedHexCommand('city_1', 2, 1),
      mapTiles,
    );
    final blocked = CityWorkedHexReducer.toggleWorkedHex(
      sandboxState,
      const ToggleWorkedHexCommand('city_1', 2, 1),
      mapTiles,
      context: const GameCommandContext(canAct: false),
    );

    expect(accepted.state.cities.single.workedHexes, const [
      CityHex(col: 2, row: 1),
    ]);
    expect(blocked.state, same(sandboxState));
  });

  test('forwards the injected worked-hex limit to the kernel', () {
    final city = _city.copyWith(
      population: 1,
      controlledHexes: const [
        CityHex(col: 1, row: 1),
        CityHex(col: 2, row: 1),
        CityHex(col: 3, row: 1),
      ],
      workedHexes: const [CityHex(col: 2, row: 1)],
    );
    final state = _stateWithSelectedCity(city);
    final ruleset = GameRuleset.defaults.copyWith(
      city: CityRulesets.standard.copyWith(
        progression: _twoWorkedHexProgression,
      ),
    );

    final defaultLimit = CityWorkedHexReducer.toggleWorkedHex(
      state,
      const ToggleWorkedHexCommand('city_1', 3, 1),
      mapTiles,
    );
    final injectedLimit = CityWorkedHexReducer.toggleWorkedHex(
      state,
      const ToggleWorkedHexCommand('city_1', 3, 1),
      mapTiles,
      ruleset: ruleset,
    );

    expect(defaultLimit.state, same(state));
    expect(injectedLimit.state.cities.single.workedHexes, const [
      CityHex(col: 2, row: 1),
      CityHex(col: 3, row: 1),
    ]);
  });
}

const _twoWorkedHexProgression = CityProgression(
  startPopulation: 3,
  startStoredFood: 0,
  startMaxHexes: 6,
  midGameMaxHexes: 8,
  lateGameMaxHexes: 10,
  startTerritoryRadius: 2,
  expandedTerritoryRadius: 3,
  foodUpkeepPerPopulation: 1,
  growthBaseCost: 10,
  growthCostPerPopulation: 4,
  growthCostPerControlledHex: 3,
  workedHexLimitBase: 2,
  workedHexesPerPopulation: 0,
);

const _city = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'City',
  center: CityHex(col: 1, row: 1),
  controlledHexes: [CityHex(col: 1, row: 1), CityHex(col: 2, row: 1)],
);

GameState _stateWithSelectedCity(
  GameCity city, {
  Map<String, int> playerGold = const {},
  ResearchState research = ResearchState.empty,
}) {
  return GameState(
    cities: [city],
    activePlayerId: 'player_1',
    playerGold: playerGold,
    research: research,
    interaction: GameInteractionState(
      selection: GameSelection.city(
        city,
        cityYield: TileYield.zero,
        playerColor: 0xFF123456,
      ),
    ),
  );
}

WorldMap _worldMap({TerrainType centerTerrain = TerrainType.plains}) {
  return WorldMap(
    cols: 4,
    rows: 4,
    tiles: [
      for (var row = 0; row < 4; row += 1)
        for (var col = 0; col < 4; col += 1)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: [
              if (col == 1 && row == 1) centerTerrain else TerrainType.plains,
            ],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
