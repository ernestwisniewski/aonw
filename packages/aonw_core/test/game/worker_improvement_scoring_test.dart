import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WorkerImprovementScoring', () {
    test('uses unified city tile yield as base yield', () {
      const tile = TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      );

      final score = WorkerImprovementScoring.scoreFor(
        type: FieldImprovementType.farm,
        tile: tile,
      );
      final baseYield = CityTileYieldRules.forTile(tile);
      final expected = WorkerImprovementScoring.scoreForYield(
        type: FieldImprovementType.farm,
        baseYield: baseYield,
      );

      expect(score, expected);
    });

    test('responds to injected ruleset base yields', () {
      const tile = TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      );
      final ruleset = CityRulesets.standard.copyWith(
        terrainYields: {
          ...CityRulesets.standard.terrainYields,
          TerrainType.grassland: const TileYield(
            food: 6,
            production: 4,
            gold: 0,
            defense: 0,
          ),
        },
      );

      final standardScore = WorkerImprovementScoring.scoreFor(
        type: FieldImprovementType.farm,
        tile: tile,
      );
      final tunedScore = WorkerImprovementScoring.scoreFor(
        type: FieldImprovementType.farm,
        tile: tile,
        ruleset: ruleset,
      );

      expect(tunedScore, greaterThan(standardScore));
      expect(
        tunedScore - standardScore,
        4 * WorkerImprovementScoreBalance.baseFoodWeight +
            4 * WorkerImprovementScoreBalance.baseProductionWeight,
      );
    });
  });
}
