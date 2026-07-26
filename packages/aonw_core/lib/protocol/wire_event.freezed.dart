// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wire_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WireEvent {

 int get v; String get matchId; int get offset; DateTime get timestamp; String? get actorPlayerId; int? get tick; int? get turn; Map<String, dynamic>? get command; List<Map<String, dynamic>> get events; WireMovementExecutionList get movementExecutions;
/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventCopyWith<WireEvent> get copyWith => _$WireEventCopyWithImpl<WireEvent>(this as WireEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEvent&&(identical(other.v, v) || other.v == v)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.actorPlayerId, actorPlayerId) || other.actorPlayerId == actorPlayerId)&&(identical(other.tick, tick) || other.tick == tick)&&(identical(other.turn, turn) || other.turn == turn)&&const DeepCollectionEquality().equals(other.command, command)&&const DeepCollectionEquality().equals(other.events, events)&&(identical(other.movementExecutions, movementExecutions) || other.movementExecutions == movementExecutions));
}


@override
int get hashCode => Object.hash(runtimeType,v,matchId,offset,timestamp,actorPlayerId,tick,turn,const DeepCollectionEquality().hash(command),const DeepCollectionEquality().hash(events),movementExecutions);

@override
String toString() {
  return 'WireEvent(v: $v, matchId: $matchId, offset: $offset, timestamp: $timestamp, actorPlayerId: $actorPlayerId, tick: $tick, turn: $turn, command: $command, events: $events, movementExecutions: $movementExecutions)';
}


}

/// @nodoc
abstract mixin class $WireEventCopyWith<$Res>  {
  factory $WireEventCopyWith(WireEvent value, $Res Function(WireEvent) _then) = _$WireEventCopyWithImpl;
@useResult
$Res call({
 int v, String matchId, int offset, DateTime timestamp, String? actorPlayerId, int? tick, int? turn, Map<String, dynamic>? command, List<Map<String, dynamic>> events, WireMovementExecutionList movementExecutions
});




}
/// @nodoc
class _$WireEventCopyWithImpl<$Res>
    implements $WireEventCopyWith<$Res> {
  _$WireEventCopyWithImpl(this._self, this._then);

  final WireEvent _self;
  final $Res Function(WireEvent) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? v = null,Object? matchId = null,Object? offset = null,Object? timestamp = null,Object? actorPlayerId = freezed,Object? tick = freezed,Object? turn = freezed,Object? command = freezed,Object? events = null,Object? movementExecutions = null,}) {
  return _then(_self.copyWith(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,actorPlayerId: freezed == actorPlayerId ? _self.actorPlayerId : actorPlayerId // ignore: cast_nullable_to_non_nullable
as String?,tick: freezed == tick ? _self.tick : tick // ignore: cast_nullable_to_non_nullable
as int?,turn: freezed == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int?,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,movementExecutions: null == movementExecutions ? _self.movementExecutions : movementExecutions // ignore: cast_nullable_to_non_nullable
as WireMovementExecutionList,
  ));
}

}


