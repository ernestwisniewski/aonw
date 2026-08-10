// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'city_site_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CitySiteCandidate {

 CityHex get center; List<CityHex> get controlledHexes; List<CityHex> get projectedTerritory; double get score; double get baseScore; double get futureYieldScore; double get overlapPenalty; int get nearestFounderDistance;
/// Create a copy of CitySiteCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitySiteCandidateCopyWith<CitySiteCandidate> get copyWith => _$CitySiteCandidateCopyWithImpl<CitySiteCandidate>(this as CitySiteCandidate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitySiteCandidate&&(identical(other.center, center) || other.center == center)&&const DeepCollectionEquality().equals(other.controlledHexes, controlledHexes)&&const DeepCollectionEquality().equals(other.projectedTerritory, projectedTerritory)&&(identical(other.score, score) || other.score == score)&&(identical(other.baseScore, baseScore) || other.baseScore == baseScore)&&(identical(other.futureYieldScore, futureYieldScore) || other.futureYieldScore == futureYieldScore)&&(identical(other.overlapPenalty, overlapPenalty) || other.overlapPenalty == overlapPenalty)&&(identical(other.nearestFounderDistance, nearestFounderDistance) || other.nearestFounderDistance == nearestFounderDistance));
}


@override
int get hashCode => Object.hash(runtimeType,center,const DeepCollectionEquality().hash(controlledHexes),const DeepCollectionEquality().hash(projectedTerritory),score,baseScore,futureYieldScore,overlapPenalty,nearestFounderDistance);

@override
String toString() {
  return 'CitySiteCandidate(center: $center, controlledHexes: $controlledHexes, projectedTerritory: $projectedTerritory, score: $score, baseScore: $baseScore, futureYieldScore: $futureYieldScore, overlapPenalty: $overlapPenalty, nearestFounderDistance: $nearestFounderDistance)';
}


}

/// @nodoc
abstract mixin class $CitySiteCandidateCopyWith<$Res>  {
  factory $CitySiteCandidateCopyWith(CitySiteCandidate value, $Res Function(CitySiteCandidate) _then) = _$CitySiteCandidateCopyWithImpl;
@useResult
$Res call({
 CityHex center, List<CityHex> controlledHexes, List<CityHex> projectedTerritory, double score, double baseScore, double futureYieldScore, double overlapPenalty, int nearestFounderDistance
});




}
/// @nodoc
class _$CitySiteCandidateCopyWithImpl<$Res>
    implements $CitySiteCandidateCopyWith<$Res> {
  _$CitySiteCandidateCopyWithImpl(this._self, this._then);

  final CitySiteCandidate _self;
  final $Res Function(CitySiteCandidate) _then;

/// Create a copy of CitySiteCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? center = null,Object? controlledHexes = null,Object? projectedTerritory = null,Object? score = null,Object? baseScore = null,Object? futureYieldScore = null,Object? overlapPenalty = null,Object? nearestFounderDistance = null,}) {
  return _then(CitySiteCandidate(
center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as CityHex,controlledHexes: null == controlledHexes ? _self.controlledHexes! : controlledHexes // ignore: cast_nullable_to_non_nullable
as Iterable<CityHex>,projectedTerritory: null == projectedTerritory ? _self.projectedTerritory! : projectedTerritory // ignore: cast_nullable_to_non_nullable
as Iterable<CityHex>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,baseScore: null == baseScore ? _self.baseScore : baseScore // ignore: cast_nullable_to_non_nullable
as double,futureYieldScore: null == futureYieldScore ? _self.futureYieldScore : futureYieldScore // ignore: cast_nullable_to_non_nullable
as double,overlapPenalty: null == overlapPenalty ? _self.overlapPenalty : overlapPenalty // ignore: cast_nullable_to_non_nullable
as double,nearestFounderDistance: null == nearestFounderDistance ? _self.nearestFounderDistance : nearestFounderDistance // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}



/// @nodoc


class _CitySiteCandidate extends CitySiteCandidate {
  const _CitySiteCandidate({required this.center, required  List<CityHex> controlledHexes, required  List<CityHex> projectedTerritory, required this.score, required this.baseScore, required this.futureYieldScore, required this.overlapPenalty, required this.nearestFounderDistance}): _controlledHexes = controlledHexes,_projectedTerritory = projectedTerritory,super._();
  

@override final  CityHex center;
 final  List<CityHex> _controlledHexes;
@override List<CityHex> get controlledHexes {
  if (_controlledHexes is EqualUnmodifiableListView) return _controlledHexes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_controlledHexes);
}

 final  List<CityHex> _projectedTerritory;
@override List<CityHex> get projectedTerritory {
  if (_projectedTerritory is EqualUnmodifiableListView) return _projectedTerritory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_projectedTerritory);
}

@override final  double score;
@override final  double baseScore;
@override final  double futureYieldScore;
@override final  double overlapPenalty;
@override final  int nearestFounderDistance;

/// Create a copy of CitySiteCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitySiteCandidateCopyWith<_CitySiteCandidate> get copyWith => __$CitySiteCandidateCopyWithImpl<_CitySiteCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitySiteCandidate&&(identical(other.center, center) || other.center == center)&&const DeepCollectionEquality().equals(other._controlledHexes, _controlledHexes)&&const DeepCollectionEquality().equals(other._projectedTerritory, _projectedTerritory)&&(identical(other.score, score) || other.score == score)&&(identical(other.baseScore, baseScore) || other.baseScore == baseScore)&&(identical(other.futureYieldScore, futureYieldScore) || other.futureYieldScore == futureYieldScore)&&(identical(other.overlapPenalty, overlapPenalty) || other.overlapPenalty == overlapPenalty)&&(identical(other.nearestFounderDistance, nearestFounderDistance) || other.nearestFounderDistance == nearestFounderDistance));
}


@override
int get hashCode => Object.hash(runtimeType,center,const DeepCollectionEquality().hash(_controlledHexes),const DeepCollectionEquality().hash(_projectedTerritory),score,baseScore,futureYieldScore,overlapPenalty,nearestFounderDistance);

@override
String toString() {
  return 'CitySiteCandidate._internal(center: $center, controlledHexes: $controlledHexes, projectedTerritory: $projectedTerritory, score: $score, baseScore: $baseScore, futureYieldScore: $futureYieldScore, overlapPenalty: $overlapPenalty, nearestFounderDistance: $nearestFounderDistance)';
}


}

