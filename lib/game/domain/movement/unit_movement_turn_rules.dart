import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class UnitMovementTurnRules {
  static GameUnit resetForNewTurn(
    GameUnit unit, {
    MapTileLookup? mapData,
    Iterable<GameUnit>? allUnits,
  }) {
    if (unit.isFortified) {
      return UnitFortificationRules.recoverForNewTurn(
        unit: unit,
        mapData: mapData,
        units: allUnits,
      );
    }

    final resetMovementPoints = unit.isWorking
        ? 0
        : UnitMovementBalance.maxMovementPointsFor(
            type: unit.type,
            carriedArtifactId: unit.carriedArtifactId,
          );
    return unit
        .copyWith(movementPoints: resetMovementPoints)
        .copyWithQueuedPath(
          _shouldKeepQueuedPath(unit) ? unit.queuedPath : null,
        );
  }

  /// Returns the unit with its queuedPath cleared if the path is no longer
  /// valid (target occupied or route blocked). Returns unit unchanged if
  /// queuedPath is null or still valid.
  static GameUnit validateQueuedPath({
    required GameUnit unit,
    required MapTraversalView mapData,
    required List<GameUnit> allUnits,
    Iterable<GameCity> cities = const [],
    DiplomacyState diplomacy = DiplomacyState.empty,
    FogOfWarState fogOfWar = FogOfWarState.empty,
  }) {
    final path = unit.queuedPath;
    if (path == null) return unit;
    if (!_shouldKeepQueuedPath(unit)) return unit.copyWithQueuedPath(null);

    final targetTile = mapData.tileAt(path.targetCol, path.targetRow);
    if (targetTile == null) return unit.copyWithQueuedPath(null);
    final visibility = UnitMovementVisibilityRules.visibilityForActor(
      fogOfWar: fogOfWar,
      actorPlayerId: unit.ownerPlayerId,
    );

    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: UnitMovementVisibilityRules.planningUnitsForActor(
        units: allUnits,
        movingUnit: unit,
        actorPlayerId: unit.ownerPlayerId,
        visibility: visibility,
      ),
      canEnterTile: (tile) => MovementHiddenObstacleRules.canPlanThroughCity(
        cities: cities,
        diplomacy: diplomacy,
        unit: unit,
        tile: tile,
        visibility: visibility,
      ),
      canEnterOccupiedTile:
          ({
            required movingUnit,
            required blockingUnit,
            required col,
            required row,
          }) => MerchantTradeRouteRules.canShareOccupiedCityTile(
            movingUnit: movingUnit,
            col: col,
            row: row,
            cities: cities,
          ),
    ).plan(unit: unit, targetTile: targetTile);

    if (plan == null) return unit.copyWithQueuedPath(null);
    if (MovementHiddenObstacleRules.reachablePathHitsHiddenBlocker(
      plan: plan,
      movingUnit: unit,
      allUnits: allUnits,
      cities: cities,
      diplomacy: diplomacy,
      visibility: visibility,
    )) {
      return unit;
    }
    return unit;
  }

  static bool _shouldKeepQueuedPath(GameUnit unit) {
    if (unit.isWorking) return false;
    if (unit.type != GameUnitType.merchant) return true;
    return unit.merchantTradeRoute == null;
  }
}
