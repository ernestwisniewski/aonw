import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Immutable renderer-neutral movement evidence for one engine command.
final class MovementExecutionDelta {
  factory MovementExecutionDelta({
    required Iterable<GameUnit> beforeUnits,
    required Iterable<GameUnit> afterUnits,
    Iterable<MovementCommandExecution> executions = const [],
  }) {
    final before = List<GameUnit>.unmodifiable(beforeUnits);
    return MovementExecutionDelta._owned(
      beforeUnits: before,
      afterUnits: identical(beforeUnits, afterUnits)
          ? before
          : List<GameUnit>.unmodifiable(afterUnits),
      executions: executions.isEmpty
          ? const []
          : List<MovementCommandExecution>.unmodifiable(executions),
    );
  }

  const MovementExecutionDelta._owned({
    required this.beforeUnits,
    required this.afterUnits,
    required this.executions,
  });

  static const empty = MovementExecutionDelta._owned(
    beforeUnits: [],
    afterUnits: [],
    executions: [],
  );

  final List<GameUnit> beforeUnits;
  final List<GameUnit> afterUnits;
  final List<MovementCommandExecution> executions;
}
