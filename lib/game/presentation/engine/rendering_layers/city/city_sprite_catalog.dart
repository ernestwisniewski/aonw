import 'dart:ui' as ui;

import 'package:aonw/shared/assets/preferred_image_assets.dart';
import 'package:aonw/shared/assets/sprite_atlas_geometry.dart';

enum CitySpriteTechnologyProfile {
  growthCivic,
  tradeKnowledgeMaritime,
  militaryFortified,
  industryModern,
}

abstract final class CitySpriteCatalog {
  static const String assetPath = PreferredImageAssets.cityAtlas;
  static const int columns = 6;
  static const int rows = 4;
  static const int visualLevelCount = columns;
  static const int technologyProfileCount = rows;
  static const double sourceInset = 0;

  static const int sourceImageWidth = 3072;
  static const int sourceImageHeight = 1280;

  static Iterable<int> get visualLevels =>
      Iterable<int>.generate(visualLevelCount);

  static Iterable<CitySpriteTechnologyProfile> get technologyProfiles =>
      CitySpriteTechnologyProfile.values;

  static String labelForProfile(CitySpriteTechnologyProfile profile) {
    return switch (profile) {
      CitySpriteTechnologyProfile.growthCivic => 'Growth / Civic',
      CitySpriteTechnologyProfile.tradeKnowledgeMaritime =>
        'Trade / Knowledge / Maritime',
      CitySpriteTechnologyProfile.militaryFortified => 'Military / Fortified',
      CitySpriteTechnologyProfile.industryModern => 'Industry / Modern',
    };
  }

  static ui.Rect sourceRectFor({
    required int imageWidth,
    required int imageHeight,
    required int row,
    required int column,
  }) {
    final visualLevel = row.clamp(0, visualLevelCount - 1).toInt();
    final profile = column.clamp(0, technologyProfileCount - 1).toInt();
    return SpriteAtlasGeometry.sourceRectFor(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      columns: columns,
      rows: rows,
      column: visualLevel,
      row: profile,
      sourceInset: sourceInset,
    );
  }
}
