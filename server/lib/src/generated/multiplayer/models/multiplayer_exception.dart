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

abstract class MultiplayerException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  MultiplayerException._({required this.code, this.message});

  factory MultiplayerException({required String code, String? message}) =
      _MultiplayerExceptionImpl;

  factory MultiplayerException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MultiplayerException(
      code: jsonSerialization['code'] as String,
      message: jsonSerialization['message'] as String?,
    );
  }

  String code;

  String? message;

  /// Returns a shallow copy of this [MultiplayerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MultiplayerException copyWith({String? code, String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MultiplayerException',
      'code': code,
      if (message != null) 'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MultiplayerException',
      'code': code,
      if (message != null) 'message': message,
    };
  }

  @override
  String toString() {
    return 'MultiplayerException(code: $code, message: $message)';
  }
}

class _Undefined {}

class _MultiplayerExceptionImpl extends MultiplayerException {
  _MultiplayerExceptionImpl({required String code, String? message})
    : super._(code: code, message: message);

  /// Returns a shallow copy of this [MultiplayerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MultiplayerException copyWith({String? code, Object? message = _Undefined}) {
    return MultiplayerException(
      code: code ?? this.code,
      message: message is String? ? message : this.message,
    );
  }
}
