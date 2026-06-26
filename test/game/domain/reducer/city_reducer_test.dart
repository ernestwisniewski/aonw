import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_founding_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/unit/unit_attachment_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

/// 7x7 plains map — large enough for city territory selection.
MapData _map7x7() => MapData(
  cols: 7,
  rows: 7,
  tiles: [
    for (int row = 0; row < 7; row++)
      for (int col = 0; col < 7; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

MapData _map7x7WithTerrain(int col, int row, TerrainType terrain) {
  final map = _map7x7();
  final index = map.tiles.indexWhere(
    (tile) => tile.col == col && tile.row == row,
  );
  map.tiles[index] = map.tiles[index].copyWith(terrains: [terrain]);
  return map;
}

/// A settler unit (commander with one settler troop).
GameUnit _settler({int col = 3, int row = 3}) => GameUnit.startingCommander(
  ownerPlayerId: 'player_1',
  col: col,
  row: row,
  army: const [ArmyTroop(type: TroopType.settler, count: 1)],
);

/// A standalone settler detached from a commander army.
GameUnit _standaloneSettler({int col = 3, int row = 3}) => GameUnit.produced(
  id: 'settler_player_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.settler,
  col: col,
  row: row,
);

/// A plain commander unit (no settlers).
GameUnit _commander({int col = 0, int row = 0}) =>
    GameUnit.startingCommander(ownerPlayerId: 'player_1', col: col, row: row);

/// A simple city with empty controlledHexes (for building tests).
GameCity _city({
  String id = 'city_1',
  String ownerPlayerId = 'player_1',
  int col = 1,
  int row = 1,
  Set<CityBuildingType> buildings = const {},
}) => GameCity(
  id: id,
  ownerPlayerId: ownerPlayerId,
  name: 'City',
  center: CityHex(col: col, row: row),
  controlledHexes: const [],
  buildings: buildings,
);

GameState _withCompleteFoundingDraft(GameState state) {
  final draft = state.cityFoundingDraft!;
  return state.copyWith(
    cityFoundingDraft: draft.copyWith(
      controlledHexes: const [CityHex(col: 3, row: 2), CityHex(col: 4, row: 3)],
    ),
  );
}

void main() {
  late MapData mapData;

  setUp(() {
    mapData = _map7x7();
  });

  group('startCityFounding', () {
    test('creates draft for valid settler unit', () {
      final settler = _settler();
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(settler),
      );

      final next = CityFoundingReducer.startCityFounding(state, mapData);

      expect(next.cityFoundingDraft, isNotNull);
      expect(next.cityFoundingDraft!.unitId, settler.id);
      expect(next.cityFoundingDraft!.ownerPlayerId, 'player_1');
      expect(next.cityFoundingDraft!.controlledHexes, isEmpty);
    });

    test('creates draft for standalone settler unit', () {
      final settler = _standaloneSettler();
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(settler),
      );

      final next = CityFoundingReducer.startCityFounding(state, mapData);

      expect(next.cityFoundingDraft, isNotNull);
      expect(next.cityFoundingDraft!.unitId, settler.id);
      expect(next.cityFoundingDraft!.ownerPlayerId, 'player_1');
    });

    test('tile taps add and remove controlled hexes in the founding draft', () {
      final settler = _settler();
      final started = CityFoundingReducer.startCityFounding(
        GameState(
          units: [settler],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(settler),
        ),
        mapData,
      );

      final withHex = CityFoundingReducer.toggleControlledHex(
        started,
        const TileTappedCommand(3, 2),
        mapData,
      );
      final withoutHex = CityFoundingReducer.toggleControlledHex(
        withHex,
        const TileTappedCommand(3, 2),
        mapData,
      );

      expect(withHex.cityFoundingDraft!.controlledHexes, const [
        CityHex(col: 3, row: 2),
      ]);
      expect(withoutHex.cityFoundingDraft!.controlledHexes, isEmpty);
    });

    test('tile taps do not add more than required controlled hexes', () {
      final settler = _settler();
      final started = CityFoundingReducer.startCityFounding(
        GameState(
          units: [settler],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(settler),
        ),
        mapData,
      );
      final full = _withCompleteFoundingDraft(started);

      final next = CityFoundingReducer.toggleControlledHex(
        full,
        const TileTappedCommand(2, 3),
        mapData,
      );

      expect(next, same(full));
    });

    test('clears moveCommandActive and movePreview', () {
      final settler = _settler();
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(settler),
        moveCommandActive: true,
      );

      final next = CityFoundingReducer.startCityFounding(state, mapData);

      expect(next.moveCommandActive, isFalse);
      expect(next.movePreview, isNull);
    });

    test('returns unchanged state for non-commander unit', () {
      final commander = _commander();
      final state = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(commander),
      );

      final next = CityFoundingReducer.startCityFounding(state, mapData);

      expect(next, same(state));
    });

    test('returns unchanged state when no unit selected', () {
      const state = GameState(activePlayerId: 'player_1');

      final next = CityFoundingReducer.startCityFounding(state, mapData);

      expect(next, same(state));
    });

    test('returns unchanged state when unit is not controllable', () {
      final settler = _settler();
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_2',
        selection: GameSelection.unit(settler),
      );

      final next = CityFoundingReducer.startCityFounding(state, mapData);

      expect(next, same(state));
    });
  });

  group('cancelCityFounding', () {
    test('clears cityFoundingDraft', () {
      final settler = _settler();
      final draft = CityFoundingDraft(
        unitId: settler.id,
        ownerPlayerId: 'player_1',
        center: CityHex(col: settler.col, row: settler.row),
        controlledHexes: [
          const CityHex(col: 3, row: 2),
          const CityHex(col: 4, row: 3),
        ],
      );
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        cityFoundingDraft: draft,
      );

      final next = CityFoundingReducer.cancelCityFounding(state);

      expect(next.cityFoundingDraft, isNull);
    });

    test('leaves other state fields unchanged', () {
      final settler = _settler();
      final draft = CityFoundingDraft(
        unitId: settler.id,
        ownerPlayerId: 'player_1',
        center: CityHex(col: settler.col, row: settler.row),
        controlledHexes: [
          const CityHex(col: 3, row: 2),
          const CityHex(col: 4, row: 3),
        ],
      );
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(settler),
        cityFoundingDraft: draft,
      );

      final next = CityFoundingReducer.cancelCityFounding(state);

      expect(next.units, state.units);
      expect(next.activePlayerId, state.activePlayerId);
      expect(next.selection, state.selection);
    });
  });

  group('confirmCityFounding', () {
    test('starts founding job for commander with settler troop', () {
      final settler = _settler();
      final stateWithDraft = _withCompleteFoundingDraft(
        CityFoundingReducer.startCityFounding(
          GameState(
            units: [settler],
            activePlayerId: 'player_1',
            selection: GameSelection.unit(settler),
          ),
          mapData,
        ),
      );
      expect(stateWithDraft.cityFoundingDraft, isNotNull);

      final result = CityFoundingReducer.confirmCityFounding(
        stateWithDraft,
        mapData,
      );

      expect(result.events, isEmpty);
      expect(result.state.cities, isEmpty);
      expect(result.state.cityFoundingDraft, isNull);
      expect(result.state.units.single.hasSettlers, isTrue);
      expect(result.state.units.single.cityFoundingJob, isNotNull);
      expect(result.state.units.single.movementPoints, 0);
    });

    test('starts founding job for standalone settler unit', () {
      final settler = _standaloneSettler();
      final stateWithDraft = _withCompleteFoundingDraft(
        CityFoundingReducer.startCityFounding(
          GameState(
            units: [settler],
            activePlayerId: 'player_1',
            selection: GameSelection.unit(settler),
          ),
          mapData,
        ),
      );
      expect(stateWithDraft.cityFoundingDraft, isNotNull);

      final result = CityFoundingReducer.confirmCityFounding(
        stateWithDraft,
        mapData,
      );

      expect(result.events, isEmpty);
      expect(result.state.cities, isEmpty);
      expect(result.state.cityFoundingDraft, isNull);
      expect(result.state.units.single.cityFoundingJob, isNotNull);
      expect(result.state.selection?.unit?.cityFoundingJob, isNotNull);
    });

    test(
      'uses injected city ruleset progression when founding job completes',
      () {
        final ruleset = CityRulesets.standard.copyWith(
          progression: const CityProgression(
            startPopulation: 5,
            startStoredFood: 2,
            startMaxHexes: 9,
            midGameMaxHexes: 10,
            lateGameMaxHexes: 12,
            startTerritoryRadius: 4,
            expandedTerritoryRadius: 5,
            foodUpkeepPerPopulation: 1,
            growthBaseCost: 10,
            growthCostPerPopulation: 4,
            growthCostPerControlledHex: 3,
          ),
        );
        final settler = _settler();
        final stateWithDraft = _withCompleteFoundingDraft(
          CityFoundingReducer.startCityFounding(
            GameState(
              units: [settler],
              activePlayerId: 'player_1',
              selection: GameSelection.unit(settler),
            ),
            mapData,
          ),
        );
        final scheduled = CityFoundingReducer.confirmCityFounding(
          stateWithDraft,
          mapData,
          cityRuleset: ruleset,
        );
        final result = CityFoundingJobProcessor.advanceForPlayer(
          playerId: 'player_1',
          units: scheduled.state.units,
          cities: scheduled.state.cities,
          mapData: mapData,
          countryForPlayer: scheduled.state.countryForPlayer,
          cityRuleset: ruleset,
        );

        final city = result.cities.single;
        expect(city.population, 5);
        expect(city.storedFood, 2);
        expect(city.maxHexes, 9);
        expect(city.territoryRadius, 4);
      },
    );

    test('returns unchanged state when draft is null', () {
      final settler = _settler();
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(settler),
      );

      final result = CityFoundingReducer.confirmCityFounding(state, mapData);

      expect(result.state, same(state));
    });

    test('can finalise founding from persisted draft without selection', () {
      final settler = _settler();
      final draft = CityFoundingDraft(
        unitId: settler.id,
        ownerPlayerId: 'player_1',
        center: CityHex(col: settler.col, row: settler.row),
        controlledHexes: [
          const CityHex(col: 3, row: 2),
          const CityHex(col: 4, row: 3),
        ],
      );
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        cityFoundingDraft: draft,
      );

      final result = CityFoundingReducer.confirmCityFounding(state, mapData);

      expect(result.state.cityFoundingDraft, isNull);
      expect(result.state.cities, isEmpty);
      expect(result.state.units.single.cityFoundingJob, isNotNull);
    });
  });

  group('startBuilding', () {
    test('starts production in city', () {
      final city = _city();
      final state = GameState(cities: [city], activePlayerId: 'player_1');
      const command = StartBuildingCommand('city_1', CityBuildingType.granary);

      final result = CityProductionReducer.startBuilding(
        state,
        command,
        mapData,
      );

      expect(result.state.cities.first.productionQueue, isNotNull);
      expect(
        result.state.cities.first.productionQueue!.target,
        const BuildingProductionTarget(CityBuildingType.granary),
      );
      expect(result.state.cities.first.productionQueue!.investedProduction, 0);
    });

    test('applies capped overflow when starting the next production', () {
      final city = _city().copyWith(productionOverflow: 6);
      final state = GameState(cities: [city], activePlayerId: 'player_1');

      final result = CityProductionReducer.startBuilding(
        state,
        const StartBuildingCommand('city_1', CityBuildingType.granary),
        mapData,
        context: const GameCommandContext(paceBalance: PaceBalance.long120),
      );

      final updatedCity = result.state.cities.single;
      expect(
        updatedCity.productionQueue,
        CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 3,
        ),
      );
      expect(updatedCity.productionOverflow, 0);
    });

    test('returns unchanged state when city not found', () {
      const state = GameState(activePlayerId: 'player_1');
      const command = StartBuildingCommand('no_city', CityBuildingType.granary);

      final result = CityProductionReducer.startBuilding(
        state,
        command,
        mapData,
      );

      expect(result.state, same(state));
    });

    test('returns unchanged state when building already built', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        buildings: {CityBuildingType.granary},
      );
      const state = GameState(cities: [city], activePlayerId: 'player_1');
      const command = StartBuildingCommand('city_1', CityBuildingType.granary);

      final result = CityProductionReducer.startBuilding(
        state,
        command,
        mapData,
      );

      expect(result.state, same(state));
    });

    test('returns unchanged state when building technology is locked', () {
      final city = _city();
      final state = GameState(cities: [city], activePlayerId: 'player_1');
      const command = StartBuildingCommand('city_1', CityBuildingType.workshop);

      final result = CityProductionReducer.startBuilding(
        state,
        command,
        mapData,
      );

      expect(result.state, same(state));
    });

    test('starts technology building when unlock is researched', () {
      final city = _city();
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.craftsmanship},
          ),
        },
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: research,
      );
      const command = StartBuildingCommand('city_1', CityBuildingType.workshop);

      final result = CityProductionReducer.startBuilding(
        state,
        command,
        mapData,
      );

      expect(
        result.state.cities.first.productionQueue?.target,
        const BuildingProductionTarget(CityBuildingType.workshop),
      );
    });

    test('returns unchanged state when coastal requirement is missing', () {
      final city = _city();
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.navigation},
          ),
        },
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: research,
      );
      const command = StartBuildingCommand('city_1', CityBuildingType.port);

      final result = CityProductionReducer.startBuilding(
        state,
        command,
        mapData,
      );

      expect(result.state, same(state));
    });

    test('starts coastal building when city has coastal access', () {
      final city = _city();
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.navigation},
          ),
        },
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: research,
      );
      final coastalMap = _map7x7WithTerrain(1, 1, TerrainType.coast);

      final result = CityProductionReducer.startBuilding(
        state,
        const StartBuildingCommand('city_1', CityBuildingType.port),
        coastalMap,
      );

      expect(
        result.state.cities.first.productionQueue?.target,
        const BuildingProductionTarget(CityBuildingType.port),
      );
    });

    test('keeps existing production progress when replacing queue', () {
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 2,
        ),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.craftsmanship},
          ),
        },
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: research,
      );

      final result = CityProductionReducer.startBuilding(
        state,
        const StartBuildingCommand('city_1', CityBuildingType.workshop),
        mapData,
      );

      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.building(
          buildingType: CityBuildingType.workshop,
          investedProduction: 2,
        ),
      );
    });

    test('updates selection when city is currently selected', () {
      final city = _city();
      final cityYield = CityYieldCalculator.totalFor(city, mapData);
      final cityEconomy = CityEconomyBreakdown.from(
        city: city,
        tileYield: cityYield,
        mapData: mapData,
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        selection: GameSelection.city(
          city,
          cityYield: cityYield,
          cityEconomy: cityEconomy,
          playerColor: 0xFFFF0000,
        ),
      );
      const command = StartBuildingCommand('city_1', CityBuildingType.granary);

      final result = CityProductionReducer.startBuilding(
        state,
        command,
        mapData,
      );

      final selectedCity = result.state.selection?.city;
      expect(selectedCity, isNotNull);
      expect(selectedCity!.productionQueue, isNotNull);
      expect(
        selectedCity.productionQueue!.target,
        const BuildingProductionTarget(CityBuildingType.granary),
      );
    });

    test('does not update selection when a different city is selected', () {
      final city1 = _city(id: 'city_1', col: 1, row: 1);
      final city2 = _city(id: 'city_2', col: 5, row: 5);
      final cityYield = CityYieldCalculator.totalFor(city2, mapData);
      final cityEconomy = CityEconomyBreakdown.from(
        city: city2,
        tileYield: cityYield,
        mapData: mapData,
      );
      final state = GameState(
        cities: [city1, city2],
        activePlayerId: 'player_1',
        selection: GameSelection.city(
          city2,
          cityYield: cityYield,
          cityEconomy: cityEconomy,
          playerColor: 0xFFFF0000,
        ),
      );
      const command = StartBuildingCommand('city_1', CityBuildingType.granary);

      final result = CityProductionReducer.startBuilding(
        state,
        command,
        mapData,
      );

      expect(result.state.selection?.city?.id, 'city_2');
    });
  });

  group('startUnitProduction', () {
    test('starts production of a base unit in city', () {
      final city = _city();
      final state = GameState(cities: [city], activePlayerId: 'player_1');
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );

      final result = CityProductionReducer.startUnitProduction(
        state,
        command,
        mapData,
      );

      expect(
        result.state.cities.first.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 0,
        ),
      );
    });

    test('returns unchanged state when unit technology is locked', () {
      final city = _city();
      final state = GameState(cities: [city], activePlayerId: 'player_1');
      const command = StartUnitProductionCommand('city_1', GameUnitType.archer);

      final result = CityProductionReducer.startUnitProduction(
        state,
        command,
        mapData,
      );

      expect(result.state, same(state));
    });

    test('returns unchanged state when food supply is full', () {
      final city = _city();
      final state = GameState(
        cities: [city],
        units: [
          for (var i = 0; i < 3; i++)
            GameUnit.produced(
              id: 'worker_$i',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: i,
              row: 0,
            ),
        ],
        activePlayerId: 'player_1',
      );

      final result = CityProductionReducer.startUnitProduction(
        state,
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        mapData,
      );

      expect(result.state, same(state));
    });

    test('starts technology unit when unlock is researched', () {
      final city = _city();
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.hunting},
          ),
        },
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: research,
      );
      const command = StartUnitProductionCommand('city_1', GameUnitType.archer);

      final result = CityProductionReducer.startUnitProduction(
        state,
        command,
        mapData,
      );

      expect(
        result.state.cities.first.productionQueue?.target,
        const UnitProductionTarget(GameUnitType.archer),
      );
    });

    test('starts merchant production only after trade is researched', () {
      final city = _city();
      final lockedState = GameState(cities: [city], activePlayerId: 'player_1');
      final unlockedState = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.trade},
            ),
          },
        ),
      );
      const command = StartUnitProductionCommand(
        'city_1',
        GameUnitType.merchant,
      );

      final lockedResult = CityProductionReducer.startUnitProduction(
        lockedState,
        command,
        mapData,
      );
      final unlockedResult = CityProductionReducer.startUnitProduction(
        unlockedState,
        command,
        mapData,
      );

      expect(lockedResult.state, same(lockedState));
      expect(
        unlockedResult.state.cities.first.productionQueue?.target,
        const UnitProductionTarget(GameUnitType.merchant),
      );
    });

    test('starts resource-gated unit production with imported resource', () {
      final city = _city();
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.horsebackRiding},
            ),
          },
        ),
        resourceTradeAgreements: const [
          ResourceTradeAgreement(
            id: 'trade_1',
            exporterPlayerId: 'player_2',
            importerPlayerId: 'player_1',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            remainingTurns: 5,
          ),
        ],
      );

      final result = CityProductionReducer.startUnitProduction(
        state,
        const StartUnitProductionCommand('city_1', GameUnitType.cavalry),
        mapData,
      );

      expect(
        result.state.cities.first.productionQueue?.target,
        const UnitProductionTarget(GameUnitType.cavalry),
      );
    });

    test('does not start naval production without a coast spawn hex', () {
      final city = _city();
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.cartography},
          ),
        },
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: research,
      );

      final result = CityProductionReducer.startUnitProduction(
        state,
        const StartUnitProductionCommand('city_1', GameUnitType.scoutShip),
        mapData,
      );

      expect(result.state, same(state));
    });

    test(
      'starts naval production when city has an ocean-adjacent coast spawn hex',
      () {
        final city = _city();
        final research = ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.cartography},
            ),
          },
        );
        final state = GameState(
          cities: [city],
          activePlayerId: 'player_1',
          research: research,
        );
        final coastalMap = _map7x7WithTerrain(2, 1, TerrainType.coast);
        final oceanIndex = coastalMap.tiles.indexWhere(
          (tile) => tile.col == 3 && tile.row == 1,
        );
        coastalMap.tiles[oceanIndex] = coastalMap.tiles[oceanIndex].copyWith(
          terrains: const [TerrainType.ocean],
        );

        final result = CityProductionReducer.startUnitProduction(
          state,
          const StartUnitProductionCommand('city_1', GameUnitType.scoutShip),
          coastalMap,
        );

        expect(
          result.state.cities.single.productionQueue,
          CityProductionQueue.unit(
            unitType: GameUnitType.scoutShip,
            investedProduction: 0,
          ),
        );
      },
    );

    test('keeps existing production progress when replacing queue', () {
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 2,
        ),
      );
      final state = GameState(cities: [city], activePlayerId: 'player_1');

      final result = CityProductionReducer.startUnitProduction(
        state,
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        mapData,
      );

      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 2,
        ),
      );
    });

    test('updates selection when city is currently selected', () {
      final city = _city();
      final cityYield = CityYieldCalculator.totalFor(city, mapData);
      final cityEconomy = CityEconomyBreakdown.from(
        city: city,
        tileYield: cityYield,
        mapData: mapData,
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        selection: GameSelection.city(
          city,
          cityYield: cityYield,
          cityEconomy: cityEconomy,
          playerColor: 0xFFFF0000,
        ),
      );

      final result = CityProductionReducer.startUnitProduction(
        state,
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        mapData,
      );

      expect(
        result.state.selection?.city?.productionQueue?.target,
        const UnitProductionTarget(GameUnitType.warrior),
      );
    });
  });

  group('rushProduction', () {
    test('spends gold to finish an active building queue', () {
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 5,
        ),
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        playerGold: const {'player_1': 2},
      );

      final result = CityProductionReducer.rushProduction(
        state,
        const RushProductionCommand('city_1'),
        mapData,
        context: const GameCommandContext(paceBalance: PaceBalance.long120),
      );

      final updatedCity = result.state.cities.single;
      expect(updatedCity.buildings, contains(CityBuildingType.granary));
      expect(updatedCity.productionQueue, isNull);
      expect(result.state.playerGold['player_1'], 0);
      expect(result.events.single, isA<CityBuiltBuildingEvent>());
    });

    test('keeps state unchanged when treasury cannot pay rush cost', () {
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 7,
        ),
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        playerGold: const {'player_1': 1},
      );

      final result = CityProductionReducer.rushProduction(
        state,
        const RushProductionCommand('city_1'),
        mapData,
      );

      expect(result.state, same(state));
      expect(result.events, isEmpty);
    });
  });

  group('detachTroop', () {
    test('successfully detaches a warrior troop', () {
      // Commander at (3,3) with a warrior troop — uses 7x7 map so neighbors exist.
      // Use activePlayerId: '' to disable fog (otherwise empty fog hides all tiles).
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 3,
        row: 3,
        army: const [
          ArmyTroop(type: TroopType.warrior, count: 2),
          ArmyTroop(type: TroopType.archer, count: 1),
        ],
      );
      final state = GameState(
        units: [commander],
        activePlayerId: '',
        selection: GameSelection.unit(commander),
      );
      final command = DetachTroopCommand(commander.id, TroopType.warrior);

      final result = UnitAttachmentReducer.detachTroop(state, command, mapData);

      expect(result.state.units, hasLength(2));
      final updatedSource = result.state.units.firstWhere(
        (u) => u.id == commander.id,
      );
      final detached = result.state.units.firstWhere(
        (unit) => unit.type == GameUnitType.warrior,
      );
      expect(updatedSource.troopCount(TroopType.warrior), 1);
      expect(updatedSource.troopCount(TroopType.archer), 1);
      expect(detached.id, 'commander_player_1_warrior_1');
      expect(detached.col, 4);
      expect(detached.row, 3);
    });

    test('returns unchanged state when unit not found', () {
      const state = GameState(activePlayerId: 'player_1');
      const command = DetachTroopCommand('ghost_unit', TroopType.warrior);

      final result = UnitAttachmentReducer.detachTroop(state, command, mapData);

      expect(result.state, same(state));
    });

    test('returns unchanged state when unit is not controllable', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 3,
        row: 3,
        army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
      );
      final state = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(commander),
      );
      final command = DetachTroopCommand(commander.id, TroopType.warrior);

      final result = UnitAttachmentReducer.detachTroop(state, command, mapData);

      expect(result.state, same(state));
    });

    test('updates selection to the updated source unit', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 3,
        row: 3,
        army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
      );
      final state = GameState(
        units: [commander],
        activePlayerId: '',
        selection: GameSelection.unit(commander),
      );
      final command = DetachTroopCommand(commander.id, TroopType.warrior);

      final result = UnitAttachmentReducer.detachTroop(state, command, mapData);

      expect(result.state.selection?.type, GameSelectionType.unit);
      expect(result.state.selection?.unit?.id, commander.id);
    });

    test('clears move/founding state', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 3,
        row: 3,
        army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
      );
      final state = GameState(
        units: [commander],
        activePlayerId: '',
        selection: GameSelection.unit(commander),
        moveCommandActive: true,
      );
      final command = DetachTroopCommand(commander.id, TroopType.warrior);

      final result = UnitAttachmentReducer.detachTroop(state, command, mapData);

      expect(result.state.moveCommandActive, isFalse);
      expect(result.state.cityFoundingDraft, isNull);
    });
  });

  group('GameStateReducer integration', () {
    late GameStateReducer reducer;

    setUp(() {
      reducer = GameStateReducer(mapData: mapData);
    });

    test('StartCityFoundingCommand creates draft', () {
      final settler = _settler();
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        selection: GameSelection.unit(settler),
      );

      final result = reducer.reduce(state, const StartCityFoundingCommand());

      expect(result.state.cityFoundingDraft, isNotNull);
    });

    test('TileTappedCommand updates city founding draft hex selection', () {
      final settler = _settler();
      final started = reducer
          .reduce(
            GameState(
              units: [settler],
              activePlayerId: 'player_1',
              selection: GameSelection.unit(settler),
            ),
            const StartCityFoundingCommand(),
          )
          .state;
      final visibleStarted = started.copyWith(
        fogOfWar: const FogOfWarService().recompute(
          current: started.fogOfWar,
          mapData: mapData,
          playerIds: const {'player_1'},
          units: started.units,
          cities: started.cities,
        ),
      );

      final result = reducer.reduce(
        visibleStarted,
        const TileTappedCommand(3, 2),
      );

      expect(result.state.cityFoundingDraft!.controlledHexes, const [
        CityHex(col: 3, row: 2),
      ]);
    });

    test('CancelCityFoundingCommand clears draft', () {
      final settler = _settler();
      final draft = CityFoundingDraft(
        unitId: settler.id,
        ownerPlayerId: 'player_1',
        center: CityHex(col: settler.col, row: settler.row),
        controlledHexes: [
          const CityHex(col: 3, row: 2),
          const CityHex(col: 4, row: 3),
        ],
      );
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        cityFoundingDraft: draft,
      );

      final result = reducer.reduce(state, const CancelCityFoundingCommand());

      expect(result.state.cityFoundingDraft, isNull);
    });

    test('FoundCityCommand starts founding job', () {
      final settler = _settler();
      final stateWithDraft = _withCompleteFoundingDraft(
        CityFoundingReducer.startCityFounding(
          GameState(
            units: [settler],
            activePlayerId: 'player_1',
            selection: GameSelection.unit(settler),
          ),
          mapData,
        ),
      );

      final result = reducer.reduce(
        stateWithDraft,
        FoundCityCommand(settler.id),
      );

      expect(result.state.cities, isEmpty);
      expect(result.state.units.single.cityFoundingJob, isNotNull);
    });

    test('StartBuildingCommand starts production', () {
      final city = _city();
      final state = GameState(cities: [city], activePlayerId: 'player_1');

      final result = reducer.reduce(
        state,
        const StartBuildingCommand('city_1', CityBuildingType.granary),
      );

      expect(result.state.cities.first.productionQueue, isNotNull);
    });

    test('StartUnitProductionCommand starts production', () {
      final city = _city();
      final state = GameState(cities: [city], activePlayerId: 'player_1');

      final result = reducer.reduce(
        state,
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
      );

      expect(result.state.cities.first.productionQueue, isNotNull);
      expect(
        result.state.cities.first.productionQueue?.target,
        const UnitProductionTarget(GameUnitType.warrior),
      );
    });

    test('StartCityProjectCommand starts continuous city project', () {
      final city = _city();
      final state = GameState(cities: [city], activePlayerId: 'player_1');

      final result = reducer.reduce(
        state,
        const StartCityProjectCommand('city_1', CityProjectType.wealth),
      );

      expect(
        result.state.cities.first.productionQueue,
        CityProductionQueue.project(projectType: CityProjectType.wealth),
      );
    });

    test('SetCitySpecializationCommand sets unlocked city specialization', () {
      final city = _city(buildings: {CityBuildingType.merchantHall});
      final cityYield = CityYieldCalculator.totalFor(city, mapData);
      final cityEconomy = CityEconomyBreakdown.from(
        city: city,
        tileYield: cityYield,
        mapData: mapData,
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.specialization},
            ),
          },
        ),
        selection: GameSelection.city(
          city,
          cityYield: cityYield,
          cityEconomy: cityEconomy,
          playerColor: 0xFFFF0000,
        ),
      );

      final result = reducer.reduce(
        state,
        const SetCitySpecializationCommand(
          'city_1',
          CitySpecializationType.commerce,
        ),
      );

      expect(
        result.state.cities.first.specialization,
        CitySpecializationType.commerce,
      );
      expect(
        result.state.selection?.city?.specialization,
        CitySpecializationType.commerce,
      );
    });

    test(
      'SetCitySpecializationCommand is ignored before technology unlock',
      () {
        final city = _city(buildings: {CityBuildingType.merchantHall});
        final state = GameState(cities: [city], activePlayerId: 'player_1');

        final result = reducer.reduce(
          state,
          const SetCitySpecializationCommand(
            'city_1',
            CitySpecializationType.commerce,
          ),
        );

        expect(result.state, state);
      },
    );

    test(
      'SetCitySpecializationCommand is ignored without required building',
      () {
        final city = _city();
        final state = GameState(
          cities: [city],
          activePlayerId: 'player_1',
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {TechnologyId.specialization},
              ),
            },
          ),
        );

        final result = reducer.reduce(
          state,
          const SetCitySpecializationCommand(
            'city_1',
            CitySpecializationType.commerce,
          ),
        );

        expect(result.state, state);
      },
    );
  });
}
