import 'package:aonw_core/protocol/protocol_version.dart';
import 'package:aonw_core/protocol/wire_json.dart';
import 'package:aonw_core/protocol/wire_movement_execution.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wire_event.freezed.dart';

@freezed
abstract class WireEvent with _$WireEvent {
  const WireEvent._();

  const factory WireEvent({
    @Default(kProtocolVersion) int v,
    required String matchId,
    required int offset,
    required DateTime timestamp,
    String? actorPlayerId,
    int? tick,
    int? turn,
    Map<String, dynamic>? command,
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> events,
    required WireMovementExecutionList movementExecutions,
  }) = _WireEvent;

  factory WireEvent.fromJson(Map<String, dynamic> json) {
    final rawEvents = WireJson.requiredList(json['events'], 'WireEvent.events');
    return WireEvent(
      v: WireJson.readVersion(json, 'WireEvent'),
      matchId: WireJson.requiredString(json, 'WireEvent', 'matchId'),
      offset: WireJson.requiredInt(json, 'WireEvent', 'offset'),
      timestamp: WireJson.requiredDateTimeUtc(json, 'WireEvent', 'timestamp'),
      actorPlayerId: WireJson.optionalString(
        json,
        'WireEvent',
        'actorPlayerId',
      ),
      tick: WireJson.optionalInt(json, 'WireEvent', 'tick'),
      turn: WireJson.optionalInt(json, 'WireEvent', 'turn'),
      command: switch (json['command']) {
        final Map<Object?, Object?> value => Map.unmodifiable(
          Map<String, dynamic>.from(value),
        ),
        null => null,
        final value => throw ArgumentError.value(
          value,
          'WireEvent.command',
          'Expected a JSON object or null',
        ),
      },
      events: rawEvents
          .map((event) => WireJson.requiredMap(event, 'WireEvent.events[]'))
          .toList(),
      movementExecutions: WireMovementExecutionList.fromJson(
        json['movementExecutions'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'v': v,
    'matchId': matchId,
    'offset': offset,
    'timestamp': timestamp.toUtc().toIso8601String(),
    if (actorPlayerId != null) 'actorPlayerId': actorPlayerId,
    if (tick != null) 'tick': tick,
    if (turn != null) 'turn': turn,
    if (command != null) 'command': Map<String, dynamic>.from(command!),
    'events': events.map(Map<String, dynamic>.from).toList(),
    'movementExecutions': movementExecutions.toJson(),
  };
}
