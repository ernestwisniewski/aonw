import 'package:aonw_core/game/domain/diplomacy/diplomatic_contact.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_auto_explore_advancer.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_unit_movement_advancer.dart';

abstract final class TurnMovementOrchestrator {
  static TurnMovementResult resetForPlayers({
    required TurnMovementState state,
    required TurnMovementContext context,
  }) {
    if (context.playerIds.isEmpty) return TurnMovementResult(state: state);
    final advanced = TurnUnitMovementAdvancer.advance(
      units: state.units,
      cities: state.cities,
      diplomacy: state.diplomacy,
      fogOfWar: state.fogOfWar,
      playerIds: context.playerIds,
      mapData: context.mapData,
    );
    var fogOfWar = state.fogOfWar;
    if (advanced.changed) {
      fogOfWar = context.fogOfWarService.recompute(
        current: state.fogOfWar,
        mapData: context.mapData,
        playerIds: context.phaseKnownPlayerIds,
        units: advanced.units,
        cities: state.cities,
      );
    }
    final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: state.diplomacy,
      fogOfWar: fogOfWar,
      units: advanced.units,
      cities: state.cities,
      playerIds: context.phaseKnownPlayerIds,
    );
    final autoExplore = TurnAutoExploreAdvancer.advance(
      units: advanced.units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      interaction: state.interaction,
      cities: state.cities,
      playerIds: context.playerIds,
      phaseKnownPlayerIds: context.phaseKnownPlayerIds,
      mapData: context.mapData,
      fogOfWarService: context.fogOfWarService,
    );
    final changed =
        advanced.changed ||
        advanced.events.isNotEmpty ||
        !identical(diplomacy, state.diplomacy) ||
        autoExplore.changed;
    if (!changed) return TurnMovementResult(state: state);
    final executions = [...advanced.executions, ...autoExplore.executions];
    return TurnMovementResult(
      state: TurnMovementState(
        units: List.unmodifiable(autoExplore.units),
        cities: state.cities,
        diplomacy: autoExplore.diplomacy,
        fogOfWar: autoExplore.fogOfWar,
        interaction: autoExplore.interaction,
      ),
      changed: true,
      events: _withMissingMovementEvents([
        ...advanced.events,
        ...autoExplore.events,
      ], executions),
      executions: executions,
    );
  }
}

List<GameEvent> _withMissingMovementEvents(
  Iterable<GameEvent> events,
  Iterable<MovementCommandExecution> executions,
) {
  final orderedEvents = events.toList(growable: false);
  final existing = {
    for (final event in orderedEvents.whereType<UnitMovedEvent>())
      _movementKey(
        event.unitId,
        event.fromCol,
        event.fromRow,
        event.toCol,
        event.toRow,
      ),
  };
  final byUnitId = <String, List<MovementCommandExecution>>{};
  for (final execution in executions) {
    byUnitId.putIfAbsent(execution.unitId, () => []).add(execution);
  }
  final leadingAlerts = orderedEvents
      .takeWhile((event) => event is FortifiedUnitThreatenedEvent)
      .toList(growable: false);
  return [
    ...leadingAlerts,
    for (final entry in byUnitId.entries)
      if (entry.value.last.steps.isNotEmpty &&
          !existing.contains(_executionKey(entry.key, entry.value)))
        UnitMovedEvent(
          unitId: entry.key,
          fromCol: entry.value.first.fromCol,
          fromRow: entry.value.first.fromRow,
          toCol: entry.value.last.destination.col,
          toRow: entry.value.last.destination.row,
        ),
    ...orderedEvents.skip(leadingAlerts.length),
  ];
}

String _executionKey(String unitId, List<MovementCommandExecution> executions) {
  final first = executions.first;
  final last = executions.last;
  return _movementKey(
    unitId,
    first.fromCol,
    first.fromRow,
    last.destination.col,
    last.destination.row,
  );
}

String _movementKey(
  String unitId,
  int fromCol,
  int fromRow,
  int toCol,
  int toRow,
) => '$unitId\u0000$fromCol\u0000$fromRow\u0000$toCol\u0000$toRow';
