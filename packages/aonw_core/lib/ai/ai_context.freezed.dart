// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AiContext {

 GameRuleset get ruleset; MapReadView get mapData; int get turn; AiRng get rng; AiPersona get persona; AiDifficulty get difficulty; CivilizationProfile get civProfile; StrategicPlan? get strategicPlan; ScoreRaceAnalysis? get scoreRace; DateTime? get deadline; double get ownControlPercent; int get knownPlayerCount;
/// Create a copy of AiContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiContextCopyWith<AiContext> get copyWith => _$AiContextCopyWithImpl<AiContext>(this as AiContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiContext&&(identical(other.ruleset, ruleset) || other.ruleset == ruleset)&&(identical(other.mapData, mapData) || other.mapData == mapData)&&(identical(other.turn, turn) || other.turn == turn)&&(identical(other.rng, rng) || other.rng == rng)&&(identical(other.persona, persona) || other.persona == persona)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.civProfile, civProfile) || other.civProfile == civProfile)&&(identical(other.strategicPlan, strategicPlan) || other.strategicPlan == strategicPlan)&&(identical(other.scoreRace, scoreRace) || other.scoreRace == scoreRace)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.ownControlPercent, ownControlPercent) || other.ownControlPercent == ownControlPercent)&&(identical(other.knownPlayerCount, knownPlayerCount) || other.knownPlayerCount == knownPlayerCount));
}


@override
int get hashCode => Object.hash(runtimeType,ruleset,mapData,turn,rng,persona,difficulty,civProfile,strategicPlan,scoreRace,deadline,ownControlPercent,knownPlayerCount);

@override
String toString() {
  return 'AiContext(ruleset: $ruleset, mapData: $mapData, turn: $turn, rng: $rng, persona: $persona, difficulty: $difficulty, civProfile: $civProfile, strategicPlan: $strategicPlan, scoreRace: $scoreRace, deadline: $deadline, ownControlPercent: $ownControlPercent, knownPlayerCount: $knownPlayerCount)';
}


}

