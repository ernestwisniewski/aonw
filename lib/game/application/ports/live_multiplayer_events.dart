import 'package:aonw/game/application/ports/auth_token.dart';
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
    CanonicalGameSnapshot? snapshot,
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
  final CanonicalGameSnapshot? snapshot;
  final List<MovementCommandExecution> movementExecutions;
}

abstract interface class LiveMultiplayerEventHandle {
  Future<void> close();

  Future<WireCommandAck> sendCommand({
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
    Duration timeout = const Duration(seconds: 10),
  });
}

abstract interface class LiveMultiplayerEvents {
  Future<LiveMultiplayerEventHandle> subscribe({
    required String matchId,
    required AuthToken token,
    Future<AuthToken> Function()? tokenReader,
    required int fromOffset,
    int Function()? nextOffset,
    required void Function(LiveServerEvent event) onEvent,
    required void Function(CanonicalGameSnapshot snapshot) onSnapshotResync,
    void Function(WireMatch match)? onMatch,
    void Function()? onConnected,
    void Function()? onReconnecting,
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onDone,
  });
}
