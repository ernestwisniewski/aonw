import 'package:aonw/shared/assets/preferred_image_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreferredImageAssets', () {
    test('caps large atlas decode widths', () {
      expect(
        PreferredImageAssets.targetDecodeWidthFor(
          PreferredImageAssets.technologyAtlas,
        ),
        PreferredImageAssets.technologyAtlasDecodeWidth,
      );
      expect(
        PreferredImageAssets.targetDecodeWidthFor(
          'assets/sprites/units/warrior.png',
        ),
        PreferredImageAssets.unitAtlasDecodeWidth,
      );
      expect(
        PreferredImageAssets.targetDecodeWidthFor(
          'assets/sprites/cities_atlas_6x4_512x320.jpg',
        ),
        isNull,
      );
    });

    test('keeps unit atlases on original asset path until WebP exists', () {
      expect(
        PreferredImageAssets.candidatesFor(
          'assets/sprites/units/warrior.png',
          preferredCandidateFailed: false,
        ),
        ['assets/sprites/units/warrior.png'],
      );
      expect(
        PreferredImageAssets.isUnitAtlasPath(
          'assets/sprites/units/warrior.png',
        ),
        isTrue,
      );
    });
  });
}
