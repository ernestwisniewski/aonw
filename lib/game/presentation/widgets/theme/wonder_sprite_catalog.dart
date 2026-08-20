import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter/material.dart';

abstract final class WonderSpriteCatalog {
  static SpriteFrameId frameIdFor(WonderType type) {
    return SpriteFrameId('wonder.${type.name}');
  }

  static SpriteAtlasIconData iconFor(WonderType type) {
    return SpriteAtlasIconData(frameId: frameIdFor(type), cropToContent: false);
  }
}

class WonderSpriteIcon extends StatelessWidget {
  const WonderSpriteIcon({
    required this.type,
    required this.size,
    this.opacity = 1,
    super.key,
  });

  final WonderType type;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SpriteAtlasIcon(
      data: WonderSpriteCatalog.iconFor(type),
      size: size,
      opacity: opacity,
    );
  }
}
