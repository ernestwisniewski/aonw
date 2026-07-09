// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'victory_rules.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VictoryRules {

 bool get conquestEnabled; bool get dominationEnabled; double get dominationControlPercent; int get dominationHoldTurns; bool get scoreFallbackEnabled; int? get turnLimit; int? get hardTimeLimitMinutes; bool get culturalEnabled; int get culturalRequiredArtifacts; int get culturalHoldTurns;
/// Create a copy of VictoryRules
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VictoryRulesCopyWith<VictoryRules> get copyWith => _$VictoryRulesCopyWithImpl<VictoryRules>(this as VictoryRules, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VictoryRules&&(identical(other.conquestEnabled, conquestEnabled) || other.conquestEnabled == conquestEnabled)&&(identical(other.dominationEnabled, dominationEnabled) || other.dominationEnabled == dominationEnabled)&&(identical(other.dominationControlPercent, dominationControlPercent) || other.dominationControlPercent == dominationControlPercent)&&(identical(other.dominationHoldTurns, dominationHoldTurns) || other.dominationHoldTurns == dominationHoldTurns)&&(identical(other.scoreFallbackEnabled, scoreFallbackEnabled) || other.scoreFallbackEnabled == scoreFallbackEnabled)&&(identical(other.turnLimit, turnLimit) || other.turnLimit == turnLimit)&&(identical(other.hardTimeLimitMinutes, hardTimeLimitMinutes) || other.hardTimeLimitMinutes == hardTimeLimitMinutes)&&(identical(other.culturalEnabled, culturalEnabled) || other.culturalEnabled == culturalEnabled)&&(identical(other.culturalRequiredArtifacts, culturalRequiredArtifacts) || other.culturalRequiredArtifacts == culturalRequiredArtifacts)&&(identical(other.culturalHoldTurns, culturalHoldTurns) || other.culturalHoldTurns == culturalHoldTurns));
}


@override
int get hashCode => Object.hash(runtimeType,conquestEnabled,dominationEnabled,dominationControlPercent,dominationHoldTurns,scoreFallbackEnabled,turnLimit,hardTimeLimitMinutes,culturalEnabled,culturalRequiredArtifacts,culturalHoldTurns);

@override
String toString() {
  return 'VictoryRules(conquestEnabled: $conquestEnabled, dominationEnabled: $dominationEnabled, dominationControlPercent: $dominationControlPercent, dominationHoldTurns: $dominationHoldTurns, scoreFallbackEnabled: $scoreFallbackEnabled, turnLimit: $turnLimit, hardTimeLimitMinutes: $hardTimeLimitMinutes, culturalEnabled: $culturalEnabled, culturalRequiredArtifacts: $culturalRequiredArtifacts, culturalHoldTurns: $culturalHoldTurns)';
}


}

