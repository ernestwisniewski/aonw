// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NetworkConnectionState {

 NetworkConnectionStatus get status; String? get lastError; DateTime? get changedAt;
/// Create a copy of NetworkConnectionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkConnectionStateCopyWith<NetworkConnectionState> get copyWith => _$NetworkConnectionStateCopyWithImpl<NetworkConnectionState>(this as NetworkConnectionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkConnectionState&&(identical(other.status, status) || other.status == status)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,lastError,changedAt);

@override
String toString() {
  return 'NetworkConnectionState(status: $status, lastError: $lastError, changedAt: $changedAt)';
}


}

/// @nodoc
abstract mixin class $NetworkConnectionStateCopyWith<$Res>  {
  factory $NetworkConnectionStateCopyWith(NetworkConnectionState value, $Res Function(NetworkConnectionState) _then) = _$NetworkConnectionStateCopyWithImpl;
@useResult
$Res call({
 NetworkConnectionStatus status, String? lastError, DateTime? changedAt
});




}
/// @nodoc
class _$NetworkConnectionStateCopyWithImpl<$Res>
    implements $NetworkConnectionStateCopyWith<$Res> {
  _$NetworkConnectionStateCopyWithImpl(this._self, this._then);

  final NetworkConnectionState _self;
  final $Res Function(NetworkConnectionState) _then;

/// Create a copy of NetworkConnectionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? lastError = freezed,Object? changedAt = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as NetworkConnectionStatus,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,changedAt: freezed == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NetworkConnectionState].
extension NetworkConnectionStatePatterns on NetworkConnectionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NetworkConnectionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetworkConnectionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NetworkConnectionState value)  $default,){
final _that = this;
switch (_that) {
case _NetworkConnectionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NetworkConnectionState value)?  $default,){
final _that = this;
switch (_that) {
case _NetworkConnectionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NetworkConnectionStatus status,  String? lastError,  DateTime? changedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetworkConnectionState() when $default != null:
return $default(_that.status,_that.lastError,_that.changedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NetworkConnectionStatus status,  String? lastError,  DateTime? changedAt)  $default,) {final _that = this;
switch (_that) {
case _NetworkConnectionState():
return $default(_that.status,_that.lastError,_that.changedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NetworkConnectionStatus status,  String? lastError,  DateTime? changedAt)?  $default,) {final _that = this;
switch (_that) {
case _NetworkConnectionState() when $default != null:
return $default(_that.status,_that.lastError,_that.changedAt);case _:
  return null;

}
}

}

/// @nodoc


class _NetworkConnectionState extends NetworkConnectionState {
  const _NetworkConnectionState({required this.status, this.lastError, this.changedAt}): super._();
  

@override final  NetworkConnectionStatus status;
@override final  String? lastError;
@override final  DateTime? changedAt;

/// Create a copy of NetworkConnectionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkConnectionStateCopyWith<_NetworkConnectionState> get copyWith => __$NetworkConnectionStateCopyWithImpl<_NetworkConnectionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkConnectionState&&(identical(other.status, status) || other.status == status)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,lastError,changedAt);

@override
String toString() {
  return 'NetworkConnectionState(status: $status, lastError: $lastError, changedAt: $changedAt)';
}


}

/// @nodoc
abstract mixin class _$NetworkConnectionStateCopyWith<$Res> implements $NetworkConnectionStateCopyWith<$Res> {
  factory _$NetworkConnectionStateCopyWith(_NetworkConnectionState value, $Res Function(_NetworkConnectionState) _then) = __$NetworkConnectionStateCopyWithImpl;
@override @useResult
$Res call({
 NetworkConnectionStatus status, String? lastError, DateTime? changedAt
});




}
/// @nodoc
class __$NetworkConnectionStateCopyWithImpl<$Res>
    implements _$NetworkConnectionStateCopyWith<$Res> {
  __$NetworkConnectionStateCopyWithImpl(this._self, this._then);

  final _NetworkConnectionState _self;
  final $Res Function(_NetworkConnectionState) _then;

/// Create a copy of NetworkConnectionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? lastError = freezed,Object? changedAt = freezed,}) {
  return _then(_NetworkConnectionState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as NetworkConnectionStatus,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,changedAt: freezed == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
