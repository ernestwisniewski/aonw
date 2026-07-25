import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class QueuedMovementEffectBuilder {
  /// Projects authoritative ordered movement evidence without re-planning.
  ///
  /// When both unit snapshots are supplied, invalid evidence is suppressed per
  /// complete unit chain. Omitting both preserves trusted local-domain mapping.
  static List<AnimateUnitMoveEffect> fromExecutions(
    Iterable<MovementCommandExecution> executions, {
    Iterable<GameUnit>? beforeUnits,
    Iterable<GameUnit>? afterUnits,
  }) {
    if ((beforeUnits == null) != (afterUnits == null)) {
      throw ArgumentError(
        'beforeUnits and afterUnits must be provided together.',
      );
    }
    final ordered = List<MovementCommandExecution>.of(executions);
    if (ordered.isEmpty) return const [];
    final validUnitIds = beforeUnits == null
        ? null
        : _validExecutionUnitIds(
            executions: ordered,
            beforeUnits: beforeUnits,
            afterUnits: afterUnits!,
          );
    final effects = [
      for (final execution in ordered)
        if (validUnitIds == null || validUnitIds.contains(execution.unitId))
          AnimateUnitMoveEffect(
            unitId: execution.unitId,
            fromCol: execution.fromCol,
            fromRow: execution.fromRow,
            steps: execution.steps,
          ),
    ];
    return effects.isEmpty
        ? const []
        : List<AnimateUnitMoveEffect>.unmodifiable(effects);
  }

  /// Builds animations from an authoritative before/after unit delta.
  ///
  /// Ordinary moves have no path data in recipient-projected snapshots.
  /// Enable [inferDirectMoves] only for a contiguous live transition; snapshot
  /// reloads and offset-gap recovery do not contain enough history to animate
  /// a direct delta reliably.
  static List<AnimateUnitMoveEffect> fromUnitDelta({
    required Iterable<GameUnit> beforeUnits,
    required Iterable<GameUnit> afterUnits,
    bool inferDirectMoves = false,
  }) {
    final beforeById = {for (final unit in beforeUnits) unit.id: unit};
    final effects = <AnimateUnitMoveEffect>[];

    for (final after in afterUnits) {
      final before = beforeById[after.id];
      if (before == null) continue;
      if (before.col == after.col && before.row == after.row) continue;

      final steps = _stepsForMovedUnit(
        before: before,
        after: after,
        inferDirectMoves: inferDirectMoves,
      );
      if (steps == null) continue;

      effects.add(
        AnimateUnitMoveEffect(
          unitId: before.id,
          fromCol: before.col,
          fromRow: before.row,
          steps: steps,
        ),
      );
    }

    return effects;
  }

  static List<UnitMovementStep>? _stepsForMovedUnit({
    required GameUnit before,
    required GameUnit after,
    required bool inferDirectMoves,
  }) {
    final pathSteps = _pathStepsFor(before);
    if (pathSteps == null) {
      return inferDirectMoves || before.isAutoExploring || after.isAutoExploring
          ? [_destinationStep(after)]
          : null;
    }

    final startIndex = pathSteps.indexWhere(
      (step) => step.col == before.col && step.row == before.row,
    );
    if (startIndex < 0) return null;
    final endIndex = pathSteps.indexWhere(
      (step) => step.col == after.col && step.row == after.row,
      startIndex + 1,
    );
    if (endIndex <= startIndex) return null;
    return pathSteps.skip(startIndex + 1).take(endIndex - startIndex).toList();
  }

  static List<UnitMovementStep>? _pathStepsFor(GameUnit unit) {
    final queuedPath = unit.queuedPath;
    if (queuedPath != null) return queuedPath.steps;
    if (unit.isMerchant) return unit.merchantTradeRoute?.steps;
    return null;
  }

  static UnitMovementStep _destinationStep(GameUnit unit) {
    return UnitMovementStep(
      col: unit.col,
      row: unit.row,
      enterCost: 0,
      cumulativeCost: 0,
    );
  }
}

Set<String> _validExecutionUnitIds({
  required Iterable<MovementCommandExecution> executions,
  required Iterable<GameUnit> beforeUnits,
  required Iterable<GameUnit> afterUnits,
}) {
  final chains = <String, _ExecutionChain>{};
  for (final execution in executions) {
    chains.putIfAbsent(execution.unitId, _ExecutionChain.new).add(execution);
  }
  final before = _UniqueUnitIndex(beforeUnits);
  final after = _UniqueUnitIndex(afterUnits);
  return {
    for (final entry in chains.entries)
      if (entry.value.matches(before[entry.key], after[entry.key])) entry.key,
  };
}

final class _ExecutionChain {
  ({int col, int row})? _origin;
  ({int col, int row})? _destination;
  var _continuous = true;

  void add(MovementCommandExecution execution) {
    final origin = (col: execution.fromCol, row: execution.fromRow);
    _origin ??= origin;
    if (_destination != null && _destination != origin) _continuous = false;
    final destination = execution.destination;
    _destination = (col: destination.col, row: destination.row);
  }

  bool matches(GameUnit? before, GameUnit? after) {
    if (!_continuous ||
        before == null ||
        after == null ||
        before.ownerPlayerId != after.ownerPlayerId) {
      return false;
    }
    return _origin == (col: before.col, row: before.row) &&
        _destination == (col: after.col, row: after.row);
  }
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
