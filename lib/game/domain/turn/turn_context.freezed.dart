// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'turn_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TurnContext {

 GameState get state; GameSave? get save; MapTileLookup get mapTiles; GameRuleset get ruleset; String get playerId; DateTime? get savedAt; List<GameEvent> get events; List<UiEffect> get uiEffects; ScienceYieldBreakdown get bonusScience;
/// Create a copy of TurnContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnContextCopyWith<TurnContext> get copyWith => _$TurnContextCopyWithImpl<TurnContext>(this as TurnContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnContext&&(identical(other.state, state) || other.state == state)&&(identical(other.save, save) || other.save == save)&&(identical(other.mapTiles, mapTiles) || other.mapTiles == mapTiles)&&(identical(other.ruleset, ruleset) || other.ruleset == ruleset)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&const DeepCollectionEquality().equals(other.events, events)&&const DeepCollectionEquality().equals(other.uiEffects, uiEffects)&&(identical(other.bonusScience, bonusScience) || other.bonusScience == bonusScience));
}


@override
int get hashCode => Object.hash(runtimeType,state,save,mapTiles,ruleset,playerId,savedAt,const DeepCollectionEquality().hash(events),const DeepCollectionEquality().hash(uiEffects),bonusScience);

@override
String toString() {
  return 'TurnContext(state: $state, save: $save, mapTiles: $mapTiles, ruleset: $ruleset, playerId: $playerId, savedAt: $savedAt, events: $events, uiEffects: $uiEffects, bonusScience: $bonusScience)';
}


}

/// @nodoc
abstract mixin class $TurnContextCopyWith<$Res>  {
  factory $TurnContextCopyWith(TurnContext value, $Res Function(TurnContext) _then) = _$TurnContextCopyWithImpl;
@useResult
$Res call({
 GameState state, GameSave? save, MapTileLookup mapTiles, GameRuleset ruleset, String playerId, DateTime? savedAt, List<GameEvent> events, List<UiEffect> uiEffects, ScienceYieldBreakdown bonusScience
});


$GameStateCopyWith<$Res> get state;$GameSaveCopyWith<$Res>? get save;

}
/// @nodoc
class _$TurnContextCopyWithImpl<$Res>
    implements $TurnContextCopyWith<$Res> {
  _$TurnContextCopyWithImpl(this._self, this._then);

  final TurnContext _self;
  final $Res Function(TurnContext) _then;

/// Create a copy of TurnContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? save = freezed,Object? mapTiles = null,Object? ruleset = null,Object? playerId = null,Object? savedAt = freezed,Object? events = null,Object? uiEffects = null,Object? bonusScience = null,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as GameState,save: freezed == save ? _self.save : save // ignore: cast_nullable_to_non_nullable
as GameSave?,mapTiles: null == mapTiles ? _self.mapTiles : mapTiles // ignore: cast_nullable_to_non_nullable
as MapTileLookup,ruleset: null == ruleset ? _self.ruleset : ruleset // ignore: cast_nullable_to_non_nullable
as GameRuleset,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<GameEvent>,uiEffects: null == uiEffects ? _self.uiEffects : uiEffects // ignore: cast_nullable_to_non_nullable
as List<UiEffect>,bonusScience: null == bonusScience ? _self.bonusScience : bonusScience // ignore: cast_nullable_to_non_nullable
as ScienceYieldBreakdown,
  ));
}
/// Create a copy of TurnContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameStateCopyWith<$Res> get state {
  
  return $GameStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}/// Create a copy of TurnContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameSaveCopyWith<$Res>? get save {
    if (_self.save == null) {
    return null;
  }

  return $GameSaveCopyWith<$Res>(_self.save!, (value) {
    return _then(_self.copyWith(save: value));
  });
}
}


/// Adds pattern-matching-related methods to [TurnContext].
extension TurnContextPatterns on TurnContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TurnContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TurnContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TurnContext value)  $default,){
final _that = this;
switch (_that) {
case _TurnContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TurnContext value)?  $default,){
final _that = this;
switch (_that) {
case _TurnContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameState state,  GameSave? save,  MapTileLookup mapTiles,  GameRuleset ruleset,  String playerId,  DateTime? savedAt,  List<GameEvent> events,  List<UiEffect> uiEffects,  ScienceYieldBreakdown bonusScience)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TurnContext() when $default != null:
return $default(_that.state,_that.save,_that.mapTiles,_that.ruleset,_that.playerId,_that.savedAt,_that.events,_that.uiEffects,_that.bonusScience);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameState state,  GameSave? save,  MapTileLookup mapTiles,  GameRuleset ruleset,  String playerId,  DateTime? savedAt,  List<GameEvent> events,  List<UiEffect> uiEffects,  ScienceYieldBreakdown bonusScience)  $default,) {final _that = this;
switch (_that) {
case _TurnContext():
return $default(_that.state,_that.save,_that.mapTiles,_that.ruleset,_that.playerId,_that.savedAt,_that.events,_that.uiEffects,_that.bonusScience);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameState state,  GameSave? save,  MapTileLookup mapTiles,  GameRuleset ruleset,  String playerId,  DateTime? savedAt,  List<GameEvent> events,  List<UiEffect> uiEffects,  ScienceYieldBreakdown bonusScience)?  $default,) {final _that = this;
switch (_that) {
case _TurnContext() when $default != null:
return $default(_that.state,_that.save,_that.mapTiles,_that.ruleset,_that.playerId,_that.savedAt,_that.events,_that.uiEffects,_that.bonusScience);case _:
  return null;

}
}

}

