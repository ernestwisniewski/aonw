import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile({
  int col = 0,
  int row = 0,
  List<TerrainType> terrains = const [TerrainType.grassland],
  List<ResourceType> resources = const [],
}) {
  return TileData(
    col: col,
    row: row,
    terrains: terrains,
    resources: resources,
    height: 0,
  );
}

void main() {
  group('FieldImprovementRules', () {
    test('prefers specialist improvements before generic farms', () {
      expect(
        FieldImprovementRules.preferredFor(
          _tile(resources: const [ResourceType.cow]),
        ),
        FieldImprovementType.pasture,
      );
      expect(
        FieldImprovementRules.preferredFor(
          _tile(resources: const [ResourceType.deer]),
        ),
        FieldImprovementType.camp,
      );
      expect(
        FieldImprovementRules.preferredFor(
          _tile(resources: const [ResourceType.marble]),
        ),
        FieldImprovementType.quarry,
      );
      expect(
        FieldImprovementRules.preferredFor(
          _tile(
            terrains: const [TerrainType.coast],
            resources: const [ResourceType.fish],
          ),
        ),
        FieldImprovementType.fishingBoats,
      );
    });

    test('prefers resource-specific improvements for expanded resources', () {
      expect(
        FieldImprovementRules.preferredFor(
          _tile(resources: const [ResourceType.banana]),
        ),
        FieldImprovementType.orchard,
      );
      expect(
        FieldImprovementRules.preferredFor(
          _tile(resources: const [ResourceType.sugar]),
        ),
        FieldImprovementType.plantation,
      );
      expect(
        FieldImprovementRules.preferredFor(
          _tile(resources: const [ResourceType.gold]),
        ),
        FieldImprovementType.prospectorCamp,
      );
      expect(
        FieldImprovementRules.preferredFor(
          _tile(resources: const [ResourceType.horses]),
        ),
        FieldImprovementType.horseRanch,
      );
      expect(
        FieldImprovementRules.preferredFor(
          _tile(
            terrains: const [TerrainType.coast],
            resources: const [ResourceType.pearls],
          ),
        ),
        FieldImprovementType.pearlDivers,
      );
      expect(
        FieldImprovementRules.preferredFor(
          _tile(resources: const [ResourceType.oil]),
        ),
        FieldImprovementType.oilWell,
      );
    });

    test('prefers river farm over a regular farm', () {
      expect(
        FieldImprovementRules.preferredFor(
          _tile(terrains: const [TerrainType.plains, TerrainType.river]),
        ),
        FieldImprovementType.riverFarm,
      );
    });

    test('reads preferred type and yield from an injected ruleset', () {
      final ruleset = CityRulesets.standard.copyWith(
        improvements: {
          FieldImprovementType.mine: const FieldImprovementDefinition(
            type: FieldImprovementType.mine,
            tileYield: TileYield(food: 0, production: 5, gold: 0, defense: 0),
            buildTurns: 3,
            resourceSpecialist: true,
            requirements: [
              RequiresAnyBaseTerrain({TerrainType.grassland}),
            ],
          ),
          FieldImprovementType.farm: const FieldImprovementDefinition(
            type: FieldImprovementType.farm,
            tileYield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
            buildTurns: 2,
            requirements: [
              RequiresAnyBaseTerrain({TerrainType.grassland}),
            ],
          ),
        },
      );

      expect(
        FieldImprovementRules.preferredFor(_tile(), ruleset: ruleset),
        FieldImprovementType.mine,
      );
      expect(
        FieldImprovementRules.yieldFor(
          FieldImprovementType.mine,
          ruleset: ruleset,
        ),
        const TileYield(food: 0, production: 5, gold: 0, defense: 0),
      );
      expect(
        FieldImprovementRules.isResourceSpecialist(
          FieldImprovementType.mine,
          ruleset: ruleset,
        ),
        isTrue,
      );
    });
  });
}
