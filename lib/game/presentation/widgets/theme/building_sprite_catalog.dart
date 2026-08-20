import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:flutter/material.dart';

abstract final class BuildingSpriteCatalog {
  static SpriteFrameId frameIdFor(CityBuildingType type) {
    return SpriteFrameId('building.${type.name}');
  }

  static SpriteAtlasIconData iconFor(CityBuildingType type) {
    return SpriteAtlasIconData(frameId: frameIdFor(type), cropToContent: false);
  }
}

class BuildingSpriteIcon extends StatelessWidget {
  const BuildingSpriteIcon({
    required this.type,
    required this.size,
    this.opacity = 1,
    super.key,
  });

  final CityBuildingType type;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SpriteAtlasIcon(
      data: BuildingSpriteCatalog.iconFor(type),
      size: size,
      opacity: opacity,
    );
  }
}
