import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/protocol.dart';

final class LiveServerEvent {
  LiveServerEvent({
    required this.wire,
    required Iterable<GameEvent> events,
    required Iterable<CombatAnimationFact> combatAnimations,
    this.snapshot,
    required Iterable<MovementCommandExecution> movementExecutions,
  }) : events = List<GameEvent>.unmodifiable(events),
       combatAnimations = List<CombatAnimationFact>.unmodifiable(
         combatAnimations,
       ),
       movementExecutions = List<MovementCommandExecution>.unmodifiable(
         movementExecutions,
       );

  factory LiveServerEvent.fromWire({
    required WireEvent wire,
    required Iterable<GameEvent> events,
    required Iterable<CombatAnimationFact> combatAnimations,
    SaveSnapshot? snapshot,
  }) {
    return LiveServerEvent(
      wire: wire,
      events: events,
      combatAnimations: combatAnimations,
      snapshot: snapshot,
      movementExecutions: wire.movementExecutions.values.map(
        MovementExecutionWireMapper.decode,
      ),
    );
  }

  final WireEvent wire;
  final List<GameEvent> events;
  final List<CombatAnimationFact> combatAnimations;
  final SaveSnapshot? snapshot;
  final List<MovementCommandExecution> movementExecutions;
}