/// @nodoc
abstract mixin class _$CitySiteCandidateCopyWith<$Res> implements $CitySiteCandidateCopyWith<$Res> {
  factory _$CitySiteCandidateCopyWith(_CitySiteCandidate value, $Res Function(_CitySiteCandidate) _then) = __$CitySiteCandidateCopyWithImpl;
@override @useResult
$Res call({
 CityHex center, List<CityHex> controlledHexes, List<CityHex> projectedTerritory, double score, double baseScore, double futureYieldScore, double overlapPenalty, int nearestFounderDistance
});




}
/// @nodoc
class __$CitySiteCandidateCopyWithImpl<$Res>
    implements _$CitySiteCandidateCopyWith<$Res> {
  __$CitySiteCandidateCopyWithImpl(this._self, this._then);

  final _CitySiteCandidate _self;
  final $Res Function(_CitySiteCandidate) _then;

/// Create a copy of CitySiteCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? center = null,Object? controlledHexes = null,Object? projectedTerritory = null,Object? score = null,Object? baseScore = null,Object? futureYieldScore = null,Object? overlapPenalty = null,Object? nearestFounderDistance = null,}) {
  return _then(_CitySiteCandidate(
center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as CityHex,controlledHexes: null == controlledHexes ? _self._controlledHexes : controlledHexes // ignore: cast_nullable_to_non_nullable
as List<CityHex>,projectedTerritory: null == projectedTerritory ? _self._projectedTerritory : projectedTerritory // ignore: cast_nullable_to_non_nullable
as List<CityHex>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,baseScore: null == baseScore ? _self.baseScore : baseScore // ignore: cast_nullable_to_non_nullable
as double,futureYieldScore: null == futureYieldScore ? _self.futureYieldScore : futureYieldScore // ignore: cast_nullable_to_non_nullable
as double,overlapPenalty: null == overlapPenalty ? _self.overlapPenalty : overlapPenalty // ignore: cast_nullable_to_non_nullable
as double,nearestFounderDistance: null == nearestFounderDistance ? _self.nearestFounderDistance : nearestFounderDistance // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