/// @nodoc
abstract mixin class $AiContextCopyWith<$Res>  {
  factory $AiContextCopyWith(AiContext value, $Res Function(AiContext) _then) = _$AiContextCopyWithImpl;
@useResult
$Res call({
 GameRuleset ruleset, MapReadView mapData, int turn, AiRng rng, AiPersona persona, AiDifficulty difficulty, CivilizationProfile civProfile, StrategicPlan? strategicPlan, ScoreRaceAnalysis? scoreRace, DateTime? deadline, double ownControlPercent, int knownPlayerCount
});


$StrategicPlanCopyWith<$Res>? get strategicPlan;

}
/// @nodoc
class _$AiContextCopyWithImpl<$Res>
    implements $AiContextCopyWith<$Res> {
  _$AiContextCopyWithImpl(this._self, this._then);

  final AiContext _self;
  final $Res Function(AiContext) _then;

/// Create a copy of AiContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ruleset = null,Object? mapData = null,Object? turn = null,Object? rng = null,Object? persona = null,Object? difficulty = null,Object? civProfile = null,Object? strategicPlan = freezed,Object? scoreRace = freezed,Object? deadline = freezed,Object? ownControlPercent = null,Object? knownPlayerCount = null,}) {
  return _then(_self.copyWith(
ruleset: null == ruleset ? _self.ruleset : ruleset // ignore: cast_nullable_to_non_nullable
as GameRuleset,mapData: null == mapData ? _self.mapData : mapData // ignore: cast_nullable_to_non_nullable
as MapReadView,turn: null == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int,rng: null == rng ? _self.rng : rng // ignore: cast_nullable_to_non_nullable
as AiRng,persona: null == persona ? _self.persona : persona // ignore: cast_nullable_to_non_nullable
as AiPersona,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as AiDifficulty,civProfile: null == civProfile ? _self.civProfile : civProfile // ignore: cast_nullable_to_non_nullable
as CivilizationProfile,strategicPlan: freezed == strategicPlan ? _self.strategicPlan : strategicPlan // ignore: cast_nullable_to_non_nullable
as StrategicPlan?,scoreRace: freezed == scoreRace ? _self.scoreRace : scoreRace // ignore: cast_nullable_to_non_nullable
as ScoreRaceAnalysis?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,ownControlPercent: null == ownControlPercent ? _self.ownControlPercent : ownControlPercent // ignore: cast_nullable_to_non_nullable
as double,knownPlayerCount: null == knownPlayerCount ? _self.knownPlayerCount : knownPlayerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AiContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StrategicPlanCopyWith<$Res>? get strategicPlan {
    if (_self.strategicPlan == null) {
    return null;
  }

  return $StrategicPlanCopyWith<$Res>(_self.strategicPlan!, (value) {
    return _then(_self.copyWith(strategicPlan: value));
  });
}
}


/// Adds pattern-matching-related methods to [AiContext].
extension AiContextPatterns on AiContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiContext value)  $default,){
final _that = this;
switch (_that) {
case _AiContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiContext value)?  $default,){
final _that = this;
switch (_that) {
case _AiContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameRuleset ruleset,  MapReadView mapData,  int turn,  AiRng rng,  AiPersona persona,  AiDifficulty difficulty,  CivilizationProfile civProfile,  StrategicPlan? strategicPlan,  ScoreRaceAnalysis? scoreRace,  DateTime? deadline,  double ownControlPercent,  int knownPlayerCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiContext() when $default != null:
return $default(_that.ruleset,_that.mapData,_that.turn,_that.rng,_that.persona,_that.difficulty,_that.civProfile,_that.strategicPlan,_that.scoreRace,_that.deadline,_that.ownControlPercent,_that.knownPlayerCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameRuleset ruleset,  MapReadView mapData,  int turn,  AiRng rng,  AiPersona persona,  AiDifficulty difficulty,  CivilizationProfile civProfile,  StrategicPlan? strategicPlan,  ScoreRaceAnalysis? scoreRace,  DateTime? deadline,  double ownControlPercent,  int knownPlayerCount)  $default,) {final _that = this;
switch (_that) {
case _AiContext():
return $default(_that.ruleset,_that.mapData,_that.turn,_that.rng,_that.persona,_that.difficulty,_that.civProfile,_that.strategicPlan,_that.scoreRace,_that.deadline,_that.ownControlPercent,_that.knownPlayerCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameRuleset ruleset,  MapReadView mapData,  int turn,  AiRng rng,  AiPersona persona,  AiDifficulty difficulty,  CivilizationProfile civProfile,  StrategicPlan? strategicPlan,  ScoreRaceAnalysis? scoreRace,  DateTime? deadline,  double ownControlPercent,  int knownPlayerCount)?  $default,) {final _that = this;
switch (_that) {
case _AiContext() when $default != null:
return $default(_that.ruleset,_that.mapData,_that.turn,_that.rng,_that.persona,_that.difficulty,_that.civProfile,_that.strategicPlan,_that.scoreRace,_that.deadline,_that.ownControlPercent,_that.knownPlayerCount);case _:
  return null;

}
}

}

/// @nodoc


class _AiContext extends AiContext {
  const _AiContext({required this.ruleset, required this.mapData, required this.turn, required this.rng, this.persona = AiPersona.balanced, this.difficulty = AiDifficulty.normal, this.civProfile = CivilizationProfiles.poland, this.strategicPlan, this.scoreRace, this.deadline, this.ownControlPercent = 0.0, this.knownPlayerCount = 1}): super._();
  

@override final  GameRuleset ruleset;
@override final  MapReadView mapData;
@override final  int turn;
@override final  AiRng rng;
@override@JsonKey() final  AiPersona persona;
@override@JsonKey() final  AiDifficulty difficulty;
@override@JsonKey() final  CivilizationProfile civProfile;
@override final  StrategicPlan? strategicPlan;
@override final  ScoreRaceAnalysis? scoreRace;
@override final  DateTime? deadline;
@override@JsonKey() final  double ownControlPercent;
@override@JsonKey() final  int knownPlayerCount;

/// Create a copy of AiContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiContextCopyWith<_AiContext> get copyWith => __$AiContextCopyWithImpl<_AiContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiContext&&(identical(other.ruleset, ruleset) || other.ruleset == ruleset)&&(identical(other.mapData, mapData) || other.mapData == mapData)&&(identical(other.turn, turn) || other.turn == turn)&&(identical(other.rng, rng) || other.rng == rng)&&(identical(other.persona, persona) || other.persona == persona)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.civProfile, civProfile) || other.civProfile == civProfile)&&(identical(other.strategicPlan, strategicPlan) || other.strategicPlan == strategicPlan)&&(identical(other.scoreRace, scoreRace) || other.scoreRace == scoreRace)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.ownControlPercent, ownControlPercent) || other.ownControlPercent == ownControlPercent)&&(identical(other.knownPlayerCount, knownPlayerCount) || other.knownPlayerCount == knownPlayerCount));
}


@override
int get hashCode => Object.hash(runtimeType,ruleset,mapData,turn,rng,persona,difficulty,civProfile,strategicPlan,scoreRace,deadline,ownControlPercent,knownPlayerCount);

@override
String toString() {
  return 'AiContext(ruleset: $ruleset, mapData: $mapData, turn: $turn, rng: $rng, persona: $persona, difficulty: $difficulty, civProfile: $civProfile, strategicPlan: $strategicPlan, scoreRace: $scoreRace, deadline: $deadline, ownControlPercent: $ownControlPercent, knownPlayerCount: $knownPlayerCount)';
}


}

