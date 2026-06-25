import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: col == 1 && row == 1
              ? const [ResourceType.iron]
              : col == 2 && row == 1
              ? const [ResourceType.coal]
              : const [],
          height: 0,
        ),
  ],
);

void main() {
  group('CityTechnologyEffectRules', () {
    test('adds production from controlled strategic resources and defense', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 2, row: 1)],
      );
      const effects = TechnologyEffectSummary(
        strategicResourceProductionByType: {
          ResourceType.iron: 1,
          ResourceType.coal: 2,
        },
        cityDefenseBonus: 2,
      );

      expect(
        CityTechnologyEffectRules.yieldForCity(city, _map(), effects: effects),
        const TileYield(food: 0, production: 3, gold: 0, defense: 2),
      );
    });

    test('applies global gold multiplier to city yield', () {
      const yield = TileYield(food: 0, production: 0, gold: 11, defense: 0);
      const effects = TechnologyEffectSummary(globalGoldMultiplier: 0.10);

      expect(
        CityTechnologyEffectRules.applyGoldMultiplier(
          yield,
          effects: effects,
        ).gold,
        12,
      );
    });

    test('adds army production bonus to unit queues', () {
      const effects = TechnologyEffectSummary(armyProductionMultiplier: 0.15);

      expect(
        CityTechnologyEffectRules.unitProductionPerTurn(3, effects: effects),
        4,
      );
      expect(
        CityTechnologyEffectRules.unitProductionPerTurn(10, effects: effects),
        12,
      );
    });

    test('adds technology territory cap to building cap', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        buildings: {CityBuildingType.housing},
      );
      const effects = TechnologyEffectSummary(maxControlledHexesBonus: 1);

      expect(
        CityTechnologyEffectRules.effectiveMaxHexes(city, effects: effects),
        9,
      );
    });
  });
}
