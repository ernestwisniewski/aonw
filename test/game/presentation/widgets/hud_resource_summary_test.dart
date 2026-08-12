import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_economy_forecast.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_summary.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudResourceSummary', () {
    test('returns empty summary without active player', () {
      final summary = HudResourceSummary.fromGameState(
        state: GameClientState(playerGold: {'player_1': 12}),
        playerId: '',
        mapData: _map(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
      );

      expect(summary.gold, 0);
      expect(summary.goldPerTurn, 0);
      expect(summary.sciencePerTurn, 0);
      expect(summary.resourceInventory.totalCount, 0);
    });

    test('uses active player treasury and empty breakdowns by default', () {
      final summary = HudResourceSummary.fromGameState(
        state: GameClientState(playerGold: {'player_1': 12}),
        playerId: 'player_1',
        mapData: _map(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
      );

      expect(summary.gold, 12);
      expect(summary.goldBreakdown.treasury, 12);
      expect(summary.goldIncome, 0);
      expect(summary.unitUpkeep, 0);
      expect(summary.scienceBreakdown.total, 0);
    });

    test('adds wealth project output to gold breakdown', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 0, row: 0),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );

      final summary = HudResourceSummary.fromGameState(
        state: GameClientState(
          cities: [city],
          playerGold: const {'player_1': 12},
        ),
        playerId: 'player_1',
        mapData: _landMap(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
      );

      expect(summary.gold, 12);
      expect(summary.goldIncome, 1);
      expect(summary.goldPerTurn, 1);
      expect(summary.goldBreakdown.cityIncome, 0);
      expect(summary.goldBreakdown.projectIncome, 1);
      expect(summary.goldBreakdown.projectSources.single.city, city);
    });

    test('adds research project output to science breakdown', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 0, row: 0),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
        ),
      );

      final summary = HudResourceSummary.fromGameState(
        state: GameClientState(cities: [city]),
        playerId: 'player_1',
        mapData: _landMap(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
      );

      expect(summary.sciencePerTurn, 3);
      expect(summary.scienceBreakdown.byCityId, {'city_1': 3});
      expect(
        summary.scienceBreakdown.sources.map((source) => source.label),
        containsAll([
          ScienceYieldSourceLabels.cityScience,
          ScienceYieldSourceLabels.cityResearchProject,
        ]),
      );
    });

    test('keeps popup breakdowns lazy after computing strip totals', () {
      final wealthCity = GameCity(
        id: 'wealth_city',
        ownerPlayerId: 'player_1',
        name: 'Wealth',
        center: const CityHex(col: 0, row: 0),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );
      final researchCity = GameCity(
        id: 'research_city',
        ownerPlayerId: 'player_1',
        name: 'Research',
        center: const CityHex(col: 0, row: 0),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
        ),
      );

      final summary = HudResourceSummary.fromGameState(
        state: GameClientState(
          cities: [wealthCity, researchCity],
          playerGold: const {'player_1': 12},
        ),
        playerId: 'player_1',
        mapData: _landMap(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
      );

      expect(summary.gold, 12);
      expect(summary.goldIncome, 1);
      expect(summary.goldPerTurn, 1);
      expect(summary.sciencePerTurn, 5);
      expect(summary.resourceBreakdowns.debugHasComputedGold, isFalse);
      expect(summary.resourceBreakdowns.debugHasComputedScience, isFalse);

      expect(summary.goldBreakdown.projectIncome, 1);
      expect(summary.resourceBreakdowns.debugHasComputedGold, isTrue);
      expect(summary.resourceBreakdowns.debugHasComputedScience, isFalse);

      expect(summary.scienceBreakdown.byCityId, {
        'wealth_city': 2,
        'research_city': 3,
      });
      expect(summary.resourceBreakdowns.debugHasComputedScience, isTrue);
    });

    test(
      'reuses strip economy forecast across interaction-only state changes',
      () {
        final forecastCache = HudResourceEconomyForecastCache();
        final city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: const CityHex(col: 0, row: 0),
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.wealth,
          ),
        );
        final state = GameClientState(
          cities: [city],
          playerGold: const {'player_1': 12},
        );
        final mapData = _landMap();

        final first = HudResourceSummary.fromGameState(
          state: state,
          playerId: 'player_1',
          mapData: mapData,
          cityRuleset: CityRulesets.standard,
          technologyRuleset: TechnologyRulesets.standard,
          economyForecastCache: forecastCache,
        );
        final second = HudResourceSummary.fromGameState(
          state: state.copyWithInteraction(moveCommandActive: true),
          playerId: 'player_1',
          mapData: mapData,
          cityRuleset: CityRulesets.standard,
          technologyRuleset: TechnologyRulesets.standard,
          economyForecastCache: forecastCache,
        );

        expect(first.goldPerTurn, 1);
        expect(second.goldPerTurn, first.goldPerTurn);
        expect(forecastCache.debugComputeCount, 1);
      },
    );

    test('keeps economy forecasts for alternating active players', () {
      final forecastCache = HudResourceEconomyForecastCache();
      final playerCity = GameCity(
        id: 'player_city',
        ownerPlayerId: 'player_1',
        name: 'Player',
        center: const CityHex(col: 0, row: 0),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );
      final opponentCity = GameCity(
        id: 'opponent_city',
        ownerPlayerId: 'player_2',
        name: 'Opponent',
        center: const CityHex(col: 1, row: 0),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
        ),
      );
      final state = GameClientState(
        cities: [playerCity, opponentCity],
        playerGold: const {'player_1': 12, 'player_2': 6},
      );
      final mapData = _twoCityLandMap();

      final playerSummary = HudResourceSummary.fromGameState(
        state: state,
        playerId: 'player_1',
        mapData: mapData,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        economyForecastCache: forecastCache,
      );
      final opponentSummary = HudResourceSummary.fromGameState(
        state: state,
        playerId: 'player_2',
        mapData: mapData,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        economyForecastCache: forecastCache,
      );
      final reusedPlayerSummary = HudResourceSummary.fromGameState(
        state: state,
        playerId: 'player_1',
        mapData: mapData,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        economyForecastCache: forecastCache,
      );

      expect(playerSummary.goldPerTurn, 1);
      expect(opponentSummary.sciencePerTurn, 3);
      expect(reusedPlayerSummary.goldPerTurn, playerSummary.goldPerTurn);
      expect(forecastCache.debugComputeCount, 2);
      expect(forecastCache.debugForecastEntryCount, 2);
    });

    test('reuses unchanged city economy across forecast misses', () {
      final forecastCache = HudResourceEconomyForecastCache();
      const stableCity = GameCity(
        id: 'stable_city',
        ownerPlayerId: 'player_1',
        name: 'Stable',
        center: CityHex(col: 0, row: 0),
        buildings: {CityBuildingType.merchantHall},
      );
      const firstVersionCity = GameCity(
        id: 'changed_city',
        ownerPlayerId: 'player_1',
        name: 'Changed',
        center: CityHex(col: 1, row: 0),
      );
      final secondVersionCity = firstVersionCity.copyWith(
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );
      final mapData = _twoCityLandMap();

      final first = HudResourceSummary.fromGameState(
        state: GameClientState(cities: [stableCity, firstVersionCity]),
        playerId: 'player_1',
        mapData: mapData,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        economyForecastCache: forecastCache,
      );
      final second = HudResourceSummary.fromGameState(
        state: GameClientState(cities: [stableCity, secondVersionCity]),
        playerId: 'player_1',
        mapData: mapData,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        economyForecastCache: forecastCache,
      );

      expect(first.goldIncome, 2);
      expect(second.goldIncome, 3);
      expect(forecastCache.debugComputeCount, 2);
      expect(forecastCache.debugCityEconomyComputeCount, 3);
    });

    test('applies cached unrest to the HUD economy forecast', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
        buildings: {CityBuildingType.merchantHall},
      );

      final summary = HudResourceSummary.fromGameState(
        state: GameClientState(
          cities: [city],
          playerStabilityNet: {'player_1': -4},
        ),
        playerId: 'player_1',
        mapData: _landMap(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
      );

      expect(summary.stabilityBand, StabilityBand.unrest);
      expect(summary.goldIncome, 1);
      expect(summary.stabilityDetails.breakdown.baseOrder, 6);
      expect(summary.stabilityDetails.breakdown.cityCost, 0);
    });

    test('reports strategic stock, allocation, and per-turn flow together', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Refinery City',
        center: const CityHex(col: 0, row: 0),
        population: 8,
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.tank,
          investedProduction: 0,
          resourceAllocation: StrategicResourceBundle.oilTwo,
        ),
      );
      final summary = HudResourceSummary.fromGameState(
        state: GameClientState(
          cities: [city],
          strategicResources: StrategicResourceAccounts(
            byPlayerId: {
              'player_1': StrategicResourceStockpile(
                onHand: StrategicResourceBundle.oilOne,
              ),
            },
          ),
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {
                  TechnologyId.combustion,
                  TechnologyId.massProduction,
                },
              ),
            },
          ),
          fieldImprovements: const [
            FieldImprovement(
              hex: CityHex(col: 0, row: 0),
              type: FieldImprovementType.oilWell,
              builtByCityId: 'city_1',
            ),
          ],
          resourceTradeAgreements: const [
            ResourceTradeAgreement(
              id: 'import_oil',
              exporterPlayerId: 'player_2',
              importerPlayerId: 'player_1',
              resource: ResourceType.oil,
              goldPerTurn: 2,
              remainingTurns: 4,
            ),
            ResourceTradeAgreement(
              id: 'export_oil',
              exporterPlayerId: 'player_1',
              importerPlayerId: 'player_3',
              resource: ResourceType.oil,
              goldPerTurn: 2,
              remainingTurns: 4,
            ),
          ],
        ),
        playerId: 'player_1',
        mapData: _oilMap(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
      );

      final oil = summary.strategicResources.rows.singleWhere(
        (row) => row.resource == ResourceType.oil,
      );
      expect(summary.strategicResources.enabled, isTrue);
      expect(oil.available, 1);
      expect(oil.allocated, 2);
      expect(oil.storedTotal, 3);
      expect(oil.domesticProduction, 1);
      expect(oil.imports, 1);
      expect(oil.exports, 1);
      expect(oil.netPerTurn, 1);
      expect(oil.shortage, isTrue);
      expect(summary.strategicResources.allocations.single.city, city);
    });
  });
}

WorldMap _map() => WorldMap(cols: 1, rows: 1, tiles: []);

WorldMap _landMap() {
  return WorldMap(
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
}

WorldMap _oilMap() => WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: const [TerrainType.plains],
      resources: const [ResourceType.oil],
      height: 0,
    ),
  ],
);

WorldMap _twoCityLandMap() {
  return WorldMap(
    cols: 2,
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
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}
