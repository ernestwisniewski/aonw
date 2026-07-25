import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/protocol.dart';

abstract final class AcknowledgedCommandEffectResolver {
  static List<UiEffect> resolve({
    required List<UiEffect> localEffects,
    required WireMovementExecutionList? movementExecutions,
    required Iterable<GameUnit> beforeUnits,
    required Iterable<GameUnit> afterUnits,
  }) {
    if (movementExecutions == null) {
      if (localEffects.isNotEmpty) return localEffects;
      return QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: beforeUnits,
        afterUnits: afterUnits,
      );
    }

    final authoritativeMovementEffects =
        QueuedMovementEffectBuilder.fromExecutions(
          movementExecutions.values.map(MovementExecutionWireMapper.decode),
          beforeUnits: beforeUnits,
          afterUnits: afterUnits,
        );
    final effects = [
      for (final effect in localEffects)
        if (effect is! AnimateUnitMoveEffect) effect,
      ...authoritativeMovementEffects,
    ];
    return effects.isEmpty ? const [] : List<UiEffect>.unmodifiable(effects);
  }
}
