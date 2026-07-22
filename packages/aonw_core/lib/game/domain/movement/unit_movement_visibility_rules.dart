import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/fog/fog_visibility.dart';
import 'package:aonw_core/game/domain/fog/fog_visibility_query.dart';
import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/game/domain/hex/hex_distance.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

/// Authoritative knowledge boundary for manual movement planning.
abstract final class UnitMovementVisibilityRules {
  static const int hiddenPathingRange = 3;

  static FogVisibilityQuery visibilityForActor({
    required FogOfWarState fogOfWar,
    required String actorPlayerId,
    bool ignoreDynamicFog = false,
  }) {
    final tracksActor =
        !ignoreDynamicFog &&
        actorPlayerId.isNotEmpty &&
        fogOfWar.players.containsKey(actorPlayerId);
    return FogVisibilityQuery(
      playerId: tracksActor ? actorPlayerId : '',
      state: fogOfWar,
    );
  }

  static Iterable<GameUnit> planningUnitsForActor({
    required Iterable<GameUnit> units,
    required GameUnit movingUnit,
    required String actorPlayerId,
    required FogVisibilityQuery visibility,
  }) {
    if (!visibility.isEnabled) return units;
    return units.where(
      (candidate) =>
          candidate.id == movingUnit.id ||
          candidate.ownerPlayerId == actorPlayerId ||
          visibility.canSeeDynamicAt(candidate.col, candidate.row),
    );
  }

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
