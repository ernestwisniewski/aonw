import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/protocol.dart';

final class AcknowledgedCommandPresentation {
  const AcknowledgedCommandPresentation({
    required this.interactionEffects,
    required this.movementExecutions,
  });

  final List<UiEffect> interactionEffects;
  final List<MovementCommandExecution> movementExecutions;
}

AcknowledgedCommandPresentation projectAcknowledgedCommandPresentation({
  required Iterable<UiEffect> localEffects,
  required WireMovementExecutionList movementExecutions,
}) {
  return AcknowledgedCommandPresentation(
    interactionEffects: List.unmodifiable([
      for (final effect in localEffects)
        if (effect is! AnimateUnitMoveEffect) effect,
    ]),
    movementExecutions: List.unmodifiable(
      movementExecutions.values.map(MovementExecutionWireMapper.decode),
    ),
  );
}
