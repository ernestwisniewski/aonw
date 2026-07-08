abstract final class PreferredImageAssets {
  static const String buildingAtlasA =
      'assets/sprites/buildings_atlas_a_5x4_512.png';
  static const String buildingAtlasB =
      'assets/sprites/buildings_atlas_b_5x4_512.png';
  static const String buildingAtlasC =
      'assets/sprites/buildings_atlas_c_5x4_512.png';
  static const String technologyAtlas =
      'assets/sprites/technologies_atlas_8x7_512.png';
  static const String wonderAtlas =
      'assets/sprites/wonders_atlas_a_5x4_512.png';
  static const String cityAtlas = 'assets/sprites/cities_atlas_6x4_512x320.jpg';
  static const String unitAtlasDirectory = 'assets/sprites/units/';
  static const int technologyAtlasDecodeWidth = 2048;
  static const int unitAtlasDecodeWidth = 1536;
  static const List<String> unitAtlasPaths = [
    'assets/sprites/units/archer.png',
    'assets/sprites/units/catapult.png',
    'assets/sprites/units/cavalry.png',
    'assets/sprites/units/commander.png',
    'assets/sprites/units/fieldCannon.png',
    'assets/sprites/units/heavyInfantry.png',
    'assets/sprites/units/merchant.png',
    'assets/sprites/units/reconPlane.png',
    'assets/sprites/units/rifleman.png',
    'assets/sprites/units/scout.png',
    'assets/sprites/units/scoutShip.png',
    'assets/sprites/units/settler.png',
    'assets/sprites/units/spearman.png',
    'assets/sprites/units/tank.png',
    'assets/sprites/units/warrior.png',
    'assets/sprites/units/warship.png',
    'assets/sprites/units/worker.png',
  ];

  static const Set<String> webpPreferredAssetPaths = {
    buildingAtlasA,
    buildingAtlasB,
    buildingAtlasC,
    technologyAtlas,
    wonderAtlas,
    ...unitAtlasPaths,
  };

  static int? targetDecodeWidthFor(String path) {
    return switch (path) {
      technologyAtlas => technologyAtlasDecodeWidth,
      _ when isUnitAtlasPath(path) => unitAtlasDecodeWidth,
      _ => null,
    };
  }

  static bool isUnitAtlasPath(String path) {
    return path.startsWith(unitAtlasDirectory);
  }

  static String unitAtlasPath(String assetName) {
    return '$unitAtlasDirectory$assetName.png';
  }

  static List<String> candidatesFor(
    String path, {
    required bool preferredCandidateFailed,
  }) {
    if (!webpPreferredAssetPaths.contains(path)) return [path];

    final webpPath = webpPathFor(path);
    if (preferredCandidateFailed) return [path];

    return [webpPath, path];
  }

  static String webpPathFor(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex <= 0) return '$path.webp';
    return '${path.substring(0, dotIndex)}.webp';
  }
}
