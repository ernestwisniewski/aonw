import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class UnitSpriteIcon extends StatelessWidget {
  final GameUnitType type;
  final double size;
  final Widget? fallback;
  final double opacity;
  final int column;
  final int row;

  const UnitSpriteIcon({
    required this.type,
    required this.size,
    this.fallback,
    this.opacity = 1,
    this.column = 0,
    this.row = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final definition = UnitSpriteCatalog.definitionFor(type);
    final safeColumn = definition == null
        ? column
        : column.clamp(0, definition.columns - 1).toInt();
    final safeRow = definition == null
        ? row
        : row.clamp(0, definition.rows - 1).toInt();
    return SpriteAtlasIcon(
      data: definition == null
          ? null
          : SpriteAtlasIconData(
              assetPath: definition.assetPath,
              columns: definition.columns,
              rows: definition.rows,
              column: safeColumn,
              row: safeRow,
              sourceInset: definition.sourceInset,
              adjustmentId: _adjustmentIdForRow(definition, safeRow),
              adjustmentFrameIndex: safeColumn,
            ),
      size: size,
      fallback: fallback,
      opacity: opacity,
    );
  }

  String? _adjustmentIdForRow(UnitSpriteDefinition definition, int row) {
    for (final entry in definition.actions.entries) {
      if (entry.value.row == row) return entry.key.name;
    }
    return UnitSpriteAction.idle.name;
  }
}
