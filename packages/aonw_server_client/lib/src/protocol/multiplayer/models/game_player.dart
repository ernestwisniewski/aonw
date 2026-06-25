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
import '../../multiplayer/models/game_match.dart' as _i2;
import 'package:aonw_server_client/src/protocol/protocol.dart' as _i3;

abstract class GamePlayer implements _i1.SerializableModel {
  GamePlayer._({
    this.id,
    required this.matchId,
    this.match,
    required this.publicPlayerId,
    required this.userIdentifier,
    required this.displayName,
    required this.colorValue,
    required this.countryId,
    required this.kind,
    required this.connectionState,
    required this.ready,
    required this.seatOrder,
  });

  factory GamePlayer({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String publicPlayerId,
    required String userIdentifier,
    required String displayName,
    required int colorValue,
    required String countryId,
    required String kind,
    required String connectionState,
    required bool ready,
    required int seatOrder,
  }) = _GamePlayerImpl;

  factory GamePlayer.fromJson(Map<String, dynamic> jsonSerialization) {
    return GamePlayer(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      publicPlayerId: jsonSerialization['publicPlayerId'] as String,
      userIdentifier: jsonSerialization['userIdentifier'] as String,
      displayName: jsonSerialization['displayName'] as String,
      colorValue: jsonSerialization['colorValue'] as int,
      countryId: jsonSerialization['countryId'] as String,
      kind: jsonSerialization['kind'] as String,
      connectionState: jsonSerialization['connectionState'] as String,
      ready: _i1.BoolJsonExtension.fromJson(jsonSerialization['ready']),
      seatOrder: jsonSerialization['seatOrder'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int matchId;

  _i2.GameMatch? match;

  String publicPlayerId;

  String userIdentifier;

  String displayName;

  int colorValue;

  String countryId;

  String kind;

  String connectionState;

  bool ready;

  int seatOrder;

  /// Returns a shallow copy of this [GamePlayer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GamePlayer copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    String? publicPlayerId,
    String? userIdentifier,
    String? displayName,
    int? colorValue,
    String? countryId,
    String? kind,
    String? connectionState,
    bool? ready,
    int? seatOrder,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GamePlayer',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'publicPlayerId': publicPlayerId,
      'userIdentifier': userIdentifier,
      'displayName': displayName,
      'colorValue': colorValue,
      'countryId': countryId,
      'kind': kind,
      'connectionState': connectionState,
      'ready': ready,
      'seatOrder': seatOrder,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GamePlayerImpl extends GamePlayer {
  _GamePlayerImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String publicPlayerId,
    required String userIdentifier,
    required String displayName,
    required int colorValue,
    required String countryId,
    required String kind,
    required String connectionState,
    required bool ready,
    required int seatOrder,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         publicPlayerId: publicPlayerId,
         userIdentifier: userIdentifier,
         displayName: displayName,
         colorValue: colorValue,
         countryId: countryId,
         kind: kind,
         connectionState: connectionState,
         ready: ready,
         seatOrder: seatOrder,
       );

  /// Returns a shallow copy of this [GamePlayer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GamePlayer copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    String? publicPlayerId,
    String? userIdentifier,
    String? displayName,
    int? colorValue,
    String? countryId,
    String? kind,
    String? connectionState,
    bool? ready,
    int? seatOrder,
  }) {
    return GamePlayer(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      publicPlayerId: publicPlayerId ?? this.publicPlayerId,
      userIdentifier: userIdentifier ?? this.userIdentifier,
      displayName: displayName ?? this.displayName,
      colorValue: colorValue ?? this.colorValue,
      countryId: countryId ?? this.countryId,
      kind: kind ?? this.kind,
      connectionState: connectionState ?? this.connectionState,
      ready: ready ?? this.ready,
      seatOrder: seatOrder ?? this.seatOrder,
    );
  }
}
