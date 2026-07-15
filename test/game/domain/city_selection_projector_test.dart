import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CitySelectionProjector', () {
    test('includes a stored artifact in city yield and gross economy', () {
      const city = GameCity(
        id: 'selected_city',
        ownerPlayerId: 'player_1',
        name: 'Selected',
        center: CityHex(col: 0, row: 0),
      );
      const artifact = WorldArtifact(
        id: 'artifact.merchants_seal',
        type: WorldArtifactType.merchantsSeal,
        location: WorldArtifactLocation.stored(cityId: 'selected_city'),
      );

      final selection = CitySelectionProjector.project(
        state: const GameState(cities: [city], artifacts: [artifact]),
        city: city,
        mapTiles: _mapData(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        wonderRuleset: WonderRuleset.standard,
        paceBalance: PaceBalance.unlimited,
      );

      expect(selection.cityYield?.gold, 2);
      expect(selection.cityEconomy?.grossYield.gold, 2);
    });

    test(
      'uses all cities, the completed registry, and the supplied wonder ruleset',
      () {
        const selectedCity = GameCity(
          id: 'selected_city',
          ownerPlayerId: 'player_1',
          name: 'Selected',
          center: CityHex(col: 0, row: 0),
        );
        const wonderHostCity = GameCity(
          id: 'wonder_host_city',
          ownerPlayerId: 'player_1',
          name: 'Wonder host',
          center: CityHex(col: 1, row: 0),
          wonders: {WonderType.greatLibrary},
        );
        const sentinelRuleset = WonderRuleset(
          wonders: {
            WonderType.greatLibrary: WonderDefinition(
              type: WonderType.greatLibrary,
              productionCost: 120,
              unlockTech: TechnologyId.writing,
              standingEffects: [
                EmpireFlatYieldEffect(
                  TileYield(food: 0, production: 0, gold: 7, defense: 0),
                ),
              ],
            ),
          },
        );
        final completedRegistry = WonderRegistry.empty.complete(
          type: WonderType.greatLibrary,
          playerId: 'player_1',
        );

        final selection = CitySelectionProjector.project(
          state: GameState(
            cities: const [selectedCity, wonderHostCity],
            wonderRegistry: completedRegistry,
          ),
          city: selectedCity,
          mapTiles: _mapData(),
          cityRuleset: CityRulesets.standard,
          technologyRuleset: TechnologyRulesets.standard,
          wonderRuleset: sentinelRuleset,
          paceBalance: PaceBalance.unlimited,
        );

        expect(selection.city?.id, selectedCity.id);
        expect(selection.cityEconomy?.wonderYield.gold, 7);
        expect(selection.cityEconomy?.grossYield.gold, 7);
      },
    );

    test('falls back to the first player palette color', () {
      const city = GameCity(
        id: 'selected_city',
        ownerPlayerId: 'player_without_color',
        name: 'Selected',
        center: CityHex(col: 0, row: 0),
      );

      final selection = CitySelectionProjector.project(
        state: const GameState(cities: [city]),
        city: city,
        mapTiles: _mapData(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        wonderRuleset: WonderRuleset.standard,
        paceBalance: PaceBalance.unlimited,
      );

      expect(selection.cityPlayerColor, Player.palette.first);
    });
  });
}

MapData _mapData() => MapData(
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
