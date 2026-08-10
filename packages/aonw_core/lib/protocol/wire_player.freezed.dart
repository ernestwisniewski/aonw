// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wire_player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WirePlayer {

 String get id; String get userId; String get name; int get colorValue; PlayerCountry get country; WirePlayerKind get kind; WirePlayerConnectionState get connectionState; bool get ready; WireAiPlayer? get ai;
/// Create a copy of WirePlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WirePlayerCopyWith<WirePlayer> get copyWith => _$WirePlayerCopyWithImpl<WirePlayer>(this as WirePlayer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WirePlayer&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.country, country) || other.country == country)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.connectionState, connectionState) || other.connectionState == connectionState)&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.ai, ai) || other.ai == ai));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,name,colorValue,country,kind,connectionState,ready,ai);

@override
String toString() {
  return 'WirePlayer(id: $id, userId: $userId, name: $name, colorValue: $colorValue, country: $country, kind: $kind, connectionState: $connectionState, ready: $ready, ai: $ai)';
}


}

/// @nodoc
abstract mixin class $WirePlayerCopyWith<$Res>  {
  factory $WirePlayerCopyWith(WirePlayer value, $Res Function(WirePlayer) _then) = _$WirePlayerCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String name, int colorValue, PlayerCountry country, WirePlayerKind kind, WirePlayerConnectionState connectionState, bool ready, WireAiPlayer? ai
});




}
/// @nodoc
class _$WirePlayerCopyWithImpl<$Res>
    implements $WirePlayerCopyWith<$Res> {
  _$WirePlayerCopyWithImpl(this._self, this._then);

  final WirePlayer _self;
  final $Res Function(WirePlayer) _then;

/// Create a copy of WirePlayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? colorValue = null,Object? country = null,Object? kind = null,Object? connectionState = null,Object? ready = null,Object? ai = freezed,}) {
  return _then(WirePlayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as PlayerCountry,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WirePlayerKind,connectionState: null == connectionState ? _self.connectionState : connectionState // ignore: cast_nullable_to_non_nullable
as WirePlayerConnectionState,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,ai: freezed == ai ? _self.ai : ai // ignore: cast_nullable_to_non_nullable
as WireAiPlayer?,
  ));
}

}


/// Adds pattern-matching-related methods to [WirePlayer].
extension WirePlayerPatterns on WirePlayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WirePlayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WirePlayer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WirePlayer value)  $default,){
final _that = this;
switch (_that) {
case _WirePlayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WirePlayer value)?  $default,){
final _that = this;
switch (_that) {
case _WirePlayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  int colorValue,  PlayerCountry country,  WirePlayerKind kind,  WirePlayerConnectionState connectionState,  bool ready,  WireAiPlayer? ai)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WirePlayer() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.colorValue,_that.country,_that.kind,_that.connectionState,_that.ready,_that.ai);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  int colorValue,  PlayerCountry country,  WirePlayerKind kind,  WirePlayerConnectionState connectionState,  bool ready,  WireAiPlayer? ai)  $default,) {final _that = this;
switch (_that) {
case _WirePlayer():
return $default(_that.id,_that.userId,_that.name,_that.colorValue,_that.country,_that.kind,_that.connectionState,_that.ready,_that.ai);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String name,  int colorValue,  PlayerCountry country,  WirePlayerKind kind,  WirePlayerConnectionState connectionState,  bool ready,  WireAiPlayer? ai)?  $default,) {final _that = this;
switch (_that) {
case _WirePlayer() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.colorValue,_that.country,_that.kind,_that.connectionState,_that.ready,_that.ai);case _:
  return null;

}
}

}

/// @nodoc


class _WirePlayer extends WirePlayer {
  const _WirePlayer({required this.id, required this.userId, required this.name, required this.colorValue, this.country = PlayerCountry.poland, required this.kind, required this.connectionState, this.ready = false, this.ai}): assert(ai == null || kind == WirePlayerKind.ai),super._();
  

@override final  String id;
@override final  String userId;
@override final  String name;
@override final  int colorValue;
@override@JsonKey() final  PlayerCountry country;
@override final  WirePlayerKind kind;
@override final  WirePlayerConnectionState connectionState;
@override@JsonKey() final  bool ready;
@override final  WireAiPlayer? ai;

/// Create a copy of WirePlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WirePlayerCopyWith<_WirePlayer> get copyWith => __$WirePlayerCopyWithImpl<_WirePlayer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WirePlayer&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.country, country) || other.country == country)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.connectionState, connectionState) || other.connectionState == connectionState)&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.ai, ai) || other.ai == ai));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,name,colorValue,country,kind,connectionState,ready,ai);

@override
String toString() {
  return 'WirePlayer(id: $id, userId: $userId, name: $name, colorValue: $colorValue, country: $country, kind: $kind, connectionState: $connectionState, ready: $ready, ai: $ai)';
}


}

/// @nodoc
abstract mixin class _$WirePlayerCopyWith<$Res> implements $WirePlayerCopyWith<$Res> {
  factory _$WirePlayerCopyWith(_WirePlayer value, $Res Function(_WirePlayer) _then) = __$WirePlayerCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String name, int colorValue, PlayerCountry country, WirePlayerKind kind, WirePlayerConnectionState connectionState, bool ready, WireAiPlayer? ai
});




}
/// @nodoc
class __$WirePlayerCopyWithImpl<$Res>
    implements _$WirePlayerCopyWith<$Res> {
  __$WirePlayerCopyWithImpl(this._self, this._then);

  final _WirePlayer _self;
  final $Res Function(_WirePlayer) _then;

/// Create a copy of WirePlayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? colorValue = null,Object? country = null,Object? kind = null,Object? connectionState = null,Object? ready = null,Object? ai = freezed,}) {
  return _then(_WirePlayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as PlayerCountry,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WirePlayerKind,connectionState: null == connectionState ? _self.connectionState : connectionState // ignore: cast_nullable_to_non_nullable
as WirePlayerConnectionState,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,ai: freezed == ai ? _self.ai : ai // ignore: cast_nullable_to_non_nullable
as WireAiPlayer?,
  ));
}


}

// dart format on
