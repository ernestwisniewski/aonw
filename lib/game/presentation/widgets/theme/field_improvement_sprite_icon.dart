import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:flutter/material.dart';

abstract final class FieldImprovementSpriteIconCatalog {
  static SpriteAtlasIconData iconFor(FieldImprovementType type, {int era = 0}) {
    final eraColumn = era
        .clamp(0, FieldImprovementSpriteCatalog.columns - 1)
        .toInt();
    return SpriteAtlasIconData(
      assetPath: FieldImprovementSpriteCatalog.assetPathFor(type),
      columns: FieldImprovementSpriteCatalog.sheetColumns,
      rows: FieldImprovementSpriteCatalog.sheetRows,
      column: FieldImprovementSpriteCatalog.sheetColumnForType(type),
      row: eraColumn,
      sourceInset: FieldImprovementSpriteCatalog.sourceInset,
      adjustmentId: FieldImprovementSpriteCatalog.adjustmentIdForVariant(
        type: type,
        eraColumn: eraColumn,
      ),
      sourceRectResolver: (image) =>
          FieldImprovementSpriteCatalog.sourceRectFor(
            imageWidth: image.width,
            imageHeight: image.height,
            type: type,
            eraColumn: eraColumn,
          ),
      cropToContent: false,
    );
  }
}

class FieldImprovementSpriteIcon extends StatelessWidget {
  const FieldImprovementSpriteIcon({
    required this.type,
    required this.size,
    this.eraColumn = 0,
    this.width,
    this.height,
    this.fallback,
    this.opacity = 1,
    super.key,
  });

  final FieldImprovementType type;
  final int eraColumn;
  final double size;
  final double? width;
  final double? height;
  final Widget? fallback;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SpriteAtlasIcon(
      data: FieldImprovementSpriteIconCatalog.iconFor(type, era: eraColumn),
      size: size,
      width: width,
      height: height,
      fallback: fallback,
      opacity: opacity,
    );
  }
}
