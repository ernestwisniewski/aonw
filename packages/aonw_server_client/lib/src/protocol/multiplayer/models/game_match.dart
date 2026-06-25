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
import '../../multiplayer/models/game_player.dart' as _i2;
import '../../multiplayer/models/game_snapshot.dart' as _i3;
import '../../multiplayer/models/game_event.dart' as _i4;
import 'package:aonw_server_client/src/protocol/protocol.dart' as _i5;

abstract class GameMatch implements _i1.SerializableModel {
  GameMatch._({
    this.id,
    required this.publicId,
    required this.ownerUserIdentifier,
    required this.name,
    required this.mapName,
    required this.state,
    required this.turn,
    required this.maxPlayers,
    required this.minPlayers,
    required this.private,
    required this.quickplay,
    required this.createdAt,
    this.startedAt,
    this.autoStartAt,
    this.inviteCode,
    this.players,
    this.snapshots,
    this.events,
  });

  factory GameMatch({
    int? id,
    required String publicId,
    required String ownerUserIdentifier,
    required String name,
    required String mapName,
    required String state,
    required int turn,
    required int maxPlayers,
    required int minPlayers,
    required bool private,
    required bool quickplay,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? autoStartAt,
    String? inviteCode,
    List<_i2.GamePlayer>? players,
    List<_i3.GameSnapshot>? snapshots,
    List<_i4.GameEvent>? events,
  }) = _GameMatchImpl;

  factory GameMatch.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameMatch(
      id: jsonSerialization['id'] as int?,
      publicId: jsonSerialization['publicId'] as String,
      ownerUserIdentifier: jsonSerialization['ownerUserIdentifier'] as String,
      name: jsonSerialization['name'] as String,
      mapName: jsonSerialization['mapName'] as String,
      state: jsonSerialization['state'] as String,
      turn: jsonSerialization['turn'] as int,
      maxPlayers: jsonSerialization['maxPlayers'] as int,
      minPlayers: jsonSerialization['minPlayers'] as int,
      private: _i1.BoolJsonExtension.fromJson(jsonSerialization['private']),
      quickplay: _i1.BoolJsonExtension.fromJson(jsonSerialization['quickplay']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      autoStartAt: jsonSerialization['autoStartAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['autoStartAt'],
            ),
      inviteCode: jsonSerialization['inviteCode'] as String?,
      players: jsonSerialization['players'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i2.GamePlayer>>(
              jsonSerialization['players'],
            ),
      snapshots: jsonSerialization['snapshots'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i3.GameSnapshot>>(
              jsonSerialization['snapshots'],
            ),
      events: jsonSerialization['events'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i4.GameEvent>>(
              jsonSerialization['events'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String publicId;

  String ownerUserIdentifier;

  String name;

  String mapName;

  String state;

  int turn;

  int maxPlayers;

  int minPlayers;

  bool private;

  bool quickplay;

  DateTime createdAt;

  DateTime? startedAt;

  DateTime? autoStartAt;

  String? inviteCode;

  List<_i2.GamePlayer>? players;

  List<_i3.GameSnapshot>? snapshots;

  List<_i4.GameEvent>? events;

  /// Returns a shallow copy of this [GameMatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameMatch copyWith({
    int? id,
    String? publicId,
    String? ownerUserIdentifier,
    String? name,
    String? mapName,
    String? state,
    int? turn,
    int? maxPlayers,
    int? minPlayers,
    bool? private,
    bool? quickplay,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? autoStartAt,
    String? inviteCode,
    List<_i2.GamePlayer>? players,
    List<_i3.GameSnapshot>? snapshots,
    List<_i4.GameEvent>? events,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameMatch',
      if (id != null) 'id': id,
      'publicId': publicId,
      'ownerUserIdentifier': ownerUserIdentifier,
      'name': name,
      'mapName': mapName,
      'state': state,
      'turn': turn,
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
      'private': private,
      'quickplay': quickplay,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (autoStartAt != null) 'autoStartAt': autoStartAt?.toJson(),
      if (inviteCode != null) 'inviteCode': inviteCode,
      if (players != null)
        'players': players?.toJson(valueToJson: (v) => v.toJson()),
      if (snapshots != null)
        'snapshots': snapshots?.toJson(valueToJson: (v) => v.toJson()),
      if (events != null)
        'events': events?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameMatchImpl extends GameMatch {
  _GameMatchImpl({
    int? id,
    required String publicId,
    required String ownerUserIdentifier,
    required String name,
    required String mapName,
    required String state,
    required int turn,
    required int maxPlayers,
    required int minPlayers,
    required bool private,
    required bool quickplay,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? autoStartAt,
    String? inviteCode,
    List<_i2.GamePlayer>? players,
    List<_i3.GameSnapshot>? snapshots,
    List<_i4.GameEvent>? events,
  }) : super._(
         id: id,
         publicId: publicId,
         ownerUserIdentifier: ownerUserIdentifier,
         name: name,
         mapName: mapName,
         state: state,
         turn: turn,
         maxPlayers: maxPlayers,
         minPlayers: minPlayers,
         private: private,
         quickplay: quickplay,
         createdAt: createdAt,
         startedAt: startedAt,
         autoStartAt: autoStartAt,
         inviteCode: inviteCode,
         players: players,
         snapshots: snapshots,
         events: events,
       );

  /// Returns a shallow copy of this [GameMatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameMatch copyWith({
    Object? id = _Undefined,
    String? publicId,
    String? ownerUserIdentifier,
    String? name,
    String? mapName,
    String? state,
    int? turn,
    int? maxPlayers,
    int? minPlayers,
    bool? private,
    bool? quickplay,
    DateTime? createdAt,
    Object? startedAt = _Undefined,
    Object? autoStartAt = _Undefined,
    Object? inviteCode = _Undefined,
    Object? players = _Undefined,
    Object? snapshots = _Undefined,
    Object? events = _Undefined,
  }) {
    return GameMatch(
      id: id is int? ? id : this.id,
      publicId: publicId ?? this.publicId,
      ownerUserIdentifier: ownerUserIdentifier ?? this.ownerUserIdentifier,
      name: name ?? this.name,
      mapName: mapName ?? this.mapName,
      state: state ?? this.state,
      turn: turn ?? this.turn,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      private: private ?? this.private,
      quickplay: quickplay ?? this.quickplay,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      autoStartAt: autoStartAt is DateTime? ? autoStartAt : this.autoStartAt,
      inviteCode: inviteCode is String? ? inviteCode : this.inviteCode,
      players: players is List<_i2.GamePlayer>?
          ? players
          : this.players?.map((e0) => e0.copyWith()).toList(),
      snapshots: snapshots is List<_i3.GameSnapshot>?
          ? snapshots
          : this.snapshots?.map((e0) => e0.copyWith()).toList(),
      events: events is List<_i4.GameEvent>?
          ? events
          : this.events?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