/// Adds pattern-matching-related methods to [WireEvent].
extension WireEventPatterns on WireEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WireEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WireEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WireEvent value)  $default,){
final _that = this;
switch (_that) {
case _WireEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WireEvent value)?  $default,){
final _that = this;
switch (_that) {
case _WireEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int v,  String matchId,  int offset,  DateTime timestamp,  String? actorPlayerId,  int? tick,  int? turn,  Map<String, dynamic>? command,  List<Map<String, dynamic>> events,  WireMovementExecutionList movementExecutions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WireEvent() when $default != null:
return $default(_that.v,_that.matchId,_that.offset,_that.timestamp,_that.actorPlayerId,_that.tick,_that.turn,_that.command,_that.events,_that.movementExecutions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int v,  String matchId,  int offset,  DateTime timestamp,  String? actorPlayerId,  int? tick,  int? turn,  Map<String, dynamic>? command,  List<Map<String, dynamic>> events,  WireMovementExecutionList movementExecutions)  $default,) {final _that = this;
switch (_that) {
case _WireEvent():
return $default(_that.v,_that.matchId,_that.offset,_that.timestamp,_that.actorPlayerId,_that.tick,_that.turn,_that.command,_that.events,_that.movementExecutions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int v,  String matchId,  int offset,  DateTime timestamp,  String? actorPlayerId,  int? tick,  int? turn,  Map<String, dynamic>? command,  List<Map<String, dynamic>> events,  WireMovementExecutionList movementExecutions)?  $default,) {final _that = this;
switch (_that) {
case _WireEvent() when $default != null:
return $default(_that.v,_that.matchId,_that.offset,_that.timestamp,_that.actorPlayerId,_that.tick,_that.turn,_that.command,_that.events,_that.movementExecutions);case _:
  return null;

}
}

}

/// @nodoc


class _WireEvent extends WireEvent {
  const _WireEvent({this.v = kProtocolVersion, required this.matchId, required this.offset, required this.timestamp, this.actorPlayerId, this.tick, this.turn, final  Map<String, dynamic>? command, final  List<Map<String, dynamic>> events = const <Map<String, dynamic>>[], required this.movementExecutions}): _command = command,_events = events,super._();
  

@override@JsonKey() final  int v;
@override final  String matchId;
@override final  int offset;
@override final  DateTime timestamp;
@override final  String? actorPlayerId;
@override final  int? tick;
@override final  int? turn;
 final  Map<String, dynamic>? _command;
@override Map<String, dynamic>? get command {
  final value = _command;
  if (value == null) return null;
  if (_command is EqualUnmodifiableMapView) return _command;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<Map<String, dynamic>> _events;
@override@JsonKey() List<Map<String, dynamic>> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override final  WireMovementExecutionList movementExecutions;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WireEventCopyWith<_WireEvent> get copyWith => __$WireEventCopyWithImpl<_WireEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WireEvent&&(identical(other.v, v) || other.v == v)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.actorPlayerId, actorPlayerId) || other.actorPlayerId == actorPlayerId)&&(identical(other.tick, tick) || other.tick == tick)&&(identical(other.turn, turn) || other.turn == turn)&&const DeepCollectionEquality().equals(other._command, _command)&&const DeepCollectionEquality().equals(other._events, _events)&&(identical(other.movementExecutions, movementExecutions) || other.movementExecutions == movementExecutions));
}


@override
int get hashCode => Object.hash(runtimeType,v,matchId,offset,timestamp,actorPlayerId,tick,turn,const DeepCollectionEquality().hash(_command),const DeepCollectionEquality().hash(_events),movementExecutions);

@override
String toString() {
  return 'WireEvent(v: $v, matchId: $matchId, offset: $offset, timestamp: $timestamp, actorPlayerId: $actorPlayerId, tick: $tick, turn: $turn, command: $command, events: $events, movementExecutions: $movementExecutions)';
}


}

/// @nodoc
abstract mixin class _$WireEventCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory _$WireEventCopyWith(_WireEvent value, $Res Function(_WireEvent) _then) = __$WireEventCopyWithImpl;
@override @useResult
$Res call({
 int v, String matchId, int offset, DateTime timestamp, String? actorPlayerId, int? tick, int? turn, Map<String, dynamic>? command, List<Map<String, dynamic>> events, WireMovementExecutionList movementExecutions
});




}
/// @nodoc
class __$WireEventCopyWithImpl<$Res>
    implements _$WireEventCopyWith<$Res> {
  __$WireEventCopyWithImpl(this._self, this._then);

  final _WireEvent _self;
  final $Res Function(_WireEvent) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? v = null,Object? matchId = null,Object? offset = null,Object? timestamp = null,Object? actorPlayerId = freezed,Object? tick = freezed,Object? turn = freezed,Object? command = freezed,Object? events = null,Object? movementExecutions = null,}) {
  return _then(_WireEvent(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,actorPlayerId: freezed == actorPlayerId ? _self.actorPlayerId : actorPlayerId // ignore: cast_nullable_to_non_nullable
as String?,tick: freezed == tick ? _self.tick : tick // ignore: cast_nullable_to_non_nullable
as int?,turn: freezed == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int?,command: freezed == command ? _self._command : command // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,movementExecutions: null == movementExecutions ? _self.movementExecutions : movementExecutions // ignore: cast_nullable_to_non_nullable
as WireMovementExecutionList,
  ));
}


}

// dart format on
