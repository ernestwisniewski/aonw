import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/protocol.dart';

class CommandCodec {
  const CommandCodec();

  WireCommand toWire({
    required String matchId,
    required int tick,
    int? turn,
    required String actorPlayerId,
    required DomainCommand command,
  }) {
    return WireCommand(
      matchId: matchId,
      tick: tick,
      turn: turn,
      actorPlayerId: actorPlayerId,
      command: DomainCommandCodec.toJson(command),
    );
  }

  DomainCommand fromWire(WireCommand wire) {
    return DomainCommandCodec.fromJson(wire.command);
  }

  GameCommandContext contextFromWire(WireCommand wire) {
    return GameCommandContext(actorPlayerId: wire.actorPlayerId);
  }
}

class EventCodec {
  const EventCodec();

  WireEvent toWire({
    required String matchId,
    required int offset,
    required DateTime timestamp,
    required List<GameEvent> events,
    String? actorPlayerId,
    int? tick,
    int? turn,
    DomainCommand? command,
    Iterable<WireMovementExecution> movementExecutions = const [],
  }) {
    return WireEvent(
      matchId: matchId,
      offset: offset,
      timestamp: timestamp,
      actorPlayerId: actorPlayerId,
      tick: tick,
      turn: turn,
      command: command == null ? null : DomainCommandCodec.toJson(command),
      events: events.map(GameEventSerializer.toJson).toList(),
      movementExecutions: WireMovementExecutionList(movementExecutions),
    );
  }

  List<GameEvent> eventsFromWire(WireEvent wire) {
    return wire.events.map(GameEventSerializer.fromJson).toList();
  }

  List<CombatAnimationFact> combatAnimationFactsFromWire(WireEvent wire) {
    return CombatAnimationFactCodec.fromEventPayloads(wire.events);
  }

  List<Map<String, dynamic>> eventsToJsonList(Iterable<GameEvent> events) {
    return events.map(GameEventSerializer.toJson).toList();
  }

  List<GameEvent> eventsFromJsonList(Iterable<Map<String, dynamic>> events) {
    return events.map(GameEventSerializer.fromJson).toList();
  }

  List<CombatAnimationFact> combatAnimationFactsFromJsonList(
    Iterable<Map<String, dynamic>> events,
  ) {
    return CombatAnimationFactCodec.fromEventPayloads(events);
  }

  DomainCommand? commandFromWire(WireEvent wire) {
    final command = wire.command;
    if (command == null) return null;
    if (command['recordKind'] == 'system') return null;
    return DomainCommandCodec.fromJson(command);
  }
}

class SnapshotCodec {
  const SnapshotCodec();

  WireSnapshot toWire({
    required String matchId,
    required CanonicalGameSnapshot snapshot,
  }) {
    final data = CanonicalGameSnapshotCodec.encode(snapshot);
    return WireSnapshot(
      matchId: matchId,
      offset: data.eventLogOffset,
      save: data.save,
      state: data.state,
    );
  }

  CanonicalGameSnapshot fromWire(WireSnapshot wire) {
    return CanonicalGameSnapshotCodec.decode(
      CanonicalGameSnapshotData(
        save: wire.save,
        state: wire.state,
        eventLogOffset: wire.offset,
      ),
    );
  }
}
