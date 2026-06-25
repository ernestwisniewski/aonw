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
import 'package:aonw_core/protocol.dart' as _i3;
import 'package:aonw_server_client/src/protocol/protocol.dart' as _i4;

abstract class GameSnapshot implements _i1.SerializableModel {
  GameSnapshot._({
    this.id,
    required this.matchId,
    this.match,
    required this.offset,
    required this.snapshot,
    required this.createdAt,
  });

  factory GameSnapshot({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int offset,
    required _i3.WireSnapshot snapshot,
    required DateTime createdAt,
  }) = _GameSnapshotImpl;

  factory GameSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameSnapshot(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      offset: jsonSerialization['offset'] as int,
      snapshot: _i3.WireSnapshot.fromJson(jsonSerialization['snapshot']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int matchId;

  _i2.GameMatch? match;

  int offset;

  _i3.WireSnapshot snapshot;

  DateTime createdAt;

  /// Returns a shallow copy of this [GameSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameSnapshot copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    int? offset,
    _i3.WireSnapshot? snapshot,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameSnapshot',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'offset': offset,
      'snapshot': snapshot.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameSnapshotImpl extends GameSnapshot {
  _GameSnapshotImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int offset,
    required _i3.WireSnapshot snapshot,
    required DateTime createdAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         offset: offset,
         snapshot: snapshot,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [GameSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameSnapshot copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    int? offset,
    _i3.WireSnapshot? snapshot,
    DateTime? createdAt,
  }) {
    return GameSnapshot(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      offset: offset ?? this.offset,
      snapshot: snapshot ?? this.snapshot.copyWith(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
