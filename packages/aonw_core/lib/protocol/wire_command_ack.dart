import 'package:aonw_core/protocol/protocol_version.dart';
import 'package:aonw_core/protocol/wire_json.dart';
import 'package:aonw_core/protocol/wire_movement_execution.dart';
import 'package:aonw_core/protocol/wire_snapshot.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wire_command_ack.freezed.dart';

@freezed
abstract class WireCommandAck with _$WireCommandAck {
  const WireCommandAck._();

  const factory WireCommandAck({
    @Default(kProtocolVersion) int v,
    required String matchId,
    required bool accepted,
    required int offset,
    int? tick,
    DateTime? timestamp,
    required WireSnapshot snapshot,
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> events,
    String? reason,
    required WireMovementExecutionList movementExecutions,
  }) = _WireCommandAck;

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
      tick: WireJson.optionalInt(json, 'WireCommandAck', 'tick'),
      timestamp: json['timestamp'] == null
          ? null
          : WireJson.requiredDateTimeUtc(json, 'WireCommandAck', 'timestamp'),
      snapshot: WireSnapshot.fromJson(
        WireJson.requiredMap(json['snapshot'], 'WireCommandAck.snapshot'),
      ),
      events: rawEvents
          .map(
            (event) => WireJson.requiredMap(event, 'WireCommandAck.events[]'),
          )
          .toList(),
      reason: WireJson.optionalString(json, 'WireCommandAck', 'reason'),
      movementExecutions: WireMovementExecutionList.fromJson(
        json['movementExecutions'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'v': v,
    'matchId': matchId,
    'accepted': accepted,
    'offset': offset,
    if (tick != null) 'tick': tick,
    if (timestamp != null) 'timestamp': timestamp!.toUtc().toIso8601String(),
    'snapshot': snapshot.toJson(),
    'events': events.map(Map<String, dynamic>.from).toList(),
    if (reason != null) 'reason': reason,
    'movementExecutions': movementExecutions.toJson(),
  };
}
