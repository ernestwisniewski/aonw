import 'package:aonw_core/protocol/protocol_version.dart';
import 'package:aonw_core/protocol/wire_json.dart';

class WireEvent {
  final int v;
  final String matchId;
  final int offset;
  final DateTime timestamp;
  final String? actorPlayerId;
  final int? tick;
  final Map<String, dynamic>? command;
  final List<Map<String, dynamic>> events;

  const WireEvent({
    this.v = kProtocolVersion,
    required this.matchId,
    required this.offset,
    required this.timestamp,
    this.actorPlayerId,
    this.tick,
    this.command,
    this.events = const [],
  });

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
    );
  }

  Map<String, dynamic> toJson() => {
    'v': v,
    'matchId': matchId,
    'offset': offset,
    'timestamp': timestamp.toUtc().toIso8601String(),
    if (actorPlayerId != null) 'actorPlayerId': actorPlayerId,
    if (tick != null) 'tick': tick,
    if (command != null) 'command': Map<String, dynamic>.from(command!),
    'events': events.map(Map<String, dynamic>.from).toList(),
  };

  WireEvent copyWith({
    int? v,
    String? matchId,
    int? offset,
    DateTime? timestamp,
    String? actorPlayerId,
    int? tick,
    Map<String, dynamic>? command,
    List<Map<String, dynamic>>? events,
  }) {
    return WireEvent(
      v: v ?? this.v,
      matchId: matchId ?? this.matchId,
      offset: offset ?? this.offset,
      timestamp: timestamp ?? this.timestamp,
      actorPlayerId: actorPlayerId ?? this.actorPlayerId,
      tick: tick ?? this.tick,
      command: command ?? this.command,
      events: events ?? this.events,
    );
  }
}
