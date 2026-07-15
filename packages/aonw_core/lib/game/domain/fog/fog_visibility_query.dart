import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/fog/fog_visibility.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

class FogVisibilityQuery {
  final String playerId;
  final FogOfWarState state;

  const FogVisibilityQuery({required this.playerId, required this.state});

  bool get isEnabled => playerId.isNotEmpty;

  FogVisibility visibilityForHex(HexCoordinate hex) {
    if (!isEnabled) return FogVisibility.visible;
    return state.visibilityFor(playerId, hex);
  }

  FogVisibility visibilityForTile(MapTileView tile) {
    return visibilityForHex(HexCoordinate.fromTile(tile));
  }

  bool canInspectTile(MapTileView tile) => visibilityForTile(tile).isKnown;

  bool canRememberStaticAt(int col, int row) {
    return visibilityForHex(HexCoordinate(col: col, row: row)).isKnown;
  }

  bool canSeeDynamicAt(int col, int row) {
    return visibilityForHex(HexCoordinate(col: col, row: row)).isVisible;
  }
}
