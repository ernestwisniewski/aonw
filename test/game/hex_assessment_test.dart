import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile(
  TerrainType terrain, {
  bool river = false,
  List<ResourceType> resources = const [],
}) {
  return TileData(
    col: 0,
    row: 0,
    terrains: [terrain, if (river) TerrainType.river],
    resources: resources,
    height: 0,
  );
}

void main() {
  group('HexAssessmentRules', () {
    test('scores ideal river food city spots independently of UI', () {
      final assessment = HexAssessmentRules.assess(
        _tile(
          TerrainType.grassland,
          river: true,
          resources: const [ResourceType.wheat],
        ),
      );

      expect(assessment.kind, HexAssessmentKind.idealCitySite);
      expect(assessment.recommendation, HexRecommendation.foundCity);
      expect(assessment.canFoundCity, isTrue);
      expect(assessment.score, const HexScore(city: 8, defense: 1, economy: 7));
      expect(assessment.tags, contains(HexAssessmentTag.city));
      expect(assessment.tags, contains(HexAssessmentTag.fertile));
    });

    test('classifies coastal river fish as a port region core', () {
      final assessment = HexAssessmentRules.assess(
        _tile(
          TerrainType.coast,
          river: true,
          resources: const [ResourceType.fish],
        ),
      );

      expect(assessment.kind, HexAssessmentKind.regionalPortHeart);
      expect(assessment.recommendation, HexRecommendation.foundCity);
      expect(assessment.canFoundCity, isTrue);
      expect(assessment.tags, contains(HexAssessmentTag.water));
    });

    test(
      'keeps barren desert pessimistic when it has no river or resources',
      () {
        final assessment = HexAssessmentRules.assess(_tile(TerrainType.desert));

        expect(assessment.kind, HexAssessmentKind.barrenLand);
        expect(assessment.recommendation, HexRecommendation.avoid);
        expect(
          assessment.score,
          const HexScore(city: -2, defense: -1, economy: 0),
        );
      },
    );

    test('treats mountains as natural barriers, not city locations', () {
      final assessment = HexAssessmentRules.assess(_tile(TerrainType.mountain));

      expect(assessment.kind, HexAssessmentKind.naturalBarrier);
      expect(assessment.recommendation, HexRecommendation.avoid);
      expect(assessment.canFoundCity, isFalse);
      expect(assessment.tags, contains(HexAssessmentTag.defense));
    });

    test('applies strategic and industrial resource scoring', () {
      final assessment = HexAssessmentRules.assess(
        _tile(TerrainType.hills, resources: const [ResourceType.iron]),
      );

      expect(assessment.kind, HexAssessmentKind.industrialStronghold);
      expect(assessment.score, const HexScore(city: 2, defense: 5, economy: 3));
      expect(assessment.tags, contains(HexAssessmentTag.strategic));
    });

    test('keeps named terrain priority rules stable', () {
      final cases = [
        _KindCase(
          name: 'grassland river food city spot',
          tile: _tile(
            TerrainType.grassland,
            river: true,
            resources: const [ResourceType.sheep],
          ),
          kind: HexAssessmentKind.idealCitySite,
        ),
        _KindCase(
          name: 'forest river wilds before forest backline',
          tile: _tile(
            TerrainType.forest,
            river: true,
            resources: const [ResourceType.deer],
          ),
          kind: HexAssessmentKind.richWilds,
        ),
        _KindCase(
          name: 'jungle river wilds before exotic backline',
          tile: _tile(
            TerrainType.jungle,
            river: true,
            resources: const [ResourceType.banana],
          ),
          kind: HexAssessmentKind.richWilds,
        ),
        _KindCase(
          name: 'wetlands exotic before river wilds',
          tile: _tile(
            TerrainType.wetlands,
            river: true,
            resources: const [ResourceType.banana],
          ),
          kind: HexAssessmentKind.exoticBackline,
        ),
        _KindCase(
          name: 'tundra cold strategic outpost',
          tile: _tile(TerrainType.tundra, resources: const [ResourceType.coal]),
          kind: HexAssessmentKind.resourceOutpost,
        ),
        _KindCase(
          name: 'snow cold strategic deposits',
          tile: _tile(TerrainType.snow, resources: const [ResourceType.coal]),
          kind: HexAssessmentKind.arcticDeposits,
        ),
      ];

      for (final testCase in cases) {
        final assessment = HexAssessmentRules.assess(testCase.tile);

        expect(assessment.kind, testCase.kind, reason: testCase.name);
      }
    });
  });
}

class _KindCase {
  final String name;
  final TileData tile;
  final HexAssessmentKind kind;

  const _KindCase({required this.name, required this.tile, required this.kind});
}
