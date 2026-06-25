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

abstract class MultiplayerClientMessage
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MultiplayerClientMessage._({
    required this.clientMessageId,
    required this.lastSeenOffset,
    required this.requestSnapshot,
    this.command,
  });

  factory MultiplayerClientMessage({
    required String clientMessageId,
    required int lastSeenOffset,
    required bool requestSnapshot,
    _i2.WireCommand? command,
  }) = _MultiplayerClientMessageImpl;

  factory MultiplayerClientMessage.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MultiplayerClientMessage(
      clientMessageId: jsonSerialization['clientMessageId'] as String,
      lastSeenOffset: jsonSerialization['lastSeenOffset'] as int,
      requestSnapshot: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['requestSnapshot'],
      ),
      command: jsonSerialization['command'] == null
          ? null
          : _i2.WireCommand.fromJson(jsonSerialization['command']),
    );
  }

  String clientMessageId;

  int lastSeenOffset;

  bool requestSnapshot;

  _i2.WireCommand? command;

  /// Returns a shallow copy of this [MultiplayerClientMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MultiplayerClientMessage copyWith({
    String? clientMessageId,
    int? lastSeenOffset,
    bool? requestSnapshot,
    _i2.WireCommand? command,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MultiplayerClientMessage',
      'clientMessageId': clientMessageId,
      'lastSeenOffset': lastSeenOffset,
      'requestSnapshot': requestSnapshot,
      if (command != null) 'command': command?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MultiplayerClientMessage',
      'clientMessageId': clientMessageId,
      'lastSeenOffset': lastSeenOffset,
      'requestSnapshot': requestSnapshot,
      if (command != null)
        'command':
            // ignore: unnecessary_type_check
            command is _i1.ProtocolSerialization
            ? (command as _i1.ProtocolSerialization).toJsonForProtocol()
            : command?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MultiplayerClientMessageImpl extends MultiplayerClientMessage {
  _MultiplayerClientMessageImpl({
    required String clientMessageId,
    required int lastSeenOffset,
    required bool requestSnapshot,
    _i2.WireCommand? command,
  }) : super._(
         clientMessageId: clientMessageId,
         lastSeenOffset: lastSeenOffset,
         requestSnapshot: requestSnapshot,
         command: command,
       );

  /// Returns a shallow copy of this [MultiplayerClientMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MultiplayerClientMessage copyWith({
    String? clientMessageId,
    int? lastSeenOffset,
    bool? requestSnapshot,
    Object? command = _Undefined,
  }) {
    return MultiplayerClientMessage(
      clientMessageId: clientMessageId ?? this.clientMessageId,
      lastSeenOffset: lastSeenOffset ?? this.lastSeenOffset,
      requestSnapshot: requestSnapshot ?? this.requestSnapshot,
      command: command is _i2.WireCommand? ? command : this.command?.copyWith(),
    );
  }
}
