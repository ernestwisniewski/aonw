import 'package:aonw/game/presentation/engine/rendering_layers/city/city_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:flutter/material.dart';

abstract final class CitySpriteIconCatalog {
  static SpriteAtlasIconData iconFor({
    required int visualLevel,
    required int technologyProfileIndex,
  }) {
    final level = visualLevel.clamp(0, CitySpriteCatalog.visualLevelCount - 1);
    final profile = technologyProfileIndex.clamp(
      0,
      CitySpriteCatalog.technologyProfileCount - 1,
    );
    return SpriteAtlasIconData(
      assetPath: CitySpriteCatalog.assetPath,
      columns: CitySpriteCatalog.columns,
      rows: CitySpriteCatalog.rows,
      column: level.toInt(),
      row: profile.toInt(),
      sourceInset: CitySpriteCatalog.sourceInset,
      cropToContent: false,
    );
  }
}

class CitySpriteIcon extends StatelessWidget {
  const CitySpriteIcon({
    required this.visualLevel,
    required this.technologyProfileIndex,
    required this.size,
    this.width,
    this.height,
    this.fallback,
    this.opacity = 1,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.key,
  });

  final int visualLevel;
  final int technologyProfileIndex;
  final double size;
  final double? width;
  final double? height;
  final Widget? fallback;
  final double opacity;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SpriteAtlasIcon(
      data: CitySpriteIconCatalog.iconFor(
        visualLevel: visualLevel,
        technologyProfileIndex: technologyProfileIndex,
      ),
      size: size,
      width: width,
      height: height,
      fallback: fallback,
      opacity: opacity,
      fit: fit,
      alignment: alignment,
    );
  }
}
