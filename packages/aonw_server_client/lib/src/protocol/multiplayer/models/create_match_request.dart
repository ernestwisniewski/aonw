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

abstract class CreateMatchRequest implements _i1.SerializableModel {
  CreateMatchRequest._({
    required this.name,
    required this.mapName,
    required this.maxPlayers,
    required this.minPlayers,
    required this.private,
    this.countryId,
  });

  factory CreateMatchRequest({
    required String name,
    required String mapName,
    required int maxPlayers,
    required int minPlayers,
    required bool private,
    String? countryId,
  }) = _CreateMatchRequestImpl;

  factory CreateMatchRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return CreateMatchRequest(
      name: jsonSerialization['name'] as String,
      mapName: jsonSerialization['mapName'] as String,
      maxPlayers: jsonSerialization['maxPlayers'] as int,
      minPlayers: jsonSerialization['minPlayers'] as int,
      private: _i1.BoolJsonExtension.fromJson(jsonSerialization['private']),
      countryId: jsonSerialization['countryId'] as String?,
    );
  }

  String name;

  String mapName;

  int maxPlayers;

  int minPlayers;

  bool private;

  String? countryId;

  /// Returns a shallow copy of this [CreateMatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CreateMatchRequest copyWith({
    String? name,
    String? mapName,
    int? maxPlayers,
    int? minPlayers,
    bool? private,
    String? countryId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateMatchRequest',
      'name': name,
      'mapName': mapName,
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
      'private': private,
      if (countryId != null) 'countryId': countryId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CreateMatchRequestImpl extends CreateMatchRequest {
  _CreateMatchRequestImpl({
    required String name,
    required String mapName,
    required int maxPlayers,
    required int minPlayers,
    required bool private,
    String? countryId,
  }) : super._(
         name: name,
         mapName: mapName,
         maxPlayers: maxPlayers,
         minPlayers: minPlayers,
         private: private,
         countryId: countryId,
       );

  /// Returns a shallow copy of this [CreateMatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CreateMatchRequest copyWith({
    String? name,
    String? mapName,
    int? maxPlayers,
    int? minPlayers,
    bool? private,
    Object? countryId = _Undefined,
  }) {
    return CreateMatchRequest(
      name: name ?? this.name,
      mapName: mapName ?? this.mapName,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      private: private ?? this.private,
      countryId: countryId is String? ? countryId : this.countryId,
    );
  }
}
