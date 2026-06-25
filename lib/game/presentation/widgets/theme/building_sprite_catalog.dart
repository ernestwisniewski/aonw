import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:flutter/material.dart';

abstract final class BuildingSpriteCatalog {
  static const List<String> assetPaths = [
    'assets/sprites/buildings_atlas_a_5x4_512.png',
    'assets/sprites/buildings_atlas_b_5x4_512.png',
    'assets/sprites/buildings_atlas_c_5x4_512.png',
  ];
  static const int columns = 5;
  static const int rows = 4;
  static const int slotsPerAtlas = columns * rows;
  static const double sourceInset = 0;

  static int atlasIndexFor(CityBuildingType type) {
    final atlasIndex = type.index ~/ slotsPerAtlas;
    if (atlasIndex >= assetPaths.length) {
      throw StateError('Missing building atlas slot for ${type.name}');
    }
    return atlasIndex;
  }

  static String assetPathFor(CityBuildingType type) {
    return assetPaths[atlasIndexFor(type)];
  }

  static int slotFor(CityBuildingType type) => type.index % slotsPerAtlas;

  static SpriteAtlasIconData iconFor(CityBuildingType type) {
    final slot = slotFor(type);
    return SpriteAtlasIconData(
      assetPath: assetPathFor(type),
      columns: columns,
      rows: rows,
      column: slot % columns,
      row: slot ~/ columns,
      sourceInset: sourceInset,
      cropToContent: false,
    );
  }
}

class BuildingSpriteIcon extends StatelessWidget {
  final CityBuildingType type;
  final double size;
  final Widget? fallback;
  final double opacity;

  const BuildingSpriteIcon({
    required this.type,
    required this.size,
    this.fallback,
    this.opacity = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SpriteAtlasIcon(
      data: BuildingSpriteCatalog.iconFor(type),
      size: size,
      fallback: fallback,
      opacity: opacity,
    );
  }
}
