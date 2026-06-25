import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/terrain_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TerrainTheme.topColor', () {
    test('ocean returns correct base color', () {
      final color = TerrainTheme.topColor(TerrainType.ocean, null);
      expect(color, const Color(0xFF1a6691));
    });

    test('grassland returns correct base color', () {
      final color = TerrainTheme.topColor(TerrainType.grassland, null);
      expect(color, const Color(0xFF5a8a3c));
    });

    test('resource does not change top color', () {
      final base = TerrainTheme.topColor(TerrainType.grassland, null);
      final withIron = TerrainTheme.topColor(
        TerrainType.grassland,
        ResourceType.iron,
      );
      // Resources show a dot overlay; terrain color is unchanged.
      expect(withIron, equals(base));
    });
  });

  group('TerrainTheme.icon', () {
    test('returns asset path for terrain', () {
      expect(
        TerrainTheme.icon(TerrainType.ocean),
        'assets/icons/terrain_ocean.png',
      );
    });

    test('returns correct asset path for mountain', () {
      expect(
        TerrainTheme.icon(TerrainType.mountain),
        'assets/icons/terrain_mountain.png',
      );
    });
  });

  group('TerrainTheme.resourceDotColor', () {
    test('returns null when no resource', () {
      expect(TerrainTheme.resourceDotColor(null), isNull);
    });

    test('returns a color when resource is set', () {
      expect(TerrainTheme.resourceDotColor(ResourceType.iron), isNotNull);
    });

    test('iron has a grey dot', () {
      final color = TerrainTheme.resourceDotColor(ResourceType.iron);
      expect(color, const Color(0xFF90a4ae));
    });

    test('gold has a yellow dot', () {
      final color = TerrainTheme.resourceDotColor(ResourceType.gold);
      expect(color, const Color(0xFFffd700));
    });
  });

  group('TerrainTheme.sideColor', () {
    test('right wall is darker than top face', () {
      final top = TerrainTheme.topColor(TerrainType.grassland, null);
      final right = TerrainTheme.sideColor(top, TerrainTheme.rightWallFactor);
      expect(right.r, lessThanOrEqualTo(top.r));
    });
  });
}
