/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:aonw_core/protocol.dart' as _i2;

abstract class MultiplayerServerMessage
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MultiplayerServerMessage._({
    required this.serverMessageId,
    required this.matchId,
    required this.offset,
    this.match,
    this.snapshot,
    this.event,
    this.ack,
  });

  factory MultiplayerServerMessage({
    required String serverMessageId,
    required String matchId,
    required int offset,
    _i2.WireMatch? match,
    _i2.WireSnapshot? snapshot,
    _i2.WireEvent? event,
    _i2.WireCommandAck? ack,
  }) = _MultiplayerServerMessageImpl;

  factory MultiplayerServerMessage.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MultiplayerServerMessage(
      serverMessageId: jsonSerialization['serverMessageId'] as String,
      matchId: jsonSerialization['matchId'] as String,
      offset: jsonSerialization['offset'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i2.WireMatch.fromJson(jsonSerialization['match']),
      snapshot: jsonSerialization['snapshot'] == null
          ? null
          : _i2.WireSnapshot.fromJson(jsonSerialization['snapshot']),
      event: jsonSerialization['event'] == null
          ? null
          : _i2.WireEvent.fromJson(jsonSerialization['event']),
      ack: jsonSerialization['ack'] == null
          ? null
          : _i2.WireCommandAck.fromJson(jsonSerialization['ack']),
    );
  }

  String serverMessageId;

  String matchId;

  int offset;

  _i2.WireMatch? match;

  _i2.WireSnapshot? snapshot;

  _i2.WireEvent? event;

  _i2.WireCommandAck? ack;

  /// Returns a shallow copy of this [MultiplayerServerMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MultiplayerServerMessage copyWith({
    String? serverMessageId,
    String? matchId,
    int? offset,
    _i2.WireMatch? match,
    _i2.WireSnapshot? snapshot,
    _i2.WireEvent? event,
    _i2.WireCommandAck? ack,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MultiplayerServerMessage',
      'serverMessageId': serverMessageId,
      'matchId': matchId,
      'offset': offset,
      if (match != null) 'match': match?.toJson(),
      if (snapshot != null) 'snapshot': snapshot?.toJson(),
      if (event != null) 'event': event?.toJson(),
      if (ack != null) 'ack': ack?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MultiplayerServerMessage',
      'serverMessageId': serverMessageId,
      'matchId': matchId,
      'offset': offset,
      if (match != null)
        'match':
            // ignore: unnecessary_type_check
            match is _i1.ProtocolSerialization
            ? (match as _i1.ProtocolSerialization).toJsonForProtocol()
            : match?.toJson(),
      if (snapshot != null)
        'snapshot':
            // ignore: unnecessary_type_check
            snapshot is _i1.ProtocolSerialization
            ? (snapshot as _i1.ProtocolSerialization).toJsonForProtocol()
            : snapshot?.toJson(),
      if (event != null)
        'event':
            // ignore: unnecessary_type_check
            event is _i1.ProtocolSerialization
            ? (event as _i1.ProtocolSerialization).toJsonForProtocol()
            : event?.toJson(),
      if (ack != null)
        'ack':
            // ignore: unnecessary_type_check
            ack is _i1.ProtocolSerialization
            ? (ack as _i1.ProtocolSerialization).toJsonForProtocol()
            : ack?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MultiplayerServerMessageImpl extends MultiplayerServerMessage {
  _MultiplayerServerMessageImpl({
    required String serverMessageId,
    required String matchId,
    required int offset,
    _i2.WireMatch? match,
    _i2.WireSnapshot? snapshot,
    _i2.WireEvent? event,
    _i2.WireCommandAck? ack,
  }) : super._(
         serverMessageId: serverMessageId,
         matchId: matchId,
         offset: offset,
         match: match,
         snapshot: snapshot,
         event: event,
         ack: ack,
       );

  /// Returns a shallow copy of this [MultiplayerServerMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MultiplayerServerMessage copyWith({
    String? serverMessageId,
    String? matchId,
    int? offset,
    Object? match = _Undefined,
    Object? snapshot = _Undefined,
    Object? event = _Undefined,
    Object? ack = _Undefined,
  }) {
    return MultiplayerServerMessage(
      serverMessageId: serverMessageId ?? this.serverMessageId,
      matchId: matchId ?? this.matchId,
      offset: offset ?? this.offset,
      match: match is _i2.WireMatch? ? match : this.match?.copyWith(),
      snapshot: snapshot is _i2.WireSnapshot?
          ? snapshot
          : this.snapshot?.copyWith(),
      event: event is _i2.WireEvent? ? event : this.event?.copyWith(),
      ack: ack is _i2.WireCommandAck? ? ack : this.ack?.copyWith(),
    );
  }
}
