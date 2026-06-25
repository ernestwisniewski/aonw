import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/fog_of_war_overlay.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:flame/components.dart';

class FogOfWarOverlayLayer extends Component with LayerAttachment {
  FogOfWarOverlay? _component;

  FogOfWarOverlayLayer() {
    priority = MapPriority.fog;
  }

  void sync({
    required Component parent,
    required MapData mapData,
    required FogVisibilityQuery visibility,
  }) {
    ensureAttachedTo(parent);
    if (!visibility.isEnabled) {
      clear();
      return;
    }

    final visibilityByHex = {
      for (final tile in mapData.tiles)
        HexCoordinate.fromTile(tile): visibility.visibilityForTile(tile),
    };

    final existing = _component;
    if (existing != null && identical(existing.mapData, mapData)) {
      existing.updateVisibility(visibilityByHex);
      return;
    }

    clear();
    final component = FogOfWarOverlay(
      mapData: mapData,
      visibilityByHex: visibilityByHex,
    );
    _component = component;
    unawaited(Future<void>.value(add(component)));
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

  FogOfWarOverlay? get componentForTesting => _component;
}
