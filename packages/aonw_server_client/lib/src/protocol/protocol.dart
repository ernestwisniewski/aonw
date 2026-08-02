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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'auth/models/account_auth_exception.dart' as _i2;
import 'auth/models/external_auth_poll_result.dart' as _i3;
import 'auth/models/external_auth_start.dart' as _i4;
import 'auth/models/steam_auth_poll_result.dart' as _i5;
import 'auth/models/steam_auth_start.dart' as _i6;
import 'multiplayer/models/create_match_request.dart' as _i7;
import 'multiplayer/models/game_event.dart' as _i8;
import 'multiplayer/models/game_match.dart' as _i9;
import 'multiplayer/models/game_player.dart' as _i10;
import 'multiplayer/models/game_snapshot.dart' as _i11;
import 'multiplayer/models/multiplayer_client_message.dart' as _i12;
import 'multiplayer/models/multiplayer_exception.dart' as _i13;
import 'multiplayer/models/multiplayer_server_message.dart' as _i14;
import 'package:aonw_core/protocol.dart' as _i15;
import 'package:aonw_core/protocol/wire_match.dart' as _i16;
import 'package:aonw_core/protocol/wire_event.dart' as _i17;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i18;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i19;
export 'auth/models/account_auth_exception.dart';
export 'auth/models/external_auth_poll_result.dart';
export 'auth/models/external_auth_start.dart';
export 'auth/models/steam_auth_poll_result.dart';
export 'auth/models/steam_auth_start.dart';
export 'multiplayer/models/create_match_request.dart';
export 'multiplayer/models/game_event.dart';
export 'multiplayer/models/game_match.dart';
export 'multiplayer/models/game_player.dart';
export 'multiplayer/models/game_snapshot.dart';
export 'multiplayer/models/multiplayer_client_message.dart';
export 'multiplayer/models/multiplayer_exception.dart';
export 'multiplayer/models/multiplayer_server_message.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.AccountAuthException) {
      return _i2.AccountAuthException.fromJson(data) as T;
    }
    if (t == _i3.ExternalAuthPollResult) {
      return _i3.ExternalAuthPollResult.fromJson(data) as T;
    }
    if (t == _i4.ExternalAuthStart) {
      return _i4.ExternalAuthStart.fromJson(data) as T;
    }
    if (t == _i5.SteamAuthPollResult) {
      return _i5.SteamAuthPollResult.fromJson(data) as T;
    }
    if (t == _i6.SteamAuthStart) {
      return _i6.SteamAuthStart.fromJson(data) as T;
    }
    if (t == _i7.CreateMatchRequest) {
      return _i7.CreateMatchRequest.fromJson(data) as T;
    }
    if (t == _i8.GameEvent) {
      return _i8.GameEvent.fromJson(data) as T;
    }
    if (t == _i9.GameMatch) {
      return _i9.GameMatch.fromJson(data) as T;
    }
    if (t == _i10.GamePlayer) {
      return _i10.GamePlayer.fromJson(data) as T;
    }
    if (t == _i11.GameSnapshot) {
      return _i11.GameSnapshot.fromJson(data) as T;
    }
    if (t == _i12.MultiplayerClientMessage) {
      return _i12.MultiplayerClientMessage.fromJson(data) as T;
    }
    if (t == _i13.MultiplayerException) {
      return _i13.MultiplayerException.fromJson(data) as T;
    }
    if (t == _i14.MultiplayerServerMessage) {
      return _i14.MultiplayerServerMessage.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AccountAuthException?>()) {
      return (data != null ? _i2.AccountAuthException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i3.ExternalAuthPollResult?>()) {
      return (data != null ? _i3.ExternalAuthPollResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.ExternalAuthStart?>()) {
      return (data != null ? _i4.ExternalAuthStart.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.SteamAuthPollResult?>()) {
      return (data != null ? _i5.SteamAuthPollResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.SteamAuthStart?>()) {
      return (data != null ? _i6.SteamAuthStart.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.CreateMatchRequest?>()) {
      return (data != null ? _i7.CreateMatchRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.GameEvent?>()) {
      return (data != null ? _i8.GameEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.GameMatch?>()) {
      return (data != null ? _i9.GameMatch.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.GamePlayer?>()) {
      return (data != null ? _i10.GamePlayer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.GameSnapshot?>()) {
      return (data != null ? _i11.GameSnapshot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.MultiplayerClientMessage?>()) {
      return (data != null
              ? _i12.MultiplayerClientMessage.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i13.MultiplayerException?>()) {
      return (data != null ? _i13.MultiplayerException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.MultiplayerServerMessage?>()) {
      return (data != null
              ? _i14.MultiplayerServerMessage.fromJson(data)
              : null)
          as T;
    }
    if (t == _i15.WireEvent) {
      return _i15.WireEvent.fromJson(data) as T;
    }
    if (t == List<_i10.GamePlayer>) {
      return (data as List).map((e) => deserialize<_i10.GamePlayer>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i10.GamePlayer>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i10.GamePlayer>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i11.GameSnapshot>) {
      return (data as List)
              .map((e) => deserialize<_i11.GameSnapshot>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i11.GameSnapshot>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i11.GameSnapshot>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i8.GameEvent>) {
      return (data as List).map((e) => deserialize<_i8.GameEvent>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i8.GameEvent>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i8.GameEvent>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i15.WireSnapshot) {
      return _i15.WireSnapshot.fromJson(data) as T;
    }
    if (t == _i1.getType<_i15.WireCommand?>()) {
      return (data != null ? _i15.WireCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WireMatch?>()) {
      return (data != null ? _i15.WireMatch.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WireSnapshot?>()) {
      return (data != null ? _i15.WireSnapshot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WireEvent?>()) {
      return (data != null ? _i15.WireEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WireCommandAck?>()) {
      return (data != null ? _i15.WireCommandAck.fromJson(data) : null) as T;
    }
    if (t == List<_i16.WireMatch>) {
      return (data as List).map((e) => deserialize<_i16.WireMatch>(e)).toList()
          as T;
    }
    if (t == List<_i17.WireEvent>) {
      return (data as List).map((e) => deserialize<_i17.WireEvent>(e)).toList()
          as T;
    }
    if (t == _i15.WireAiPlayer) {
      return _i15.WireAiPlayer.fromJson(data) as T;
    }
    if (t == _i15.WireCommand) {
      return _i15.WireCommand.fromJson(data) as T;
    }
    if (t == _i15.WireCommandAck) {
      return _i15.WireCommandAck.fromJson(data) as T;
    }
    if (t == _i15.WireMatch) {
      return _i15.WireMatch.fromJson(data) as T;
    }
    if (t == _i15.WirePlayer) {
      return _i15.WirePlayer.fromJson(data) as T;
    }
    if (t == _i1.getType<_i15.WireAiPlayer?>()) {
      return (data != null ? _i15.WireAiPlayer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WireCommand?>()) {
      return (data != null ? _i15.WireCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WireCommandAck?>()) {
      return (data != null ? _i15.WireCommandAck.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WireEvent?>()) {
      return (data != null ? _i15.WireEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WireMatch?>()) {
      return (data != null ? _i15.WireMatch.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WirePlayer?>()) {
      return (data != null ? _i15.WirePlayer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WireSnapshot?>()) {
      return (data != null ? _i15.WireSnapshot.fromJson(data) : null) as T;
    }
    try {
      return _i18.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i19.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i15.WireAiPlayer => 'WireAiPlayer',
      _i15.WireCommand => 'WireCommand',
      _i15.WireCommandAck => 'WireCommandAck',
      _i15.WireEvent => 'WireEvent',
      _i15.WireMatch => 'WireMatch',
      _i15.WirePlayer => 'WirePlayer',
      _i15.WireSnapshot => 'WireSnapshot',
      _i2.AccountAuthException => 'AccountAuthException',
      _i3.ExternalAuthPollResult => 'ExternalAuthPollResult',
      _i4.ExternalAuthStart => 'ExternalAuthStart',
      _i5.SteamAuthPollResult => 'SteamAuthPollResult',
      _i6.SteamAuthStart => 'SteamAuthStart',
      _i7.CreateMatchRequest => 'CreateMatchRequest',
      _i8.GameEvent => 'GameEvent',
      _i9.GameMatch => 'GameMatch',
      _i10.GamePlayer => 'GamePlayer',
      _i11.GameSnapshot => 'GameSnapshot',
      _i12.MultiplayerClientMessage => 'MultiplayerClientMessage',
      _i13.MultiplayerException => 'MultiplayerException',
      _i14.MultiplayerServerMessage => 'MultiplayerServerMessage',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('aonw.', '');
    }

    switch (data) {
      case _i15.WireAiPlayer():
        return 'WireAiPlayer';
      case _i15.WireCommand():
        return 'WireCommand';
      case _i15.WireCommandAck():
        return 'WireCommandAck';
      case _i15.WireEvent():
        return 'WireEvent';
      case _i15.WireMatch():
        return 'WireMatch';
      case _i15.WirePlayer():
        return 'WirePlayer';
      case _i15.WireSnapshot():
        return 'WireSnapshot';
      case _i2.AccountAuthException():
        return 'AccountAuthException';
      case _i3.ExternalAuthPollResult():
        return 'ExternalAuthPollResult';
      case _i4.ExternalAuthStart():
        return 'ExternalAuthStart';
      case _i5.SteamAuthPollResult():
        return 'SteamAuthPollResult';
      case _i6.SteamAuthStart():
        return 'SteamAuthStart';
      case _i7.CreateMatchRequest():
        return 'CreateMatchRequest';
      case _i8.GameEvent():
        return 'GameEvent';
      case _i9.GameMatch():
        return 'GameMatch';
      case _i10.GamePlayer():
        return 'GamePlayer';
      case _i11.GameSnapshot():
        return 'GameSnapshot';
      case _i12.MultiplayerClientMessage():
        return 'MultiplayerClientMessage';
      case _i13.MultiplayerException():
        return 'MultiplayerException';
      case _i14.MultiplayerServerMessage():
        return 'MultiplayerServerMessage';
    }
    className = _i18.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i19.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'WireAiPlayer') {
      return deserialize<_i15.WireAiPlayer>(data['data']);
    }
    if (dataClassName == 'WireCommand') {
      return deserialize<_i15.WireCommand>(data['data']);
    }
    if (dataClassName == 'WireCommandAck') {
      return deserialize<_i15.WireCommandAck>(data['data']);
    }
    if (dataClassName == 'WireEvent') {
      return deserialize<_i15.WireEvent>(data['data']);
    }
    if (dataClassName == 'WireMatch') {
      return deserialize<_i15.WireMatch>(data['data']);
    }
    if (dataClassName == 'WirePlayer') {
      return deserialize<_i15.WirePlayer>(data['data']);
    }
    if (dataClassName == 'WireSnapshot') {
      return deserialize<_i15.WireSnapshot>(data['data']);
    }
    if (dataClassName == 'AccountAuthException') {
      return deserialize<_i2.AccountAuthException>(data['data']);
    }
    if (dataClassName == 'ExternalAuthPollResult') {
      return deserialize<_i3.ExternalAuthPollResult>(data['data']);
    }
    if (dataClassName == 'ExternalAuthStart') {
      return deserialize<_i4.ExternalAuthStart>(data['data']);
    }
    if (dataClassName == 'SteamAuthPollResult') {
      return deserialize<_i5.SteamAuthPollResult>(data['data']);
    }
    if (dataClassName == 'SteamAuthStart') {
      return deserialize<_i6.SteamAuthStart>(data['data']);
    }
    if (dataClassName == 'CreateMatchRequest') {
      return deserialize<_i7.CreateMatchRequest>(data['data']);
    }
    if (dataClassName == 'GameEvent') {
      return deserialize<_i8.GameEvent>(data['data']);
    }
    if (dataClassName == 'GameMatch') {
      return deserialize<_i9.GameMatch>(data['data']);
    }
    if (dataClassName == 'GamePlayer') {
      return deserialize<_i10.GamePlayer>(data['data']);
    }
    if (dataClassName == 'GameSnapshot') {
      return deserialize<_i11.GameSnapshot>(data['data']);
    }
    if (dataClassName == 'MultiplayerClientMessage') {
      return deserialize<_i12.MultiplayerClientMessage>(data['data']);
    }
    if (dataClassName == 'MultiplayerException') {
      return deserialize<_i13.MultiplayerException>(data['data']);
    }
    if (dataClassName == 'MultiplayerServerMessage') {
      return deserialize<_i14.MultiplayerServerMessage>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i18.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i19.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i18.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i19.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
