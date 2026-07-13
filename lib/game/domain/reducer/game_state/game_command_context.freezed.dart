// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_command_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameCommandContext {

 String? get actorPlayerId; bool get canAct; int get combatSeedTurn; int get commandTick; PaceBalance get paceBalance; VictoryRules get victoryRules; bool get ignoreFogOfWar;
/// Create a copy of GameCommandContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameCommandContextCopyWith<GameCommandContext> get copyWith => _$GameCommandContextCopyWithImpl<GameCommandContext>(this as GameCommandContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameCommandContext&&(identical(other.actorPlayerId, actorPlayerId) || other.actorPlayerId == actorPlayerId)&&(identical(other.canAct, canAct) || other.canAct == canAct)&&(identical(other.combatSeedTurn, combatSeedTurn) || other.combatSeedTurn == combatSeedTurn)&&(identical(other.commandTick, commandTick) || other.commandTick == commandTick)&&(identical(other.paceBalance, paceBalance) || other.paceBalance == paceBalance)&&(identical(other.victoryRules, victoryRules) || other.victoryRules == victoryRules)&&(identical(other.ignoreFogOfWar, ignoreFogOfWar) || other.ignoreFogOfWar == ignoreFogOfWar));
}


@override
int get hashCode => Object.hash(runtimeType,actorPlayerId,canAct,combatSeedTurn,commandTick,paceBalance,victoryRules,ignoreFogOfWar);

@override
String toString() {
  return 'GameCommandContext(actorPlayerId: $actorPlayerId, canAct: $canAct, combatSeedTurn: $combatSeedTurn, commandTick: $commandTick, paceBalance: $paceBalance, victoryRules: $victoryRules, ignoreFogOfWar: $ignoreFogOfWar)';
}


}

