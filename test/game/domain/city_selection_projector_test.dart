import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
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
        state: GameClientState(cities: [city], artifacts: [artifact]),
        city: city,
        mapTiles: _mapData(),
        ruleset: GameRuleset.defaults,
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
          state: GameClientState(
            cities: const [selectedCity, wonderHostCity],
            wonderRegistry: completedRegistry,
          ),
          city: selectedCity,
          mapTiles: _mapData(),
          ruleset: GameRuleset.defaults.copyWith(wonders: sentinelRuleset),
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
        state: GameClientState(cities: [city]),
        city: city,
        mapTiles: _mapData(),
        ruleset: GameRuleset.defaults,
      );

      expect(selection.cityPlayerColor, Player.palette.first);
    });

    test('projects cached owner stability through the supplied ruleset without '
        'changing raw yield', () {
      final cityRuleset = CityRulesets.standard.copyWith(
        cityCenterYield: _stabilityRawYield,
      );

      for (final testCase in _stabilityProjectionCases) {
        final selection = CitySelectionProjector.project(
          state: GameClientState(
            cities: const [_stabilityCity],
            playerStabilityNet: testCase.playerStabilityNet,
            activePlayerId: testCase.activePlayerId,
          ),
          city: _stabilityCity,
          mapTiles: _mapData(),
          ruleset: GameRuleset.defaults.copyWith(
            city: cityRuleset,
            stability: testCase.stabilityRuleset,
          ),
        );
        final economy = selection.cityEconomy!;

        expect(selection.cityYield, _stabilityRawYield, reason: testCase.label);
        expect(economy.tileYield, _stabilityRawYield, reason: testCase.label);
        expect(economy.grossYield, _stabilityRawYield, reason: testCase.label);
        expect(
          economy.stabilityModifier,
          testCase.expectedModifier,
          reason: testCase.label,
        );
        expect(
          economy.netYield,
          TileYield(
            food: 7,
            production: testCase.expectedProduction,
            gold: testCase.expectedGold,
            defense: 2,
          ),
          reason: testCase.label,
        );
        expect(
          economy.foodDeposit,
          testCase.expectedFoodDeposit,
          reason: testCase.label,
        );
      }
    });
  });
}

const _stabilityCity = GameCity(
  id: 'selected_city',
  ownerPlayerId: 'city_owner',
  name: 'Selected',
  population: 1,
  center: CityHex(col: 0, row: 0),
);

const _stabilityRawYield = TileYield(
  food: 8,
  production: 7,
  gold: 7,
  defense: 2,
);

const _contentModifier = StabilityModifier(
  productionMultiplier: 1,
  goldMultiplier: 1,
  foodBonus: 1,
  haltsGrowth: false,
);

const _strainedModifier = StabilityModifier(
  productionMultiplier: 1,
  goldMultiplier: 0.9,
  foodBonus: 0,
  haltsGrowth: true,
);

const _unrestModifier = StabilityModifier(
  productionMultiplier: 0.75,
  goldMultiplier: 0.75,
  foodBonus: 0,
  haltsGrowth: true,
);

final _customStabilityRuleset = StabilityRuleset.standard.copyWith(
  contentThreshold: 5,
  unrestThreshold: -2,
  relativeStandingOffset: 999,
);

final _stabilityProjectionCases =
    <
      ({
        String label,
        Map<String, int> playerStabilityNet,
        String activePlayerId,
        StabilityRuleset stabilityRuleset,
        StabilityModifier expectedModifier,
        int expectedProduction,
        int expectedGold,
        int expectedFoodDeposit,
      })
    >[
      (
        label: 'content',
        playerStabilityNet: const {'city_owner': 4},
        activePlayerId: 'city_owner',
        stabilityRuleset: StabilityRuleset.standard,
        expectedModifier: _contentModifier,
        expectedProduction: 7,
        expectedGold: 7,
        expectedFoodDeposit: 8,
      ),
      (
        label: 'stable',
        playerStabilityNet: const {'city_owner': 0},
        activePlayerId: 'city_owner',
        stabilityRuleset: StabilityRuleset.standard,
        expectedModifier: StabilityModifier.stable,
        expectedProduction: 7,
        expectedGold: 7,
        expectedFoodDeposit: 7,
      ),
      (
        label: 'strained with floor-rounded gold',
        playerStabilityNet: const {'city_owner': -1},
        activePlayerId: 'city_owner',
        stabilityRuleset: StabilityRuleset.standard,
        expectedModifier: _strainedModifier,
        expectedProduction: 7,
        expectedGold: 6,
        expectedFoodDeposit: 0,
      ),
      (
        label: 'unrest with floor-rounded production and gold',
        playerStabilityNet: const {'city_owner': -4},
        activePlayerId: 'city_owner',
        stabilityRuleset: StabilityRuleset.standard,
        expectedModifier: _unrestModifier,
        expectedProduction: 5,
        expectedGold: 5,
        expectedFoodDeposit: 0,
      ),
      (
        label: 'missing cached owner net defaults to stable zero',
        playerStabilityNet: const {},
        activePlayerId: 'city_owner',
        stabilityRuleset: StabilityRuleset.standard,
        expectedModifier: StabilityModifier.stable,
        expectedProduction: 7,
        expectedGold: 7,
        expectedFoodDeposit: 7,
      ),
      (
        label: 'city owner net wins over the active player net',
        playerStabilityNet: const {'city_owner': -4, 'active_player': 4},
        activePlayerId: 'active_player',
        stabilityRuleset: StabilityRuleset.standard,
        expectedModifier: _unrestModifier,
        expectedProduction: 5,
        expectedGold: 5,
        expectedFoodDeposit: 0,
      ),
      (
        label: 'custom thresholds classify standard content as stable',
        playerStabilityNet: const {'city_owner': 4},
        activePlayerId: 'other_player',
        stabilityRuleset: _customStabilityRuleset,
        expectedModifier: StabilityModifier.stable,
        expectedProduction: 7,
        expectedGold: 7,
        expectedFoodDeposit: 7,
      ),
    ];

WorldMap _mapData() => WorldMap(
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
