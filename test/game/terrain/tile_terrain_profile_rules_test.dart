import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/terrain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TileTerrainProfileRules', () {
    test(
      'splits mixed terrain into base, features, modifiers, and blockers',
      () {
        final profile = TileTerrainProfileRules.fromTerrains(const [
          TerrainType.grassland,
          TerrainType.forest,
          TerrainType.hills,
          TerrainType.wetlands,
          TerrainType.river,
          TerrainType.mountain,
        ]);

        expect(profile.base, TerrainType.grassland);
        expect(profile.features, {
          TerrainType.forest,
          TerrainType.hills,
          TerrainType.wetlands,
        });
        expect(profile.modifiers, {TerrainType.river});
        expect(profile.blockers, {TerrainType.mountain});
        expect(profile.hasForest, isTrue);
        expect(profile.hasHills, isTrue);
        expect(profile.hasRiver, isTrue);
        expect(profile.hasMountain, isTrue);
      },
    );

    test(
      'keeps the first non-ocean base terrain when multiple bases are present',
      () {
        final profile = TileTerrainProfileRules.fromTerrains(const [
          TerrainType.plains,
          TerrainType.grassland,
          TerrainType.forest,
        ]);

        expect(profile.base, TerrainType.plains);
        expect(profile.features, {TerrainType.forest});
      },
    );

    test('any land base terrain beats open water when both are present', () {
      // A tile with open water + any land terrain has land; the land terrain
      // wins so that movement rules treat it as passable.
      expect(
        TileTerrainProfileRules.fromTerrains(const [
          TerrainType.ocean,
          TerrainType.coast,
        ]).base,
        TerrainType.coast,
      );
      expect(
        TileTerrainProfileRules.fromTerrains(const [
          TerrainType.ocean,
          TerrainType.grassland,
        ]).base,
        TerrainType.grassland,
      );
      expect(
        TileTerrainProfileRules.fromTerrains(const [
          TerrainType.ocean,
          TerrainType.plains,
        ]).base,
        TerrainType.plains,
      );
      expect(
        TileTerrainProfileRules.fromTerrains(const [
          TerrainType.ocean,
          TerrainType.tundra,
        ]).base,
        TerrainType.tundra,
      );
      // Pure ocean stays ocean
      expect(
        TileTerrainProfileRules.fromTerrains(const [TerrainType.ocean]).base,
        TerrainType.ocean,
      );
      expect(
        TileTerrainProfileRules.fromTerrains(const [TerrainType.lake]).base,
        TerrainType.lake,
      );
      expect(
        TileTerrainProfileRules.fromTerrains(const [
          TerrainType.lake,
          TerrainType.coast,
        ]).base,
        TerrainType.coast,
      );
    });

    test('infers a default base for feature-only tiles', () {
      expect(
        TileTerrainProfileRules.fromTerrains(const [TerrainType.forest]).base,
        TerrainType.grassland,
      );
      expect(
        TileTerrainProfileRules.fromTerrains(const [TerrainType.wetlands]).base,
        TerrainType.grassland,
      );
      expect(
        TileTerrainProfileRules.fromTerrains(const [TerrainType.hills]).base,
        TerrainType.plains,
      );
    });
  });
}
