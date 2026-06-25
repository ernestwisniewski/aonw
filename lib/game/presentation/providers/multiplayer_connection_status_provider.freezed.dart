// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'multiplayer_connection_status_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MultiplayerConnectionStatusSnapshot {

 String get saveId; NetworkConnectionStatus get status; DateTime get changedAt; String? get message;
/// Create a copy of MultiplayerConnectionStatusSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MultiplayerConnectionStatusSnapshotCopyWith<MultiplayerConnectionStatusSnapshot> get copyWith => _$MultiplayerConnectionStatusSnapshotCopyWithImpl<MultiplayerConnectionStatusSnapshot>(this as MultiplayerConnectionStatusSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MultiplayerConnectionStatusSnapshot&&(identical(other.saveId, saveId) || other.saveId == saveId)&&(identical(other.status, status) || other.status == status)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,saveId,status,changedAt,message);

@override
String toString() {
  return 'MultiplayerConnectionStatusSnapshot(saveId: $saveId, status: $status, changedAt: $changedAt, message: $message)';
}


}

/// @nodoc
abstract mixin class $MultiplayerConnectionStatusSnapshotCopyWith<$Res>  {
  factory $MultiplayerConnectionStatusSnapshotCopyWith(MultiplayerConnectionStatusSnapshot value, $Res Function(MultiplayerConnectionStatusSnapshot) _then) = _$MultiplayerConnectionStatusSnapshotCopyWithImpl;
@useResult
$Res call({
 String saveId, NetworkConnectionStatus status, DateTime changedAt, String? message
});




}
/// @nodoc
class _$MultiplayerConnectionStatusSnapshotCopyWithImpl<$Res>
    implements $MultiplayerConnectionStatusSnapshotCopyWith<$Res> {
  _$MultiplayerConnectionStatusSnapshotCopyWithImpl(this._self, this._then);

  final MultiplayerConnectionStatusSnapshot _self;
  final $Res Function(MultiplayerConnectionStatusSnapshot) _then;

/// Create a copy of MultiplayerConnectionStatusSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? saveId = null,Object? status = null,Object? changedAt = null,Object? message = freezed,}) {
  return _then(_self.copyWith(
saveId: null == saveId ? _self.saveId : saveId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as NetworkConnectionStatus,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MultiplayerConnectionStatusSnapshot].
extension MultiplayerConnectionStatusSnapshotPatterns on MultiplayerConnectionStatusSnapshot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MultiplayerConnectionStatusSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MultiplayerConnectionStatusSnapshot() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MultiplayerConnectionStatusSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _MultiplayerConnectionStatusSnapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MultiplayerConnectionStatusSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _MultiplayerConnectionStatusSnapshot() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String saveId,  NetworkConnectionStatus status,  DateTime changedAt,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MultiplayerConnectionStatusSnapshot() when $default != null:
return $default(_that.saveId,_that.status,_that.changedAt,_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String saveId,  NetworkConnectionStatus status,  DateTime changedAt,  String? message)  $default,) {final _that = this;
switch (_that) {
case _MultiplayerConnectionStatusSnapshot():
return $default(_that.saveId,_that.status,_that.changedAt,_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String saveId,  NetworkConnectionStatus status,  DateTime changedAt,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _MultiplayerConnectionStatusSnapshot() when $default != null:
return $default(_that.saveId,_that.status,_that.changedAt,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _MultiplayerConnectionStatusSnapshot extends MultiplayerConnectionStatusSnapshot {
  const _MultiplayerConnectionStatusSnapshot({required this.saveId, required this.status, required this.changedAt, this.message}): super._();
  

@override final  String saveId;
@override final  NetworkConnectionStatus status;
@override final  DateTime changedAt;
@override final  String? message;

/// Create a copy of MultiplayerConnectionStatusSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MultiplayerConnectionStatusSnapshotCopyWith<_MultiplayerConnectionStatusSnapshot> get copyWith => __$MultiplayerConnectionStatusSnapshotCopyWithImpl<_MultiplayerConnectionStatusSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MultiplayerConnectionStatusSnapshot&&(identical(other.saveId, saveId) || other.saveId == saveId)&&(identical(other.status, status) || other.status == status)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,saveId,status,changedAt,message);

@override
String toString() {
  return 'MultiplayerConnectionStatusSnapshot(saveId: $saveId, status: $status, changedAt: $changedAt, message: $message)';
}


}

/// @nodoc
abstract mixin class _$MultiplayerConnectionStatusSnapshotCopyWith<$Res> implements $MultiplayerConnectionStatusSnapshotCopyWith<$Res> {
  factory _$MultiplayerConnectionStatusSnapshotCopyWith(_MultiplayerConnectionStatusSnapshot value, $Res Function(_MultiplayerConnectionStatusSnapshot) _then) = __$MultiplayerConnectionStatusSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String saveId, NetworkConnectionStatus status, DateTime changedAt, String? message
});




}
/// @nodoc
class __$MultiplayerConnectionStatusSnapshotCopyWithImpl<$Res>
    implements _$MultiplayerConnectionStatusSnapshotCopyWith<$Res> {
  __$MultiplayerConnectionStatusSnapshotCopyWithImpl(this._self, this._then);

  final _MultiplayerConnectionStatusSnapshot _self;
  final $Res Function(_MultiplayerConnectionStatusSnapshot) _then;

/// Create a copy of MultiplayerConnectionStatusSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? saveId = null,Object? status = null,Object? changedAt = null,Object? message = freezed,}) {
  return _then(_MultiplayerConnectionStatusSnapshot(
saveId: null == saveId ? _self.saveId : saveId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as NetworkConnectionStatus,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
