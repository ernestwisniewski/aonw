import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_summary.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudResourceSummary', () {
    test('returns empty summary without active player', () {
      final summary = HudResourceSummary.fromGameState(
        state: const GameState(playerGold: {'player_1': 12}),
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
        state: const GameState(playerGold: {'player_1': 12}),
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
        state: GameState(cities: [city], playerGold: const {'player_1': 12}),
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
        state: GameState(cities: [city]),
        playerId: 'player_1',
        mapData: _landMap(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
      );

      expect(summary.sciencePerTurn, 3);
      expect(summary.scienceBreakdown.byCityId, {'city_1': 3});
      expect(
        summary.scienceBreakdown.sources.map((source) => source.label),
        containsAll(['City science', 'City research project']),
      );
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
        state: const GameState(
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
  });
}

MapData _map() => MapData(cols: 1, rows: 1, tiles: const []);

MapData _landMap() {
  return MapData(
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
}