/// @nodoc
abstract mixin class $GameCommandContextCopyWith<$Res>  {
  factory $GameCommandContextCopyWith(GameCommandContext value, $Res Function(GameCommandContext) _then) = _$GameCommandContextCopyWithImpl;
@useResult
$Res call({
 String? actorPlayerId, bool canAct, int combatSeedTurn, int commandTick, PaceBalance paceBalance, VictoryRules victoryRules, bool ignoreFogOfWar
});


$VictoryRulesCopyWith<$Res> get victoryRules;

}
/// @nodoc
class _$GameCommandContextCopyWithImpl<$Res>
    implements $GameCommandContextCopyWith<$Res> {
  _$GameCommandContextCopyWithImpl(this._self, this._then);

  final GameCommandContext _self;
  final $Res Function(GameCommandContext) _then;

/// Create a copy of GameCommandContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actorPlayerId = freezed,Object? canAct = null,Object? combatSeedTurn = null,Object? commandTick = null,Object? paceBalance = null,Object? victoryRules = null,Object? ignoreFogOfWar = null,}) {
  return _then(_self.copyWith(
actorPlayerId: freezed == actorPlayerId ? _self.actorPlayerId : actorPlayerId // ignore: cast_nullable_to_non_nullable
as String?,canAct: null == canAct ? _self.canAct : canAct // ignore: cast_nullable_to_non_nullable
as bool,combatSeedTurn: null == combatSeedTurn ? _self.combatSeedTurn : combatSeedTurn // ignore: cast_nullable_to_non_nullable
as int,commandTick: null == commandTick ? _self.commandTick : commandTick // ignore: cast_nullable_to_non_nullable
as int,paceBalance: null == paceBalance ? _self.paceBalance : paceBalance // ignore: cast_nullable_to_non_nullable
as PaceBalance,victoryRules: null == victoryRules ? _self.victoryRules : victoryRules // ignore: cast_nullable_to_non_nullable
as VictoryRules,ignoreFogOfWar: null == ignoreFogOfWar ? _self.ignoreFogOfWar : ignoreFogOfWar // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of GameCommandContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VictoryRulesCopyWith<$Res> get victoryRules {
  
  return $VictoryRulesCopyWith<$Res>(_self.victoryRules, (value) {
    return _then(_self.copyWith(victoryRules: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameCommandContext].
extension GameCommandContextPatterns on GameCommandContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameCommandContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameCommandContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameCommandContext value)  $default,){
final _that = this;
switch (_that) {
case _GameCommandContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameCommandContext value)?  $default,){
final _that = this;
switch (_that) {
case _GameCommandContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? actorPlayerId,  bool canAct,  int combatSeedTurn,  int commandTick,  PaceBalance paceBalance,  VictoryRules victoryRules,  bool ignoreFogOfWar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameCommandContext() when $default != null:
return $default(_that.actorPlayerId,_that.canAct,_that.combatSeedTurn,_that.commandTick,_that.paceBalance,_that.victoryRules,_that.ignoreFogOfWar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? actorPlayerId,  bool canAct,  int combatSeedTurn,  int commandTick,  PaceBalance paceBalance,  VictoryRules victoryRules,  bool ignoreFogOfWar)  $default,) {final _that = this;
switch (_that) {
case _GameCommandContext():
return $default(_that.actorPlayerId,_that.canAct,_that.combatSeedTurn,_that.commandTick,_that.paceBalance,_that.victoryRules,_that.ignoreFogOfWar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? actorPlayerId,  bool canAct,  int combatSeedTurn,  int commandTick,  PaceBalance paceBalance,  VictoryRules victoryRules,  bool ignoreFogOfWar)?  $default,) {final _that = this;
switch (_that) {
case _GameCommandContext() when $default != null:
return $default(_that.actorPlayerId,_that.canAct,_that.combatSeedTurn,_that.commandTick,_that.paceBalance,_that.victoryRules,_that.ignoreFogOfWar);case _:
  return null;

}
}

}

/// @nodoc


class _GameCommandContext extends GameCommandContext {
  const _GameCommandContext({this.actorPlayerId, this.canAct = true, this.combatSeedTurn = 0, this.commandTick = 0, this.paceBalance = PaceBalance.unlimited, this.victoryRules = VictoryRules.standard, this.ignoreFogOfWar = false}): super._();
  

@override final  String? actorPlayerId;
@override@JsonKey() final  bool canAct;
@override@JsonKey() final  int combatSeedTurn;
@override@JsonKey() final  int commandTick;
@override@JsonKey() final  PaceBalance paceBalance;
@override@JsonKey() final  VictoryRules victoryRules;
@override@JsonKey() final  bool ignoreFogOfWar;

/// Create a copy of GameCommandContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameCommandContextCopyWith<_GameCommandContext> get copyWith => __$GameCommandContextCopyWithImpl<_GameCommandContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameCommandContext&&(identical(other.actorPlayerId, actorPlayerId) || other.actorPlayerId == actorPlayerId)&&(identical(other.canAct, canAct) || other.canAct == canAct)&&(identical(other.combatSeedTurn, combatSeedTurn) || other.combatSeedTurn == combatSeedTurn)&&(identical(other.commandTick, commandTick) || other.commandTick == commandTick)&&(identical(other.paceBalance, paceBalance) || other.paceBalance == paceBalance)&&(identical(other.victoryRules, victoryRules) || other.victoryRules == victoryRules)&&(identical(other.ignoreFogOfWar, ignoreFogOfWar) || other.ignoreFogOfWar == ignoreFogOfWar));
}


@override
int get hashCode => Object.hash(runtimeType,actorPlayerId,canAct,combatSeedTurn,commandTick,paceBalance,victoryRules,ignoreFogOfWar);

@override
String toString() {
  return 'GameCommandContext(actorPlayerId: $actorPlayerId, canAct: $canAct, combatSeedTurn: $combatSeedTurn, commandTick: $commandTick, paceBalance: $paceBalance, victoryRules: $victoryRules, ignoreFogOfWar: $ignoreFogOfWar)';
}


}

/// @nodoc
abstract mixin class _$GameCommandContextCopyWith<$Res> implements $GameCommandContextCopyWith<$Res> {
  factory _$GameCommandContextCopyWith(_GameCommandContext value, $Res Function(_GameCommandContext) _then) = __$GameCommandContextCopyWithImpl;
@override @useResult
$Res call({
 String? actorPlayerId, bool canAct, int combatSeedTurn, int commandTick, PaceBalance paceBalance, VictoryRules victoryRules, bool ignoreFogOfWar
});


@override $VictoryRulesCopyWith<$Res> get victoryRules;

}
/// @nodoc
class __$GameCommandContextCopyWithImpl<$Res>
    implements _$GameCommandContextCopyWith<$Res> {
  __$GameCommandContextCopyWithImpl(this._self, this._then);

  final _GameCommandContext _self;
  final $Res Function(_GameCommandContext) _then;

/// Create a copy of GameCommandContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actorPlayerId = freezed,Object? canAct = null,Object? combatSeedTurn = null,Object? commandTick = null,Object? paceBalance = null,Object? victoryRules = null,Object? ignoreFogOfWar = null,}) {
  return _then(_GameCommandContext(
actorPlayerId: freezed == actorPlayerId ? _self.actorPlayerId : actorPlayerId // ignore: cast_nullable_to_non_nullable
as String?,canAct: null == canAct ? _self.canAct : canAct // ignore: cast_nullable_to_non_nullable
as bool,combatSeedTurn: null == combatSeedTurn ? _self.combatSeedTurn : combatSeedTurn // ignore: cast_nullable_to_non_nullable
as int,commandTick: null == commandTick ? _self.commandTick : commandTick // ignore: cast_nullable_to_non_nullable
as int,paceBalance: null == paceBalance ? _self.paceBalance : paceBalance // ignore: cast_nullable_to_non_nullable
as PaceBalance,victoryRules: null == victoryRules ? _self.victoryRules : victoryRules // ignore: cast_nullable_to_non_nullable
as VictoryRules,ignoreFogOfWar: null == ignoreFogOfWar ? _self.ignoreFogOfWar : ignoreFogOfWar // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of GameCommandContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VictoryRulesCopyWith<$Res> get victoryRules {
  
  return $VictoryRulesCopyWith<$Res>(_self.victoryRules, (value) {
    return _then(_self.copyWith(victoryRules: value));
  });
}
}

// dart format on
