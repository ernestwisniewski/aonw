// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'combat_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CombatStats {

 int get attack; int get defense; int get hp; int get range; int get mobility;
/// Create a copy of CombatStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CombatStatsCopyWith<CombatStats> get copyWith => _$CombatStatsCopyWithImpl<CombatStats>(this as CombatStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CombatStats&&(identical(other.attack, attack) || other.attack == attack)&&(identical(other.defense, defense) || other.defense == defense)&&(identical(other.hp, hp) || other.hp == hp)&&(identical(other.range, range) || other.range == range)&&(identical(other.mobility, mobility) || other.mobility == mobility));
}


@override
int get hashCode => Object.hash(runtimeType,attack,defense,hp,range,mobility);

@override
String toString() {
  return 'CombatStats(attack: $attack, defense: $defense, hp: $hp, range: $range, mobility: $mobility)';
}


}

/// @nodoc
abstract mixin class $CombatStatsCopyWith<$Res>  {
  factory $CombatStatsCopyWith(CombatStats value, $Res Function(CombatStats) _then) = _$CombatStatsCopyWithImpl;
@useResult
$Res call({
 int attack, int defense, int hp, int range, int mobility
});




}
/// @nodoc
class _$CombatStatsCopyWithImpl<$Res>
    implements $CombatStatsCopyWith<$Res> {
  _$CombatStatsCopyWithImpl(this._self, this._then);

  final CombatStats _self;
  final $Res Function(CombatStats) _then;

/// Create a copy of CombatStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attack = null,Object? defense = null,Object? hp = null,Object? range = null,Object? mobility = null,}) {
  return _then(_self.copyWith(
attack: null == attack ? _self.attack : attack // ignore: cast_nullable_to_non_nullable
as int,defense: null == defense ? _self.defense : defense // ignore: cast_nullable_to_non_nullable
as int,hp: null == hp ? _self.hp : hp // ignore: cast_nullable_to_non_nullable
as int,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as int,mobility: null == mobility ? _self.mobility : mobility // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CombatStats].
extension CombatStatsPatterns on CombatStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CombatStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CombatStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CombatStats value)  $default,){
final _that = this;
switch (_that) {
case _CombatStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CombatStats value)?  $default,){
final _that = this;
switch (_that) {
case _CombatStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int attack,  int defense,  int hp,  int range,  int mobility)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CombatStats() when $default != null:
return $default(_that.attack,_that.defense,_that.hp,_that.range,_that.mobility);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int attack,  int defense,  int hp,  int range,  int mobility)  $default,) {final _that = this;
switch (_that) {
case _CombatStats():
return $default(_that.attack,_that.defense,_that.hp,_that.range,_that.mobility);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int attack,  int defense,  int hp,  int range,  int mobility)?  $default,) {final _that = this;
switch (_that) {
case _CombatStats() when $default != null:
return $default(_that.attack,_that.defense,_that.hp,_that.range,_that.mobility);case _:
  return null;

}
}

}

/// @nodoc


class _CombatStats extends CombatStats {
  const _CombatStats({this.attack = 0, this.defense = 0, this.hp = 0, this.range = 1, this.mobility = 1}): super._();
  

@override@JsonKey() final  int attack;
@override@JsonKey() final  int defense;
@override@JsonKey() final  int hp;
@override@JsonKey() final  int range;
@override@JsonKey() final  int mobility;

/// Create a copy of CombatStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CombatStatsCopyWith<_CombatStats> get copyWith => __$CombatStatsCopyWithImpl<_CombatStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CombatStats&&(identical(other.attack, attack) || other.attack == attack)&&(identical(other.defense, defense) || other.defense == defense)&&(identical(other.hp, hp) || other.hp == hp)&&(identical(other.range, range) || other.range == range)&&(identical(other.mobility, mobility) || other.mobility == mobility));
}


@override
int get hashCode => Object.hash(runtimeType,attack,defense,hp,range,mobility);

@override
String toString() {
  return 'CombatStats(attack: $attack, defense: $defense, hp: $hp, range: $range, mobility: $mobility)';
}


}

/// @nodoc
abstract mixin class _$CombatStatsCopyWith<$Res> implements $CombatStatsCopyWith<$Res> {
  factory _$CombatStatsCopyWith(_CombatStats value, $Res Function(_CombatStats) _then) = __$CombatStatsCopyWithImpl;
@override @useResult
$Res call({
 int attack, int defense, int hp, int range, int mobility
});




}
/// @nodoc
class __$CombatStatsCopyWithImpl<$Res>
    implements _$CombatStatsCopyWith<$Res> {
  __$CombatStatsCopyWithImpl(this._self, this._then);

  final _CombatStats _self;
  final $Res Function(_CombatStats) _then;

/// Create a copy of CombatStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attack = null,Object? defense = null,Object? hp = null,Object? range = null,Object? mobility = null,}) {
  return _then(_CombatStats(
attack: null == attack ? _self.attack : attack // ignore: cast_nullable_to_non_nullable
as int,defense: null == defense ? _self.defense : defense // ignore: cast_nullable_to_non_nullable
as int,hp: null == hp ? _self.hp : hp // ignore: cast_nullable_to_non_nullable
as int,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as int,mobility: null == mobility ? _self.mobility : mobility // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
