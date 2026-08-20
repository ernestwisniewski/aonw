import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class UnitSpriteIcon extends StatelessWidget {
  final GameUnitType type;
  final double size;
  final double opacity;
  final int column;
  final int row;

  const UnitSpriteIcon({
    required this.type,
    required this.size,
    this.opacity = 1,
    this.column = 0,
    this.row = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final definition = UnitSpriteCatalog.definitionFor(type);
    if (definition == null) {
      return SpriteAtlasIcon(data: null, size: size, opacity: opacity);
    }
    final safeColumn = column.clamp(0, 5).toInt();
    final action = _actionForRow(definition, row);
    final sequenceId = definition.sequenceIdFor(action);
    return SpriteAtlasIcon(
      data: SpriteAtlasIconData(
        frameId: sequenceId.frame(safeColumn),
        adjustmentSequenceId: sequenceId,
        adjustmentFrameIndex: safeColumn,
      ),
      size: size,
      opacity: opacity,
    );
  }

  UnitSpriteAction _actionForRow(UnitSpriteDefinition definition, int row) {
    final ordered = definition.actions.keys.toList(growable: false);
    return ordered[row.clamp(0, ordered.length - 1).toInt()];
  }
}
