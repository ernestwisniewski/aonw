import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/movement/merchant_trade_route_rules.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_queued_path_advancer.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_fortification_rules.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class TurnUnitMovementAdvance {
  factory TurnUnitMovementAdvance({
    required List<GameUnit> units,
    bool changed = false,
    Iterable<MovementCommandExecution> executions = const [],
    Iterable<GameEvent> events = const [],
  }) {
    return TurnUnitMovementAdvance._(
      units: units,
      changed: changed,
      executions: executions.isEmpty ? const [] : List.unmodifiable(executions),
      events: events.isEmpty ? const [] : List.unmodifiable(events),
    );
  }

  const TurnUnitMovementAdvance._({
    required this.units,
    required this.changed,
    required this.executions,
    required this.events,
  });

  final List<GameUnit> units;
  final bool changed;
  final List<MovementCommandExecution> executions;
  final List<GameEvent> events;
}

abstract final class TurnUnitMovementAdvancer {
  static TurnUnitMovementAdvance advance({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required DiplomacyState diplomacy,
    required FogOfWarState fogOfWar,
    required Set<String> playerIds,
    required MapTraversalView mapData,
  }) {
    final alerts = _fortificationAlerts(
      units: units,
      playerIds: playerIds,
      mapData: mapData,
    );
    final resetUnits = [
      for (final unit in units)
        playerIds.contains(unit.ownerPlayerId) ? _resetForNewTurn(unit) : unit,
    ];
    var changed = _unitsChanged(units, resetUnits);
    final finalUnits = <GameUnit>[];
    final executions = <MovementCommandExecution>[];
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
        diplomacy: diplomacy,
        fogOfWar: fogOfWar,
        mapData: mapData,
      );
      if (advanced.changed) changed = true;
      finalUnits.add(advanced.unit);
      executions.addAll(advanced.executions);
    }
    return TurnUnitMovementAdvance(
      units: finalUnits,
      changed: changed,
      executions: executions,
      events: alerts,
    );
  }

  static ({
    GameUnit unit,
    bool changed,
    List<MovementCommandExecution> executions,
  })
  _advanceUnit({
    required GameUnit unit,
    required List<GameUnit> allUnits,
    required List<GameCity> cities,
    required DiplomacyState diplomacy,
    required FogOfWarState fogOfWar,
    required MapTraversalView mapData,
  }) {
    final routeAdvance = MerchantTradeRouteRules.advanceUnit(
      unit: unit,
      units: allUnits,
      cities: cities,
      mapData: mapData,
    );
    final routed = routeAdvance.unit;
    final executions = <MovementCommandExecution>[
      if (routeAdvance.moved)
        MovementCommandExecution(
          unitId: unit.id,
          fromCol: unit.col,
          fromRow: unit.row,
          steps: routeAdvance.movedSteps,
        ),
    ];
    if (routed.type == GameUnitType.merchant &&
        routed.merchantTradeRoute != null) {
      return (unit: routed, changed: routed != unit, executions: executions);
    }
    final queued = TurnQueuedPathAdvancer.advance(
      unit: routed,
      mapData: mapData,
      allUnits: allUnits,
      cities: cities,
      diplomacy: diplomacy,
      fogOfWar: fogOfWar,
    );
    if (queued.execution case final execution?) executions.add(execution);
    return (
      unit: queued.unit,
      changed: routed != unit || queued.unit != routed,
      executions: executions,
    );
  }

  static GameUnit _resetForNewTurn(GameUnit unit) {
    if (unit.isFortified) {
      return UnitFortificationRules.recoverForNewTurn(unit: unit);
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

  static List<GameEvent> _fortificationAlerts({
    required List<GameUnit> units,
    required Set<String> playerIds,
    required MapTileLookup mapData,
  }) {
    final fortifiers =
        units
            .where(
              (unit) =>
                  playerIds.contains(unit.ownerPlayerId) && unit.isFortified,
            )
            .toList()
          ..sort((first, second) {
            final ownerOrder = first.ownerPlayerId.compareTo(
              second.ownerPlayerId,
            );
            return ownerOrder != 0 ? ownerOrder : first.id.compareTo(second.id);
          });
    return [
      for (final fortifier in fortifiers)
        if (UnitFortificationRules.visibleEnemies(
              unit: fortifier,
              mapData: mapData,
              units: units,
            )
            case final targets when targets.isNotEmpty)
          FortifiedUnitThreatenedEvent(
            unitId: fortifier.id,
            ownerPlayerId: fortifier.ownerPlayerId,
            targets: [
              for (final target in targets)
                FortifiedUnitThreatTarget(
                  unitId: target.id,
                  col: target.col,
                  row: target.row,
                ),
            ],
          ),
    ];
  }

  static bool _unitsChanged(List<GameUnit> before, List<GameUnit> after) {
    for (var index = 0; index < after.length; index++) {
      if (after[index] != before[index]) return true;
    }
    return false;
  }
}
