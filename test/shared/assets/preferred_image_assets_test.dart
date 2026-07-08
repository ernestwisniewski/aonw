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
          PreferredImageAssets.wonderAtlas,
        ),
        isNull,
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

    test('prefers WebP wonder atlas with PNG fallback', () {
      expect(
        PreferredImageAssets.candidatesFor(
          PreferredImageAssets.wonderAtlas,
          preferredCandidateFailed: false,
        ),
        [
          'assets/sprites/wonders_atlas_a_5x4_512.webp',
          'assets/sprites/wonders_atlas_a_5x4_512.png',
        ],
      );
      expect(
        PreferredImageAssets.candidatesFor(
          PreferredImageAssets.wonderAtlas,
          preferredCandidateFailed: true,
        ),
        ['assets/sprites/wonders_atlas_a_5x4_512.png'],
      );
      expect(File(PreferredImageAssets.wonderAtlas).existsSync(), isTrue);
      expect(
        File(
          PreferredImageAssets.webpPathFor(PreferredImageAssets.wonderAtlas),
        ).existsSync(),
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
