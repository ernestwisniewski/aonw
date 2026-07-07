// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_spec.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UnitSpec {

 GameUnitType get type; int get productionCost; List<UnitProductionRequirement> get requirements; CombatStats get baseStats; UnitCapabilities get capabilities; int get upkeep; int get supplyCost; int get scoreValue;
/// Create a copy of UnitSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitSpecCopyWith<UnitSpec> get copyWith => _$UnitSpecCopyWithImpl<UnitSpec>(this as UnitSpec, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitSpec&&(identical(other.type, type) || other.type == type)&&(identical(other.productionCost, productionCost) || other.productionCost == productionCost)&&const DeepCollectionEquality().equals(other.requirements, requirements)&&(identical(other.baseStats, baseStats) || other.baseStats == baseStats)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&(identical(other.upkeep, upkeep) || other.upkeep == upkeep)&&(identical(other.supplyCost, supplyCost) || other.supplyCost == supplyCost)&&(identical(other.scoreValue, scoreValue) || other.scoreValue == scoreValue));
}


@override
int get hashCode => Object.hash(runtimeType,type,productionCost,const DeepCollectionEquality().hash(requirements),baseStats,capabilities,upkeep,supplyCost,scoreValue);

@override
String toString() {
  return 'UnitSpec(type: $type, productionCost: $productionCost, requirements: $requirements, baseStats: $baseStats, capabilities: $capabilities, upkeep: $upkeep, supplyCost: $supplyCost, scoreValue: $scoreValue)';
}


}

/// @nodoc
abstract mixin class $UnitSpecCopyWith<$Res>  {
  factory $UnitSpecCopyWith(UnitSpec value, $Res Function(UnitSpec) _then) = _$UnitSpecCopyWithImpl;
@useResult
$Res call({
 GameUnitType type, int productionCost, List<UnitProductionRequirement> requirements, CombatStats baseStats, UnitCapabilities capabilities, int upkeep, int supplyCost, int scoreValue
});


$CombatStatsCopyWith<$Res> get baseStats;

}
/// @nodoc
class _$UnitSpecCopyWithImpl<$Res>
    implements $UnitSpecCopyWith<$Res> {
  _$UnitSpecCopyWithImpl(this._self, this._then);

  final UnitSpec _self;
  final $Res Function(UnitSpec) _then;

/// Create a copy of UnitSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? productionCost = null,Object? requirements = null,Object? baseStats = null,Object? capabilities = null,Object? upkeep = null,Object? supplyCost = null,Object? scoreValue = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GameUnitType,productionCost: null == productionCost ? _self.productionCost : productionCost // ignore: cast_nullable_to_non_nullable
as int,requirements: null == requirements ? _self.requirements : requirements // ignore: cast_nullable_to_non_nullable
as List<UnitProductionRequirement>,baseStats: null == baseStats ? _self.baseStats : baseStats // ignore: cast_nullable_to_non_nullable
as CombatStats,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as UnitCapabilities,upkeep: null == upkeep ? _self.upkeep : upkeep // ignore: cast_nullable_to_non_nullable
as int,supplyCost: null == supplyCost ? _self.supplyCost : supplyCost // ignore: cast_nullable_to_non_nullable
as int,scoreValue: null == scoreValue ? _self.scoreValue : scoreValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of UnitSpec
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CombatStatsCopyWith<$Res> get baseStats {
  
  return $CombatStatsCopyWith<$Res>(_self.baseStats, (value) {
    return _then(_self.copyWith(baseStats: value));
  });
}
}


