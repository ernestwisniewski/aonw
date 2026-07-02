import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model_factory.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CitySelectionViewModelFactory', () {
    final l10n = AppLocalizationsEn();

    GameSelection citySelection({
      TileYield yield = TileYield.zero,
      int playerColor = 0xFF4488cc,
      int population = 1,
      Set<CityBuildingType> buildings = const {},
      CityProductionQueue? productionQueue,
    }) {
      final city = GameCity(
        id: 'city_1_2',
        ownerPlayerId: 'player_1',
        name: 'Nowe City',
        population: population,
        center: const CityHex(col: 1, row: 2),
        controlledHexes: const [
          CityHex(col: 2, row: 2),
          CityHex(col: 1, row: 3),
        ],
        buildings: buildings,
        productionQueue: productionQueue,
      );
      return GameSelection.city(
        city,
        cityYield: yield,
        playerColor: playerColor,
      );
    }

    test('uses city icon', () {
      final vm = SelectionViewModelFactory.from(citySelection(), l10n: l10n);
      expect(vm.icon, GameIcons.cityFilled);
    });

    test('uses city name as title', () {
      final vm = SelectionViewModelFactory.from(citySelection(), l10n: l10n);
      expect(vm.title, 'Nowe City');
    });

    test('shows populacja subtitle', () {
      final vm = SelectionViewModelFactory.from(
        citySelection(population: 2),
        l10n: l10n,
      );
      expect(
        vm.subtitle,
        'Population 2 • 3/6 fields • Production: no production',
      );
    });

    test('shows active city production in subtitle', () {
      final vm = SelectionViewModelFactory.from(
        citySelection(
          population: 2,
          productionQueue: CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: 4,
          ),
        ),
        l10n: l10n,
      );
      expect(vm.subtitle, 'Population 2 • 3/6 fields • Production: Granary');
    });

    test('uses player color', () {
      final vm = SelectionViewModelFactory.from(
        citySelection(playerColor: 0xFF4488cc),
        l10n: l10n,
      );
      expect(vm.color, const Color(0xFF4488cc));
    });

    test('yields match city total yield', () {
      const cityYield = TileYield(food: 3, production: 2, gold: 1, defense: 4);
      final vm = SelectionViewModelFactory.from(
        citySelection(yield: cityYield),
        l10n: l10n,
      );
      final yields = vm.yields;
      expect(yields.length, 4);
      expect(vm.yieldTitle, 'City income');
      expect(
        vm.yieldTooltip,
        'Actual city yield per turn from the city economy.',
      );

      final food = yields.firstWhere((y) => y.label == 'FOOD');
      expect(food.value, 3);

      final prod = yields.firstWhere((y) => y.label == 'PROD');
      expect(prod.value, 2);

      final gold = yields.firstWhere((y) => y.label == 'GOLD');
      expect(gold.value, 1);

      final def = yields.firstWhere((y) => y.label == 'DEF');
      expect(def.value, 4);
    });

    test('shows city details behind the details toggle', () {
      final vm = SelectionViewModelFactory.from(
        citySelection(population: 2),
        l10n: l10n,
      );

      expect(vm.items, hasLength(5));
      expect(vm.items[0].label, 'Population');
      expect(vm.items[0].value, '2');
      expect(vm.items[1].label, 'Territory');
      expect(vm.items[1].value, '3/6');
      expect(vm.items[2].label, 'Food');
      expect(vm.items[2].value, '0');
      expect(vm.items[3].label, 'Net food');
      expect(vm.items[4].label, 'Buildings');
    });

    test('shows frontier distance and cohesion cost', () {
      const capital = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        foundingOwnerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      );
      const frontier = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        foundingOwnerPlayerId: 'player_1',
        name: 'Frontier',
        center: CityHex(col: 8, row: 0),
        controlledHexes: [CityHex(col: 7, row: 0)],
      );

      final vm = SelectionViewModelFactory.from(
        GameSelection.city(
          frontier,
          cityYield: TileYield.zero,
          playerColor: 0xFF4488cc,
        ),
        gameState: const GameState(cities: [capital, frontier]),
        l10n: l10n,
      );

      final cohesion = vm.items.singleWhere((item) => item.label == 'Cohesion');
      expect(cohesion.value, 'Frontier • 8 hexes • -4 stability');
    });

    test('marks city info when the city stores an artifact', () {
      const artifact = WorldArtifact(
        id: 'artifact.hero_sword',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.stored(cityId: 'city_1_2'),
      );

      final vm = SelectionViewModelFactory.from(
        citySelection(population: 2),
        gameState: const GameState(artifacts: [artifact]),
        l10n: l10n,
      );

      final item = vm.items.singleWhere(
        (item) => item.icon == GameIcons.artifact,
      );
      expect(item.label, 'Artifact');
      expect(item.value, contains("Hero's Sword"));
      expect(item.value, contains('+2 XP for produced units'));
    });

    test('adds controlled map objectives to city description info', () {
      final vm = SelectionViewModelFactory.from(
        citySelection(population: 2),
        gameState: const GameState(activePlayerId: 'player_1'),
        mapData: _mapWithObjective(),
        l10n: l10n,
      );

      final item = vm.descriptionItems.singleWhere(
        (item) => item.icon == GameIcons.victory,
      );
      expect(item.label, 'Strategic pass');
      expect(item.value, contains('Holding 0/3'));
      expect(item.value, contains('+2 VP'));
      expect(item.value, contains('+1 gold/turn'));
    });

    test('keeps typed city buildings for details popups', () {
      final vm = SelectionViewModelFactory.from(
        citySelection(buildings: {CityBuildingType.granary}),
        l10n: l10n,
        buildingName: (type) => 'Granary',
      );

      expect(vm.cityBuildings, ['Granary']);
      expect(vm.cityBuildingItems, hasLength(1));
      expect(vm.cityBuildingItems.single.type, CityBuildingType.granary);
      expect(vm.cityBuildingItems.single.label, 'Granary');
    });
  });
}

MapData _mapWithObjective() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
    objectives: const [
      MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: CityHex(col: 2, row: 2),
        requiredHoldTurns: 3,
        victoryPoints: 2,
        goldPerTurn: 1,
      ),
    ],
  );
}
