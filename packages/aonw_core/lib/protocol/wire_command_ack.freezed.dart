// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wire_command_ack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WireCommandAck {

 int get v; String get matchId; bool get accepted; int get offset; WireSnapshot get snapshot; List<Map<String, dynamic>> get events; String? get reason; WireMovementExecutionList get movementExecutions;
/// Create a copy of WireCommandAck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireCommandAckCopyWith<WireCommandAck> get copyWith => _$WireCommandAckCopyWithImpl<WireCommandAck>(this as WireCommandAck, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireCommandAck&&(identical(other.v, v) || other.v == v)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.accepted, accepted) || other.accepted == accepted)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&const DeepCollectionEquality().equals(other.events, events)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.movementExecutions, movementExecutions) || other.movementExecutions == movementExecutions));
}


@override
int get hashCode => Object.hash(runtimeType,v,matchId,accepted,offset,snapshot,const DeepCollectionEquality().hash(events),reason,movementExecutions);

@override
String toString() {
  return 'WireCommandAck(v: $v, matchId: $matchId, accepted: $accepted, offset: $offset, snapshot: $snapshot, events: $events, reason: $reason, movementExecutions: $movementExecutions)';
}


}

/// @nodoc
abstract mixin class $WireCommandAckCopyWith<$Res>  {
  factory $WireCommandAckCopyWith(WireCommandAck value, $Res Function(WireCommandAck) _then) = _$WireCommandAckCopyWithImpl;
@useResult
$Res call({
 int v, String matchId, bool accepted, int offset, WireSnapshot snapshot, List<Map<String, dynamic>> events, String? reason, WireMovementExecutionList movementExecutions
});




}
/// @nodoc
class _$WireCommandAckCopyWithImpl<$Res>
    implements $WireCommandAckCopyWith<$Res> {
  _$WireCommandAckCopyWithImpl(this._self, this._then);

  final WireCommandAck _self;
  final $Res Function(WireCommandAck) _then;

/// Create a copy of WireCommandAck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? v = null,Object? matchId = null,Object? accepted = null,Object? offset = null,Object? snapshot = null,Object? events = null,Object? reason = freezed,Object? movementExecutions = null,}) {
  return _then(_self.copyWith(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as bool,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as WireSnapshot,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,movementExecutions: null == movementExecutions ? _self.movementExecutions : movementExecutions // ignore: cast_nullable_to_non_nullable
as WireMovementExecutionList,
  ));
}

}


/// Adds pattern-matching-related methods to [WireCommandAck].
extension WireCommandAckPatterns on WireCommandAck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WireCommandAck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WireCommandAck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WireCommandAck value)  $default,){
final _that = this;
switch (_that) {
case _WireCommandAck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WireCommandAck value)?  $default,){
final _that = this;
switch (_that) {
case _WireCommandAck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int v,  String matchId,  bool accepted,  int offset,  WireSnapshot snapshot,  List<Map<String, dynamic>> events,  String? reason,  WireMovementExecutionList movementExecutions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WireCommandAck() when $default != null:
return $default(_that.v,_that.matchId,_that.accepted,_that.offset,_that.snapshot,_that.events,_that.reason,_that.movementExecutions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int v,  String matchId,  bool accepted,  int offset,  WireSnapshot snapshot,  List<Map<String, dynamic>> events,  String? reason,  WireMovementExecutionList movementExecutions)  $default,) {final _that = this;
switch (_that) {
case _WireCommandAck():
return $default(_that.v,_that.matchId,_that.accepted,_that.offset,_that.snapshot,_that.events,_that.reason,_that.movementExecutions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int v,  String matchId,  bool accepted,  int offset,  WireSnapshot snapshot,  List<Map<String, dynamic>> events,  String? reason,  WireMovementExecutionList movementExecutions)?  $default,) {final _that = this;
switch (_that) {
case _WireCommandAck() when $default != null:
return $default(_that.v,_that.matchId,_that.accepted,_that.offset,_that.snapshot,_that.events,_that.reason,_that.movementExecutions);case _:
  return null;

}
}

}

/// @nodoc


class _WireCommandAck extends WireCommandAck {
  const _WireCommandAck({this.v = kProtocolVersion, required this.matchId, required this.accepted, required this.offset, required this.snapshot, final  List<Map<String, dynamic>> events = const <Map<String, dynamic>>[], this.reason, required this.movementExecutions}): _events = events,super._();
  

@override@JsonKey() final  int v;
@override final  String matchId;
@override final  bool accepted;
@override final  int offset;
@override final  WireSnapshot snapshot;
 final  List<Map<String, dynamic>> _events;
@override@JsonKey() List<Map<String, dynamic>> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override final  String? reason;
@override final  WireMovementExecutionList movementExecutions;

/// Create a copy of WireCommandAck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WireCommandAckCopyWith<_WireCommandAck> get copyWith => __$WireCommandAckCopyWithImpl<_WireCommandAck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WireCommandAck&&(identical(other.v, v) || other.v == v)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.accepted, accepted) || other.accepted == accepted)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&const DeepCollectionEquality().equals(other._events, _events)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.movementExecutions, movementExecutions) || other.movementExecutions == movementExecutions));
}


@override
int get hashCode => Object.hash(runtimeType,v,matchId,accepted,offset,snapshot,const DeepCollectionEquality().hash(_events),reason,movementExecutions);

@override
String toString() {
  return 'WireCommandAck(v: $v, matchId: $matchId, accepted: $accepted, offset: $offset, snapshot: $snapshot, events: $events, reason: $reason, movementExecutions: $movementExecutions)';
}


}

/// @nodoc
abstract mixin class _$WireCommandAckCopyWith<$Res> implements $WireCommandAckCopyWith<$Res> {
  factory _$WireCommandAckCopyWith(_WireCommandAck value, $Res Function(_WireCommandAck) _then) = __$WireCommandAckCopyWithImpl;
@override @useResult
$Res call({
 int v, String matchId, bool accepted, int offset, WireSnapshot snapshot, List<Map<String, dynamic>> events, String? reason, WireMovementExecutionList movementExecutions
});




}
/// @nodoc
class __$WireCommandAckCopyWithImpl<$Res>
    implements _$WireCommandAckCopyWith<$Res> {
  __$WireCommandAckCopyWithImpl(this._self, this._then);

  final _WireCommandAck _self;
  final $Res Function(_WireCommandAck) _then;

/// Create a copy of WireCommandAck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? v = null,Object? matchId = null,Object? accepted = null,Object? offset = null,Object? snapshot = null,Object? events = null,Object? reason = freezed,Object? movementExecutions = null,}) {
  return _then(_WireCommandAck(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as bool,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as WireSnapshot,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,movementExecutions: null == movementExecutions ? _self.movementExecutions : movementExecutions // ignore: cast_nullable_to_non_nullable
as WireMovementExecutionList,
  ));
}


}

// dart format on