/// @nodoc
abstract mixin class _$AiContextCopyWith<$Res> implements $AiContextCopyWith<$Res> {
  factory _$AiContextCopyWith(_AiContext value, $Res Function(_AiContext) _then) = __$AiContextCopyWithImpl;
@override @useResult
$Res call({
 GameRuleset ruleset, MapReadView mapData, int turn, AiRng rng, AiPersona persona, AiDifficulty difficulty, CivilizationProfile civProfile, StrategicPlan? strategicPlan, ScoreRaceAnalysis? scoreRace, DateTime? deadline, double ownControlPercent, int knownPlayerCount
});


@override $StrategicPlanCopyWith<$Res>? get strategicPlan;

}
/// @nodoc
class __$AiContextCopyWithImpl<$Res>
    implements _$AiContextCopyWith<$Res> {
  __$AiContextCopyWithImpl(this._self, this._then);

  final _AiContext _self;
  final $Res Function(_AiContext) _then;

/// Create a copy of AiContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ruleset = null,Object? mapData = null,Object? turn = null,Object? rng = null,Object? persona = null,Object? difficulty = null,Object? civProfile = null,Object? strategicPlan = freezed,Object? scoreRace = freezed,Object? deadline = freezed,Object? ownControlPercent = null,Object? knownPlayerCount = null,}) {
  return _then(_AiContext(
ruleset: null == ruleset ? _self.ruleset : ruleset // ignore: cast_nullable_to_non_nullable
as GameRuleset,mapData: null == mapData ? _self.mapData : mapData // ignore: cast_nullable_to_non_nullable
as MapReadView,turn: null == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int,rng: null == rng ? _self.rng : rng // ignore: cast_nullable_to_non_nullable
as AiRng,persona: null == persona ? _self.persona : persona // ignore: cast_nullable_to_non_nullable
as AiPersona,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as AiDifficulty,civProfile: null == civProfile ? _self.civProfile : civProfile // ignore: cast_nullable_to_non_nullable
as CivilizationProfile,strategicPlan: freezed == strategicPlan ? _self.strategicPlan : strategicPlan // ignore: cast_nullable_to_non_nullable
as StrategicPlan?,scoreRace: freezed == scoreRace ? _self.scoreRace : scoreRace // ignore: cast_nullable_to_non_nullable
as ScoreRaceAnalysis?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,ownControlPercent: null == ownControlPercent ? _self.ownControlPercent : ownControlPercent // ignore: cast_nullable_to_non_nullable
as double,knownPlayerCount: null == knownPlayerCount ? _self.knownPlayerCount : knownPlayerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AiContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StrategicPlanCopyWith<$Res>? get strategicPlan {
    if (_self.strategicPlan == null) {
    return null;
  }

  return $StrategicPlanCopyWith<$Res>(_self.strategicPlan!, (value) {
    return _then(_self.copyWith(strategicPlan: value));
  });
}
}

// dart format on