/// @nodoc
abstract mixin class $VictoryRulesCopyWith<$Res>  {
  factory $VictoryRulesCopyWith(VictoryRules value, $Res Function(VictoryRules) _then) = _$VictoryRulesCopyWithImpl;
@useResult
$Res call({
 bool conquestEnabled, bool dominationEnabled, double dominationControlPercent, int dominationHoldTurns, bool scoreFallbackEnabled, int? turnLimit, int? hardTimeLimitMinutes, bool culturalEnabled, int culturalRequiredArtifacts, int culturalHoldTurns
});




}
/// @nodoc
class _$VictoryRulesCopyWithImpl<$Res>
    implements $VictoryRulesCopyWith<$Res> {
  _$VictoryRulesCopyWithImpl(this._self, this._then);

  final VictoryRules _self;
  final $Res Function(VictoryRules) _then;

/// Create a copy of VictoryRules
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conquestEnabled = null,Object? dominationEnabled = null,Object? dominationControlPercent = null,Object? dominationHoldTurns = null,Object? scoreFallbackEnabled = null,Object? turnLimit = freezed,Object? hardTimeLimitMinutes = freezed,Object? culturalEnabled = null,Object? culturalRequiredArtifacts = null,Object? culturalHoldTurns = null,}) {
  return _then(_self.copyWith(
conquestEnabled: null == conquestEnabled ? _self.conquestEnabled : conquestEnabled // ignore: cast_nullable_to_non_nullable
as bool,dominationEnabled: null == dominationEnabled ? _self.dominationEnabled : dominationEnabled // ignore: cast_nullable_to_non_nullable
as bool,dominationControlPercent: null == dominationControlPercent ? _self.dominationControlPercent : dominationControlPercent // ignore: cast_nullable_to_non_nullable
as double,dominationHoldTurns: null == dominationHoldTurns ? _self.dominationHoldTurns : dominationHoldTurns // ignore: cast_nullable_to_non_nullable
as int,scoreFallbackEnabled: null == scoreFallbackEnabled ? _self.scoreFallbackEnabled : scoreFallbackEnabled // ignore: cast_nullable_to_non_nullable
as bool,turnLimit: freezed == turnLimit ? _self.turnLimit : turnLimit // ignore: cast_nullable_to_non_nullable
as int?,hardTimeLimitMinutes: freezed == hardTimeLimitMinutes ? _self.hardTimeLimitMinutes : hardTimeLimitMinutes // ignore: cast_nullable_to_non_nullable
as int?,culturalEnabled: null == culturalEnabled ? _self.culturalEnabled : culturalEnabled // ignore: cast_nullable_to_non_nullable
as bool,culturalRequiredArtifacts: null == culturalRequiredArtifacts ? _self.culturalRequiredArtifacts : culturalRequiredArtifacts // ignore: cast_nullable_to_non_nullable
as int,culturalHoldTurns: null == culturalHoldTurns ? _self.culturalHoldTurns : culturalHoldTurns // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VictoryRules].
extension VictoryRulesPatterns on VictoryRules {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VictoryRules value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VictoryRules() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VictoryRules value)  $default,){
final _that = this;
switch (_that) {
case _VictoryRules():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VictoryRules value)?  $default,){
final _that = this;
switch (_that) {
case _VictoryRules() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool conquestEnabled,  bool dominationEnabled,  double dominationControlPercent,  int dominationHoldTurns,  bool scoreFallbackEnabled,  int? turnLimit,  int? hardTimeLimitMinutes,  bool culturalEnabled,  int culturalRequiredArtifacts,  int culturalHoldTurns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VictoryRules() when $default != null:
return $default(_that.conquestEnabled,_that.dominationEnabled,_that.dominationControlPercent,_that.dominationHoldTurns,_that.scoreFallbackEnabled,_that.turnLimit,_that.hardTimeLimitMinutes,_that.culturalEnabled,_that.culturalRequiredArtifacts,_that.culturalHoldTurns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool conquestEnabled,  bool dominationEnabled,  double dominationControlPercent,  int dominationHoldTurns,  bool scoreFallbackEnabled,  int? turnLimit,  int? hardTimeLimitMinutes,  bool culturalEnabled,  int culturalRequiredArtifacts,  int culturalHoldTurns)  $default,) {final _that = this;
switch (_that) {
case _VictoryRules():
return $default(_that.conquestEnabled,_that.dominationEnabled,_that.dominationControlPercent,_that.dominationHoldTurns,_that.scoreFallbackEnabled,_that.turnLimit,_that.hardTimeLimitMinutes,_that.culturalEnabled,_that.culturalRequiredArtifacts,_that.culturalHoldTurns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool conquestEnabled,  bool dominationEnabled,  double dominationControlPercent,  int dominationHoldTurns,  bool scoreFallbackEnabled,  int? turnLimit,  int? hardTimeLimitMinutes,  bool culturalEnabled,  int culturalRequiredArtifacts,  int culturalHoldTurns)?  $default,) {final _that = this;
switch (_that) {
case _VictoryRules() when $default != null:
return $default(_that.conquestEnabled,_that.dominationEnabled,_that.dominationControlPercent,_that.dominationHoldTurns,_that.scoreFallbackEnabled,_that.turnLimit,_that.hardTimeLimitMinutes,_that.culturalEnabled,_that.culturalRequiredArtifacts,_that.culturalHoldTurns);case _:
  return null;

}
}

}

/// @nodoc


class _VictoryRules extends VictoryRules {
  const _VictoryRules({required this.conquestEnabled, required this.dominationEnabled, required this.dominationControlPercent, required this.dominationHoldTurns, required this.scoreFallbackEnabled, this.turnLimit, this.hardTimeLimitMinutes, this.culturalEnabled = true, this.culturalRequiredArtifacts = 6, this.culturalHoldTurns = 5}): super._();
  

@override final  bool conquestEnabled;
@override final  bool dominationEnabled;
@override final  double dominationControlPercent;
@override final  int dominationHoldTurns;
@override final  bool scoreFallbackEnabled;
@override final  int? turnLimit;
@override final  int? hardTimeLimitMinutes;
@override@JsonKey() final  bool culturalEnabled;
@override@JsonKey() final  int culturalRequiredArtifacts;
@override@JsonKey() final  int culturalHoldTurns;

/// Create a copy of VictoryRules
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VictoryRulesCopyWith<_VictoryRules> get copyWith => __$VictoryRulesCopyWithImpl<_VictoryRules>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VictoryRules&&(identical(other.conquestEnabled, conquestEnabled) || other.conquestEnabled == conquestEnabled)&&(identical(other.dominationEnabled, dominationEnabled) || other.dominationEnabled == dominationEnabled)&&(identical(other.dominationControlPercent, dominationControlPercent) || other.dominationControlPercent == dominationControlPercent)&&(identical(other.dominationHoldTurns, dominationHoldTurns) || other.dominationHoldTurns == dominationHoldTurns)&&(identical(other.scoreFallbackEnabled, scoreFallbackEnabled) || other.scoreFallbackEnabled == scoreFallbackEnabled)&&(identical(other.turnLimit, turnLimit) || other.turnLimit == turnLimit)&&(identical(other.hardTimeLimitMinutes, hardTimeLimitMinutes) || other.hardTimeLimitMinutes == hardTimeLimitMinutes)&&(identical(other.culturalEnabled, culturalEnabled) || other.culturalEnabled == culturalEnabled)&&(identical(other.culturalRequiredArtifacts, culturalRequiredArtifacts) || other.culturalRequiredArtifacts == culturalRequiredArtifacts)&&(identical(other.culturalHoldTurns, culturalHoldTurns) || other.culturalHoldTurns == culturalHoldTurns));
}


@override
int get hashCode => Object.hash(runtimeType,conquestEnabled,dominationEnabled,dominationControlPercent,dominationHoldTurns,scoreFallbackEnabled,turnLimit,hardTimeLimitMinutes,culturalEnabled,culturalRequiredArtifacts,culturalHoldTurns);

@override
String toString() {
  return 'VictoryRules(conquestEnabled: $conquestEnabled, dominationEnabled: $dominationEnabled, dominationControlPercent: $dominationControlPercent, dominationHoldTurns: $dominationHoldTurns, scoreFallbackEnabled: $scoreFallbackEnabled, turnLimit: $turnLimit, hardTimeLimitMinutes: $hardTimeLimitMinutes, culturalEnabled: $culturalEnabled, culturalRequiredArtifacts: $culturalRequiredArtifacts, culturalHoldTurns: $culturalHoldTurns)';
}


}

/// @nodoc
abstract mixin class _$VictoryRulesCopyWith<$Res> implements $VictoryRulesCopyWith<$Res> {
  factory _$VictoryRulesCopyWith(_VictoryRules value, $Res Function(_VictoryRules) _then) = __$VictoryRulesCopyWithImpl;
@override @useResult
$Res call({
 bool conquestEnabled, bool dominationEnabled, double dominationControlPercent, int dominationHoldTurns, bool scoreFallbackEnabled, int? turnLimit, int? hardTimeLimitMinutes, bool culturalEnabled, int culturalRequiredArtifacts, int culturalHoldTurns
});




}
/// @nodoc
class __$VictoryRulesCopyWithImpl<$Res>
    implements _$VictoryRulesCopyWith<$Res> {
  __$VictoryRulesCopyWithImpl(this._self, this._then);

  final _VictoryRules _self;
  final $Res Function(_VictoryRules) _then;

/// Create a copy of VictoryRules
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conquestEnabled = null,Object? dominationEnabled = null,Object? dominationControlPercent = null,Object? dominationHoldTurns = null,Object? scoreFallbackEnabled = null,Object? turnLimit = freezed,Object? hardTimeLimitMinutes = freezed,Object? culturalEnabled = null,Object? culturalRequiredArtifacts = null,Object? culturalHoldTurns = null,}) {
  return _then(_VictoryRules(
conquestEnabled: null == conquestEnabled ? _self.conquestEnabled : conquestEnabled // ignore: cast_nullable_to_non_nullable
as bool,dominationEnabled: null == dominationEnabled ? _self.dominationEnabled : dominationEnabled // ignore: cast_nullable_to_non_nullable
as bool,dominationControlPercent: null == dominationControlPercent ? _self.dominationControlPercent : dominationControlPercent // ignore: cast_nullable_to_non_nullable
as double,dominationHoldTurns: null == dominationHoldTurns ? _self.dominationHoldTurns : dominationHoldTurns // ignore: cast_nullable_to_non_nullable
as int,scoreFallbackEnabled: null == scoreFallbackEnabled ? _self.scoreFallbackEnabled : scoreFallbackEnabled // ignore: cast_nullable_to_non_nullable
as bool,turnLimit: freezed == turnLimit ? _self.turnLimit : turnLimit // ignore: cast_nullable_to_non_nullable
as int?,hardTimeLimitMinutes: freezed == hardTimeLimitMinutes ? _self.hardTimeLimitMinutes : hardTimeLimitMinutes // ignore: cast_nullable_to_non_nullable
as int?,culturalEnabled: null == culturalEnabled ? _self.culturalEnabled : culturalEnabled // ignore: cast_nullable_to_non_nullable
as bool,culturalRequiredArtifacts: null == culturalRequiredArtifacts ? _self.culturalRequiredArtifacts : culturalRequiredArtifacts // ignore: cast_nullable_to_non_nullable
as int,culturalHoldTurns: null == culturalHoldTurns ? _self.culturalHoldTurns : culturalHoldTurns // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