/// @nodoc


class _TurnContext extends TurnContext {
  const _TurnContext({required this.state, this.save, required this.mapTiles, required this.ruleset, required this.playerId, this.savedAt, final  List<GameEvent> events = const <GameEvent>[], final  List<UiEffect> uiEffects = const <UiEffect>[], this.bonusScience = ScienceYieldBreakdown.empty}): _events = events,_uiEffects = uiEffects,super._();
  

@override final  GameState state;
@override final  GameSave? save;
@override final  MapTileLookup mapTiles;
@override final  GameRuleset ruleset;
@override final  String playerId;
@override final  DateTime? savedAt;
 final  List<GameEvent> _events;
@override@JsonKey() List<GameEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

 final  List<UiEffect> _uiEffects;
@override@JsonKey() List<UiEffect> get uiEffects {
  if (_uiEffects is EqualUnmodifiableListView) return _uiEffects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_uiEffects);
}

@override@JsonKey() final  ScienceYieldBreakdown bonusScience;

/// Create a copy of TurnContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TurnContextCopyWith<_TurnContext> get copyWith => __$TurnContextCopyWithImpl<_TurnContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TurnContext&&(identical(other.state, state) || other.state == state)&&(identical(other.save, save) || other.save == save)&&(identical(other.mapTiles, mapTiles) || other.mapTiles == mapTiles)&&(identical(other.ruleset, ruleset) || other.ruleset == ruleset)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&const DeepCollectionEquality().equals(other._events, _events)&&const DeepCollectionEquality().equals(other._uiEffects, _uiEffects)&&(identical(other.bonusScience, bonusScience) || other.bonusScience == bonusScience));
}


@override
int get hashCode => Object.hash(runtimeType,state,save,mapTiles,ruleset,playerId,savedAt,const DeepCollectionEquality().hash(_events),const DeepCollectionEquality().hash(_uiEffects),bonusScience);

@override
String toString() {
  return 'TurnContext(state: $state, save: $save, mapTiles: $mapTiles, ruleset: $ruleset, playerId: $playerId, savedAt: $savedAt, events: $events, uiEffects: $uiEffects, bonusScience: $bonusScience)';
}


}

/// @nodoc
abstract mixin class _$TurnContextCopyWith<$Res> implements $TurnContextCopyWith<$Res> {
  factory _$TurnContextCopyWith(_TurnContext value, $Res Function(_TurnContext) _then) = __$TurnContextCopyWithImpl;
@override @useResult
$Res call({
 GameState state, GameSave? save, MapTileLookup mapTiles, GameRuleset ruleset, String playerId, DateTime? savedAt, List<GameEvent> events, List<UiEffect> uiEffects, ScienceYieldBreakdown bonusScience
});


@override $GameStateCopyWith<$Res> get state;@override $GameSaveCopyWith<$Res>? get save;

}
/// @nodoc
class __$TurnContextCopyWithImpl<$Res>
    implements _$TurnContextCopyWith<$Res> {
  __$TurnContextCopyWithImpl(this._self, this._then);

  final _TurnContext _self;
  final $Res Function(_TurnContext) _then;

/// Create a copy of TurnContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? save = freezed,Object? mapTiles = null,Object? ruleset = null,Object? playerId = null,Object? savedAt = freezed,Object? events = null,Object? uiEffects = null,Object? bonusScience = null,}) {
  return _then(_TurnContext(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as GameState,save: freezed == save ? _self.save : save // ignore: cast_nullable_to_non_nullable
as GameSave?,mapTiles: null == mapTiles ? _self.mapTiles : mapTiles // ignore: cast_nullable_to_non_nullable
as MapTileLookup,ruleset: null == ruleset ? _self.ruleset : ruleset // ignore: cast_nullable_to_non_nullable
as GameRuleset,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<GameEvent>,uiEffects: null == uiEffects ? _self._uiEffects : uiEffects // ignore: cast_nullable_to_non_nullable
as List<UiEffect>,bonusScience: null == bonusScience ? _self.bonusScience : bonusScience // ignore: cast_nullable_to_non_nullable
as ScienceYieldBreakdown,
  ));
}

/// Create a copy of TurnContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameStateCopyWith<$Res> get state {
  
  return $GameStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}/// Create a copy of TurnContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameSaveCopyWith<$Res>? get save {
    if (_self.save == null) {
    return null;
  }

  return $GameSaveCopyWith<$Res>(_self.save!, (value) {
    return _then(_self.copyWith(save: value));
  });
}
}

// dart format on
