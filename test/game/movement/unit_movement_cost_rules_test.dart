import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/terrain.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitMovementCostRules', () {
    test('uses base terrain cost for simple land tiles', () {
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.grassland),
        ),
        const MovementCost.passable(1),
      );
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.tundra),
        ),
        const MovementCost.passable(2),
      );
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.snow),
        ),
        const MovementCost.passable(3),
      );
    });

    test('adds feature costs when one hex has multiple terrain types', () {
      final profile = TileTerrainProfileRules.fromTerrains(const [
        TerrainType.plains,
        TerrainType.forest,
        TerrainType.hills,
        TerrainType.river,
      ]);

      expect(
        UnitMovementCostRules.costToEnter(profile),
        const MovementCost.passable(3),
      );
    });

    test('blocks mountains and open ocean', () {
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(
            base: TerrainType.grassland,
            blockers: {TerrainType.mountain},
          ),
        ),
        const MovementCost.blocked(),
      );
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.ocean),
        ),
        const MovementCost.blocked(),
      );
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.lake),
        ),
        const MovementCost.blocked(),
      );
    });

    test('coast is passable — tile with coast terrain has land', () {
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.coast),
        ),
        const MovementCost.passable(1),
      );
    });

    test('coast with forest adds feature cost', () {
      final profile = TileTerrainProfileRules.fromTerrains(const [
        TerrainType.coast,
        TerrainType.forest,
      ]);
      expect(
        UnitMovementCostRules.costToEnter(profile),
        const MovementCost.passable(2),
      );
    });

    test('snowy forest remains passable for ordinary foot units', () {
      expect(
        UnitMovementCostRules.costToEnter(
          TileTerrainProfileRules.fromTerrains(const [
            TerrainType.snow,
            TerrainType.forest,
          ]),
          unitType: GameUnitType.warrior,
        ),
        const MovementCost.passable(3),
      );
      expect(
        UnitMovementCostRules.costToEnter(
          TileTerrainProfileRules.fromTerrains(const [
            TerrainType.snow,
            TerrainType.tundra,
            TerrainType.forest,
          ]),
          unitType: GameUnitType.warrior,
        ),
        const MovementCost.passable(3),
      );
      expect(
        UnitMovementCostRules.costToEnter(
          TileTerrainProfileRules.fromTerrains(const [
            TerrainType.tundra,
            TerrainType.snow,
            TerrainType.forest,
          ]),
          unitType: GameUnitType.warrior,
        ),
        const MovementCost.passable(3),
      );
    });

    test('wetlands are slow land', () {
      final profile = TileTerrainProfileRules.fromTerrains(const [
        TerrainType.wetlands,
      ]);

      expect(
        UnitMovementCostRules.costToEnter(profile),
        const MovementCost.passable(2),
      );
    });

    test('naval units can enter only coast and ocean', () {
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.coast),
          unitType: GameUnitType.scoutShip,
        ),
        const MovementCost.passable(1),
      );
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.ocean),
          unitType: GameUnitType.warship,
        ),
        const MovementCost.passable(1),
      );
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.grassland),
          unitType: GameUnitType.scoutShip,
        ),
        const MovementCost.blocked(),
      );
      expect(
        UnitMovementCostRules.costToEnter(
          const TileTerrainProfile(base: TerrainType.lake),
          unitType: GameUnitType.scoutShip,
        ),
        const MovementCost.blocked(),
      );
    });
  });
}
