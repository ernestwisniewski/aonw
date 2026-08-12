import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/state.dart';
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

CommandTransportResult acknowledgedCommandTransportResult({
  required WireCommandAck acknowledgment,
  required GameClientState state,
  required CanonicalGameSnapshot snapshot,
  required int offset,
  List<UiEffect> uiEffects = const [],
  List<GameEvent> events = const [],
  List<MovementCommandExecution> movementExecutions = const [],
  List<CombatAnimationFact> combatAnimations = const [],
}) {
  return CommandTransportResult(
    state: state,
    uiEffects: uiEffects,
    snapshot: snapshot,
    offset: offset,
    authoritativeTick: acknowledgment.tick,
    authoritativeStartMicrosUtc: acknowledgment.timestamp
        ?.add(multiplayerPresentationStartBuffer)
        .microsecondsSinceEpoch,
    events: events,
    movementExecutions: movementExecutions,
    combatAnimations: combatAnimations,
    storedSnapshot: true,
    accepted: acknowledgment.accepted,
    rejectionReason: acknowledgment.reason,
  );
}

List<UiEffect> commandRejectionUiEffects(String? reason) {
  return switch (reason) {
    'worker_automation_no_target' => const [
      ShowWorkerAutomationNoTargetEffect(),
    ],
    'unit_production_missing_strategic_resource' => const [
      ShowHudFeedbackEffect(
        reason: HudFeedbackReason.productionStrategicResourceShortage,
      ),
    ],
    _ => const [],
  };
}