/// Adds pattern-matching-related methods to [UnitSpec].
extension UnitSpecPatterns on UnitSpec {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitSpec value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitSpec() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitSpec value)  $default,){
final _that = this;
switch (_that) {
case _UnitSpec():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitSpec value)?  $default,){
final _that = this;
switch (_that) {
case _UnitSpec() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameUnitType type,  int productionCost,  List<UnitProductionRequirement> requirements,  CombatStats baseStats,  UnitCapabilities capabilities,  int upkeep,  int supplyCost,  int scoreValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitSpec() when $default != null:
return $default(_that.type,_that.productionCost,_that.requirements,_that.baseStats,_that.capabilities,_that.upkeep,_that.supplyCost,_that.scoreValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameUnitType type,  int productionCost,  List<UnitProductionRequirement> requirements,  CombatStats baseStats,  UnitCapabilities capabilities,  int upkeep,  int supplyCost,  int scoreValue)  $default,) {final _that = this;
switch (_that) {
case _UnitSpec():
return $default(_that.type,_that.productionCost,_that.requirements,_that.baseStats,_that.capabilities,_that.upkeep,_that.supplyCost,_that.scoreValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameUnitType type,  int productionCost,  List<UnitProductionRequirement> requirements,  CombatStats baseStats,  UnitCapabilities capabilities,  int upkeep,  int supplyCost,  int scoreValue)?  $default,) {final _that = this;
switch (_that) {
case _UnitSpec() when $default != null:
return $default(_that.type,_that.productionCost,_that.requirements,_that.baseStats,_that.capabilities,_that.upkeep,_that.supplyCost,_that.scoreValue);case _:
  return null;

}
}

}

/// @nodoc


class _UnitSpec extends UnitSpec {
  const _UnitSpec({required this.type, required this.productionCost, final  List<UnitProductionRequirement> requirements = const [], required this.baseStats, required this.capabilities, required this.upkeep, required this.supplyCost, required this.scoreValue}): _requirements = requirements,super._();
  

@override final  GameUnitType type;
@override final  int productionCost;
 final  List<UnitProductionRequirement> _requirements;
@override@JsonKey() List<UnitProductionRequirement> get requirements {
  if (_requirements is EqualUnmodifiableListView) return _requirements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requirements);
}

@override final  CombatStats baseStats;
@override final  UnitCapabilities capabilities;
@override final  int upkeep;
@override final  int supplyCost;
@override final  int scoreValue;

/// Create a copy of UnitSpec
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitSpecCopyWith<_UnitSpec> get copyWith => __$UnitSpecCopyWithImpl<_UnitSpec>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitSpec&&(identical(other.type, type) || other.type == type)&&(identical(other.productionCost, productionCost) || other.productionCost == productionCost)&&const DeepCollectionEquality().equals(other._requirements, _requirements)&&(identical(other.baseStats, baseStats) || other.baseStats == baseStats)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&(identical(other.upkeep, upkeep) || other.upkeep == upkeep)&&(identical(other.supplyCost, supplyCost) || other.supplyCost == supplyCost)&&(identical(other.scoreValue, scoreValue) || other.scoreValue == scoreValue));
}


@override
int get hashCode => Object.hash(runtimeType,type,productionCost,const DeepCollectionEquality().hash(_requirements),baseStats,capabilities,upkeep,supplyCost,scoreValue);

@override
String toString() {
  return 'UnitSpec(type: $type, productionCost: $productionCost, requirements: $requirements, baseStats: $baseStats, capabilities: $capabilities, upkeep: $upkeep, supplyCost: $supplyCost, scoreValue: $scoreValue)';
}


}

/// @nodoc
abstract mixin class _$UnitSpecCopyWith<$Res> implements $UnitSpecCopyWith<$Res> {
  factory _$UnitSpecCopyWith(_UnitSpec value, $Res Function(_UnitSpec) _then) = __$UnitSpecCopyWithImpl;
@override @useResult
$Res call({
 GameUnitType type, int productionCost, List<UnitProductionRequirement> requirements, CombatStats baseStats, UnitCapabilities capabilities, int upkeep, int supplyCost, int scoreValue
});


@override $CombatStatsCopyWith<$Res> get baseStats;

}
/// @nodoc
class __$UnitSpecCopyWithImpl<$Res>
    implements _$UnitSpecCopyWith<$Res> {
  __$UnitSpecCopyWithImpl(this._self, this._then);

  final _UnitSpec _self;
  final $Res Function(_UnitSpec) _then;

/// Create a copy of UnitSpec
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? productionCost = null,Object? requirements = null,Object? baseStats = null,Object? capabilities = null,Object? upkeep = null,Object? supplyCost = null,Object? scoreValue = null,}) {
  return _then(_UnitSpec(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GameUnitType,productionCost: null == productionCost ? _self.productionCost : productionCost // ignore: cast_nullable_to_non_nullable
as int,requirements: null == requirements ? _self._requirements : requirements // ignore: cast_nullable_to_non_nullable
as List<UnitProductionRequirement>,baseStats: null == baseStats ? _self.baseStats : baseStats // ignore: cast_nullable_to_non_nullable
as CombatStats,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as UnitCapabilities,upkeep: null == upkeep ? _self.upkeep : upkeep // ignore: cast_nullable_to_non_nullable
as int,supplyCost: null == supplyCost ? _self.supplyCost : supplyCost // ignore: cast_nullable_to_non_nullable
as int,scoreValue: null == scoreValue ? _self.scoreValue : scoreValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of UnitSpec
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CombatStatsCopyWith<$Res> get baseStats {
  
  return $CombatStatsCopyWith<$Res>(_self.baseStats, (value) {
    return _then(_self.copyWith(baseStats: value));
  });
}
}

// dart format on
