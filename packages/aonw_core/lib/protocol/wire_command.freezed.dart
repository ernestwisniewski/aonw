// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wire_command.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WireCommand {

 int get v; String get matchId; int get tick; int? get turn; String get actorPlayerId; Map<String, dynamic> get command;
/// Create a copy of WireCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireCommandCopyWith<WireCommand> get copyWith => _$WireCommandCopyWithImpl<WireCommand>(this as WireCommand, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireCommand&&(identical(other.v, v) || other.v == v)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.tick, tick) || other.tick == tick)&&(identical(other.turn, turn) || other.turn == turn)&&(identical(other.actorPlayerId, actorPlayerId) || other.actorPlayerId == actorPlayerId)&&const DeepCollectionEquality().equals(other.command, command));
}


@override
int get hashCode => Object.hash(runtimeType,v,matchId,tick,turn,actorPlayerId,const DeepCollectionEquality().hash(command));

@override
String toString() {
  return 'WireCommand(v: $v, matchId: $matchId, tick: $tick, turn: $turn, actorPlayerId: $actorPlayerId, command: $command)';
}


}

/// @nodoc
abstract mixin class $WireCommandCopyWith<$Res>  {
  factory $WireCommandCopyWith(WireCommand value, $Res Function(WireCommand) _then) = _$WireCommandCopyWithImpl;
@useResult
$Res call({
 int v, String matchId, int tick, int? turn, String actorPlayerId, Map<String, dynamic> command
});




}
/// @nodoc
class _$WireCommandCopyWithImpl<$Res>
    implements $WireCommandCopyWith<$Res> {
  _$WireCommandCopyWithImpl(this._self, this._then);

  final WireCommand _self;
  final $Res Function(WireCommand) _then;

/// Create a copy of WireCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? v = null,Object? matchId = null,Object? tick = null,Object? turn = freezed,Object? actorPlayerId = null,Object? command = null,}) {
  return _then(_self.copyWith(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,tick: null == tick ? _self.tick : tick // ignore: cast_nullable_to_non_nullable
as int,turn: freezed == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int?,actorPlayerId: null == actorPlayerId ? _self.actorPlayerId : actorPlayerId // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [WireCommand].
extension WireCommandPatterns on WireCommand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WireCommand value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WireCommand() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WireCommand value)  $default,){
final _that = this;
switch (_that) {
case _WireCommand():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WireCommand value)?  $default,){
final _that = this;
switch (_that) {
case _WireCommand() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int v,  String matchId,  int tick,  int? turn,  String actorPlayerId,  Map<String, dynamic> command)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WireCommand() when $default != null:
return $default(_that.v,_that.matchId,_that.tick,_that.turn,_that.actorPlayerId,_that.command);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int v,  String matchId,  int tick,  int? turn,  String actorPlayerId,  Map<String, dynamic> command)  $default,) {final _that = this;
switch (_that) {
case _WireCommand():
return $default(_that.v,_that.matchId,_that.tick,_that.turn,_that.actorPlayerId,_that.command);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int v,  String matchId,  int tick,  int? turn,  String actorPlayerId,  Map<String, dynamic> command)?  $default,) {final _that = this;
switch (_that) {
case _WireCommand() when $default != null:
return $default(_that.v,_that.matchId,_that.tick,_that.turn,_that.actorPlayerId,_that.command);case _:
  return null;

}
}

}

/// @nodoc


class _WireCommand extends WireCommand {
  const _WireCommand({this.v = kProtocolVersion, required this.matchId, required this.tick, this.turn, required this.actorPlayerId, required final  Map<String, dynamic> command}): _command = command,super._();
  

@override@JsonKey() final  int v;
@override final  String matchId;
@override final  int tick;
@override final  int? turn;
@override final  String actorPlayerId;
 final  Map<String, dynamic> _command;
@override Map<String, dynamic> get command {
  if (_command is EqualUnmodifiableMapView) return _command;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_command);
}


/// Create a copy of WireCommand
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WireCommandCopyWith<_WireCommand> get copyWith => __$WireCommandCopyWithImpl<_WireCommand>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WireCommand&&(identical(other.v, v) || other.v == v)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.tick, tick) || other.tick == tick)&&(identical(other.turn, turn) || other.turn == turn)&&(identical(other.actorPlayerId, actorPlayerId) || other.actorPlayerId == actorPlayerId)&&const DeepCollectionEquality().equals(other._command, _command));
}


@override
int get hashCode => Object.hash(runtimeType,v,matchId,tick,turn,actorPlayerId,const DeepCollectionEquality().hash(_command));

@override
String toString() {
  return 'WireCommand(v: $v, matchId: $matchId, tick: $tick, turn: $turn, actorPlayerId: $actorPlayerId, command: $command)';
}


}

/// @nodoc
abstract mixin class _$WireCommandCopyWith<$Res> implements $WireCommandCopyWith<$Res> {
  factory _$WireCommandCopyWith(_WireCommand value, $Res Function(_WireCommand) _then) = __$WireCommandCopyWithImpl;
@override @useResult
$Res call({
 int v, String matchId, int tick, int? turn, String actorPlayerId, Map<String, dynamic> command
});




}
/// @nodoc
class __$WireCommandCopyWithImpl<$Res>
    implements _$WireCommandCopyWith<$Res> {
  __$WireCommandCopyWithImpl(this._self, this._then);

  final _WireCommand _self;
  final $Res Function(_WireCommand) _then;

/// Create a copy of WireCommand
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? v = null,Object? matchId = null,Object? tick = null,Object? turn = freezed,Object? actorPlayerId = null,Object? command = null,}) {
  return _then(_WireCommand(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,tick: null == tick ? _self.tick : tick // ignore: cast_nullable_to_non_nullable
as int,turn: freezed == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int?,actorPlayerId: null == actorPlayerId ? _self.actorPlayerId : actorPlayerId // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self._command : command // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
