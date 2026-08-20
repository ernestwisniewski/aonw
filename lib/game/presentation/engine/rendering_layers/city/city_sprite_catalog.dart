import 'package:aonw/shared/assets/sprite_frame_id.dart';

enum CitySpriteTechnologyProfile {
  growthCivic,
  tradeKnowledgeMaritime,
  militaryFortified,
  industryModern,
}

abstract final class CitySpriteCatalog {
  static const int visualLevelCount = 6;
  static const int technologyProfileCount = 4;

  static Iterable<int> get visualLevels =>
      Iterable<int>.generate(visualLevelCount);

  static Iterable<CitySpriteTechnologyProfile> get technologyProfiles =>
      CitySpriteTechnologyProfile.values;

  static SpriteFrameId frameIdFor({
    required int visualLevel,
    required CitySpriteTechnologyProfile technologyProfile,
  }) {
    final level = visualLevel.clamp(0, visualLevelCount - 1).toInt();
    return SpriteFrameId('city.${technologyProfile.name}.$level');
  }

  static String labelForProfile(CitySpriteTechnologyProfile profile) {
    return switch (profile) {
      CitySpriteTechnologyProfile.growthCivic => 'Growth / Civic',
      CitySpriteTechnologyProfile.tradeKnowledgeMaritime =>
        'Trade / Knowledge / Maritime',
      CitySpriteTechnologyProfile.militaryFortified => 'Military / Fortified',
      CitySpriteTechnologyProfile.industryModern => 'Industry / Modern',
    };
  }
}
