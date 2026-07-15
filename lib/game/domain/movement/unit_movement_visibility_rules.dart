import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

abstract final class UnitMovementVisibilityRules {
  static const hiddenPathingRange = 3;

  static bool canPlanThroughTile({
    required GameUnit unit,
    required MapTileView tile,
    required FogVisibilityQuery visibility,
  }) {
    final tileVisibility = visibility.visibilityForTile(tile);
    if (tileVisibility.isKnown) return true;

    final distance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      HexCoordinate.fromTile(tile),
    );
    return distance <= hiddenPathingRange;
  }
}
