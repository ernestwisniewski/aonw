import 'package:aonw_core/protocol/protocol_version.dart';
import 'package:aonw_core/protocol/wire_json.dart';
import 'package:aonw_core/protocol/wire_snapshot.dart';

class WireCommandAck {
  final int v;
  final String matchId;
  final bool accepted;
  final int offset;
  final WireSnapshot snapshot;
  final List<Map<String, dynamic>> events;
  final String? reason;

  const WireCommandAck({
    this.v = kProtocolVersion,
    required this.matchId,
    required this.accepted,
    required this.offset,
    required this.snapshot,
    this.events = const [],
    this.reason,
  });

  factory WireCommandAck.fromJson(Map<String, dynamic> json) {
    final accepted = json['accepted'];
    if (accepted is! bool) {
      throw ArgumentError.value(
        accepted,
        'WireCommandAck.accepted',
        'Expected a bool',
      );
    }
    final rawEvents = switch (json['events']) {
      final List<dynamic> value => value,
      null => const <dynamic>[],
      final value => throw ArgumentError.value(
        value,
        'WireCommandAck.events',
        'Expected a JSON array or null',
      ),
    };
    return WireCommandAck(
      v: WireJson.readVersion(json, 'WireCommandAck'),
      matchId: WireJson.requiredString(json, 'WireCommandAck', 'matchId'),
      accepted: accepted,
      offset: WireJson.requiredInt(json, 'WireCommandAck', 'offset'),
      snapshot: WireSnapshot.fromJson(
        WireJson.requiredMap(json['snapshot'], 'WireCommandAck.snapshot'),
      ),
      events: rawEvents
          .map(
            (event) => WireJson.requiredMap(event, 'WireCommandAck.events[]'),
          )
          .toList(),
      reason: WireJson.optionalString(json, 'WireCommandAck', 'reason'),
    );
  }

  Map<String, dynamic> toJson() => {
    'v': v,
    'matchId': matchId,
    'accepted': accepted,
    'offset': offset,
    'snapshot': snapshot.toJson(),
    'events': events.map(Map<String, dynamic>.from).toList(),
    if (reason != null) 'reason': reason,
  };

  WireCommandAck copyWith({
    int? v,
    String? matchId,
    bool? accepted,
    int? offset,
    WireSnapshot? snapshot,
    List<Map<String, dynamic>>? events,
    String? reason,
  }) {
    return WireCommandAck(
      v: v ?? this.v,
      matchId: matchId ?? this.matchId,
      accepted: accepted ?? this.accepted,
      offset: offset ?? this.offset,
      snapshot: snapshot ?? this.snapshot,
      events: events ?? this.events,
      reason: reason ?? this.reason,
    );
  }
}
