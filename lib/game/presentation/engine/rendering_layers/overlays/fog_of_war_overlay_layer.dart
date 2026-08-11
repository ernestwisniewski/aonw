import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/overlays/fog_of_war_overlay.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:flame/components.dart';

class FogOfWarOverlayLayer extends Component with LayerAttachment {
  FogOfWarOverlay? _component;
  WorldMap? _lastMapData;
  FogOfWarState? _lastVisibilityState;
  String? _lastVisibilityPlayerId;

  FogOfWarOverlayLayer() {
    priority = MapPriority.fog;
  }

  void sync({
    required Component parent,
    required WorldMap mapData,
    required FogVisibilityQuery visibility,
  }) {
    ensureAttachedTo(parent);
    if (!visibility.isEnabled) {
      clear();
      return;
    }

    final existing = _component;
    if (existing != null &&
        identical(_lastMapData, mapData) &&
        _lastVisibilityPlayerId == visibility.playerId &&
        (identical(_lastVisibilityState, visibility.state) ||
            _lastVisibilityState == visibility.state)) {
      return;
    }

    final visibilityByHex = {
      for (final tile in mapData.tiles)
        HexCoordinate.fromTile(tile): visibility.visibilityForTile(tile),
    };

    if (existing != null && identical(existing.mapData, mapData)) {
      existing.updateVisibility(visibilityByHex);
      _rememberVisibility(mapData, visibility);
      return;
    }

    clear();
    final component = FogOfWarOverlay(
      mapData: mapData,
      visibilityByHex: visibilityByHex,
    );
    _component = component;
    _rememberVisibility(mapData, visibility);
    unawaited(Future<void>.value(add(component)));
  }

  void _rememberVisibility(WorldMap mapData, FogVisibilityQuery visibility) {
    _lastMapData = mapData;
    _lastVisibilityState = visibility.state;
    _lastVisibilityPlayerId = visibility.playerId;
  }

  void clear() {
    _component?.removeFromParent();
    _component = null;
    _lastMapData = null;
    _lastVisibilityState = null;
    _lastVisibilityPlayerId = null;
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  FogOfWarOverlay? get componentForTesting => _component;
}
