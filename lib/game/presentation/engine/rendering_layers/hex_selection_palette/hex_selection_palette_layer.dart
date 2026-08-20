import 'dart:async';

import 'package:aonw/game/presentation/engine/hex_selection/hex_selection_target.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/hex_selection_palette/hex_selection_palette_component.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:flame/components.dart';

final class HexSelectionPaletteLayer extends Component with LayerAttachment {
  HexSelectionPaletteLayer({required this.onSelected});

  final HexSelectionTargetCallback onSelected;
  HexSelectionPaletteComponent? _component;

  HexSelectionPaletteComponent? get componentForTesting => _component;
  bool get visible => _component != null;

  void open({
    required Component parent,
    required int col,
    required int row,
    required List<HexSelectionTarget> targets,
    required double directionAngle,
    required double screenScale,
  }) {
    ensureAttachedTo(parent);
    clear();
    final component =
        HexSelectionPaletteComponent(
            targets: targets,
            directionAngle: directionAngle,
            onSelected: (target) {
              clear();
              onSelected(target);
            },
            onCanceled: clear,
          )
          ..position = HexGeometry.projectedTopFaceCenter(
            col: col,
            row: row,
            perspectiveY: HexGrid.perspectiveY,
          )
          ..scale = Vector2.all(screenScale);
    _component = component;
    unawaited(Future<void>.value(attachedOwner.add(component)));
  }

  void clear() {
    _component?.removeFromParent();
    _component = null;
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }
}
