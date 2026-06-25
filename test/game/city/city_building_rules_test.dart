import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile({
  required int col,
  required int row,
  List<TerrainType> terrains = const [TerrainType.grassland],
}) {
  return TileData(
    col: col,
    row: row,
    terrains: terrains,
    resources: const [],
    height: 0,
  );
}

MapData _map() => MapData(
  cols: 4,
  rows: 4,
  tiles: [
    _tile(col: 1, row: 1, terrains: const [TerrainType.plains]),
    _tile(
      col: 2,
      row: 1,
      terrains: const [TerrainType.plains, TerrainType.river],
    ),
    _tile(
      col: 1,
      row: 2,
      terrains: const [TerrainType.grassland, TerrainType.river],
    ),
    _tile(
      col: 2,
      row: 2,
      terrains: const [TerrainType.forest, TerrainType.river],
    ),
    _tile(
      col: 3,
      row: 2,
      terrains: const [TerrainType.hills, TerrainType.river],
    ),
  ],
);

GameCity _city({Set<CityBuildingType> buildings = const {}}) {
  return GameCity(
    id: 'city',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: const CityHex(col: 1, row: 1),
    controlledHexes: const [
      CityHex(col: 2, row: 1),
      CityHex(col: 1, row: 2),
      CityHex(col: 2, row: 2),
      CityHex(col: 3, row: 2),
    ],
    buildings: buildings,
  );
}

void main() {
  group('CityBuildingRules', () {
    test('applies standard building effects from definitions', () {
      final city = _city(
        buildings: {
          CityBuildingType.granary,
          CityBuildingType.waterMill,
          CityBuildingType.workshop,
        },
      );

      expect(
        CityBuildingRules.yieldForCity(city, _map()),
        const TileYield(food: 5, production: 2, gold: 0, defense: 0),
      );
    });

    test('applies storage and territory effects from definitions', () {
      final city = _city(
        buildings: {CityBuildingType.storehouse, CityBuildingType.housing},
      );

      expect(CityBuildingRules.foodDeposited(city, 10), 12);
      expect(CityBuildingRules.effectiveMaxHexes(city), 8);
    });

    test('applies technology building effects from definitions', () {
      final city = _city(
        buildings: {
          CityBuildingType.merchantHall,
          CityBuildingType.stonemason,
          CityBuildingType.barracks,
          CityBuildingType.marketplace,
          CityBuildingType.port,
          CityBuildingType.aqueduct,
          CityBuildingType.forge,
          CityBuildingType.stable,
          CityBuildingType.bank,
          CityBuildingType.buildersGuild,
          CityBuildingType.factory,
          CityBuildingType.lighthouse,
          CityBuildingType.trainingGrounds,
          CityBuildingType.townHall,
          CityBuildingType.monument,
        },
      );

      expect(
        CityBuildingRules.yieldForCity(city, _map()),
        const TileYield(food: 5, production: 13, gold: 19, defense: 6),
      );
      expect(CityBuildingRules.effectiveMaxHexes(city), 9);
    });

    test('uses injected building effects from a custom ruleset', () {
      final ruleset = CityRulesets.standard.copyWith(
        buildings: {
          CityBuildingType.granary: const CityBuildingDefinition(
            type: CityBuildingType.granary,
            productionCost: 1,
            effects: [
              FlatCityYieldEffect(
                TileYield(food: 0, production: 0, gold: 4, defense: 0),
              ),
              MaxControlledHexesEffect(5),
              FoodDepositMultiplierEffect(2),
            ],
          ),
        },
      );
      final city = _city(buildings: {CityBuildingType.granary});

      expect(
        CityBuildingRules.yieldForCity(city, _map(), ruleset: ruleset),
        const TileYield(food: 0, production: 0, gold: 4, defense: 0),
      );
      expect(CityBuildingRules.effectiveMaxHexes(city, ruleset: ruleset), 11);
      expect(CityBuildingRules.foodDeposited(city, 3, ruleset: ruleset), 6);
    });
  });
}
