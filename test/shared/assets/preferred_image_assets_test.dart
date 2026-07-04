import 'dart:io';

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

    test('prefers WebP unit atlases with PNG fallback', () {
      expect(
        PreferredImageAssets.candidatesFor(
          'assets/sprites/units/warrior.png',
          preferredCandidateFailed: false,
        ),
        [
          'assets/sprites/units/warrior.webp',
          'assets/sprites/units/warrior.png',
        ],
      );
      expect(
        PreferredImageAssets.candidatesFor(
          'assets/sprites/units/warrior.png',
          preferredCandidateFailed: true,
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

    test('declares existing unit atlas PNG and WebP files', () {
      for (final path in PreferredImageAssets.unitAtlasPaths) {
        expect(File(path).existsSync(), isTrue, reason: path);
        expect(
          File(PreferredImageAssets.webpPathFor(path)).existsSync(),
          isTrue,
          reason: PreferredImageAssets.webpPathFor(path),
        );
      }
    });
  });
}
