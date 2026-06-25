/// Visual configuration for hex tile geometry (radius only).
/// Grid dimensions come from [MapData] loaded from JSON.
class MapConfig {
  final double hexRadius;

  const MapConfig({required this.hexRadius});

  static const double defaultHexRadius = 60.0;
  static const MapConfig defaultConfig = MapConfig(hexRadius: defaultHexRadius);
}
