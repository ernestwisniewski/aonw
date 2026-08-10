// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_length_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameLengthConfig {

 GameLengthKind get kind; int? get targetMinutes; int? get turnLimit; PaceProfile get paceProfile; bool get scoreFallbackEnabled;
/// Create a copy of GameLengthConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameLengthConfigCopyWith<GameLengthConfig> get copyWith => _$GameLengthConfigCopyWithImpl<GameLengthConfig>(this as GameLengthConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameLengthConfig&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.targetMinutes, targetMinutes) || other.targetMinutes == targetMinutes)&&(identical(other.turnLimit, turnLimit) || other.turnLimit == turnLimit)&&(identical(other.paceProfile, paceProfile) || other.paceProfile == paceProfile)&&(identical(other.scoreFallbackEnabled, scoreFallbackEnabled) || other.scoreFallbackEnabled == scoreFallbackEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,kind,targetMinutes,turnLimit,paceProfile,scoreFallbackEnabled);

@override
String toString() {
  return 'GameLengthConfig(kind: $kind, targetMinutes: $targetMinutes, turnLimit: $turnLimit, paceProfile: $paceProfile, scoreFallbackEnabled: $scoreFallbackEnabled)';
}


}

/// @nodoc
abstract mixin class $GameLengthConfigCopyWith<$Res>  {
  factory $GameLengthConfigCopyWith(GameLengthConfig value, $Res Function(GameLengthConfig) _then) = _$GameLengthConfigCopyWithImpl;
@useResult
$Res call({
 GameLengthKind kind, int? targetMinutes, int? turnLimit, PaceProfile paceProfile, bool scoreFallbackEnabled
});




}
/// @nodoc
class _$GameLengthConfigCopyWithImpl<$Res>
    implements $GameLengthConfigCopyWith<$Res> {
  _$GameLengthConfigCopyWithImpl(this._self, this._then);

  final GameLengthConfig _self;
  final $Res Function(GameLengthConfig) _then;

/// Create a copy of GameLengthConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? targetMinutes = freezed,Object? turnLimit = freezed,Object? paceProfile = null,Object? scoreFallbackEnabled = null,}) {
  return _then(GameLengthConfig(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GameLengthKind,targetMinutes: freezed == targetMinutes ? _self.targetMinutes : targetMinutes // ignore: cast_nullable_to_non_nullable
as int?,turnLimit: freezed == turnLimit ? _self.turnLimit : turnLimit // ignore: cast_nullable_to_non_nullable
as int?,paceProfile: null == paceProfile ? _self.paceProfile : paceProfile // ignore: cast_nullable_to_non_nullable
as PaceProfile,scoreFallbackEnabled: null == scoreFallbackEnabled ? _self.scoreFallbackEnabled : scoreFallbackEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GameLengthConfig].
extension GameLengthConfigPatterns on GameLengthConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameLengthConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameLengthConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameLengthConfig value)  $default,){
final _that = this;
switch (_that) {
case _GameLengthConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameLengthConfig value)?  $default,){
final _that = this;
switch (_that) {
case _GameLengthConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameLengthKind kind,  int? targetMinutes,  int? turnLimit,  PaceProfile paceProfile,  bool scoreFallbackEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameLengthConfig() when $default != null:
return $default(_that.kind,_that.targetMinutes,_that.turnLimit,_that.paceProfile,_that.scoreFallbackEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameLengthKind kind,  int? targetMinutes,  int? turnLimit,  PaceProfile paceProfile,  bool scoreFallbackEnabled)  $default,) {final _that = this;
switch (_that) {
case _GameLengthConfig():
return $default(_that.kind,_that.targetMinutes,_that.turnLimit,_that.paceProfile,_that.scoreFallbackEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameLengthKind kind,  int? targetMinutes,  int? turnLimit,  PaceProfile paceProfile,  bool scoreFallbackEnabled)?  $default,) {final _that = this;
switch (_that) {
case _GameLengthConfig() when $default != null:
return $default(_that.kind,_that.targetMinutes,_that.turnLimit,_that.paceProfile,_that.scoreFallbackEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _GameLengthConfig extends GameLengthConfig {
  const _GameLengthConfig({required this.kind, this.targetMinutes, this.turnLimit, required this.paceProfile, required this.scoreFallbackEnabled}): super._();
  

@override final  GameLengthKind kind;
@override final  int? targetMinutes;
@override final  int? turnLimit;
@override final  PaceProfile paceProfile;
@override final  bool scoreFallbackEnabled;

/// Create a copy of GameLengthConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameLengthConfigCopyWith<_GameLengthConfig> get copyWith => __$GameLengthConfigCopyWithImpl<_GameLengthConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameLengthConfig&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.targetMinutes, targetMinutes) || other.targetMinutes == targetMinutes)&&(identical(other.turnLimit, turnLimit) || other.turnLimit == turnLimit)&&(identical(other.paceProfile, paceProfile) || other.paceProfile == paceProfile)&&(identical(other.scoreFallbackEnabled, scoreFallbackEnabled) || other.scoreFallbackEnabled == scoreFallbackEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,kind,targetMinutes,turnLimit,paceProfile,scoreFallbackEnabled);

@override
String toString() {
  return 'GameLengthConfig(kind: $kind, targetMinutes: $targetMinutes, turnLimit: $turnLimit, paceProfile: $paceProfile, scoreFallbackEnabled: $scoreFallbackEnabled)';
}


}

/// @nodoc
abstract mixin class _$GameLengthConfigCopyWith<$Res> implements $GameLengthConfigCopyWith<$Res> {
  factory _$GameLengthConfigCopyWith(_GameLengthConfig value, $Res Function(_GameLengthConfig) _then) = __$GameLengthConfigCopyWithImpl;
@override @useResult
$Res call({
 GameLengthKind kind, int? targetMinutes, int? turnLimit, PaceProfile paceProfile, bool scoreFallbackEnabled
});




}
/// @nodoc
class __$GameLengthConfigCopyWithImpl<$Res>
    implements _$GameLengthConfigCopyWith<$Res> {
  __$GameLengthConfigCopyWithImpl(this._self, this._then);

  final _GameLengthConfig _self;
  final $Res Function(_GameLengthConfig) _then;

/// Create a copy of GameLengthConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? targetMinutes = freezed,Object? turnLimit = freezed,Object? paceProfile = null,Object? scoreFallbackEnabled = null,}) {
  return _then(_GameLengthConfig(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GameLengthKind,targetMinutes: freezed == targetMinutes ? _self.targetMinutes : targetMinutes // ignore: cast_nullable_to_non_nullable
as int?,turnLimit: freezed == turnLimit ? _self.turnLimit : turnLimit // ignore: cast_nullable_to_non_nullable
as int?,paceProfile: null == paceProfile ? _self.paceProfile : paceProfile // ignore: cast_nullable_to_non_nullable
as PaceProfile,scoreFallbackEnabled: null == scoreFallbackEnabled ? _self.scoreFallbackEnabled : scoreFallbackEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
