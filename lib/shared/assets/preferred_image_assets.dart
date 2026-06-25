abstract final class PreferredImageAssets {
  static const String buildingAtlasA =
      'assets/sprites/buildings_atlas_a_5x4_512.png';
  static const String buildingAtlasB =
      'assets/sprites/buildings_atlas_b_5x4_512.png';
  static const String buildingAtlasC =
      'assets/sprites/buildings_atlas_c_5x4_512.png';
  static const String technologyAtlas =
      'assets/sprites/technologies_atlas_8x7_512.png';
  static const String cityAtlas = 'assets/sprites/cities_atlas_6x4_512x320.jpg';

  static const Set<String> webpPreferredAssetPaths = {
    buildingAtlasA,
    buildingAtlasB,
    buildingAtlasC,
    technologyAtlas,
  };

  static int? targetDecodeWidthFor(String path) {
    return switch (path) {
      technologyAtlas => 2048,
      _ => null,
    };
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
