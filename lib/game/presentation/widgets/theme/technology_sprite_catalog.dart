import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

abstract final class TechnologySpriteCatalog {
  static SpriteFrameId frameIdFor(TechnologyId id) {
    return SpriteFrameId('technology.${id.name}');
  }

  static SpriteAtlasIconData iconFor(TechnologyId id) {
    return SpriteAtlasIconData(frameId: frameIdFor(id), cropToContent: false);
  }
}

class TechnologySpriteIcon extends StatelessWidget {
  const TechnologySpriteIcon({
    required this.id,
    required this.size,
    this.opacity = 1,
    super.key,
  });

  final TechnologyId id;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SpriteAtlasIcon(
      data: TechnologySpriteCatalog.iconFor(id),
      size: size,
      opacity: opacity,
    );
  }
}
