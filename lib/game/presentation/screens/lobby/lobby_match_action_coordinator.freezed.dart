// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lobby_match_action_coordinator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LobbyMatchActionConfig {

 String get mapName; String get displayName; PlayerCountry get country; String get mapNotReadyMessage; MatchRules get matchRules;
/// Create a copy of LobbyMatchActionConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LobbyMatchActionConfigCopyWith<LobbyMatchActionConfig> get copyWith => _$LobbyMatchActionConfigCopyWithImpl<LobbyMatchActionConfig>(this as LobbyMatchActionConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LobbyMatchActionConfig&&(identical(other.mapName, mapName) || other.mapName == mapName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.country, country) || other.country == country)&&(identical(other.mapNotReadyMessage, mapNotReadyMessage) || other.mapNotReadyMessage == mapNotReadyMessage)&&(identical(other.matchRules, matchRules) || other.matchRules == matchRules));
}


@override
int get hashCode => Object.hash(runtimeType,mapName,displayName,country,mapNotReadyMessage,matchRules);

@override
String toString() {
  return 'LobbyMatchActionConfig(mapName: $mapName, displayName: $displayName, country: $country, mapNotReadyMessage: $mapNotReadyMessage, matchRules: $matchRules)';
}


}

/// @nodoc
abstract mixin class $LobbyMatchActionConfigCopyWith<$Res>  {
  factory $LobbyMatchActionConfigCopyWith(LobbyMatchActionConfig value, $Res Function(LobbyMatchActionConfig) _then) = _$LobbyMatchActionConfigCopyWithImpl;
@useResult
$Res call({
 String mapName, String displayName, PlayerCountry country, String mapNotReadyMessage, MatchRules matchRules
});




}
/// @nodoc
class _$LobbyMatchActionConfigCopyWithImpl<$Res>
    implements $LobbyMatchActionConfigCopyWith<$Res> {
  _$LobbyMatchActionConfigCopyWithImpl(this._self, this._then);

  final LobbyMatchActionConfig _self;
  final $Res Function(LobbyMatchActionConfig) _then;

/// Create a copy of LobbyMatchActionConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mapName = null,Object? displayName = null,Object? country = null,Object? mapNotReadyMessage = null,Object? matchRules = null,}) {
  return _then(_self.copyWith(
mapName: null == mapName ? _self.mapName : mapName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as PlayerCountry,mapNotReadyMessage: null == mapNotReadyMessage ? _self.mapNotReadyMessage : mapNotReadyMessage // ignore: cast_nullable_to_non_nullable
as String,matchRules: null == matchRules ? _self.matchRules : matchRules // ignore: cast_nullable_to_non_nullable
as MatchRules,
  ));
}

}


/// Adds pattern-matching-related methods to [LobbyMatchActionConfig].
extension LobbyMatchActionConfigPatterns on LobbyMatchActionConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LobbyMatchActionConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LobbyMatchActionConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LobbyMatchActionConfig value)  $default,){
final _that = this;
switch (_that) {
case _LobbyMatchActionConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LobbyMatchActionConfig value)?  $default,){
final _that = this;
switch (_that) {
case _LobbyMatchActionConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mapName,  String displayName,  PlayerCountry country,  String mapNotReadyMessage,  MatchRules matchRules)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LobbyMatchActionConfig() when $default != null:
return $default(_that.mapName,_that.displayName,_that.country,_that.mapNotReadyMessage,_that.matchRules);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mapName,  String displayName,  PlayerCountry country,  String mapNotReadyMessage,  MatchRules matchRules)  $default,) {final _that = this;
switch (_that) {
case _LobbyMatchActionConfig():
return $default(_that.mapName,_that.displayName,_that.country,_that.mapNotReadyMessage,_that.matchRules);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mapName,  String displayName,  PlayerCountry country,  String mapNotReadyMessage,  MatchRules matchRules)?  $default,) {final _that = this;
switch (_that) {
case _LobbyMatchActionConfig() when $default != null:
return $default(_that.mapName,_that.displayName,_that.country,_that.mapNotReadyMessage,_that.matchRules);case _:
  return null;

}
}

}

/// @nodoc


class _LobbyMatchActionConfig extends LobbyMatchActionConfig {
  const _LobbyMatchActionConfig({required this.mapName, required this.displayName, required this.country, required this.mapNotReadyMessage, this.matchRules = MatchRules.standard}): super._();
  

@override final  String mapName;
@override final  String displayName;
@override final  PlayerCountry country;
@override final  String mapNotReadyMessage;
@override@JsonKey() final  MatchRules matchRules;

/// Create a copy of LobbyMatchActionConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LobbyMatchActionConfigCopyWith<_LobbyMatchActionConfig> get copyWith => __$LobbyMatchActionConfigCopyWithImpl<_LobbyMatchActionConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LobbyMatchActionConfig&&(identical(other.mapName, mapName) || other.mapName == mapName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.country, country) || other.country == country)&&(identical(other.mapNotReadyMessage, mapNotReadyMessage) || other.mapNotReadyMessage == mapNotReadyMessage)&&(identical(other.matchRules, matchRules) || other.matchRules == matchRules));
}


@override
int get hashCode => Object.hash(runtimeType,mapName,displayName,country,mapNotReadyMessage,matchRules);

@override
String toString() {
  return 'LobbyMatchActionConfig(mapName: $mapName, displayName: $displayName, country: $country, mapNotReadyMessage: $mapNotReadyMessage, matchRules: $matchRules)';
}


}

/// @nodoc
abstract mixin class _$LobbyMatchActionConfigCopyWith<$Res> implements $LobbyMatchActionConfigCopyWith<$Res> {
  factory _$LobbyMatchActionConfigCopyWith(_LobbyMatchActionConfig value, $Res Function(_LobbyMatchActionConfig) _then) = __$LobbyMatchActionConfigCopyWithImpl;
@override @useResult
$Res call({
 String mapName, String displayName, PlayerCountry country, String mapNotReadyMessage, MatchRules matchRules
});




}
/// @nodoc
class __$LobbyMatchActionConfigCopyWithImpl<$Res>
    implements _$LobbyMatchActionConfigCopyWith<$Res> {
  __$LobbyMatchActionConfigCopyWithImpl(this._self, this._then);

  final _LobbyMatchActionConfig _self;
  final $Res Function(_LobbyMatchActionConfig) _then;

/// Create a copy of LobbyMatchActionConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mapName = null,Object? displayName = null,Object? country = null,Object? mapNotReadyMessage = null,Object? matchRules = null,}) {
  return _then(_LobbyMatchActionConfig(
mapName: null == mapName ? _self.mapName : mapName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as PlayerCountry,mapNotReadyMessage: null == mapNotReadyMessage ? _self.mapNotReadyMessage : mapNotReadyMessage // ignore: cast_nullable_to_non_nullable
as String,matchRules: null == matchRules ? _self.matchRules : matchRules // ignore: cast_nullable_to_non_nullable
as MatchRules,
  ));
}


}

// dart format on
