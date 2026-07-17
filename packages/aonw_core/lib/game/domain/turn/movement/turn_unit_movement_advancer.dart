import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/movement/merchant_trade_route_rules.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_queued_path_advancer.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_fortification_rules.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class TurnUnitMovementAdvance {
  const TurnUnitMovementAdvance({required this.units, this.changed = false});

  final List<GameUnit> units;
  final bool changed;
}

abstract final class TurnUnitMovementAdvancer {
  static TurnUnitMovementAdvance advance({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required Set<String> playerIds,
    required MapTraversalView mapData,
  }) {
    final resetUnits = [
      for (final unit in units)
        playerIds.contains(unit.ownerPlayerId)
            ? _resetForNewTurn(unit, mapData: mapData, allUnits: units)
            : unit,
    ];
    var changed = _unitsChanged(units, resetUnits);
    final finalUnits = <GameUnit>[];
    for (var index = 0; index < resetUnits.length; index++) {
      final unit = resetUnits[index];
      if (!playerIds.contains(unit.ownerPlayerId)) {
        finalUnits.add(unit);
        continue;
      }
      final currentAllUnits = [...finalUnits, ...resetUnits.sublist(index)];
      final advanced = _advanceUnit(
        unit: unit,
        allUnits: currentAllUnits,
        cities: cities,
        mapData: mapData,
      );
      if (advanced.changed) changed = true;
      finalUnits.add(advanced.unit);
    }
    return TurnUnitMovementAdvance(units: finalUnits, changed: changed);
  }

  static ({GameUnit unit, bool changed}) _advanceUnit({
    required GameUnit unit,
    required List<GameUnit> allUnits,
    required List<GameCity> cities,
    required MapTraversalView mapData,
  }) {
    final routed = MerchantTradeRouteRules.advanceUnit(
      unit: unit,
      units: allUnits,
      cities: cities,
      mapData: mapData,
    ).unit;
    if (routed.type == GameUnitType.merchant &&
        routed.merchantTradeRoute != null) {
      return (unit: routed, changed: routed != unit);
    }
    final moved = TurnQueuedPathAdvancer.advance(
      unit: routed,
      mapData: mapData,
      allUnits: allUnits,
      cities: cities,
    );
    return (unit: moved, changed: routed != unit || moved != routed);
  }

  static GameUnit _resetForNewTurn(
    GameUnit unit, {
    required MapTileLookup mapData,
    required Iterable<GameUnit> allUnits,
  }) {
    if (unit.isFortified) {
      return UnitFortificationRules.recoverForNewTurn(
        unit: unit,
        mapData: mapData,
        units: allUnits,
      );
    }
    final movementPoints = unit.isWorking
        ? 0
        : UnitMovementBalance.maxMovementPointsFor(
            type: unit.type,
            carriedArtifactId: unit.carriedArtifactId,
          );
    return unit
        .copyWith(movementPoints: movementPoints)
        .copyWithQueuedPath(
          TurnQueuedPathAdvancer.shouldKeep(unit) ? unit.queuedPath : null,
        );
  }

  static bool _unitsChanged(List<GameUnit> before, List<GameUnit> after) {
    for (var index = 0; index < after.length; index++) {
      if (after[index] != before[index]) return true;
    }
    return false;
  }
}
