import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter/material.dart';

abstract final class WonderSpriteCatalog {
  static const String assetPath = 'assets/sprites/wonders_atlas_a_5x4_512.png';
  static const int columns = 5;
  static const int rows = 4;
  static const int slotsPerAtlas = columns * rows;
  static const double sourceInset = 0;

  static int slotFor(WonderType type) {
    if (type.index >= slotsPerAtlas) {
      throw StateError('Missing wonder atlas slot for ${type.name}');
    }
    return type.index;
  }

  static SpriteAtlasIconData iconFor(WonderType type) {
    final slot = slotFor(type);
    return SpriteAtlasIconData(
      assetPath: assetPath,
      columns: columns,
      rows: rows,
      column: slot % columns,
      row: slot ~/ columns,
      sourceInset: sourceInset,
      cropToContent: false,
    );
  }
}

class WonderSpriteIcon extends StatelessWidget {
  const WonderSpriteIcon({
    required this.type,
    required this.size,
    this.fallback,
    this.opacity = 1,
    super.key,
  });

  final WonderType type;
  final double size;
  final Widget? fallback;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SpriteAtlasIcon(
      data: WonderSpriteCatalog.iconFor(type),
      size: size,
      fallback:
          fallback ??
          const GameIcon(
            GameIcons.victory,
            size: GameIconSize.regular,
            color: GameUiTheme.goldLight,
          ),
      opacity: opacity,
    );
  }
}
