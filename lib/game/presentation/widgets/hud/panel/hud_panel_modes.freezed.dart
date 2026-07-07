// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hud_panel_modes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HudPanelModes {

 bool get cityBuildings; bool get technology; bool get objectives; bool get empire; bool get activityLog;
/// Create a copy of HudPanelModes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HudPanelModesCopyWith<HudPanelModes> get copyWith => _$HudPanelModesCopyWithImpl<HudPanelModes>(this as HudPanelModes, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HudPanelModes&&(identical(other.cityBuildings, cityBuildings) || other.cityBuildings == cityBuildings)&&(identical(other.technology, technology) || other.technology == technology)&&(identical(other.objectives, objectives) || other.objectives == objectives)&&(identical(other.empire, empire) || other.empire == empire)&&(identical(other.activityLog, activityLog) || other.activityLog == activityLog));
}


@override
int get hashCode => Object.hash(runtimeType,cityBuildings,technology,objectives,empire,activityLog);

@override
String toString() {
  return 'HudPanelModes(cityBuildings: $cityBuildings, technology: $technology, objectives: $objectives, empire: $empire, activityLog: $activityLog)';
}


}

/// @nodoc
abstract mixin class $HudPanelModesCopyWith<$Res>  {
  factory $HudPanelModesCopyWith(HudPanelModes value, $Res Function(HudPanelModes) _then) = _$HudPanelModesCopyWithImpl;
@useResult
$Res call({
 bool cityBuildings, bool technology, bool objectives, bool empire, bool activityLog
});




}
/// @nodoc
class _$HudPanelModesCopyWithImpl<$Res>
    implements $HudPanelModesCopyWith<$Res> {
  _$HudPanelModesCopyWithImpl(this._self, this._then);

  final HudPanelModes _self;
  final $Res Function(HudPanelModes) _then;

/// Create a copy of HudPanelModes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cityBuildings = null,Object? technology = null,Object? objectives = null,Object? empire = null,Object? activityLog = null,}) {
  return _then(_self.copyWith(
cityBuildings: null == cityBuildings ? _self.cityBuildings : cityBuildings // ignore: cast_nullable_to_non_nullable
as bool,technology: null == technology ? _self.technology : technology // ignore: cast_nullable_to_non_nullable
as bool,objectives: null == objectives ? _self.objectives : objectives // ignore: cast_nullable_to_non_nullable
as bool,empire: null == empire ? _self.empire : empire // ignore: cast_nullable_to_non_nullable
as bool,activityLog: null == activityLog ? _self.activityLog : activityLog // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HudPanelModes].
extension HudPanelModesPatterns on HudPanelModes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HudPanelModes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HudPanelModes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HudPanelModes value)  $default,){
final _that = this;
switch (_that) {
case _HudPanelModes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HudPanelModes value)?  $default,){
final _that = this;
switch (_that) {
case _HudPanelModes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool cityBuildings,  bool technology,  bool objectives,  bool empire,  bool activityLog)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HudPanelModes() when $default != null:
return $default(_that.cityBuildings,_that.technology,_that.objectives,_that.empire,_that.activityLog);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool cityBuildings,  bool technology,  bool objectives,  bool empire,  bool activityLog)  $default,) {final _that = this;
switch (_that) {
case _HudPanelModes():
return $default(_that.cityBuildings,_that.technology,_that.objectives,_that.empire,_that.activityLog);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool cityBuildings,  bool technology,  bool objectives,  bool empire,  bool activityLog)?  $default,) {final _that = this;
switch (_that) {
case _HudPanelModes() when $default != null:
return $default(_that.cityBuildings,_that.technology,_that.objectives,_that.empire,_that.activityLog);case _:
  return null;

}
}

}

/// @nodoc


class _HudPanelModes extends HudPanelModes {
  const _HudPanelModes({this.cityBuildings = false, this.technology = false, this.objectives = false, this.empire = false, this.activityLog = false}): super._();
  

@override@JsonKey() final  bool cityBuildings;
@override@JsonKey() final  bool technology;
@override@JsonKey() final  bool objectives;
@override@JsonKey() final  bool empire;
@override@JsonKey() final  bool activityLog;

/// Create a copy of HudPanelModes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HudPanelModesCopyWith<_HudPanelModes> get copyWith => __$HudPanelModesCopyWithImpl<_HudPanelModes>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HudPanelModes&&(identical(other.cityBuildings, cityBuildings) || other.cityBuildings == cityBuildings)&&(identical(other.technology, technology) || other.technology == technology)&&(identical(other.objectives, objectives) || other.objectives == objectives)&&(identical(other.empire, empire) || other.empire == empire)&&(identical(other.activityLog, activityLog) || other.activityLog == activityLog));
}


@override
int get hashCode => Object.hash(runtimeType,cityBuildings,technology,objectives,empire,activityLog);

@override
String toString() {
  return 'HudPanelModes(cityBuildings: $cityBuildings, technology: $technology, objectives: $objectives, empire: $empire, activityLog: $activityLog)';
}


}

/// @nodoc
abstract mixin class _$HudPanelModesCopyWith<$Res> implements $HudPanelModesCopyWith<$Res> {
  factory _$HudPanelModesCopyWith(_HudPanelModes value, $Res Function(_HudPanelModes) _then) = __$HudPanelModesCopyWithImpl;
@override @useResult
$Res call({
 bool cityBuildings, bool technology, bool objectives, bool empire, bool activityLog
});




}
/// @nodoc
class __$HudPanelModesCopyWithImpl<$Res>
    implements _$HudPanelModesCopyWith<$Res> {
  __$HudPanelModesCopyWithImpl(this._self, this._then);

  final _HudPanelModes _self;
  final $Res Function(_HudPanelModes) _then;

/// Create a copy of HudPanelModes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cityBuildings = null,Object? technology = null,Object? objectives = null,Object? empire = null,Object? activityLog = null,}) {
  return _then(_HudPanelModes(
cityBuildings: null == cityBuildings ? _self.cityBuildings : cityBuildings // ignore: cast_nullable_to_non_nullable
as bool,technology: null == technology ? _self.technology : technology // ignore: cast_nullable_to_non_nullable
as bool,objectives: null == objectives ? _self.objectives : objectives // ignore: cast_nullable_to_non_nullable
as bool,empire: null == empire ? _self.empire : empire // ignore: cast_nullable_to_non_nullable
as bool,activityLog: null == activityLog ? _self.activityLog : activityLog // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
