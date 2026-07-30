import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

/// Binds recipient-visible movement evidence to its exact canonical event.
///
/// A unit is admitted only when all of its events and executions have one
/// complete, continuous and unambiguous assignment. Unmatched evidence is
/// suppressed rather than inferred from snapshots.
abstract final class MovementEventExecutionMatcher {
  static MovementEventExecutionPlan match({
    required List<GameEvent> events,
    required Iterable<MovementCommandExecution> executions,
    required Iterable<GameUnit> beforeUnits,
    required Iterable<GameUnit> afterUnits,
  }) {
    final indexedEvents = <String, List<_IndexedMovementEvent>>{};
    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      if (event is UnitMovedEvent) {
        indexedEvents
            .putIfAbsent(event.unitId, () => [])
            .add(_IndexedMovementEvent(index, event));
      }
    }

    final orderedExecutions = executions.toList(growable: false);
    final indexedExecutions = <String, List<_IndexedExecution>>{};
    for (var index = 0; index < orderedExecutions.length; index++) {
      final execution = orderedExecutions[index];
      indexedExecutions
          .putIfAbsent(execution.unitId, () => [])
          .add(_IndexedExecution(index, execution));
    }

    final before = _UniqueUnitIndex(beforeUnits);
    final after = _UniqueUnitIndex(afterUnits);
    final eventIndexByExecutionIndex = <int, int>{};
    final unitIds = {...indexedEvents.keys, ...indexedExecutions.keys};
    for (final unitId in unitIds) {
      final unitEvents = indexedEvents[unitId] ?? const [];
      final unitExecutions = indexedExecutions[unitId] ?? const [];
      if (unitEvents.isEmpty ||
          unitExecutions.isEmpty ||
          _hasDuplicateEvents(unitEvents) ||
          !_matchesSnapshotChain(
            unitExecutions,
            before[unitId],
            after[unitId],
          )) {
        continue;
      }
      final assignment = _uniqueAssignment(unitEvents, unitExecutions);
      if (assignment == null) continue;
      for (var index = 0; index < unitExecutions.length; index++) {
        eventIndexByExecutionIndex[unitExecutions[index].index] =
            assignment[index];
      }
    }

    return MovementEventExecutionPlan._(
      orderedExecutions,
      eventIndexByExecutionIndex,
    );
  }
}

final class MovementEventExecutionPlan {
  const MovementEventExecutionPlan._(
    this._executions,
    this._eventIndexByExecutionIndex,
  );

  final List<MovementCommandExecution> _executions;
  final Map<int, int> _eventIndexByExecutionIndex;

  Iterable<MovementCommandExecution> executionsForEventRange(
    int start,
    int end, {
    Set<String> excludedUnitIds = const {},
  }) sync* {
    for (var index = 0; index < _executions.length; index++) {
      final eventIndex = _eventIndexByExecutionIndex[index];
      final execution = _executions[index];
      if (eventIndex != null &&
          eventIndex >= start &&
          eventIndex < end &&
          !excludedUnitIds.contains(execution.unitId)) {
        yield execution;
      }
    }
  }
}

List<int>? _uniqueAssignment(
  List<_IndexedMovementEvent> events,
  List<_IndexedExecution> executions,
) {
  final solutions = <List<int>>[];

  void search(int eventOffset, int executionOffset, List<int> assignment) {
    if (solutions.length > 1) return;
    if (eventOffset == events.length) {
      if (executionOffset == executions.length) {
        solutions.add(List<int>.of(assignment));
      }
      return;
    }
    if (executionOffset >= executions.length) return;

    final event = events[eventOffset];
    var destination = (
      col: executions[executionOffset].execution.fromCol,
      row: executions[executionOffset].execution.fromRow,
    );
    if (destination != (col: event.event.fromCol, row: event.event.fromRow)) {
      return;
    }
    for (var end = executionOffset; end < executions.length; end++) {
      final execution = executions[end].execution;
      final origin = (col: execution.fromCol, row: execution.fromRow);
      if (origin != destination) break;
      destination = (
        col: execution.destination.col,
        row: execution.destination.row,
      );
      if (destination != (col: event.event.toCol, row: event.event.toRow)) {
        continue;
      }
      final count = end - executionOffset + 1;
      search(eventOffset + 1, end + 1, [
        ...assignment,
        ...List.filled(count, event.index),
      ]);
    }
  }

  search(0, 0, const []);
  return solutions.length == 1 ? solutions.single : null;
}

bool _hasDuplicateEvents(List<_IndexedMovementEvent> events) {
  final keys = <(int, int, int, int)>{};
  for (final indexed in events) {
    final event = indexed.event;
    if (!keys.add((event.fromCol, event.fromRow, event.toCol, event.toRow))) {
      return true;
    }
  }
  return false;
}

bool _matchesSnapshotChain(
  List<_IndexedExecution> executions,
  GameUnit? before,
  GameUnit? after,
) {
  if (before == null ||
      after == null ||
      before.ownerPlayerId != after.ownerPlayerId) {
    return false;
  }
  var destination = (col: before.col, row: before.row);
  for (final indexed in executions) {
    final execution = indexed.execution;
    if ((col: execution.fromCol, row: execution.fromRow) != destination) {
      return false;
    }
    destination = (
      col: execution.destination.col,
      row: execution.destination.row,
    );
  }
  return destination == (col: after.col, row: after.row);
}

final class _IndexedMovementEvent {
  const _IndexedMovementEvent(this.index, this.event);

  final int index;
  final UnitMovedEvent event;
}

final class _IndexedExecution {
  const _IndexedExecution(this.index, this.execution);

  final int index;
  final MovementCommandExecution execution;
}

final class _UniqueUnitIndex {
  _UniqueUnitIndex(Iterable<GameUnit> units) {
    for (final unit in units) {
      if (_duplicates.contains(unit.id)) continue;
      if (_units.containsKey(unit.id)) {
        _units.remove(unit.id);
        _duplicates.add(unit.id);
      } else {
        _units[unit.id] = unit;
      }
    }
  }

  final Map<String, GameUnit> _units = {};
  final Set<String> _duplicates = {};

  GameUnit? operator [](String unitId) => _units[unitId];
}
